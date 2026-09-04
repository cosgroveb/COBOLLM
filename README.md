# COBOLLM

Build and run the hello world program with GnuCOBOL:

```sh
make run
```

Run the portable COBOL unit test:

```sh
make test
```

The GNU build uses GnuCOBOL's strict IBM dialect. The test calls `GREETER`
through its `LINKAGE SECTION`, compares the returned message, and exits with a
nonzero return code on failure.

## z/OS test

Copy these files to fixed-block, 80-byte record data sets:

- `test/tsthello.cob` to `your.hlq.COBOLLM.COBOL(TSTHELLO)`
- `greeter.cob` to `your.hlq.COBOLLM.COBOL(GREETER)`
- `copy/HELLOMSG.cpy` to `your.hlq.COBOLLM.COPY(HELLOMSG)`

Set `HLQ` in `zos/test.jcl`, adjust the job card for the target system, and
submit the job. A passing run prints `PASS GREETER HAPPY PATH` and returns
condition code 0.
