# COBOLLM

Run a small coding agent written in COBOL against an OpenAI-compatible
Responses endpoint. The agent has one tool: an unsandboxed `/bin/sh` running
with the COBOLLM process user's permissions. It does not ask before executing
commands. Run it only in a directory where that access is acceptable.

## GNU/Linux

The GNU build currently supports the reviewed Linux/aarch64 ABI family. It
requires glibc 2.39 or newer, OpenSSL 3, GnuCOBOL 3.2 or newer, and
`libcob.so.4`. The repository includes an opt-in bootstrap for GnuCOBOL 3.2:

```sh
make bootstrap-gnucobol
export COBC="${XDG_DATA_HOME:-$HOME/.local/share}/cobollm/gnucobol-3.2/bin/cobc"
make COBC="$COBC"
make COBC="$COBC" test
```

The bootstrap downloads the official GNU archive, verifies its SHA-256, and
installs it below `${XDG_DATA_HOME:-$HOME/.local/share}`. It needs a C compiler,
`make`, `curl`, `tar`, and the GnuCOBOL build dependencies. Normal build and
test targets do not download anything.

Set the endpoint configuration, then pass exactly one nonempty task:

```sh
export OPENAI_API_KEY='...'
export OPENAI_MODEL='gpt-5.3-codex'
make COBC="$COBC" run TASK='Print the current directory, then answer with its path.'
```

`OPENAI_BASE_URL` defaults to `https://api.openai.com/v1`. An `http://` URL is
allowed on GNU/Linux, but COBOLLM prints a warning before sending the API key,
task, commands, or command output without encryption.

COBOLLM removes `OPENAI_API_KEY` from the child environment before it starts a
shell command. The key remains in the COBOLLM parent process memory until
cleanup. An unsandboxed command running as the same user can inspect the parent
process when the operating system permits it, so this does not protect the key
from the agent. Treat the task and endpoint response as trusted with that key.

COBOLLM keeps the session in memory and sends accepted Responses output items
back on each turn. It does not stream, persist sessions, request permissions,
or run more than one tool call at a time. Shell output and final UTF-8 output
are each limited to 1 MiB. Tasks and tool commands are limited to 65,535
bytes. Responses are limited to 8 MiB, and in-memory history and request bodies
are limited to 16 MiB.

Exit status `0` means the agent returned a final response. Statuses `1` through
`6` report internal/output, usage/configuration, protocol/provider, network,
shell, and capacity/conversion failures respectively.

## z/OS target source

The `zos/` tree carries Enterprise COBOL, USS, JCL, source-staging, and AT-TLS
configuration for a 31-bit z/OS build. It has not been compiled, bound, or run
on a z/OS installation. Treat it as target source, not verified support.

The AT-TLS example permits TLS 1.3 suite `1301` followed by TLS 1.2 suite
`C02F`. That `1301C02F` order is a point-in-time endpoint policy. Update the
adapter, policy, tests, and documentation together if endpoint support changes.

`zos/stage-source.sh` defines the reviewed IBM-1047/FB80 transfer path for
COBOL, copybooks, and JCL. Site operators must still supply data-set names,
compiler and binder libraries, Policy Agent paths, and a trust store before
running the target gates described in the JCL templates.
