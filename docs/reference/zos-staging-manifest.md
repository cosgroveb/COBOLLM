# z/OS staging manifest

This manifest maps every repository source used by `zos/build.jcl`,
`zos/test.jcl`, `zos/tsttls.jcl`, or `zos/run.jcl` to its checked JCL data set
and member.
Follow [How to prepare the z/OS target](../how-to/prepare-the-zos-target.md)
for data set allocation, site-value substitution, and staging commands.

| Repository path | Data set and member | Jobs |
|---|---|---|
| `cobollm.cob` | `YOURHLQ.COBOLLM.COBOL(COBOLLM)` | BUILD, TEST |
| `respapi.cob` | `YOURHLQ.COBOLLM.COBOL(RESPAPI)` | BUILD, TEST |
| `jsonscan.cob` | `YOURHLQ.COBOLLM.COBOL(JSONSCAN)` | BUILD, TEST |
| `http11.cob` | `YOURHLQ.COBOLLM.COBOL(HTTP11)` | BUILD, TEST |
| `zos/launch.cob` | `YOURHLQ.COBOLLM.COBOL(ZOSLNCHR)` | BUILD, TEST |
| `zos/netio.cob` | `YOURHLQ.COBOLLM.COBOL(NETIO)` | BUILD, TEST, TSTTLS |
| `zos/shell.cob` | `YOURHLQ.COBOLLM.COBOL(SHELL)` | BUILD, TEST, TSTTLS |
| `zos/natutf8.cob` | `YOURHLQ.COBOLLM.COBOL(NATUTF8)` | BUILD, TEST, TSTTLS |
| `zos/output.cob` | `YOURHLQ.COBOLLM.COBOL(OUTPUT)` | BUILD, TEST |
| `zos/testnative.cob` | `YOURHLQ.COBOLLM.COBOL(TSTNATIV)` | TEST |

## Shared copybooks

| Repository path | Data set and member | Jobs |
|---|---|---|
| `copy/CLIPARM.cpy` | `YOURHLQ.COBOLLM.COPY(CLIPARM)` | BUILD, TEST |
| `copy/HTTPPARM.cpy` | `YOURHLQ.COBOLLM.COPY(HTTPPARM)` | BUILD, TEST |
| `copy/JSONPARM.cpy` | `YOURHLQ.COBOLLM.COPY(JSONPARM)` | BUILD, TEST |
| `copy/LIMITS.cpy` | `YOURHLQ.COBOLLM.COPY(LIMITS)` | BUILD, TEST, TSTTLS |
| `copy/NETPARM.cpy` | `YOURHLQ.COBOLLM.COPY(NETPARM)` | BUILD, TEST, TSTTLS |
| `copy/OUTPARM.cpy` | `YOURHLQ.COBOLLM.COPY(OUTPARM)` | BUILD, TEST |
| `copy/RESPPARM.cpy` | `YOURHLQ.COBOLLM.COPY(RESPPARM)` | BUILD, TEST |
| `copy/SHLPARM.cpy` | `YOURHLQ.COBOLLM.COPY(SHLPARM)` | BUILD, TEST, TSTTLS |
| `copy/TXTPARM.cpy` | `YOURHLQ.COBOLLM.COPY(TXTPARM)` | BUILD, TEST, TSTTLS |
| `zos/copy/NETNAT.cpy` | `YOURHLQ.COBOLLM.ZCOPY(NETNAT)` | BUILD, TEST, TSTTLS |
| `zos/copy/POSIXNAT.cpy` | `YOURHLQ.COBOLLM.ZCOPY(POSIXNAT)` | BUILD, TEST, TSTTLS |

## Test programs

| Repository path | Data set and member | Jobs |
|---|---|---|
| `test/tstcontracts.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTCNTR)` | TEST |
| `test/tstjson.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTJSON)` | TEST |
| `test/tsthttp.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTHTTP)` | TEST |
| `test/tstresp.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTRESP)` | TEST |
| `test/tstztext.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTZTXT)` | TEST |
| `test/tstshell.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTSHELL)` | TEST |
| `test/tstzagt.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTZAGT)` | TEST |
| `test/tstzlaunch.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTZLCH)` | TEST |
| `test/tstznet.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTZNET)` | TEST |
| `test/tstzoutput.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTZOUT)` | TEST |
| `test/tstzbytes.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTZBYTE)` | TEST |
| `test/tstztls.cob` | `YOURHLQ.COBOLLM.TESTCOB(TSTZTLS)` | TSTTLS |
| `test/fakes/http11.cob` | `YOURHLQ.COBOLLM.TESTCOB(FHTTP)` | TEST |
| `test/fakes/netio.cob` | `YOURHLQ.COBOLLM.TESTCOB(FNET)` | TEST |
| `test/fakes/respapi.cob` | `YOURHLQ.COBOLLM.TESTCOB(FRESP)` | TEST |
| `test/fakes/shell.cob` | `YOURHLQ.COBOLLM.TESTCOB(FSHELL)` | TEST |
| `test/fakes/output.cob` | `YOURHLQ.COBOLLM.TESTCOB(FOUTPUT)` | TEST |
| `test/fakes/cobollm.cob` | `YOURHLQ.COBOLLM.TESTCOB(FCOBOL)` | TEST |
| `test/fakes/ezasoket.cob` | `YOURHLQ.COBOLLM.TESTCOB(FEZAS)` | TEST |
| `test/fakes/signal.cob` | `YOURHLQ.COBOLLM.TESTCOB(FSIGNAL)` | TEST |
| `test/fakes/natutf8.cob` | `YOURHLQ.COBOLLM.TESTCOB(FNATUTF8)` | TEST |
| `test/fakes/zlaunchio.cob` | `YOURHLQ.COBOLLM.TESTCOB(FZLIO)` | TEST |

## Test copybooks

| Repository path | Data set and member | Jobs |
|---|---|---|
| `test/copy/EZAFCTRL.cpy` | `YOURHLQ.COBOLLM.TCOPY(EZAFCTRL)` | TEST |
| `test/copy/FHCTRL.cpy` | `YOURHLQ.COBOLLM.TCOPY(FHCTRL)` | TEST |
| `test/copy/FOCTRL.cpy` | `YOURHLQ.COBOLLM.TCOPY(FOCTRL)` | TEST |
| `test/copy/FRCTRL.cpy` | `YOURHLQ.COBOLLM.TCOPY(FRCTRL)` | TEST |
| `test/copy/FSCTRL.cpy` | `YOURHLQ.COBOLLM.TCOPY(FSCTRL)` | TEST |
| `test/copy/SIGFCTRL.cpy` | `YOURHLQ.COBOLLM.TCOPY(SIGFCTRL)` | TEST |
| `test/copy/ZLCHCTRL.cpy` | `YOURHLQ.COBOLLM.TCOPY(ZLCHCTRL)` | TEST |

## JCL

| Repository path | Data set and member |
|---|---|
| `zos/build.jcl` | `YOURHLQ.COBOLLM.JCL(BUILD)` |
| `zos/test.jcl` | `YOURHLQ.COBOLLM.JCL(TEST)` |
| `zos/tsttls.jcl` | `YOURHLQ.COBOLLM.JCL(TSTTLS)` |
| `zos/run.jcl` | `YOURHLQ.COBOLLM.JCL(RUN)` |

The jobs also require site libraries that are not repository staging targets:
`CEEHLQ.SCEERUN`, `CEEHLQ.SCEELKED`, `TCPHLQ.SEZANMAC`, and
`TCPHLQ.SEZATCP`. They write object members to `OBJ`, `TESTOBJ`, and
`TLSOBJ`, and load members to `LOAD` and `TESTLOAD`. The repository does
not prescribe allocation attributes for those site-owned output libraries.

`zos/run.jcl` also reads `YOURHLQ.COBOLLM.RUNENV`. That external environment
data set is site-owned and must not be staged from repository source.

`zos/attls.policy.example` and `zos/verify-attls.sh` stay in USS and are not
accepted by `zos/stage-source.sh`. Their installation boundary is described
in [How to prepare the z/OS target](../how-to/prepare-the-zos-target.md).
