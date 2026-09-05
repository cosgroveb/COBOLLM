# COBOLLM

COBOLLM is a small coding agent written in COBOL. It talks directly to an
OpenAI-compatible Responses endpoint and gives the model one tool: `/bin/sh`.

> [!WARNING]
> COBOLLM runs model-supplied shell commands without a sandbox, permission
> checks, or confirmation. The commands inherit the COBOLLM process user's
> access. Run it only in a directory and environment you are willing to let the
> model change.
> Removing the API key from child shells does not protect it from same-user
> inspection of parent process memory when the operating system permits it.

## Build

The GNU build supports the reviewed Linux/aarch64 ABI family. It requires
glibc 2.39 or newer, OpenSSL 3, GnuCOBOL major 3 at version 3.2 or newer,
and `libcob.so.4`.

The system GnuCOBOL package may be too old. The optional bootstrap installs
GnuCOBOL 3.2 below your user data directory:

```sh
make bootstrap-gnucobol
export COBC="${XDG_DATA_HOME:-$HOME/.local/share}/cobollm/gnucobol-3.2/bin/cobc"
make COBC="$COBC"
```

Normal build and test targets do not download anything. See
[Getting started](docs/tutorials/getting-started.md) for the complete first
run.

## Run

Set the API key and model, then pass one nonempty task:

```sh
export OPENAI_API_KEY='...'
export OPENAI_MODEL='gpt-5.3-codex'
./cobollm 'Inspect this repository and report what it builds.'
```

`OPENAI_BASE_URL` defaults to `https://api.openai.com/v1`. The model name is
configurable. `gpt-5.3-codex` is an example. Its availability depends on the
endpoint and account.

COBOLLM sends the task, accepted response items, and shell results in one
in-memory Responses conversation. It sets `store:false`, does not stream, and
does not save or resume sessions. Each tool call starts a fresh `/bin/sh` in
the current directory. Shell-local state does not survive between calls, but
filesystem changes do. Standard error is merged into standard output.

## Documentation

- [Getting started](docs/tutorials/getting-started.md)
- [How to use a compatible endpoint](docs/how-to/use-a-compatible-endpoint.md)
- [How to prepare the z/OS target](docs/how-to/prepare-the-zos-target.md)
- [How to troubleshoot a failed run](docs/how-to/troubleshoot-a-failed-run.md)
- [Configuration and limits](docs/reference/configuration-and-limits.md)
- [z/OS staging manifest](docs/reference/zos-staging-manifest.md)
- [Architecture](docs/explanation/architecture.md)
- Manual: `man cobollm`

## Development

Run the GNU suite with the selected compiler:

```sh
make COBC="$COBC" test
```

`make test` runs component tests, GNU native integration tests, shared-source
strict syntax checks, and static z/OS source gates. A public TLS test and a
credentialed Responses call remain opt-in:

```sh
make COBC="$COBC" test-net-public \
  NET_TEST_CONNECT_HOST=api.openai.com \
  NET_TEST_VERIFY_HOST=api.openai.com \
  NET_TEST_PORT=443

make COBC="$COBC" run TASK='Report the current directory.'
```

`make help` lists component test targets and build checks.

## z/OS status

The `zos/` tree contains Enterprise COBOL source, JCL, USS source staging, an
MVS batch launch template, and AT-TLS policy material for a 31-bit z/OS build.
Nobody has compiled, bound, or run it on z/OS yet. Treat it as target source,
not verified platform support.
