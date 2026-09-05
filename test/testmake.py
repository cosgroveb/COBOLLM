#!/usr/bin/env python3
import os
import pathlib
import subprocess
import tempfile


root = pathlib.Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory() as temporary:
    directory = pathlib.Path(temporary)
    capture = directory / "capture"
    marker = directory / "executed"
    task = (
        'quoted "value" and single \'value\'; touch "'
        + str(marker)
        + '"\n$HOME $(touch ignored) $$ end'
    )
    environment = os.environ.copy()
    environment["COBOLLM_RUN_CAPTURE"] = str(capture)
    subprocess.run(
        [
            "make",
            "--no-print-directory",
            "--assume-old=test/runargv.py",
            "PROGRAM=test/runargv.py",
            f"TASK={task}",
            "run",
        ],
        cwd=root,
        env=environment,
        check=True,
    )
    if capture.read_bytes() != os.fsencode(task):
        raise SystemExit("make run changed TASK bytes")
    if marker.exists():
        raise SystemExit("make run executed TASK as shell source")

print("PASS make run argument")
