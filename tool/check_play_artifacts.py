"""Inspect the actual signed APK/AAB; no credentials or production API calls."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile


ANDROID = "{http://schemas.android.com/apk/res/android}"
FORBIDDEN_PERMISSIONS = {
    "com.google.android.gms.permission.AD_ID",
    "android.permission.ACCESS_ADSERVICES_AD_ID",
    "android.permission.ACCESS_ADSERVICES_ATTRIBUTION",
    "android.permission.ACCESS_ADSERVICES_CUSTOM_AUDIENCE",
    "android.permission.ACCESS_ADSERVICES_TOPICS",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.MANAGE_EXTERNAL_STORAGE",
    "android.permission.READ_MEDIA_IMAGES",
    "android.permission.READ_MEDIA_VIDEO",
    "android.permission.QUERY_ALL_PACKAGES",
    "android.permission.REQUEST_INSTALL_PACKAGES",
}


def run(*args):
    result = subprocess.run(
        [str(arg) for arg in args], check=True, capture_output=True,
        encoding="utf-8", errors="replace", timeout=180,
    )
    return result.stdout


def native_libraries(archive):
    libraries = {}
    with zipfile.ZipFile(archive) as bundle:
        for name in bundle.namelist():
            if not name.endswith(".so"):
                continue
            data = bundle.read(name)
            assert data[:4] == b"\x7fELF", f"Invalid ELF: {name}"
            assert data[4] == 2, f"Expected a 64-bit library: {name}"
            order = "<" if data[5] == 1 else ">"
            phoff = struct.unpack_from(order + "Q", data, 32)[0]
            entry_size, count = struct.unpack_from(order + "HH", data, 54)
            alignments = []
            for index in range(count):
                offset = phoff + index * entry_size
                if struct.unpack_from(order + "I", data, offset)[0] != 1:
                    continue
                file_offset, address = struct.unpack_from(order + "QQ", data, offset + 8)
                alignment = struct.unpack_from(order + "Q", data, offset + 48)[0]
                assert alignment >= 16384, f"ELF alignment below 16KB: {name}"
                assert file_offset % 16384 == address % 16384, name
                alignments.append(alignment)
            assert alignments, f"No load segments: {name}"
            key = name.removeprefix("base/")
            libraries[key] = {
                "sha256": hashlib.sha256(data).hexdigest(),
                "load_segment_alignments": alignments,
            }
    assert libraries, "No native libraries found"
    return libraries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("aab", type=Path)
    parser.add_argument("--java-home", required=True, type=Path)
    parser.add_argument("--bundletool", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    sdk = Path(os.environ["LOCALAPPDATA"]) / "Android/Sdk/build-tools/36.1.0"
    java = args.java_home / "bin/java.exe"
    # apksigner.bat reads JAVA_HOME even when Java is not on PATH.
    os.environ["JAVA_HOME"] = str(args.java_home)
    badging = run(sdk / "aapt.exe", "dump", "badging", args.apk)
    assert "name='com.yallamarket.app.com'" in badging.splitlines()[0]
    assert "application-debuggable" not in badging
    assert "targetSdkVersion:'36'" in badging
    assert "native-code: 'arm64-v8a'" in badging
    run(sdk / "zipalign.exe", "-c", "-P", "16", "4", args.apk)
    certificates = run(sdk / "apksigner.bat", "verify", "--print-certs", args.apk)
    certificate = re.search(r"certificate SHA-256 digest: ([0-9a-f]+)", certificates)[1]
    run(java, "-jar", args.bundletool, "validate", f"--bundle={args.aab}")
    signature = run(args.java_home / "bin/jarsigner.exe", "-verify", args.aab)
    assert "jar verified" in signature, "AAB signature not verified"
    bundle_certificate = run(
        args.java_home / "bin/keytool.exe", "-printcert", "-jarfile", args.aab
    )
    bundle_digest = re.search(r"SHA256:\s*([A-Fa-f0-9:]+)", bundle_certificate)[1]
    assert bundle_digest.replace(":", "").lower() == certificate, "APK/AAB signing differs"
    manifest_xml = run(
        java, "-jar", args.bundletool, "dump", "manifest",
        f"--bundle={args.aab}", "--module=base",
    )
    manifest = ET.fromstring(manifest_xml)
    permissions = {
        node.get(ANDROID + "name") for node in manifest
        if node.tag in ("uses-permission", "uses-permission-sdk-23")
    }
    apk_permissions = set(re.findall(r"^uses-permission: name='([^']+)'", badging, re.MULTILINE))
    implied = set(re.findall(r"^uses-implied-permission: name='([^']+)'", badging, re.MULTILINE))
    assert permissions | implied == apk_permissions, "APK and AAB permissions differ"
    assert not apk_permissions & FORBIDDEN_PERMISSIONS, apk_permissions & FORBIDDEN_PERMISSIONS
    app = manifest.find("application")
    assert app.get(ANDROID + "usesCleartextTraffic") == "false"
    assert app.get(ANDROID + "allowBackup") == "false"
    assert app.get(ANDROID + "debuggable", "false") == "false"
    features = {
        node.get(ANDROID + "name"): node.get(ANDROID + "required", "true")
        for node in manifest.findall("uses-feature")
    }
    for name in ("location", "location.gps", "location.network"):
        assert features.get("android.hardware." + name) == "false", name
    sdk_node = manifest.find("uses-sdk")
    assert sdk_node.get(ANDROID + "targetSdkVersion") == "36"
    version_code = manifest.get(ANDROID + "versionCode")
    version_name = manifest.get(ANDROID + "versionName")
    assert f"versionCode='{version_code}'" in badging
    assert f"versionName='{version_name}'" in badging
    apk_native = native_libraries(args.apk)
    aab_native = native_libraries(args.aab)
    assert apk_native == aab_native, "APK and AAB contain different native code"
    with zipfile.ZipFile(args.apk) as apk_zip, zipfile.ZipFile(args.aab) as aab_zip:
        apk_dex = {
            name: hashlib.sha256(apk_zip.read(name)).hexdigest()
            for name in apk_zip.namelist() if re.fullmatch(r"classes\d*\.dex", name)
        }
        aab_dex = {
            name.removeprefix("base/dex/"): hashlib.sha256(aab_zip.read(name)).hexdigest()
            for name in aab_zip.namelist() if re.fullmatch(r"base/dex/classes\d*\.dex", name)
        }
        assert apk_dex and apk_dex == aab_dex, "APK and AAB DEX code differs"
    config = run(java, "-jar", args.bundletool, "dump", "config", f"--bundle={args.aab}")
    assert "PAGE_ALIGNMENT_16K" in config, "Bundle requests 4KB ZIP alignment"
    report = {
        "package": manifest.get("package"),
        "version_code": int(version_code), "version_name": version_name,
        "min_sdk": int(sdk_node.get(ANDROID + "minSdkVersion")), "target_sdk": 36,
        "apk_sha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
        "aab_sha256": hashlib.sha256(args.aab.read_bytes()).hexdigest(),
        "apk_signing_certificate_sha256": certificate,
        "apk_signature": "verified", "aab_signature": "verified",
        "bundle_structure": "valid", "zip_alignment_16kb": "passed",
        "bundle_alignment": "PAGE_ALIGNMENT_16K",
        "native_libraries_match": True, "native_libraries": apk_native,
        "dex_files_match": True, "dex_files": apk_dex,
        "permissions": sorted(permissions), "implied_permissions": sorted(implied),
        "hardware_features": features,
        "cleartext_traffic": False, "backup": False, "debuggable": False,
    }
    args.output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    args.output.with_suffix(".manifest.xml").write_text(manifest_xml, encoding="utf-8")
    print(f"Verified {version_name} / {version_code}: signing, permissions, SDK, 16KB, APK/AAB parity.")


if __name__ == "__main__":
    main()
