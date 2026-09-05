#!/bin/sh
set -eu

fail() {
    printf '%s\n' "AT-TLS gate: $*" >&2
    exit 1
}

need_file() {
    name=$1
    value=$2
    [ -n "$value" ] || fail "$name is unset"
    [ -r "$value" ] || fail "$value is not readable"
}

need_value() {
    name=$1
    value=$2
    [ -n "$value" ] || fail "$name is unset"
}

validate_expectations() {
    need_value COBOLLM_EXPECT_JOB "${COBOLLM_EXPECT_JOB-}"
    need_value COBOLLM_EXPECT_HOST "${COBOLLM_EXPECT_HOST-}"
    need_value COBOLLM_EXPECT_PORT "${COBOLLM_EXPECT_PORT-}"
    need_value COBOLLM_EXPECT_KEYRING "${COBOLLM_EXPECT_KEYRING-}"
    case "$COBOLLM_EXPECT_JOB" in
        *[!A-Za-z0-9@\$#]*|'') fail 'expected job name is invalid' ;;
    esac
    [ "${#COBOLLM_EXPECT_JOB}" -le 8 ] ||
        fail 'expected job name is too long'
    case "$COBOLLM_EXPECT_HOST" in
        *[!A-Za-z0-9.-]*|.*|*..*|*.)
            fail 'expected endpoint hostname is invalid' ;;
    esac
    case "$COBOLLM_EXPECT_PORT" in
        *[!0-9]*|'') fail 'expected endpoint port is invalid' ;;
    esac
    if [ "$COBOLLM_EXPECT_PORT" -lt 1 ] ||
        [ "$COBOLLM_EXPECT_PORT" -gt 65535 ]; then
        fail 'expected endpoint port is out of range'
    fi
    case "$COBOLLM_EXPECT_KEYRING" in
        *[!A-Za-z0-9@\$#._/-]*|'') fail 'expected keyring is invalid' ;;
    esac
    [ "$COBOLLM_EXPECT_KEYRING" != 'SITEUSER/SITERING' ] ||
        fail 'site keyring placeholder was not substituted'
}

normalize_lines() {
    awk '
        {
            sub(/\r$/, "")
            sub(/[[:space:]]*#.*/, "")
            gsub(/[[:space:]]*:[[:space:]]*/, " ")
            gsub(/[[:space:]]+/, " ")
            sub(/^ /, "")
            sub(/ $/, "")
            if (length) print
        }
    ' "$1"
}

# Prefix non-owned top-level blocks with ! instead of hiding them.
normalize_policy() {
    awk '
        function clean(value) {
            sub(/\r$/, "", value)
            sub(/[[:space:]]*#.*/, "", value)
            gsub(/[[:space:]]+/, " ", value)
            sub(/^ /, "", value)
            sub(/ $/, "", value)
            return value
        }
        function owned(value) {
            return value == "TTLSRule COBOLLMRule" ||
                value == "TTLSGroupAction COBOLLMGroup" ||
                value == "TTLSEnvironmentAction COBOLLMEnvironment" ||
                value == "TTLSEnvironmentAdvancedParms COBOLLMAdvanced" ||
                value == "TTLSCipherParms COBOLLMCiphers"
        }
        function token(value, fields, count) {
            count = split(value, fields, " ")
            if (count == 1) return fields[1]
            if (count == 2) return fields[1] "=" fields[2]
            bad = 1
            return "INVALID"
        }
        function flush() {
            if (pending != "" && depth > 0) {
                prefix = active[depth] ? "" : "!"
                print prefix path[depth] "|" pending
            }
            pending = ""
        }
        {
            line = clean($0)
            if (line == "") next
            if (line == "{") {
                if (pending == "") { bad = 1; next }
                ++depth
                part = token(pending)
                if (depth == 1) {
                    path[depth] = "/" part
                    active[depth] = owned(pending)
                } else {
                    path[depth] = path[depth - 1] "/" part
                    active[depth] = active[depth - 1]
                }
                prefix = active[depth] ? "" : "!"
                print prefix "@|" path[depth]
                pending = ""
            } else if (line == "}") {
                flush()
                if (depth < 1) { bad = 1; next }
                delete path[depth]
                delete active[depth]
                --depth
            } else {
                flush()
                pending = line
            }
        }
        END {
            flush()
            if (depth != 0 || bad) exit 1
        }
    ' "$1" | LC_ALL=C sort
}

reject_competitors() {
    awk -v job="$COBOLLM_EXPECT_JOB" \
        -v port="$COBOLLM_EXPECT_PORT" '
        function owned_name(value) {
            return value == "COBOLLMRule" ||
                value == "COBOLLMGroup" ||
                value == "COBOLLMEnvironment" ||
                value == "COBOLLMAdvanced" ||
                value == "COBOLLMCiphers"
        }
        function wildcard(value) {
            return value ~ /[*?%]/
        }
        function port_matches(value, range, count) {
            sub(/^RemotePortRange /, "", value)
            gsub(/[-:]/, " ", value)
            count = split(value, range, / +/)
            if (count == 1 && range[1] ~ /^[0-9]+$/)
                return range[1] == port
            if (count == 2 && range[1] ~ /^[0-9]+$/ &&
                range[2] ~ /^[0-9]+$/)
                return range[1] <= port && port <= range[2]
            return 1
        }
        /^!@\// { bad=1 }
        /^!@\|\// {
            path = substr($0, 4)
            rest = substr(path, 2)
            if (rest ~ /\//) next
            split(rest, pair, "=")
            if (owned_name(pair[2])) bad=1
            if (pair[1] == "TTLSRule") rule[path]=1
            next
        }
        /^!\// {
            line = substr($0, 2)
            separator = index(line, "|")
            path = substr(line, 1, separator - 1)
            statement = substr(line, separator + 1)
            if (statement ~ /Ref /) {
                count = split(statement, fields, " ")
                if (owned_name(fields[count])) bad=1
            }
            if (path !~ /^\/TTLSRule=[^/]+$/) next
            rule[path]=1
            if (statement ~ /^Jobname /) {
                job_seen[path]=1
                value = statement
                sub(/^Jobname /, "", value)
                if (value == job || wildcard(value)) job_match[path]=1
            } else if (statement ~ /^RemotePortRange /) {
                port_seen[path]=1
                if (port_matches(statement)) port_match[path]=1
            } else if (statement ~ /^Direction /) {
                direction_seen[path]=1
                value = statement
                sub(/^Direction /, "", value)
                if (value != "Inbound") direction_match[path]=1
            }
        }
        END {
            for (path in rule) {
                jm = !job_seen[path] || job_match[path]
                pm = !port_seen[path] || port_match[path]
                dm = !direction_seen[path] || direction_match[path]
                if (jm && pm && dm) bad=1
            }
            exit bad
        }
    ' "$1"
}

expected_policy() {
    rule='/TTLSRule=COBOLLMRule'
    group='/TTLSGroupAction=COBOLLMGroup'
    env='/TTLSEnvironmentAction=COBOLLMEnvironment'
    keyring="$env/TTLSKeyringParms"
    advanced='/TTLSEnvironmentAdvancedParms=COBOLLMAdvanced'
    ciphers='/TTLSCipherParms=COBOLLMCiphers'
    {
        printf '%s\n' "@|$rule"
        printf '%s\n' "$rule|Jobname $COBOLLM_EXPECT_JOB"
        printf '%s\n' "$rule|RemotePortRange $COBOLLM_EXPECT_PORT"
        printf '%s\n' "$rule|Direction Outbound"
        printf '%s\n' "$rule|TTLSGroupActionRef COBOLLMGroup"
        printf '%s\n' \
            "$rule|TTLSEnvironmentActionRef COBOLLMEnvironment"
        printf '%s\n' "@|$group" "$group|TTLSEnabled On"
        printf '%s\n' "@|$env" "$env|HandshakeRole Client"
        printf '%s\n' "@|$keyring" \
            "$keyring|Keyring $COBOLLM_EXPECT_KEYRING"
        printf '%s\n' "$env|TTLSCipherParmsRef COBOLLMCiphers"
        printf '%s\n' \
            "$env|TTLSEnvironmentAdvancedParmsRef COBOLLMAdvanced"
        printf '%s\n' "@|$advanced"
        printf '%s\n' "$advanced|SSLv2 Off" "$advanced|SSLv3 Off"
        printf '%s\n' "$advanced|TLSv1 Off" "$advanced|TLSv1.1 Off"
        printf '%s\n' "$advanced|TLSv1.2 On" "$advanced|TLSv1.3 On"
        printf '%s\n' "$advanced|ClientHandshakeSNI Required"
        printf '%s\n' "$advanced|ClientHandshakeSNIMatch Required"
        printf '%s\n' \
            "$advanced|ClientHandshakeSNIList $COBOLLM_EXPECT_HOST"
        printf '%s\n' \
            "$advanced|HostReferenceIdDNS $COBOLLM_EXPECT_HOST"
        printf '%s\n' "$advanced|HostRefWildcardValidation On"
        printf '%s\n' "@|$ciphers"
        printf '%s\n' "$ciphers|V3CipherSuites4Char 1301C02F"
    } | LC_ALL=C sort
}

verify_effective() {
    need_file COBOLLM_EFFECTIVE_POLICY "$COBOLLM_EFFECTIVE_POLICY"
    validate_expectations
    work_dir=$1
    normalize_policy "$COBOLLM_EFFECTIVE_POLICY" > \
        "$work_dir/effective.all" ||
        fail 'effective policy has malformed block syntax'
    reject_competitors "$work_dir/effective.all" ||
        fail 'effective policy has a competing rule or action'
    grep -v '^!' "$work_dir/effective.all" > \
        "$work_dir/effective.normalized"
    expected_policy > "$work_dir/expected.normalized"
    cmp "$work_dir/expected.normalized" \
        "$work_dir/effective.normalized" >/dev/null ||
        fail 'effective policy differs from exact owned structure'
    normalize_lines "$COBOLLM_EFFECTIVE_POLICY" > \
        "$work_dir/effective.lines"
    [ "$(grep -Fxc "ImageName $COBOLLM_SELECTED_STACK" \
        "$work_dir/effective.lines")" -eq 1 ] ||
        fail 'effective policy lacks exact selected image'
    [ "$(grep -Fxc "ImageFileName $COBOLLM_POLICY_DEST" \
        "$work_dir/effective.lines")" -eq 1 ] ||
        fail 'effective policy lacks exact installed source'
    [ "$(grep -Fxc 'Status Active' \
        "$work_dir/effective.lines")" -eq 1 ] ||
        fail 'effective policy is not uniquely active'
}

new_work_dir() {
    work_dir=$(mktemp -d "${TMPDIR:-/tmp}/cobollm-attls.XXXXXX")
    case "$work_dir" in
        "${TMPDIR:-/tmp}"/cobollm-attls.*) ;;
        *) fail 'mktemp returned an unexpected path' ;;
    esac
    trap 'rm -rf "$work_dir"' EXIT HUP INT TERM
}

case "${1-}" in
    effective)
        need_value COBOLLM_SELECTED_STACK "${COBOLLM_SELECTED_STACK-}"
        need_value COBOLLM_POLICY_DEST "${COBOLLM_POLICY_DEST-}"
        need_file COBOLLM_EFFECTIVE_POLICY \
            "${COBOLLM_EFFECTIVE_POLICY-}"
        new_work_dir
        verify_effective "$work_dir"
        printf '%s\n' 'PASS AT-TLS effective policy'
        ;;
    provenance)
        need_file COBOLLM_PAGENT_MAIN "${COBOLLM_PAGENT_MAIN-}"
        need_file COBOLLM_PAGENT_IMAGE "${COBOLLM_PAGENT_IMAGE-}"
        need_file COBOLLM_POLICY_SOURCE "${COBOLLM_POLICY_SOURCE-}"
        need_file COBOLLM_POLICY_STAGE "${COBOLLM_POLICY_STAGE-}"
        need_file COBOLLM_INSTALLED_POLICY \
            "${COBOLLM_INSTALLED_POLICY-}"
        need_file COBOLLM_POLICY_PARSE_LOG \
            "${COBOLLM_POLICY_PARSE_LOG-}"
        need_file COBOLLM_EFFECTIVE_POLICY \
            "${COBOLLM_EFFECTIVE_POLICY-}"
        need_value COBOLLM_RUNNING_MAIN "${COBOLLM_RUNNING_MAIN-}"
        need_value COBOLLM_SELECTED_STACK "${COBOLLM_SELECTED_STACK-}"
        need_value COBOLLM_POLICY_DEST "${COBOLLM_POLICY_DEST-}"
        [ "$COBOLLM_RUNNING_MAIN" = "$COBOLLM_PAGENT_MAIN" ] ||
            fail 'running PAGENT_CONFIG_FILE differs from inspected main'
        [ "$COBOLLM_POLICY_DEST" = "$COBOLLM_INSTALLED_POLICY" ] ||
            fail 'installed policy path differs from recorded destination'
        validate_expectations
        new_work_dir
        export _BPXK_AUTOCVT=OFF
        export _ICONV_TECHNIQUE=L
        perl -e '
            use strict;
            my $file = shift;
            open my $fh, "<", $file or die "$file: $!\n";
            binmode $fh;
            local $/;
            my $data = <$fh>;
            defined($data) && length($data) or die "$file: empty\n";
            $data =~ /\x0a\z/ or die "$file: missing final LF\n";
            $data !~ /\x0a\x0a\z/ or die "$file: extra final LF\n";
            $data !~ /[^\x20-\x7e\x0a]/ or
                die "$file: invalid source byte\n";
        ' "$COBOLLM_POLICY_SOURCE" || fail 'policy source validation failed'
        normalize_policy "$COBOLLM_POLICY_SOURCE" > \
            "$work_dir/source.normalized" ||
            fail 'substituted policy has malformed block syntax'
        expected_policy > "$work_dir/expected.normalized"
        cmp "$work_dir/expected.normalized" \
            "$work_dir/source.normalized" >/dev/null ||
            fail 'substituted policy differs from exact owned structure'
        iconv -f UTF-8 -t IBM-1047 "$COBOLLM_POLICY_SOURCE" > \
            "$work_dir/source.1047"
        cmp "$work_dir/source.1047" "$COBOLLM_POLICY_STAGE" >/dev/null ||
            fail 'staged policy bytes differ from explicit conversion'
        cmp "$COBOLLM_POLICY_STAGE" \
            "$COBOLLM_INSTALLED_POLICY" >/dev/null ||
            fail 'installed destination bytes differ from staging'
        for file in "$COBOLLM_POLICY_STAGE" \
            "$COBOLLM_INSTALLED_POLICY"; do
            tag=$(chtag -p "$file")
            printf '%s\n' "$tag" | awk '
                NR == 1 && $1 == "t" && $2 == "IBM-1047" &&
                    $3 == "T=on" { found=1 }
                END { exit !found }
            ' || fail "$file is not tagged IBM-1047 text"
        done
        iconv -f IBM-1047 -t UTF-8 "$COBOLLM_POLICY_STAGE" > \
            "$work_dir/source.roundtrip"
        cmp "$COBOLLM_POLICY_SOURCE" \
            "$work_dir/source.roundtrip" >/dev/null ||
            fail 'staged policy reverse conversion differs'
        printf '[]{}\\^~|@#$' | iconv -f UTF-8 -t IBM-1047 > \
            "$work_dir/variant.1047"
        [ "$(od -An -tx1 "$work_dir/variant.1047" | tr -d ' \n')" = \
            'adbdc0d0e05fa14f7c7b5b' ] ||
            fail 'IBM-1047 variant mapping differs'
        normalize_lines "$COBOLLM_PAGENT_MAIN" > "$work_dir/main.lines"
        [ "$(grep -Fxc 'Codepage IBM-1047' \
            "$work_dir/main.lines")" -eq 1 ] ||
            fail 'main configuration lacks one explicit code page'
        awk -v stack="$COBOLLM_SELECTED_STACK" \
            -v image="$COBOLLM_PAGENT_IMAGE" '
            $1 == "TcpImage" && $2 == stack && $3 == image { ++found }
            $1 == "TcpImage" && $2 == stack && $3 != image { bad=1 }
            END { exit found != 1 || bad }
        ' "$work_dir/main.lines" ||
            fail 'selected stack does not map once to inspected image'
        normalize_lines "$COBOLLM_PAGENT_IMAGE" > "$work_dir/image.lines"
        [ "$(grep -Fxc "TTLSConfig $COBOLLM_POLICY_DEST" \
            "$work_dir/image.lines")" -eq 1 ] ||
            fail 'image lacks one exact installed TTLSConfig'
        [ "$(grep -c '^TTLSConfig ' "$work_dir/image.lines")" -eq 1 ] ||
            fail 'image contains an alternate TTLSConfig source'
        if grep -Ei \
            '^(CommonTTLSConfig|PolicyServer|LDAP|Dynamic)[[:space:]]' \
            "$work_dir/main.lines" "$work_dir/image.lines" >/dev/null; then
            fail 'alternate active policy source is configured'
        fi
        normalize_lines "$COBOLLM_POLICY_PARSE_LOG" > \
            "$work_dir/parser.lines"
        if grep -F 'EZZ8438I' "$work_dir/parser.lines" >/dev/null; then
            fail 'Policy Agent parser reported definition errors'
        fi
        parser_complete="EZZ8771I PAGENT CONFIG POLICY PROCESSING COMPLETE"
        parser_complete="$parser_complete FOR $COBOLLM_SELECTED_STACK TTLS"
        [ "$(grep -Fxc "$parser_complete" \
            "$work_dir/parser.lines")" -eq 1 ] ||
            fail 'parser completion evidence is missing'
        install_complete='EZD1586I PAGENT HAS INSTALLED ALL LOCAL POLICIES'
        install_complete="$install_complete FOR $COBOLLM_SELECTED_STACK"
        [ "$(grep -Fxc "$install_complete" \
            "$work_dir/parser.lines")" -eq 1 ] ||
            fail 'local policy installation evidence is missing'
        verify_effective "$work_dir"
        printf '%s\n' 'PASS AT-TLS provenance'
        ;;
    no-leak)
        need_file COBOLLM_PEER_CAPTURE "${COBOLLM_PEER_CAPTURE-}"
        bytes=$(wc -c < "$COBOLLM_PEER_CAPTURE" | tr -d ' ')
        [ "$bytes" -eq 0 ] ||
            fail 'failed protection gate sent application bytes'
        printf '%s\n' 'PASS AT-TLS no application-byte leak'
        ;;
    *)
        printf '%s\n' \
            'usage: verify-attls.sh effective|provenance|no-leak' >&2
        exit 2
        ;;
esac
