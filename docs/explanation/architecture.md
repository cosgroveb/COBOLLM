# Architecture

COBOLLM keeps the agent loop and protocol machinery in shared COBOL. Platform
adapters supply process startup, shell execution, text conversion, output, and
network I/O.

## Agent loop

One process owns one conversation:

1. The GNU launcher normalizes one task argument. The z/OS launcher reads a
   native task byte stream from the `TASK` DD.
2. `COBOLLM` reads configuration, validates the endpoint, and starts
   `RESPAPI`.
3. `RESPAPI` serializes a Responses request from an append-only input-item
   history.
4. `HTTP11` sends the request through `NETIO` and returns a bounded response
   body.
5. `RESPAPI` validates the complete response before it commits output items to
   history.
6. A custom tool call runs through `SHELL`. COBOLLM reports the result to the
   same in-memory history and sends another request.
7. A completed assistant message goes through `OUTPUT`, then the process
   clears memory and exits.

The loop handles one tool call at a time. It has no scheduler, permission
engine, persistent shell, retry policy, session store, streaming path, or
resumption protocol.

## Shared protocol code

`JSONSCAN` is a bounded cursor parser. It escapes and decodes strings, locates
object members, iterates arrays, and validates complete values without
building a JSON object tree.

`HTTP11` implements the required HTTP/1.1 client subset. It constructs one
POST request, handles partial I/O, and accepts content-length, chunked, or
close-delimited response bodies. It rejects ambiguous framing and unsupported
content encodings.

`RESPAPI` owns conversation state and pending tool-call identity. It preserves
accepted output items as raw JSON spans, which avoids rebuilding provider
items and preserves encrypted reasoning fields. The process sends the growing
history on every turn with `store:false`.

### Conversation replay

Each request repeats the unchanged input prefix and appends accepted output
items plus the matching `custom_tool_call_output`. This shape lets an endpoint
reuse a cached prefix within one process when it supports provider prompt
caching. COBOLLM neither controls that cache nor carries input into another
process.

## Platform boundary

The build links one implementation of each platform contract:

| Contract | GNU/Linux | z/OS |
|---|---|---|
| Launcher | GnuCOBOL argument access | MVS `TASK` DD byte stream |
| `NETIO` | POSIX sockets and OpenSSL 3 | `EZASOKET` and AT-TLS |
| `SHELL` | native `/bin/sh` pipe calls | USS `/bin/sh` pipe calls |
| `NATUTF8` | UTF-8 validation and replacement | IBM-1047 and UTF-8 conversion through `iconv` |
| `OUTPUT` | POSIX file descriptors | USS file descriptors |

The GNU adapter calls native libraries directly from GnuCOBOL. Its checked
ABI family records widths and layouts for the reviewed Linux/aarch64 host.
The build rejects other GNU ABI families rather than guessing at their native
layouts. Production sources contain COBOL only, with no C shim.

The z/OS network adapter writes plain HTTP bytes to a socket protected by
AT-TLS. Before the first write it queries the connection and requires policy
enabled, connection secure, security type client, and one of two exact
protocol and cipher pairs: TLS 1.3 with `1301`, or TLS 1.2 with `C02F`.

That runtime query cannot prove which Policy Agent source or rule selected the
connection. The separate provenance gate checks source, staging, installation,
active stack selection, policy uniqueness, hostname rules, and keyring. Both
checks are mandatory for deployment.

## Text boundary

HTTP and JSON are ASCII and UTF-8 protocols. Shared code uses explicit byte
values for protocol syntax, so native source encoding does not redefine wire
characters. `NATUTF8` converts user tasks, model commands, shell output, and
final output at the platform boundary.

Shell commands require lossless conversion to native text. Invalid command
text is returned to the model as a command-encoding result and is not run.
Shell and final output permit replacement characters. Shell results report
conversion loss to the model, while final output emits a warning.

## z/OS verification boundary

GNU tests exercise shared protocol code, GNU adapters, and static properties
of the z/OS source. They cannot verify Enterprise COBOL compilation, binder
behavior, USS runtime calls, IBM-1047 conversion, or active AT-TLS policy on a
real system. The JCL and verification scripts define those remaining gates.

The production JCL is configured to compile each COBOL object with `RENT`,
then bind one MVS program object with `REUS(NONE)` because the non-CICS
`EZASOKET` interface requires one copy per task. The configured output is
`HLQ.COBOLLM.LOAD(COBOLLM)`. There is no USS executable output.

The run JCL is configured to start that member directly with
`EXEC PGM=COBOLLM`, supply the load library through `STEPLIB`, and enable
Language Environment `POSIX(ON)` for `popen` and `/bin/sh`. It reads API
configuration from an external `RUNENV` data set. The launcher reads a
protected USS byte file through the `TASK` DD, preserving 1 through 65,535
native IBM-1047 bytes without argv, environment-variable, or record-padding
semantics. The JCL forces
`_BPXK_AUTOCVT=OFF` in CEEOPTS so Language Environment does not convert that
byte stream again.

Static source gates check this shape. They do not prove Enterprise COBOL,
binder, MVS batch, Language Environment, POSIX, or AT-TLS behavior on a real
z/OS system.

## Related documentation

[Configuration and limits](../reference/configuration-and-limits.md) describes
the wire and process bounds.
[How to prepare the z/OS target](../how-to/prepare-the-zos-target.md) covers the
target procedure.
