# How to prepare the z/OS target

Stage, build, and gate the z/OS target with site-owned data sets and AT-TLS
configuration.

Nobody has run this procedure on z/OS. Expect to adapt data set, library,
stack, Policy Agent, and keyring values to your installation. Passing the
static GNU-side source gates does not establish z/OS support.

## Prerequisites

- Enterprise COBOL with Language Environment
- z/OS UNIX System Services
- USS Perl plus `awk`, `iconv`, `chtag`, `cmp`, and `mktemp`
- the `EZASOKET` call interface and TCP/IP macro libraries
- Policy Agent with AT-TLS enabled for the selected TCP/IP stack
- a keyring that trusts the endpoint certificate chain
- FB/80 source PDSEs plus site object and load-module libraries

The repository does not allocate the data sets, install Policy Agent files, or
define their access controls. The site owner must do that before staging.

## Stage source

1. Transfer the repository to USS as binary data. Do not let FTP or file-tag
   conversion alter the UTF-8 repository bytes.

2. Allocate every source PDSE named in the
   [z/OS staging manifest](../reference/zos-staging-manifest.md). Each target
   passed to `zos/stage-source.sh` must be an FB/80 PDSE.

3. Run `zos/stage-source.sh` for every source, copybook, and JCL row in that
   manifest. The script validates printable repository bytes and fixed-format
   line lengths, converts UTF-8 to IBM-1047, writes FB/80 records, and compares
   a readback with the source.

4. Put `zos/verify-attls.sh` at the USS path assigned to `GATE` in
   `zos/tsttls.jcl` and make it executable. This script is not handled by
   `stage-source.sh`. The repository does not specify a checked shell-script
   transfer and tagging procedure, so validate that path on the target before
   submitting the TLS job.

Do not submit the JCL until every manifest row required by that job has been
staged.

## Configure AT-TLS

1. Copy `zos/attls.policy.example` to a UTF-8 USS working file. Replace the job
   name, hostname, port, and keyring with site values.

2. Keep the policy bound to the selected job, outbound endpoint port, client
   role, SNI hostname, reference hostname, and keyring. The checked policy
   enables TLS 1.3 suite `1301` followed by TLS 1.2 suite `C02F`.

3. Convert and tag the installed policy as IBM-1047 text. Refresh Policy Agent
   and capture its parse log and effective policy.

4. Create the four environment data sets referenced by `zos/tsttls.jcl`.
   Replace every sample path and identifier below with the actual evidence.
   `PROVENV` is the complete environment for both the `provenance` and
   `effective` verifier modes.

   Protect `POSENV` and `MISENV` from other users. Allocate both as RECFM=V,
   not VBS or fixed records, and store each shown record as native IBM-1047.
   Their test steps force automatic conversion off.

   `PROVENV`:

   ```text
   COBOLLM_PAGENT_MAIN=/etc/pagent.conf
   COBOLLM_PAGENT_IMAGE=/etc/pagent.TCPIP.conf
   COBOLLM_POLICY_SOURCE=/u/site/cobollm/attls.policy.utf8
   COBOLLM_POLICY_STAGE=/u/site/cobollm/attls.policy.ibm1047
   COBOLLM_INSTALLED_POLICY=/etc/pagent/cobollm.policy
   COBOLLM_POLICY_PARSE_LOG=/u/site/cobollm/pagent-refresh.log
   COBOLLM_EFFECTIVE_POLICY=/u/site/cobollm/pagent-effective.policy
   COBOLLM_RUNNING_MAIN=/etc/pagent.conf
   COBOLLM_SELECTED_STACK=TCPIP
   COBOLLM_POLICY_DEST=/etc/pagent/cobollm.policy
   COBOLLM_EXPECT_JOB=COBLMTLS
   COBOLLM_EXPECT_HOST=api.openai.com
   COBOLLM_EXPECT_PORT=443
   COBOLLM_EXPECT_KEYRING=YOURUSER/YOURRING
   ```

   `COBOLLM_RUNNING_MAIN` must equal `COBOLLM_PAGENT_MAIN`.
   `COBOLLM_POLICY_DEST` must equal `COBOLLM_INSTALLED_POLICY`. The expected
   job, host, port, and keyring must exactly match the substituted policy.

   `POSENV`:

   ```text
   COBOLLM_TLS_CONNECT_HOST=api.openai.com
   COBOLLM_TLS_EXPECT=SUCCESS
   ```

   `MISENV`:

   ```text
   COBOLLM_TLS_CONNECT_HOST=mismatch.example.com
   COBOLLM_TLS_EXPECT=FAILURE
   ```

   Replace the mismatch host with a controlled endpoint that accepts TCP on
   port 443 but fails the configured hostname or certificate check. A DNS or
   TCP failure does not prove that negative case.

   `CAPENV`:

   ```text
   COBOLLM_PEER_CAPTURE=/u/site/cobollm/failed-gate.capture
   ```

   The capture must contain bytes observed by the controlled peer for the
   failed protection gate.

5. Run both policy checks before the live TLS test.

   ```sh
   zos/verify-attls.sh provenance
   zos/verify-attls.sh effective
   ```

   Run these commands with the `PROVENV` values exported. The verifier rejects
   placeholders, competing rules, changed protocol or cipher settings,
   missing hostname checks, wrong file tags, and mismatches between source,
   staged, installed, and active policy.

## Build and test

1. Edit every site value at the top of `zos/build.jcl`, `zos/test.jcl`, and
   `zos/tsttls.jcl`. The member names and required input libraries are listed
   in the
   [staging manifest](../reference/zos-staging-manifest.md).

2. Submit the staged `TEST` member for deterministic component tests.

3. Submit the staged `TSTTLS` member for Policy Agent provenance, a positive
   TLS connection, a hostname or certificate mismatch, and the
   no-application-byte failure check.

4. Submit the staged `BUILD` member after both test jobs pass. The compiler
   uses `RENT`. The single production bind uses `REUS(NONE)` and writes
   `HLQ.COBOLLM.LOAD(COBOLLM)`. The final program object cannot be RENT because
   it contains the non-CICS `EZASOKET` interface.

At runtime, the adapter checks that AT-TLS reports policy enabled, connection
secure, security type client, and an allowed protocol and cipher. That check
does not establish policy provenance. The provenance verifier remains a
mandatory deployment gate. See
[Architecture](../explanation/architecture.md#platform-boundary) for the
boundary between the adapter and Policy Agent checks.

## Run as an MVS batch program

1. Create the site-owned `YOURHLQ.COBOLLM.RUNENV` data set named by `ENVDSN`
   in `zos/run.jcl`. Protect it from other users and allocate it as RECFM=V,
   not VBS or fixed records, with LRECL at least 8211. That accommodates the
   8,207-byte `OPENAI_API_KEY=` payload plus its four-byte record descriptor.
   Put one native IBM-1047 `NAME=value` entry on each record:

   ```text
   OPENAI_API_KEY=...
   OPENAI_MODEL=gpt-5.3-codex
   OPENAI_BASE_URL=https://api.openai.com/v1
   ```

   `gpt-5.3-codex` is an example whose availability depends on the endpoint
   and account. Replace the endpoint and account values. Do not use
   substitutions or leave trailing blanks. Do not put the API key in JCL.

2. Create a protected USS regular file containing the task as native IBM-1047
   bytes. The file must contain 1 through 65,535 bytes. Spaces, newlines, and
   trailing bytes are part of the task. A 65,536th byte is rejected.

3. Set `TASKFILE` in `zos/run.jcl` to that file. The JCL opens it read-only as
   the `TASK` DD. The task does not travel through argv, `STDPARM`, standard
   input, or an environment variable.

4. Before the production run, install and prove a policy whose `Jobname` and
   `COBOLLM_EXPECT_JOB` are both `COBOLLM`, the job name in `zos/run.jcl`. The
   TLS-test template uses `COBLMTLS`, so its provenance evidence does not prove
   the production job rule.

5. Stage `zos/run.jcl` as `YOURHLQ.COBOLLM.JCL(RUN)` and submit it. The job
   runs `PGM=COBOLLM` from `YOURHLQ.COBOLLM.LOAD`, reads `RUNENV` through the
   Language Environment environment-file option, and enables `POSIX(ON)` for
   `popen` and `/bin/sh`. It provides `SYSPRINT` and `SYSOUT` DDs for process
   output. CEEOPTS forces `_BPXK_AUTOCVT=OFF` so the already native `TASK`
   bytes reach the launcher without automatic conversion.

   The checked invocation is:

   ```jcl
   //RUN      EXEC PGM=COBOLLM,REGION=0M,TIME=NOLIMIT
   //STEPLIB  DD DISP=SHR,DSN=&HLQ..COBOLLM.LOAD
   //CEEOPTS  DD *
   POSIX(ON),
   ENVAR("_BPXK_AUTOCVT=OFF","_CEE_ENVFILE=DD:RUNENV")
   /*
   //RUNENV   DD DISP=SHR,DSN=&ENVDSN
   //TASK     DD PATH='&TASKFILE',PATHOPTS=(ORDONLY)
   //SYSPRINT DD SYSOUT=*
   //SYSOUT   DD SYSOUT=*
   ```

This launch path has static source coverage only. Nobody has compiled the
program, bound the MVS program object, or run the job on z/OS.
