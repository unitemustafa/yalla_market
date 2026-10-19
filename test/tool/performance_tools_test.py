import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from tool.performance_android import PACKAGE, prepare_fresh_install, storage_snapshot
from tool.performance_command import run


class NativeExecutionTests(unittest.TestCase):
    def execute(self, code, completed):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact = root / "raw.json"
            script = "import pathlib,sys;pathlib.Path(sys.argv[1]).write_text(sys.argv[2]);print('native warning',file=sys.stderr);sys.exit(int(sys.argv[3]))"
            result = run(
                [
                    sys.executable,
                    "-c",
                    script,
                    str(artifact),
                    json.dumps({"completed": completed}),
                    str(code),
                ],
                root / "execution",
                artifact,
            )
            evidence = json.loads((root / "execution/execution.json").read_text())
            self.assertIn("native warning", (root / "execution/stderr.log").read_text())
            return result, evidence

    def test_stderr_does_not_turn_native_success_into_failure(self):
        result, evidence = self.execute(0, True)
        self.assertEqual(result, 0)
        self.assertEqual(evidence["status"], "completed")

    def test_completed_artifact_does_not_hide_native_error(self):
        result, evidence = self.execute(7, True)
        self.assertEqual(result, 7)
        self.assertEqual(evidence["status"], "completed_with_process_error")

    def test_zero_exit_does_not_certify_incomplete_measurement(self):
        result, evidence = self.execute(0, False)
        self.assertEqual(result, 1)
        self.assertEqual(evidence["status"], "incomplete_artifact")

    def test_rejects_old_artifact_before_launch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            artifact = root / "raw.json"
            artifact.write_text('{"completed":true}')
            with patch("tool.performance_command.subprocess.run") as launch:
                with self.assertRaises(ValueError):
                    run(["unused"], root / "execution", artifact)
                launch.assert_not_called()

    def test_missing_executable_still_records_launch_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch(
                "tool.performance_command.subprocess.run", side_effect=FileNotFoundError
            ):
                result = run(["missing"], root / "execution", root / "raw.json")
            evidence = json.loads((root / "execution/execution.json").read_text())
            self.assertEqual(result, 127)
            self.assertEqual(evidence["status"], "launch_error")
            self.assertIsNone(evidence["native_exit_code"])


class StorageSnapshotTests(unittest.TestCase):
    def test_denied_private_data_is_unavailable_instead_of_zero(self):
        responses = [subprocess.CalledProcessError(1, ["adb"])] * 4 + [
            f"package:/data/app/~~test/{PACKAGE}-test/base.apk",
            "123\t/data/app/test",
        ]
        with patch("tool.performance_android.adb", side_effect=responses):
            value = storage_snapshot("adb", "device")
        self.assertEqual(value["sizes"]["private_total"]["status"], "unavailable")
        self.assertNotIn("kib", value["sizes"]["private_total"])
        self.assertEqual(value["sizes"]["installed_code"]["kib"], 123)

    def test_unexpected_code_path_is_not_passed_to_a_shell(self):
        with patch(
            "tool.performance_android.adb",
            side_effect=["4 x"] * 4 + ["package:/data/app/unsafe;command/base.apk"],
        ) as call:
            value = storage_snapshot("adb", "device")
        self.assertEqual(value["sizes"]["installed_code"]["status"], "unavailable")
        self.assertEqual(call.call_count, 5)


class FreshInstallTests(unittest.TestCase):
    def prepare(self, responses, package=PACKAGE):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            apk = root / "isolated.apk"
            apk.write_bytes(b"test-apk")
            with (
                patch(
                    "tool.performance_android.subprocess.run",
                    return_value=subprocess.CompletedProcess(
                        [], 0, f"package: name='{package}'\n"
                    ),
                ),
                patch("tool.performance_android.adb", side_effect=responses) as adb,
            ):
                try:
                    value = prepare_fresh_install("adb", "device", apk, "aapt", root)
                except (ValueError, subprocess.CalledProcessError):
                    value = None
                evidence = (
                    json.loads((root / "fresh-install.json").read_text())
                    if (root / "fresh-install.json").exists()
                    else None
                )
                return value, evidence, adb.call_args_list

    def test_production_apk_is_rejected_before_any_device_action(self):
        value, evidence, calls = self.prepare([], "com.yallamarket.app")
        self.assertIsNone(value)
        self.assertIsNone(evidence)
        self.assertEqual(calls, [])

    def test_failed_uninstall_cannot_proceed_to_install(self):
        value, evidence, calls = self.prepare(
            ["0", f"package:{PACKAGE}", "Failure [DELETE_FAILED_INTERNAL_ERROR]"]
        )
        self.assertIsNone(value)
        self.assertFalse(evidence["verified"])
        self.assertFalse(any("install" in call.args[2:] for call in calls))

    def test_checks_absence_and_unlaunched_user_before_certifying(self):
        value, evidence, _ = self.prepare(
            [
                "0",
                f"package:{PACKAGE}",
                "Success",
                "",
                "Performing Streamed Install\nSuccess",
                "User 0: installed=true\n    notLaunched=true\nUser 10: notLaunched=false",
            ]
        )
        self.assertTrue(value["verified"])
        self.assertTrue(evidence["absent_before_install"])

    def test_already_launched_state_is_not_fresh(self):
        value, evidence, _ = self.prepare(
            [
                "0",
                "",
                "",
                "Success",
                "User 0: notLaunched=false\nUser 10: notLaunched=true",
            ]
        )
        self.assertIsNone(value)
        self.assertFalse(evidence["verified"])


if __name__ == "__main__":
    unittest.main()
