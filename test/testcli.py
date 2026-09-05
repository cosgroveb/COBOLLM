#!/usr/bin/env python3
import os
import subprocess
import sys


def run(program, args, expected_code, expected_out, expected_err):
    env = os.environ.copy()
    env.update(
        OPENAI_API_KEY="test-secret",
        OPENAI_MODEL="gpt-test",
        OPENAI_BASE_URL="https://example",
    )
    completed = subprocess.run(
        [program, *args], env=env, capture_output=True, check=False
    )
    actual = (completed.returncode, completed.stdout, completed.stderr)
    expected = (expected_code, expected_out, expected_err)
    if actual != expected:
        raise AssertionError(
            f"args={args!r}: expected {expected!r}, got {actual!r}"
        )


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: testcli.py PROGRAM")
    program = sys.argv[1]
    usage = b"COBOLLM: usage: expected exactly one nonempty task\n"
    capacity = b"COBOLLM: capacity: fixed buffer limit exceeded\n"
    run(program, [], 2, b"", usage)
    run(program, [""], 2, b"", usage)
    run(program, ["   "], 2, b"", usage)
    run(program, ["a", "b"], 2, b"", usage)
    run(program, [" lead  middle   "], 0, b"ok", b"")
    run(program, ["x" * 65534], 0, b"ok", b"")
    run(program, ["x" * 65535], 0, b"ok", b"")
    run(program, ["x" * 65536], 6, b"", capacity)
    print("PASS GNU launcher")


if __name__ == "__main__":
    main()
