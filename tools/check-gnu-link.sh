#!/bin/sh
set -eu

[ "$#" -eq 2 ] || {
    printf 'usage: check-gnu-link.sh ARTIFACT COBC\n' >&2
    exit 2
}

artifact=$1
cobc=$2
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
artifact=$(CDPATH= cd -- "$(dirname -- "$artifact")" && pwd)/\
$(basename -- "$artifact")
name=$(basename -- "$artifact")
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

case "$name" in
    cobollm)
        sources='gnu/launch.cob gnu/netio.cob gnu/shell.cob
            gnu/natutf8.cob gnu/output.cob cobollm.cob respapi.cob
            jsonscan.cob http11.cob'
        openssl=yes
        ;;
    test-net)
        sources='test/tstnet.cob gnu/netio.cob gnu/shell.cob'
        openssl=yes
        fake_resolver=no
        ;;
    test-tls-close)
        sources='test/tsttlsclose.cob gnu/netio.cob
            test/fakes/tlsclose.cob'
        openssl=yes
        fake_resolver=no
        fake_tls_close=yes
        ;;
    test-resolver)
        sources='test/tstresolve.cob gnu/netio.cob
            test/fakes/getaddr.cob'
        openssl=yes
        fake_resolver=yes
        ;;
    test-shell)
        sources='test/tstshell.cob gnu/testnative.cob
            gnu/shell.cob gnu/output.cob'
        openssl=no
        fake_resolver=no
        ;;
    test-env-child)
        sources='test/envchild.cob gnu/testnative.cob'
        openssl=no
        fake_resolver=no
        ;;
    test-shell-stage)
        sources='test/tststage.cob gnu/shell.cob test/fakes/popen.cob'
        openssl=no
        fake_resolver=no
        fake_popen=yes
        ;;
    test-text)
        sources='test/tsttext.cob gnu/natutf8.cob'
        openssl=no
        fake_resolver=no
        ;;
    test-agent)
        sources='test/tstagent.cob cobollm.cob http11.cob
            gnu/natutf8.cob test/fakes/respapi.cob
            test/fakes/shell.cob test/fakes/output.cob
            test/fakes/netio.cob'
        openssl=no
        fake_resolver=no
        ;;
    test-cli)
        sources='gnu/launch.cob cobollm.cob http11.cob
            gnu/natutf8.cob gnu/output.cob test/fakes/respcli.cob
            test/fakes/shell.cob test/fakes/netio.cob'
        openssl=no
        fake_resolver=no
        ;;
    *)
        printf 'no fixed source inventory for %s\n' "$name" >&2
        exit 1
        ;;
esac

set --
for source in $sources; do
    set -- "$@" "$root/$source"
done
native_flags=$("$root/tools/native-call-flags.sh" "$@")
printf '%s\n' "$native_flags" |
    sed -n 's/^-K //p' >"$tmp/expected-native"
if [ "${fake_resolver:-no}" = yes ]; then
    grep -Ev '^(getaddrinfo|freeaddrinfo)$' "$tmp/expected-native" \
        >"$tmp/expected-native-real"
    mv "$tmp/expected-native-real" "$tmp/expected-native"
    readelf -Ws "$artifact" >"$tmp/symbols"
    grep -Eq 'LOCAL.*getaddrinfo$' "$tmp/symbols"
    grep -Eq 'LOCAL.*freeaddrinfo$' "$tmp/symbols"
fi
if [ "${fake_tls_close:-no}" = yes ]; then
    grep -Ev '^(SSL_shutdown|SSL_get_error)$' "$tmp/expected-native" \
        >"$tmp/expected-native-real"
    mv "$tmp/expected-native-real" "$tmp/expected-native"
    readelf -Ws "$artifact" >"$tmp/symbols"
    grep -Eq 'LOCAL.*SSL_shutdown$' "$tmp/symbols"
    grep -Eq 'LOCAL.*SSL_get_error$' "$tmp/symbols"
fi
if [ "${fake_popen:-no}" = yes ]; then
    grep -Ev '^popen$' "$tmp/expected-native" \
        >"$tmp/expected-native-real"
    mv "$tmp/expected-native-real" "$tmp/expected-native"
    readelf -Ws "$artifact" >"$tmp/symbols"
    grep -Eq 'LOCAL.*popen$' "$tmp/symbols"
fi

readelf -h "$artifact" >"$tmp/header"
grep -q 'Class:.*ELF64' "$tmp/header"
grep -q 'Data:.*little endian' "$tmp/header"
grep -q 'Machine:.*AArch64' "$tmp/header"

readelf -d "$artifact" >"$tmp/dynamic"
sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p' "$tmp/dynamic" \
    >"$tmp/needed"
[ "$(grep -cx 'libcob.so.4' "$tmp/needed")" -eq 1 ]
if grep -q '/' "$tmp/needed"; then
    printf 'absolute DT_NEEDED rejected\n' >&2
    exit 1
fi
if grep -E 'lib(ssl|crypto)\.so\.3\.' "$tmp/needed" >/dev/null; then
    printf 'patch-named OpenSSL dependency rejected\n' >&2
    exit 1
fi
case "$openssl" in
    yes)
        [ "$(grep -cx 'libssl.so.3' "$tmp/needed")" -eq 1 ]
        [ "$(grep -cx 'libcrypto.so.3' "$tmp/needed")" -eq 1 ]
        ;;
    no)
        if grep -E '^lib(ssl|crypto)' "$tmp/needed" >/dev/null; then
            printf 'unexpected OpenSSL dependency\n' >&2
            exit 1
        fi
        ;;
esac

cobc_real=$(command -v "$cobc")
bootstrap_lib=${XDG_DATA_HOME:-"$HOME/.local/share"}/cobollm/\
gnucobol-3.2/lib
runpath=$(sed -n \
    's/.*\(RPATH\|RUNPATH\).*[[]\([^]]*\)[]].*/\2/p' \
    "$tmp/dynamic")
case "$cobc_real" in
    "${bootstrap_lib%/lib}"/bin/cobc)
        [ "$runpath" = "$bootstrap_lib" ] || {
            printf 'bootstrap RUNPATH mismatch: %s\n' "$runpath" >&2
            exit 1
        }
        [ -f "$bootstrap_lib/libcob.so.4" ]
        ;;
    *)
        [ -z "$runpath" ] || {
            printf 'system compiler artifact has RPATH/RUNPATH\n' >&2
            exit 1
        }
        ;;
esac
if [ -n "$runpath" ] && printf '%s\n' "$runpath" |
    grep -E 'ssl|crypto' >/dev/null; then
    printf 'OpenSSL RPATH/RUNPATH rejected\n' >&2
    exit 1
fi

nm -D --undefined-only "$artifact" |
    sed -n -E 's/.* U ([^@ ]+)(@.*)?$/\1/p' |
    LC_ALL=C sort -u >"$tmp/imports"
while IFS= read -r symbol; do
    grep -qx "$symbol" "$tmp/imports" || {
        printf 'missing native import: %s\n' "$symbol" >&2
        exit 1
    }
done <"$tmp/expected-native"

readelf --version-info "$artifact" >"$tmp/versions"
glibc_max=$(grep -o 'GLIBC_[0-9][0-9.]*' "$tmp/versions" |
    sed 's/^GLIBC_//' | sort -Vu | tail -1)
[ -n "$glibc_max" ]
if [ "$(printf '%s\n%s\n' 2.39 "$glibc_max" |
    sort -V | tail -1)" != 2.39 ]; then
    printf 'GLIBC symbol floor exceeded: %s\n' "$glibc_max" >&2
    exit 1
fi
if [ "$openssl" = yes ]; then
    openssl_versions=$(grep -o 'OPENSSL_[0-9][0-9.]*' \
        "$tmp/versions" | LC_ALL=C sort -u)
    [ "$openssl_versions" = OPENSSL_3.0.0 ] || {
        printf 'unexpected OpenSSL symbol versions: %s\n' \
            "$openssl_versions" >&2
        exit 1
    }
fi

ldd -r "$artifact" >"$tmp/ldd" 2>&1
if grep -E 'undefined symbol|not found' "$tmp/ldd" >/dev/null; then
    sed -n '1,200p' "$tmp/ldd" >&2
    exit 1
fi
selected_libdir=$($cobc -info | awk \
    '/^COB_LIBS/{for(i=1;i<=NF;i++)if($i~/^-L/){print substr($i,3);exit}}')
selected_lib=$(readlink -f "$selected_libdir/libcob.so.4")
resolved_lib=$(awk '/libcob\.so\.4 =>/{print $3;exit}' "$tmp/ldd")
[ -n "$selected_lib" ] && [ -n "$resolved_lib" ] &&
    [ "$selected_lib" = "$(readlink -f "$resolved_lib")" ] || {
    printf 'artifact did not resolve selected compiler libcob.so.4\n' >&2
    exit 1
}
"$cobc" --version >/dev/null
printf 'PASS GNU link %s\n' "$name"
