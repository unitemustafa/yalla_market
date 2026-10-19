"""Read-only device inventory/samples; startup actions target the isolated APK."""

import argparse
import hashlib
import json
import re
import subprocess
import time
from datetime import datetime, timezone
from pathlib import Path

PACKAGE = "com.yallamarket.app.performance"


def prepare_fresh_install(executable, serial, apk, aapt, output):
    """Fail closed before installing anything except the isolated package."""
    badging = subprocess.run(
        [str(aapt), "dump", "badging", str(apk)],
        capture_output=True,
        text=True,
        timeout=30,
        check=True,
    ).stdout
    match = re.search(r"^package: name='([^']+)'", badging, re.MULTILINE)
    if not match or match.group(1) != PACKAGE:
        raise ValueError("Fresh install accepts only the isolated performance APK")
    evidence = {
        "package": PACKAGE,
        "apk_sha256": hashlib.sha256(apk.read_bytes()).hexdigest(),
        "verified": False,
    }
    target = output / "fresh-install.json"
    try:
        if adb(executable, serial, "shell", "am", "get-current-user") != "0":
            raise ValueError(
                "Fresh install measurement is restricted to Android user 0"
            )
        packages = adb(
            executable, serial, "shell", "pm", "list", "packages", PACKAGE
        ).splitlines()
        if f"package:{PACKAGE}" in packages:
            result = adb(executable, serial, "uninstall", PACKAGE)
            if result != "Success":
                raise ValueError("Isolated uninstall was not confirmed")
        packages = adb(
            executable, serial, "shell", "pm", "list", "packages", PACKAGE
        ).splitlines()
        if f"package:{PACKAGE}" in packages:
            raise ValueError(
                "Isolated package remains installed; cannot certify fresh install"
            )
        evidence["absent_before_install"] = True
        result = adb(executable, serial, "install", str(apk))
        if "Success" not in result.splitlines():
            raise ValueError("Isolated installation was not confirmed")
        details = adb(executable, serial, "shell", "dumpsys", "package", PACKAGE)
        user_zero = re.search(r"User 0:([^\n]*(?:\n(?!\s*User \d+:)[^\n]*)*)", details)
        if not user_zero or "notLaunched=true" not in user_zero.group(1):
            raise ValueError(
                "Fresh package was already launched or state is unavailable"
            )
        evidence["verified"] = True
        return evidence
    finally:
        target.write_text(json.dumps(evidence, indent=2), encoding="utf-8")


def adb(executable, serial, *args):
    result = subprocess.run(
        [executable, "-s", serial, *args],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=20,
        check=True,
    )
    return result.stdout.strip()


def inventory(executable, serial):
    def shell(*args):
        return adb(executable, serial, "shell", *args)

    return {
        "recorded_at": datetime.now(timezone.utc).isoformat(),
        "model": shell("getprop", "ro.product.model"),
        "android": shell("getprop", "ro.build.version.release"),
        "sdk": shell("getprop", "ro.build.version.sdk"),
        "abi": shell("getprop", "ro.product.cpu.abilist"),
        "memory": shell("cat", "/proc/meminfo").splitlines()[:5],
        "battery": [
            line.strip()
            for line in shell("dumpsys", "battery").splitlines()
            if re.match(r"\s*(level|temperature|status|voltage):", line)
        ],
        "brightness": shell("settings", "get", "system", "screen_brightness"),
        "peak_refresh_rate": shell("settings", "get", "system", "peak_refresh_rate"),
        "min_refresh_rate": shell("settings", "get", "system", "min_refresh_rate"),
        "display_modes": [
            line.strip()
            for line in shell("dumpsys", "display").splitlines()
            if any(
                key in line
                for key in ("mActiveModeId=", "mDisplayModeSpecs=", "DisplayConfig{")
            )
        ],
        "accessibility_enabled": shell(
            "settings", "get", "secure", "accessibility_enabled"
        ),
        "animator_scale": shell("settings", "get", "global", "animator_duration_scale"),
        "production_version": [
            line.strip()
            for line in shell("dumpsys", "package", "com.yallamarket.app").splitlines()
            if "versionName=" in line or "versionCode=" in line
        ],
        "settings_changed": False,
    }


def storage_snapshot(executable, serial):
    """Sizes only: never list or export application data contents."""
    result = {
        "recorded_at": datetime.now(timezone.utc).isoformat(),
        "package": PACKAGE,
        "unit": "KiB",
        "sizes": {},
    }
    for name, directory in (
        ("private_total", "."),
        ("files", "files"),
        ("cache", "cache"),
        ("code_cache", "code_cache"),
    ):
        try:
            value = adb(
                executable, serial, "shell", "run-as", PACKAGE, "du", "-sk", directory
            )
            result["sizes"][name] = {"status": "measured", "kib": int(value.split()[0])}
        except (subprocess.SubprocessError, ValueError, IndexError) as error:
            result["sizes"][name] = {
                "status": "unavailable",
                "reason": type(error).__name__,
            }
    try:
        paths = adb(executable, serial, "shell", "pm", "path", PACKAGE).splitlines()
        apk = next(
            line.removeprefix("package:")
            for line in paths
            if line.endswith("/base.apk")
        )
        if not apk.startswith("/data/app/") or not re.fullmatch(
            r"[A-Za-z0-9/_~+=.-]+", apk
        ):
            raise ValueError("Unexpected package code path")
        value = adb(executable, serial, "shell", "du", "-sk", apk.rsplit("/", 1)[0])
        result["sizes"]["installed_code"] = {
            "status": "measured",
            "kib": int(value.split()[0]),
        }
    except (subprocess.SubprocessError, ValueError, IndexError, StopIteration) as error:
        result["sizes"]["installed_code"] = {
            "status": "unavailable",
            "reason": type(error).__name__,
        }
    result["limitations"] = (
        "Observed package/private directories only; excludes shared system compilation caches. Unavailable is not zero."
    )
    return result


def current_cpu(executable, serial):
    try:
        pids = adb(executable, serial, "shell", "pidof", PACKAGE).split()
    except subprocess.CalledProcessError:
        pids = []
    if not pids:
        return "isolated_process_not_running"
    raw = adb(
        executable, serial, "shell", "top", "-b", "-n", "2", "-d", "1", "-p", pids[0]
    )
    # top's first window can represent a long preceding interval. Retain the
    # second window, sampled over one second, for this isolated process only.
    return "Tasks:" + raw.rsplit("Tasks:", 1)[-1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", required=True)
    parser.add_argument("--device", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--sample-seconds", type=int, default=0)
    parser.add_argument("--startup", action="store_true")
    parser.add_argument(
        "--release-review",
        action="store_true",
        help="Run one private-fixture review after startup sampling",
    )
    parser.add_argument(
        "--first-install",
        action="store_true",
        help="Record once only immediately after a fresh isolated install",
    )
    parser.add_argument(
        "--fresh-install-apk",
        type=Path,
        help="Verified reinstall of isolated package only",
    )
    parser.add_argument(
        "--aapt",
        type=Path,
        help="Android aapt used to verify APK package before reinstall",
    )
    parser.add_argument(
        "--first-install-only",
        action="store_true",
        help="One verified fresh launch; no cold/warm repeats",
    )
    parser.add_argument(
        "--storage",
        action="store_true",
        help="Read isolated package disk sizes without exporting contents",
    )
    args = parser.parse_args()
    if args.startup and args.release_review:
        parser.error("Startup and authenticated review must be separate sessions")
    if args.first_install and (
        not args.startup or not args.fresh_install_apk or not args.aapt
    ):
        parser.error(
            "--first-install requires --startup, --fresh-install-apk and --aapt for verification"
        )
    if (args.fresh_install_apk or args.first_install_only) and not args.first_install:
        parser.error("Fresh-install options require --first-install")
    args.output.mkdir(parents=True, exist_ok=True)
    if args.startup and any(
        (args.output / name).exists() for name in ("startup.json", "startup.raw.jsonl")
    ):
        parser.error(
            "Choose a new output directory; existing startup results must be preserved"
        )
    fresh_install = (
        prepare_fresh_install(
            args.adb, args.device, args.fresh_install_apk, args.aapt, args.output
        )
        if args.first_install
        else None
    )
    data = inventory(args.adb, args.device)
    (args.output / "device.json").write_text(
        json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    if args.storage:
        (args.output / "storage.json").write_text(
            json.dumps(storage_snapshot(args.adb, args.device), indent=2),
            encoding="utf-8",
        )
    start = time.monotonic()
    while time.monotonic() - start < args.sample_seconds:
        tick = time.monotonic()
        sample = {
            "time": time.time(),
            "memory": adb(
                args.adb, args.device, "shell", "dumpsys", "meminfo", PACKAGE
            ),
            "cpu": current_cpu(args.adb, args.device),
            "cpu_method": "top second 1-second window; percent of one CPU core",
            "battery": adb(args.adb, args.device, "shell", "dumpsys", "battery"),
        }
        with (args.output / "resources.jsonl").open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(sample) + "\n")
        time.sleep(max(0, 5 - (time.monotonic() - tick)))
    if args.startup:
        # Android TotalTime is retained by its real name; it is not renamed
        # first Flutter frame or usable content without application markers.
        samples = []
        seen_events = set()
        activity = PACKAGE + "/com.yallamarket.app.MainActivity"
        modes = (["first_install"] if args.first_install else []) + [
            "process_stopped_disk_cache_preserved",
            "background_return",
        ]
        if args.first_install_only:
            modes = ["first_install"]
        for state in modes:
            for repeat in range(1 if state == "first_install" else 30):
                if state != "background_return":
                    adb(args.adb, args.device, "shell", "am", "force-stop", PACKAGE)
                else:
                    adb(
                        args.adb,
                        args.device,
                        "shell",
                        "input",
                        "keyevent",
                        "KEYCODE_HOME",
                    )
                    time.sleep(1)
                raw = adb(
                    args.adb, args.device, "shell", "am", "start", "-W", "-n", activity
                )
                try:
                    pids = adb(args.adb, args.device, "shell", "pidof", PACKAGE).split()
                except subprocess.CalledProcessError:
                    pids = []
                pid = pids[0] if pids else None
                events = []
                for _ in range(20 if pid else 0):
                    log = adb(
                        args.adb,
                        args.device,
                        "logcat",
                        "-d",
                        "--pid=" + pid,
                        "-s",
                        "flutter:I",
                    )
                    markers = [
                        line.split("PERF_STARTUP ", 1)[1]
                        for line in log.splitlines()
                        if "PERF_STARTUP " in line
                    ]
                    events = []
                    for marker in markers:
                        try:
                            event = json.loads(marker)
                            identity = (pid, event.get("epoch_ms"), event.get("event"))
                            if identity not in seen_events:
                                events.append(event)
                        except ValueError:
                            continue
                    desired = (
                        "resume_usable_content"
                        if state == "background_return"
                        else "usable_content"
                    )
                    frame = (
                        "resume_first_frame"
                        if state == "background_return"
                        else "first_frame"
                    )
                    names = {event.get("event") for event in events}
                    if {desired, frame}.issubset(names):
                        break
                    time.sleep(0.25)
                samples.append(
                    {
                        "state": state,
                        "repeat": repeat + 1,
                        "android_activity_start": raw,
                        "events": events,
                        "error": None if pid else "isolated_process_not_running",
                    }
                )
                seen_events.update(
                    (pid, event.get("epoch_ms"), event.get("event")) for event in events
                )
                with (args.output / "startup.raw.jsonl").open(
                    "a", encoding="utf-8"
                ) as stream:
                    stream.write(json.dumps(samples[-1]) + "\n")
                time.sleep(1)
        (args.output / "startup.json").write_text(
            json.dumps(
                {
                    "scope": "isolated_package",
                    "samples": samples,
                    "first_flutter_frame": "Dart main to raster end; Android TotalTime retained separately",
                    "usable_content": "Unauthenticated entry controls; images may still load",
                    "first_install": "recorded"
                    if args.first_install
                    else "unmeasured_no_reinstall_performed",
                    "fresh_install_verification": fresh_install,
                    "limitations": [
                        "Firebase and push excluded in isolated package",
                        "Warm markers begin at Dart resume callback, not tap",
                    ],
                },
                indent=2,
            ),
            encoding="utf-8",
        )
    if args.release_review:
        adb(args.adb, args.device, "shell", "am", "force-stop", PACKAGE)
        adb(
            args.adb,
            args.device,
            "shell",
            "am",
            "start",
            "-W",
            "-n",
            PACKAGE + "/com.yallamarket.app.MainActivity",
        )
        events, seen = [], set()
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            try:
                pid = adb(args.adb, args.device, "shell", "pidof", PACKAGE).split()[0]
                log = adb(
                    args.adb,
                    args.device,
                    "logcat",
                    "-d",
                    "--pid=" + pid,
                    "-s",
                    "flutter:I",
                )
            except (subprocess.CalledProcessError, IndexError):
                break
            for line in log.splitlines():
                if "PERF_STARTUP " not in line:
                    continue
                try:
                    event = json.loads(line.split("PERF_STARTUP ", 1)[1])
                except ValueError:
                    continue
                if (
                    event.get("event") != "release_review"
                    or event.get("epoch_ms") in seen
                ):
                    continue
                seen.add(event.get("epoch_ms"))
                events.append(event)
            if any(e.get("status") in {"passed", "failed"} for e in events):
                break
            time.sleep(0.5)
        result = {
            "scope": "isolated_release_functional_review",
            "events": events,
            "completed": any(
                e.get("status") == "passed" and e.get("push_isolated") for e in events
            ),
            "limitations": "Rendered control callbacks, not touch latency; private fixture deleted by the app",
        }
        (args.output / "release-review.json").write_text(
            json.dumps(result, indent=2), encoding="utf-8"
        )
        print("Release review completed: " + str(result["completed"]))
        if not result["completed"]:
            raise SystemExit(1)
    print("Device evidence: " + str(args.output))


if __name__ == "__main__":
    main()
