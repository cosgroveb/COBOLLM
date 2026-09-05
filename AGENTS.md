# Agent instructions

## Quick overview

Use these instructions for changes to COBOLLM. COBOLLM is a small COBOL
coding agent that calls an OpenAI-compatible Responses endpoint and gives the
model one free-form, unsandboxed, fresh `/bin/sh` tool per call.

Start with code nearest the change, then read the owning file, package or
platform directory, and project documentation. Use
[`docs/explanation/architecture.md`](docs/explanation/architecture.md) for
boundaries and
[`docs/reference/configuration-and-limits.md`](docs/reference/configuration-and-limits.md)
for wire contracts and capacities. GNU/Linux aarch64 is the only verified
runtime family, and Debian packaging targets arm64. Treat `zos/` as reviewed
target source, not verified z/OS support.

## Working procedure

1. Read the surrounding code and its nearest tests.
2. Before specialized COBOL, GnuCOBOL, or z/OS work, search or query relevant
   GBrain technical knowledge when GBrain is available. Open applicable pages
   and apply only the material in scope.
3. State current behavior and required behavior before editing.
4. Verify material documentation claims in code, tests, build rules, or
   runtime evidence.
5. Proceed directly with a localized change after inspection.
6. Write a durable plan before unresolved work crosses component, platform,
   ABI, protocol, or deployment boundaries.
7. Make the smallest change that satisfies the requirement.
8. Run the nearest deterministic test first, then the full relevant suite.
9. Report every test or target that did not run.

Use *A Philosophy of Software Design* as the design lens. Minimize complexity,
preserve clear ownership, keep interfaces small, and add no moving part until
a real requirement rules out the simpler design. Keep unrelated cleanup out
of the change.

## Architecture map

| Path | Ownership |
|---|---|
| `cobollm.cob` | Agent-loop control, configuration, shell dispatch, stdout and stderr emission, and cleanup |
| `respapi.cob` | Responses request shape, complete response validation, raw item replay, conversation history, and pending call identity |
| `jsonscan.cob` | Bounded cursor operations over JSON bytes without an object tree |
| `http11.cob` | Narrow HTTP/1.1 request and response framing subset |
| `copy/*.cpy` | Shared level-01 interfaces, status values, and fixed capacities |
| `gnu/` and `zos/` | Platform implementations of `NETIO`, `SHELL`, `NATUTF8`, `OUTPUT`, and launch behavior |
| `test/fakes/` | Link-time substitutes at COBOL boundaries and narrowly scoped native-symbol seams |

Shared interfaces are level-01 copybooks passed by reference. Callers own the
storage. Callees do not retain or replace caller pointers.

## Durable constraints

- Preserve the v1 execution model unless the task changes its scope: one
  process-local append-only trajectory, `store:false`, raw item replay, one
  sequential shell call, and fixed buffers.
- Add no streaming, persistence, resumption, retry, redirect, proxy,
  compression, connection pool, scheduler, or persistent shell unless the
  task explicitly requires it.
- Keep production source COBOL-only. Do not add a C escape hatch.
- Keep Responses handling in `respapi.cob`, JSON handling in `jsonscan.cob`,
  and HTTP handling in `http11.cob`. Do not invoke `curl` or add provider or
  platform HTTP SDKs.
- Keep common HTTP and JSON buffers as ASCII or UTF-8 bytes. Convert native
  text only through `NATUTF8` at platform boundaries.
- Validate the complete response before committing history or permitting a
  shell side effect. Roll back a partial history append. Fail closed on every
  malformed or unsupported item.
- Define capacities and shared statuses in `copy/LIMITS.cpy`. Cover capacity
  changes with below-limit, exact-limit, and over-limit fixtures.
- Keep external names for production COBOL component contracts at eight
  characters or fewer. Preserve exact native symbol names and reviewed
  test-helper exceptions.
- Keep COBOL and copybook lines at 72 bytes or fewer and JCL lines at 71 bytes
  or fewer. Use printable ASCII plus LF and one final LF.
- Treat a nonzero shell command exit as a model-visible tool result, not
  COBOLLM exit status `5`.
- Write the final answer to standard output. Write activity and diagnostics to
  standard error. Keep `OPENAI_API_KEY` out of child shell environments.
- Do not claim reproducible builds. GnuCOBOL 3.2 multi-source
  `SOURCE_DATE_EPOCH` behavior leaves that work deferred.

## Decision rules

| If the change affects... | Then... |
|---|---|
| Platform-native behavior | Put it in the owning `gnu/` or `zos/` adapter or its private copybook. |
| A shared capacity or status | Change `copy/LIMITS.cpy` and add boundary fixtures. |
| A public component contract | Change its level-01 copybook and test the public COBOL boundary. |
| A native ABI | Put every prototype, width, layout, and constant in the owning platform copybook and match the reviewed platform definition. Use exact `BY VALUE SIZE IS 4` for every 32-bit GNU C argument passed by value. Extend the native-call audit and behavior fixture. |
| Test isolation | Prefer public COBOL boundaries and controlled loopback peers. If they cannot drive a native branch, use a narrow test-only native-symbol fake through partial linking and localization. |
| An ABI, compiler, native-call, link, or TLS gate | Treat the environment as unsupported or change the reviewed contract with evidence. Do not bypass the gate. |
| A z/OS build, launch, or policy path | Follow [`docs/how-to/prepare-the-zos-target.md`](docs/how-to/prepare-the-zos-target.md). |
| A z/OS support or verification claim | Name the real target evidence that ran and every applicable target gate that remains unrun. |
| A difficult debugging investigation | Reproduce it, quote exact output, and read recent changes. Use GBrain page `technical-knowledge/agentic-debugging-process` when available. Otherwise follow [`docs/how-to/troubleshoot-a-failed-run.md`](docs/how-to/troubleshoot-a-failed-run.md). Find the root cause before editing. |

## Build procedure

Inspect available targets:

```sh
make help
```

Bootstrap and select the reviewed compiler when needed:

```sh
make bootstrap-gnucobol
export COBC="${XDG_DATA_HOME:-$HOME/.local/share}/cobollm/gnucobol-3.2/bin/cobc"
```

Build and run the full deterministic suite:

```sh
make COBC="$COBC"
make COBC="$COBC" test
```

## Focused test selection

Run the closest focused target before the full suite:

| Change area | First target |
|---|---|
| Shared copybooks, statuses, or capacities | `make COBC="$COBC" test-contracts` |
| `jsonscan.cob` | `make COBC="$COBC" test-json` |
| `http11.cob` | `make COBC="$COBC" test-http` |
| `respapi.cob` and Responses transactions | `make COBC="$COBC" test-resp` |
| GNU `NATUTF8` implementation | `make COBC="$COBC" test-text` |
| GNU `SHELL` implementation | `make COBC="$COBC" test-shell` |
| GNU `NETIO`, DNS, or TLS implementation | `make COBC="$COBC" test-net` |
| Common agent loop | `make COBC="$COBC" test-agent` |
| GNU launch, output, or CLI implementation | `make COBC="$COBC" test-agent` |
| z/OS source, JCL, or AT-TLS material | `make check-zos-source`, then applicable real-target JCL when available. Report exact target evidence not run. |
| Make targets and run plumbing | `make COBC="$COBC" test-make` |

## Build constraints

GNU builds use `-std=ibm -Wall -Werror`. Shared source also passes a separate
`-std=ibm-strict -fsyntax-only` gate. Keep GNU extensions and native layouts
private to `gnu/`. Preserve the compiler, ABI, native-call, and post-link
checks without bypasses.

`make test` runs deterministic GNU tests and static z/OS gates. It does not
verify z/OS. The `test-net-public` target contacts an external endpoint. The
`make run TASK='...'` target sends configured credentials to a provider and
may incur provider cost. Do not run either target unless the user explicitly
requests that external call.

## z/OS target facts

The JCL is configured to compile COBOL objects with `RENT`, bind a
`REUS(NONE),AMODE(31),RMODE(ANY)` module, and launch direct MVS
`PGM=COBOLLM` with `POSIX(ON)` and a protected `TASK` DD. AT-TLS must fail
closed before any credential or HTTP byte leaves the process. Enterprise
COBOL compilation, binder output, MVS launch, USS shell behavior, IBM-1047
conversion, and live AT-TLS policy and runtime checks remain unverified.

## Wrong and right

| Wrong | Right |
|---|---|
| Add a platform special case to common code. | Put native behavior in the owning adapter or private copybook. |
| Loosen an ABI, compiler, link, or TLS gate. | Reject the environment or revise the reviewed contract with evidence. |
| Add a capability during a focused fix. | Preserve the narrow v1 contract. |
| Execute the first valid shell item immediately. | Validate the whole response before dispatch. |
| Infer z/OS support from GNU or static checks. | Name the exact target gate that remains unrun. |
| Add a local capacity literal. | Change `copy/LIMITS.cpy` and test below, at, and above the boundary. |
| Add a production hook or generic syscall facade solely for a test. | Prefer a public COBOL boundary or loopback peer. Use narrow test-only native-symbol interposition when those cannot reach the branch. |

## Verification checklist

- [ ] Did I read the closest code and tests before applying broader
  conventions?
- [ ] Before specialized COBOL, GnuCOBOL, or z/OS work, did I check applicable
  GBrain technical knowledge when available?
- [ ] Does each change have one project-relevant reason?
- [ ] Did I preserve component and platform ownership?
- [ ] Did I keep wire bytes and native text conversion on the correct sides of
  `NATUTF8`?
- [ ] Does response validation finish before history commit or shell dispatch?
- [ ] Did every capacity change update `copy/LIMITS.cpy` and cover below, at,
  and above the limit?
- [ ] Did every native ABI change update its platform copybook, exact argument
  widths, audit, and behavior fixture?
- [ ] Did the closest focused test pass?
- [ ] Did the full relevant suite pass, or did I name what did not run?
- [ ] Did I avoid `test-net-public` and `make run` unless the user requested
  that external call?
- [ ] Did I avoid claiming z/OS behavior that no real target established?
- [ ] Did source, ABI, compiler, native-call, link, and TLS gates remain intact?
