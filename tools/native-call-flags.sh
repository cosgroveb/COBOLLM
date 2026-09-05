#!/bin/sh
set -eu

[ "$#" -gt 0 ] || {
    printf 'usage: native-call-flags.sh SOURCE...\n' >&2
    exit 2
}

native_calls='ERR_clear_error
SSL_CTX_free
SSL_CTX_new
SSL_CTX_set_default_verify_paths
SSL_CTX_set_verify
SSL_connect
SSL_ctrl
SSL_free
SSL_get_error
SSL_new
SSL_read
SSL_set1_host
SSL_set_fd
SSL_shutdown
SSL_write
TLS_client_method
__errno_location
close
connect
dup
dup2
feof
ferror
fread
freeaddrinfo
getaddrinfo
getenv
pclose
pipe
popen
read
setenv
sigaction
sigemptyset
socket
unsetenv
write'

project_calls='COBOLLM
HTTP11
JSONSCAN
NATUTF8
NETIO
OUTPUT
RESPAPI
SHELL
TSTCLOSE
TSTDUP
TSTDUP2
TSTENVCOMMAND
TSTGETENV
TSTSETENV
TSTPIPE
TSTREAD
TSTUNSETENV'

calls=$(
    sed -n -E \
        "s/.*CALL( STATIC)?[[:space:]]+['\"]([^'\"]+)['\"].*/\\2/p" \
        "$@" | LC_ALL=C sort -u
)

for call in $calls; do
    if printf '%s\n' "$project_calls" | grep -qx "$call"; then
        continue
    fi
    if ! printf '%s\n' "$native_calls" | grep -qx "$call"; then
        printf 'unlisted literal call: %s\n' "$call" >&2
        exit 1
    fi
    printf '%s\n' "-K $call"
done
