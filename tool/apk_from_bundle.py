"""Create a signed universal APK from an already built release AAB."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import zipfile


def decode_property(value):
    escapes = {"t": "\t", "n": "\n", "r": "\r", "f": "\f"}
    return re.sub(
        r"\\(u[0-9a-fA-F]{4}|.)",
        lambda match: chr(int(match[1][1:], 16)) if match[1].startswith("u")
        else escapes.get(match[1], match[1]),
        value,
    )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("aab", type=Path)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--java-home", required=True, type=Path)
    parser.add_argument("--bundletool", required=True, type=Path)
    args = parser.parse_args()
    app = Path(__file__).resolve().parent.parent
    properties = {}
    for line in (app / "android/key.properties").read_text(encoding="latin-1").splitlines():
        if not line.strip() or line.lstrip().startswith(("#", "!")):
            continue
        key, separator, value = line.partition("=")
        if separator:
            properties[key.strip()] = decode_property(value.lstrip(" \t\f"))
    keystore = Path(properties["storeFile"])
    if not keystore.is_absolute():
        keystore = app / "android/app" / keystore
    assert keystore.is_file(), "Upload keystore is missing"
    for name in ("storePassword", "keyPassword"):
        assert not any(c in properties[name] for c in "\r\n"), "Multiline password is unsupported"
    with tempfile.TemporaryDirectory(prefix="yalla-bundle-apk-") as temporary:
        directory = Path(temporary)
        store_password = directory / "store-password.txt"
        key_password = directory / "key-password.txt"
        store_password.write_text(properties["storePassword"] + "\n", encoding="utf-8")
        key_password.write_text(properties["keyPassword"] + "\n", encoding="utf-8")
        result = subprocess.run([
            str(args.java_home / "bin/java.exe"), "-jar", str(args.bundletool),
            "build-apks", f"--bundle={args.aab.resolve()}",
            f"--output={directory / 'release.apks'}", "--mode=universal",
            f"--ks={keystore}", f"--ks-key-alias={properties['keyAlias']}",
            f"--ks-pass=file:{store_password}", f"--key-pass=file:{key_password}",
        ], capture_output=True, text=True, encoding="utf-8", errors="replace")
        if result.returncode:
            raise SystemExit("bundletool APK generation failed; no passwords were logged.")
        with zipfile.ZipFile(directory / "release.apks") as archive:
            with archive.open("universal.apk") as source, args.apk.open("wb") as target:
                shutil.copyfileobj(source, target)
    print(f"Prepared signed APK from completed AAB: {args.apk.name}")


if __name__ == "__main__":
    main()
