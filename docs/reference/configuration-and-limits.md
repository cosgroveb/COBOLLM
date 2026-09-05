# Configuration and limits

COBOLLM accepts one task and three API environment variables. It has no
configuration file or command-line options.

## Invocation

GNU/Linux:

```text
cobollm TASK
```

`TASK` must be one nonempty native command-line argument. GNU/Linux expects
valid UTF-8.

The z/OS MVS batch launcher takes no task argument. It reads exactly 1 through
65,535 native IBM-1047 bytes from the `TASK` DD byte stream. It preserves
spaces, newlines, and trailing bytes. A 65,536th byte is a capacity error.

## Environment

| Name | Required | Limit | Meaning |
|---|---:|---:|---|
| `OPENAI_API_KEY` | yes | 8,192 bytes | Printable ASCII bearer token without spaces. |
| `OPENAI_MODEL` | yes | 256 bytes | Model identifier sent in each request. |
| `OPENAI_BASE_URL` | no | 2,048 bytes | Responses base URL. Default: `https://api.openai.com/v1`. |
The z/OS run JCL reads these values from a protected RECFM=V `RUNENV` data
set with LRECL at least 8211. The maximum `OPENAI_API_KEY=` payload is 8,207
bytes, plus a four-byte record descriptor. Each record contains one native
IBM-1047 `NAME=value` entry without substitutions or trailing blanks.
The run JCL forces `_BPXK_AUTOCVT=OFF` through CEEOPTS, outside `RUNENV`, to
preserve the native `TASK` bytes.

COBOLLM reads the key into process memory, removes `OPENAI_API_KEY` from its
environment before it starts a shell, and clears its key buffers during
cleanup. A same-user shell command may still inspect the parent process when
the operating system permits it.

## Base URL grammar

The parser accepts `http://` and `https://` followed by an ASCII DNS hostname,
an optional port from 1 through 65535, and an optional origin path. It strips
trailing path slashes and appends `/responses`.

The parser rejects IP literals, user information, query strings, fragments,
backslashes, whitespace, control or non-ASCII bytes, invalid percent escapes,
empty or invalid DNS labels, and trailing dots. Hostnames have a 253-byte
limit. DNS labels have a 63-byte limit.

GNU HTTPS uses OpenSSL 3 default trust paths, SNI, certificate-chain
verification, and hostname verification. GNU plain HTTP prints a warning.
z/OS accepts HTTPS only and delegates TLS to AT-TLS.

## Responses request

Requests use this fixed behavior:

| Field | Value |
|---|---|
| `model` | `OPENAI_MODEL` |
| `store` | `false` |
| `parallel_tool_calls` | `false` |
| `include` | `["reasoning.encrypted_content"]` |
| `instructions` | Fixed coding-agent instructions. Not configurable. |
| `tools` | one custom tool named `shell` |
| `input` | append-only in-memory conversation items |

The endpoint must return `status: "completed"`, an `output` array, and either
no `error` field or `error: null`. The accepted output items are:

| Item | Required shape | Optional accepted fields |
|---|---|---|
| Reasoning | string `id`, array `summary` containing `summary_text` objects with string `text` | array `content` containing `reasoning_text` objects with string `text`, string `encrypted_content`, and `status: "completed"` |
| Custom tool call | `name: "shell"`, string `call_id`, and string `input` | string `id`, `status: "completed"`, and `async: false` |
| Assistant message | string `id`, `role: "assistant"`, `status: "completed"`, and array `content` | `phase: "commentary"` or `phase: "final_answer"` |

Message content may contain `output_text` with a string `text` and an
`annotations` array. An optional `logprobs` value must be an array. It may also
contain `refusal` with a string `refusal`. A final turn needs at least one
accepted `output_text`. A refusal alone is not a final response.

COBOLLM handles at most one custom tool call per turn. A custom tool call's
status must be `completed` when present. On a turn with a tool call, message
text is validated but not returned. On a turn without one, `final_answer`
content wins over `commentary` and unphased content. When no phase appears,
unphased `output_text` is the final response. Parallel calls and other output
item or content types are rejected.

COBOLLM does not use response IDs. It replays accepted raw output items and
appends each matching `custom_tool_call_output`. See
[Architecture](../explanation/architecture.md#conversation-replay) for the
reasoning behind this request shape. COBOLLM does not retain input between
processes.

## Shell tool

Each call starts a fresh shell equivalent to:

```text
/bin/sh -c COMMAND
```

The working directory and process-user permissions come from COBOLLM. The
shell has no sandbox, permission prompt, persistent process, timeout, retry,
or separate standard-error stream. Standard error is merged into standard
output. Shell-local variables, functions, aliases, and directory changes do
not survive the call. Filesystem changes do. The next Responses input includes
the outcome, exit code or signal, truncation flag, encoding-loss flag, and
captured output.

## Capacities

| Data | Limit |
|---|---:|
| Task | 65,535 bytes |
| Shell command | 65,535 bytes |
| Shell output after UTF-8 conversion | 1 MiB |
| Final UTF-8 response | 1 MiB |
| HTTP response body | 8 MiB |
| Conversation history | 16 MiB |
| Serialized request body | 16 MiB |
| HTTP response headers | 64 KiB |
| One network operation | 64 KiB |
| JSON nesting depth | 64 |

Input, protocol, and final-response capacity failures stop the process. Shell
output beyond the capture limit is marked truncated and sent to the model.
COBOLLM has no dynamic spill file.

## Exit status

| Status | Category |
|---:|---|
| `0` | Final model response written successfully |
| `1` | Internal invariant or output failure |
| `2` | Usage or configuration failure |
| `3` | HTTP, JSON, or Responses protocol failure |
| `4` | Network or TLS failure |
| `5` | Shell runtime failure |
| `6` | Capacity or text-conversion failure |

Nonzero diagnostics go to standard error. For a non-2xx HTTP response, COBOLLM
exposes the numeric status only and does not print the response body or reason
phrase. JSON, framing, and Responses-shape failures in category `3` have no
numeric HTTP diagnostic.
An ordinary nonzero shell-command exit is a tool result, not process status
`5`. COBOLLM sends that result to the model and continues the session.

## Build targets

| Target | Meaning |
|---|---|
| `all` | Build `cobollm` after compiler, ABI, syntax, call, and link gates. |
| `run TASK="..."` | Build and run one credentialed task. |
| `test` | Run deterministic GNU tests and static z/OS source checks. |
| `test-net-public` | Run the opt-in public TLS check against caller-supplied hosts. |
| `bootstrap-gnucobol` | Download, verify, build, and install GnuCOBOL 3.2 under user data. |
| `clean` | Remove GNU build artifacts and generated compiler files. |
| `help` | Print prerequisites and available targets. |
