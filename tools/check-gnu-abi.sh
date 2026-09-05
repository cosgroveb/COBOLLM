#!/bin/sh
set -eu

family=linux-aarch64-elf64-le-lp64-glibc2-openssl3-so3-gnucobol3-libcob4-ai48-sa152
cobc=${1:-cobc}
failed=0

fail() {
    printf 'COBOLLM GNU ABI mismatch: %s\n' "$1" >&2
    failed=1
}

[ "$(uname -s)" = Linux ] || fail "OS $(uname -s), expected Linux"
[ "$(uname -m)" = aarch64 ] || fail "machine $(uname -m), expected aarch64"
[ "$(getconf LONG_BIT)" = 64 ] || fail "LONG_BIT, expected 64"
pagesize=$(getconf PAGESIZE)
case "$pagesize" in
    ''|*[!0-9]*) fail "PAGESIZE $pagesize, expected integer" ;;
    *) [ "$((32 * pagesize))" -le 131072 ] ||
           fail "32 * PAGESIZE exceeds 131072" ;;
esac
readelf -h /proc/self/exe | grep -q 'Class:.*ELF64' || fail "ELF class"
readelf -h /proc/self/exe | grep -q 'Data:.*little endian' || fail "endian"
glibc=$(getconf GNU_LIBC_VERSION | awk '{print $2}')
case "$glibc" in
    2.*) minor=${glibc#2.}; minor=${minor%%.*}
         [ "$minor" -ge 39 ] || fail "glibc $glibc, expected >= 2.39" ;;
    *) fail "glibc $glibc, expected glibc 2.x" ;;
esac
openssl version | grep -q '^OpenSSL 3\.' || fail "OpenSSL major"
pkg-config --modversion openssl | grep -q '^3\.' || fail "OpenSSL headers"
ldconfig -p | grep -q 'libssl\.so\.3 ' || fail "libssl.so.3"
ldconfig -p | grep -q 'libcrypto\.so\.3 ' || fail "libcrypto.so.3"
version=$($cobc --version | sed -n '1s/.* \([0-9][0-9.]*\).*/\1/p')
major=${version%%.*}
rest=${version#*.}
minor=${rest%%.*}
[ "$major" = 3 ] || fail "GnuCOBOL $version, expected major 3"
[ "$minor" -ge 2 ] || fail "GnuCOBOL $version, expected >= 3.2"
libdir=$($cobc -info | awk \
    '/^COB_LIBS/{for(i=1;i<=NF;i++)if($i~/^-L/){print substr($i,3);exit}}')
[ -n "$libdir" ] || fail "selected compiler reports no COB_LIBS -L path"
[ -f "$libdir/libcob.so.4" ] ||
    fail "selected compiler has no matching libcob.so.4"

provenance_text='spark 2026-09-04 glibc 2.39 OpenSSL 3.0.13 /usr/include /lib/aarch64-linux-gnu'
for marker in \
    'GNU-ABI-FAMILY' 'GNU-NET-ABI-FAMILY'; do
    file=gnu/copy/POSIXNAT.cpy
    case "$marker" in GNU-NET-*) file=gnu/copy/NETNAT.cpy ;; esac
    value=$(awk -v marker="$marker" '
        index($0, marker) {on=1}
        on {while(match($0,/"[^"]*"/)){v=v substr($0,RSTART+1,RLENGTH-2);$0=substr($0,RSTART+RLENGTH)};if(/\./){print v;exit}}
    ' "$file")
    [ "$value" = "$family" ] || fail "$file exact family metadata"
done
for marker in \
    'GNU-ABI-PROVENANCE' 'GNU-NET-ABI-PROVENANCE'; do
    file=gnu/copy/POSIXNAT.cpy
    case "$marker" in GNU-NET-*) file=gnu/copy/NETNAT.cpy ;; esac
    value=$(awk -v marker="$marker" '
        index($0, marker) {on=1}
        on {while(match($0,/"[^"]*"/)){v=v substr($0,RSTART+1,RLENGTH-2);$0=substr($0,RSTART+RLENGTH)};if(/\./){print v;exit}}
    ' "$file")
    [ "$value" = "$provenance_text" ] ||
        fail "$file exact provenance metadata"
done
for spec in \
    'INT-WIDTH 4' 'SOCKLEN-WIDTH 4' 'POINTER-WIDTH 8' \
    'LONG-WIDTH 8' 'SIZE-WIDTH 8' 'SSIZE-WIDTH 8' \
    'ADDRINFO-SIZE 48' 'SIGACTION-SIZE 152'; do
    name=${spec% *}
    expected=${spec#* }
    for prefix in GNU- GNU-NET-; do
        file=gnu/copy/POSIXNAT.cpy
        [ "$prefix" = GNU-NET- ] && file=gnu/copy/NETNAT.cpy
        line=$(grep "${prefix}${name}" "$file")
        value=$(printf '%s\n' "$line" | sed -n 's/.*VALUE \([0-9][0-9]*\)\..*/\1/p;s/.*VALUE \([0-9][0-9]*\) *\..*/\1/p;s/.*VALUE \([0-9][0-9]*\) *$/\1/p' | head -1)
        [ "$value" = "$expected" ] || fail "$file ${name} exact value"
    done
done

addrinfo_layout=$(sed -n '/^       01 GNU-ADDRINFO\.$/,/^       01 GNU-ADDRINFO-VIEW BASED\.$/p' gnu/copy/NETNAT.cpy | sed '$d')
expected_addrinfo='       01 GNU-ADDRINFO.
           05 GNU-AI-FLAGS          PIC S9(9) COMP-5.
           05 GNU-AI-FAMILY         PIC S9(9) COMP-5.
           05 GNU-AI-SOCKTYPE       PIC S9(9) COMP-5.
           05 GNU-AI-PROTOCOL       PIC S9(9) COMP-5.
           05 GNU-AI-ADDRLEN        PIC 9(9) COMP-5.
           05 GNU-AI-PADDING        PIC X(4).
           05 GNU-AI-ADDR           USAGE POINTER.
           05 GNU-AI-CANONNAME      USAGE POINTER.
           05 GNU-AI-NEXT           USAGE POINTER.'
[ "$addrinfo_layout" = "$expected_addrinfo" ] || fail 'addrinfo exact layout'
addrinfo_view_layout=$(sed -n '/^       01 GNU-ADDRINFO-VIEW BASED\.$/,/^       01 GNU-SIGACTION-RECORD\.$/p' gnu/copy/NETNAT.cpy | sed '$d')
expected_addrinfo_view='       01 GNU-ADDRINFO-VIEW BASED.
           05 GNU-V-AI-FLAGS        PIC S9(9) COMP-5.
           05 GNU-V-AI-FAMILY       PIC S9(9) COMP-5.
           05 GNU-V-AI-SOCKTYPE     PIC S9(9) COMP-5.
           05 GNU-V-AI-PROTOCOL     PIC S9(9) COMP-5.
           05 GNU-V-AI-ADDRLEN      PIC 9(9) COMP-5.
           05 GNU-V-AI-PADDING      PIC X(4).
           05 GNU-V-AI-ADDR         USAGE POINTER.
           05 GNU-V-AI-CANONNAME    USAGE POINTER.
           05 GNU-V-AI-NEXT         USAGE POINTER.'
[ "$addrinfo_view_layout" = "$expected_addrinfo_view" ] ||
    fail 'addrinfo view exact layout'
sigaction_layout=$(sed -n '/^       01 GNU-SIGACTION-RECORD\.$/,/^       01 GNU-SAVED-SIGACTION-RECORD\.$/p' gnu/copy/NETNAT.cpy | sed '$d')
expected_sigaction='       01 GNU-SIGACTION-RECORD.
           05 GNU-SA-HANDLER        PIC 9(18) COMP-5.
           05 GNU-SA-MASK           PIC X(128).
           05 GNU-SA-FLAGS          PIC S9(9) COMP-5.
           05 GNU-SA-PADDING        PIC X(4).
           05 GNU-SA-RESTORER       USAGE POINTER.'
[ "$sigaction_layout" = "$expected_sigaction" ] || fail 'sigaction exact layout'
saved_sigaction_layout=$(sed -n '/^       01 GNU-SAVED-SIGACTION-RECORD\.$/,$p' gnu/copy/NETNAT.cpy)
expected_saved_sigaction='       01 GNU-SAVED-SIGACTION-RECORD.
           05 GNU-SAVED-SA-HANDLER  PIC 9(18) COMP-5.
           05 GNU-SAVED-SA-MASK     PIC X(128).
           05 GNU-SAVED-SA-FLAGS    PIC S9(9) COMP-5.
           05 GNU-SAVED-SA-PADDING  PIC X(4).
           05 GNU-SAVED-SA-RESTORER USAGE POINTER.'
[ "$saved_sigaction_layout" = "$expected_saved_sigaction" ] ||
    fail 'saved sigaction exact layout'
[ "$failed" -eq 0 ] || exit 1
printf 'COBOLLM GNU ABI %s\n' "$family"
