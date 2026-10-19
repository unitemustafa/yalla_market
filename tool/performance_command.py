"""Run a measurement without conflating native stderr with its exit status."""

import argparse
import json
import subprocess
from pathlib import Path


def classify(returncode, artifact):
    if returncode:
        return (
            "completed_with_process_error"
            if artifact.get("completed") is True
            else "process_error"
        )
    return "completed" if artifact.get("completed") is True else "incomplete_artifact"


def run(command, output, artifact):
    output, artifact = Path(output), Path(artifact)
    if artifact.exists():
        raise ValueError(
            "Choose a new artifact path; existing results must be preserved"
        )
    output.mkdir(parents=True, exist_ok=False)
    with (
        (output / "stdout.log").open("wb") as stdout,
        (output / "stderr.log").open("wb") as stderr,
    ):
        try:
            process = subprocess.run(command, stdout=stdout, stderr=stderr, check=False)
        except OSError as error:
            result = {
                "native_exit_code": None,
                "status": "launch_error",
                "error_type": type(error).__name__,
                "artifact_completed": False,
            }
            (output / "execution.json").write_text(
                json.dumps(result, indent=2), encoding="utf-8"
            )
            return 127
    try:
        data = json.loads(artifact.read_text(encoding="utf-8-sig"))
        if not isinstance(data, dict):
            data = {}
    except (OSError, ValueError):
        data = {}
    status = classify(process.returncode, data)
    result = {
        "native_exit_code": process.returncode,
        "status": status,
        "artifact_completed": data.get("completed") is True,
        "artifact": str(artifact),
        "stdout": "stdout.log",
        "stderr": "stderr.log",
    }
    (output / "execution.json").write_text(
        json.dumps(result, indent=2), encoding="utf-8"
    )
    return process.returncode or (0 if status == "completed" else 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--artifact", type=Path, required=True)
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    if not command:
        parser.error("Supply a native command after --")
    raise SystemExit(run(command, args.output, args.artifact))


if __name__ == "__main__":
    main()
