#!/bin/sh
set -eu

fail() {
    printf '%s\n' "AT-TLS fixture test: $*" >&2
    exit 1
}

root=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
gate=$root/zos/verify-attls.sh
fixture=$root/test/fixtures/attls-effective.policy
template=$root/zos/attls.policy.example
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/cobollm-attls-test.XXXXXX")
case "$work_dir" in
    "${TMPDIR:-/tmp}"/cobollm-attls-test.*) ;;
    *) fail 'mktemp returned an unexpected path' ;;
esac
trap 'rm -rf "$work_dir"' EXIT HUP INT TERM

export COBOLLM_SELECTED_STACK=TCPIP
export COBOLLM_POLICY_DEST=/etc/pagent/cobollm.policy
export COBOLLM_EXPECT_JOB=COBOLLM
export COBOLLM_EXPECT_HOST=api.openai.com
export COBOLLM_EXPECT_PORT=443
export COBOLLM_EXPECT_KEYRING=SITEUSER/REALRING
template_fixture=$work_dir/template-effective.policy
{
    printf '%s\n' 'ImageName: TCPIP'
    printf '%s\n' 'ImageFileName: /etc/pagent/cobollm.policy'
    printf '%s\n' 'Status: Active'
    sed 's#SITEUSER/SITERING#SITEUSER/REALRING#' "$template"
} > "$template_fixture"
fixtures="$fixture $template_fixture"

run_valid() {
    for policy in $fixtures; do
        COBOLLM_EFFECTIVE_POLICY=$policy "$gate" effective >/dev/null
    done
}

reject_change() {
    name=$1
    expression=$2
    sequence=0
    for policy in $fixtures; do
        sequence=$((sequence + 1))
        candidate=$work_dir/$name-$sequence.policy
        perl -0pe "$expression" "$policy" > "$candidate"
        if COBOLLM_EFFECTIVE_POLICY=$candidate \
            "$gate" effective >/dev/null 2>&1; then
            fail "$name fixture $sequence was accepted"
        fi
    done
}

accept_append() {
    name=$1
    body=$2
    sequence=0
    for policy in $fixtures; do
        sequence=$((sequence + 1))
        candidate=$work_dir/$name-$sequence.policy
        cp "$policy" "$candidate"
        printf '\n%s\n' "$body" >> "$candidate"
        COBOLLM_EFFECTIVE_POLICY=$candidate "$gate" effective >/dev/null
    done
}

reject_append() {
    name=$1
    body=$2
    sequence=0
    for policy in $fixtures; do
        sequence=$((sequence + 1))
        candidate=$work_dir/$name-$sequence.policy
        cp "$policy" "$candidate"
        printf '\n%s\n' "$body" >> "$candidate"
        if COBOLLM_EFFECTIVE_POLICY=$candidate \
            "$gate" effective >/dev/null 2>&1; then
            fail "$name fixture $sequence was accepted"
        fi
    done
}

run_valid
reject_change wrong-rule 's/COBOLLMRule/OtherRule/'
reject_change wrong-job 's/Jobname COBOLLM/Jobname OTHER/'
reject_change wrong-endpoint 's/api[.]openai[.]com/bad.example/g'
reject_change wrong-port 's/RemotePortRange 443/RemotePortRange 80/'
reject_change wrong-direction 's/Direction Outbound/Direction Inbound/'
reject_change wrong-reference \
    's/TTLSGroupActionRef COBOLLMGroup/TTLSGroupActionRef OtherGroup/'
reject_change wrong-action \
    's/TTLSGroupAction COBOLLMGroup/TTLSGroupAction OtherGroup/'
reject_change wrong-sni \
    's/ClientHandshakeSNI Required/ClientHandshakeSNI Optional/'
reject_change wrong-role 's/HandshakeRole Client/HandshakeRole Server/'
reject_change missing-role 's/  HandshakeRole Client\n//'
reject_change wrong-sni-match \
    's/ClientHandshakeSNIMatch Required/ClientHandshakeSNIMatch Optional/'
reject_change wildcard-off \
    's/HostRefWildcardValidation On/HostRefWildcardValidation Off/'
reject_change wrong-refdns \
    's/HostReferenceIdDNS api[.]openai[.]com/HostReferenceIdDNS bad.example/'
reject_change wrong-keyring \
    's/Keyring SITEUSER\/REALRING/Keyring SITEUSER\/OTHERRING/'
reject_change missing-keyring \
    's/  Keyring SITEUSER\/REALRING\n//'
reject_change wrong-protocol 's/TLSv1[.]2 On/TLSv1.2 Off/'
reject_change wrong-ciphers \
    's/V3CipherSuites4Char 1301C02F/V3CipherSuites4Char C02F1301/'
reject_change override \
    's/  TTLSGroupActionRef/  TTLSConnectionActionRef Bad\n  TTLSGroupActionRef/'
reject_change duplicate \
    's/(  TTLSEnabled On)/$1\n$1/'
reject_change duplicate-block '$_ .= $_'
reject_change wrong-nesting \
    's/  HandshakeRole Client\n//; s/(  TTLSEnabled On)/$1\n  HandshakeRole Client/'
reject_change missing-enabled 's/  TTLSEnabled On\n//'
reject_change wrong-enabled-placement \
    's/  TTLSEnabled On\n//; s/(  HandshakeRole Client)/$1\n  TTLSEnabled On/'
reject_change wrong-role-nesting \
    's/  HandshakeRole Client\n//; s/(  TTLSEnabled On)/$1\n  HandshakeRole Client/'
reject_change wrong-sni-nesting \
    's/  ClientHandshakeSNI Required\n//; s/(  Keyring SITEUSER\/REALRING)/$1\n    ClientHandshakeSNI Required/'
reject_change wrong-keyring-nesting \
    's/  TTLSKeyringParms\n  \{\n    Keyring SITEUSER\/REALRING\n  \}\n/  Keyring SITEUSER\/REALRING\n/'
reject_change missing-group-ref \
    's/  TTLSGroupActionRef COBOLLMGroup\n//'
reject_change missing-environment-ref \
    's/  TTLSEnvironmentActionRef COBOLLMEnvironment\n//'
reject_change missing-advanced-ref \
    's/  TTLSEnvironmentAdvancedParmsRef COBOLLMAdvanced\n//'
reject_change missing-cipher-ref \
    's/  TTLSCipherParmsRef COBOLLMCiphers\n//'
reject_change missing-group-block \
    's/\nTTLSGroupAction COBOLLMGroup\n\{.*?\n\}\n//s'
reject_change missing-environment-block \
    's/\nTTLSEnvironmentAction COBOLLMEnvironment\n\{.*?\n\}\n\nTTLSEnvironmentAdvancedParms/\nTTLSEnvironmentAdvancedParms/s'
reject_change missing-advanced-block \
    's/\nTTLSEnvironmentAdvancedParms COBOLLMAdvanced\n\{.*?\n\}\n//s'
reject_change missing-cipher-block \
    's/\nTTLSCipherParms COBOLLMCiphers\n\{.*?\n\}\n//s'
reject_change sslv2-enabled 's/SSLv2 Off/SSLv2 On/'
reject_change sslv3-enabled 's/SSLv3 Off/SSLv3 On/'
reject_change tlsv1-enabled 's/TLSv1 Off/TLSv1 On/'
reject_change tlsv11-enabled 's/TLSv1[.]1 Off/TLSv1.1 On/'
reject_change tlsv13-disabled 's/TLSv1[.]3 On/TLSv1.3 Off/'
reject_change missing-sni-required \
    's/  ClientHandshakeSNI Required\n//'
reject_change missing-sni-match \
    's/  ClientHandshakeSNIMatch Required\n//'
reject_change missing-sni-list \
    's/  ClientHandshakeSNIList api[.]openai[.]com\n//'
reject_change extra-sni-list \
    's/(  ClientHandshakeSNIList api[.]openai[.]com)/$1\n  ClientHandshakeSNIList bad.example/'
reject_change missing-refdns \
    's/  HostReferenceIdDNS api[.]openai[.]com\n//'
reject_change extra-refdns \
    's/(  HostReferenceIdDNS api[.]openai[.]com)/$1\n  HostReferenceIdDNS bad.example/'
reject_change missing-wildcard-validation \
    's/  HostRefWildcardValidation On\n//'
reject_change missing-ciphers \
    's/  V3CipherSuites4Char 1301C02F\n//'
reject_change extra-ciphers \
    's/(  V3CipherSuites4Char 1301C02F)/$1\n  V3CipherSuites4Char 003B/'
reject_change inherited-group-override \
    's/(  TTLSGroupActionRef COBOLLMGroup)/$1\n  TTLSGroupActionRef OtherGroup/'
reject_change connection-override \
    's/(  HandshakeRole Client)/$1\n  TTLSConnectionActionRef OtherConnection/'
accept_append unrelated-rule 'TTLSRule OtherRule
{
  Jobname OTHER
  RemotePortRange 80
  Direction Outbound
  TTLSGroupActionRef OtherGroup
}
TTLSGroupAction OtherGroup
{
  TTLSEnabled On
}'
reject_append competing-rule 'TTLSRule CompetingRule
{
  Jobname COBOLLM
  RemotePortRange 443
  Direction Outbound
  TTLSGroupActionRef OtherGroup
}'
reject_append competing-broad-rule 'TTLSRule BroadRule
{
  RemotePortRange 1-65535
  Direction Outbound
  TTLSGroupActionRef OtherGroup
}'
reject_append competing-owned-reference 'TTLSRule OtherRule
{
  Jobname OTHER
  RemotePortRange 80
  Direction Outbound
  TTLSGroupActionRef COBOLLMGroup
}'
reject_append competing-action 'TTLSConnectionAction COBOLLMGroup
{
  HandshakeRole Client
}'

printf '%s\n' 'PASS AT-TLS policy fixtures'
