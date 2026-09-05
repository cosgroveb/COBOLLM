#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

forbidden=$(find . -type f \( -name '*.c' -o -name '*.h' \) \
    -not -path './.git/*' -print |
    LC_ALL=C sort)
[ -z "$forbidden" ] || {
    printf 'production C/header source rejected:\n%s\n' "$forbidden" >&2
    exit 1
}

sources='gnu/launch.cob gnu/netio.cob gnu/shell.cob
    gnu/natutf8.cob gnu/output.cob cobollm.cob respapi.cob
    jsonscan.cob http11.cob'

set --
for source in $sources; do
    set -- "$@" "$source"
done
tools/native-call-flags.sh "$@" >/dev/null

if grep -En \
    'BY VALUE (GNU-SIGPIPE|GNU-V-AI-(FAMILY|SOCKTYPE|PROTOCOL|ADDRLEN)|WS-SOCKET|WS-VERIFY-MODE|GNU-SSL-CTRL-SNI|WS-INT-RESULT|NP-REQUEST-LENGTH|NP-BUFFER-CAPACITY|OP-FILE-DESCRIPTOR)([^A-Z0-9-]|$)' \
    gnu/*.cob >/dev/null; then
    printf '32-bit native BY VALUE argument lacks SIZE IS 4\n' >&2
    exit 1
fi
if grep -En 'BY VALUE [0-9]' gnu/*.cob >/dev/null; then
    printf 'untyped numeric native BY VALUE argument rejected\n' >&2
    exit 1
fi
shutdown_flow=$(sed -n \
    '/^       SHUTDOWN-TLS\.$/,/^       RESTORE-SIGNAL\.$/p' \
    gnu/netio.cob)
clear_line=$(printf '%s\n' "$shutdown_flow" | \
    grep -n 'CALL STATIC "ERR_clear_error"' | cut -d: -f1)
shutdown_line=$(printf '%s\n' "$shutdown_flow" | \
    grep -n 'CALL STATIC "SSL_shutdown"' | cut -d: -f1)
errno_line=$(printf '%s\n' "$shutdown_flow" | \
    grep -n 'PERFORM SAVE-ERRNO' | cut -d: -f1)
error_line=$(printf '%s\n' "$shutdown_flow" | \
    grep -n 'CALL STATIC "SSL_get_error"' | cut -d: -f1)
if [ "$clear_line" -ge "$shutdown_line" ] ||
   [ "$shutdown_line" -ge "$errno_line" ] ||
   [ "$errno_line" -ge "$error_line" ] ||
   ! printf '%s\n' "$shutdown_flow" |
       grep -q 'PERFORM UNTIL WS-RETRY = FLAG-OFF' ||
   ! printf '%s\n' "$shutdown_flow" |
       grep -q 'GNU-SSL-ERROR-WANT-READ' ||
   ! printf '%s\n' "$shutdown_flow" |
       grep -q 'GNU-SSL-ERROR-WANT-WRITE'; then
    printf 'TLS shutdown retry lifecycle rejected\n' >&2
    exit 1
fi
grep -q 'LINKFLAGS := -fstatic-call' Makefile
[ "$(grep -c 'tools/check-gnu-link.sh \$@ "$(COBC)"' Makefile)" \
    -eq 10 ] || {
    printf 'native executable post-link inventory mismatch\n' >&2
    exit 1
}
printf 'PASS native call inventory\n'
