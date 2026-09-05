#!/usr/bin/env python3
import os
import pathlib
import sys


pathlib.Path(os.environ["COBOLLM_RUN_CAPTURE"]).write_bytes(
    os.fsencode(sys.argv[1])
)
