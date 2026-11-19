"""Build signed review artifacts without exposing encoded environment values."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.stderr.reconfigure(encoding="utf-8", errors="replace")


APP = Path(__file__).resolve().parent.parent
RELEASE = APP.parent / "release"


def main():
    match = re.search(
        r"^version:\s*(\S+)\+(\d+)\s*$",
        (APP / "pubspec.yaml").read_text(encoding="utf-8"),
        re.MULTILINE,
    )
    version, code = match.groups()
    kinds = sys.argv[1:] or ["appbundle", "apk"]
    if any(kind not in ("apk", "appbundle") for kind in kinds):
        raise SystemExit("Expected appbundle and/or apk")
    flutter = shutil.which("flutter")
    if not flutter:
        raise SystemExit("Flutter is not on PATH")
    environment = os.environ.copy()
    environment.pop("DEBUG", None)
    dart = Path(flutter).with_name("dart.bat" if os.name == "nt" else "dart")
    subprocess.run(
        [str(dart), "run", "tool/release_preflight.dart",
         "env/production.local.json", "--platform=android"],
        cwd=APP, env=environment, check=True,
    )
    RELEASE.mkdir(exist_ok=True)
    for kind in kinds:
        log_path = RELEASE / f"build-{code}-{kind}.log"
        command = [
            flutter, "build", kind, "--release", "--obfuscate",
            "--target-platform=android-arm64",
            f"--split-debug-info=build/debug-symbols/android/{code}",
            "--dart-define-from-file=env/production.local.json",
        ]
        print(f"Building {kind} for {version} / {code}", flush=True)
        with log_path.open("w", encoding="utf-8") as log:
            process = subprocess.Popen(
                command, cwd=APP, env=environment,
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                text=True, encoding="utf-8", errors="replace",
            )
            for raw in process.stdout:
                line = re.sub(r"(-Pdart-defines=)[^\s\r\n]+", r"\1[REDACTED]", raw)
                log.write(line)
                log.flush()
                if any(marker in line for marker in (
                    "Running Gradle", "Built ", "FAILURE:", "Error:",
                    "* What went wrong:", "BUILD FAILED",
                )):
                    print(line.rstrip(), flush=True)
            result = process.wait()
        if result:
            raise SystemExit(f"Build failed ({result}); inspect {log_path.name}")
        source = APP / (
            "build/app/outputs/bundle/release/app-release.aab" if kind == "appbundle"
            else "build/app/outputs/flutter-apk/app-release.apk"
        )
        suffix = "aab" if kind == "appbundle" else "apk"
        target = RELEASE / f"yalla-market-{version}-{code}.{suffix}"
        shutil.copy2(source, target)
        print(f"Prepared {target.name}", flush=True)
    symbols = APP / f"build/debug-symbols/android/{code}"
    target_symbols = RELEASE / f"release-symbols/{code}"
    shutil.copytree(symbols, target_symbols, dirs_exist_ok=True)
    mapping = APP / "build/app/outputs/mapping/release/mapping.txt"
    if mapping.exists():
        shutil.copy2(mapping, target_symbols / "mapping.txt")


if __name__ == "__main__":
    main()
