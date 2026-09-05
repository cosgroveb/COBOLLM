#!/bin/sh
set -eu

fail() {
    printf '%s\n' "z/OS source gate: $*" >&2
    exit 1
}

check_text() {
    file=$1
    limit=$2
    [ -s "$file" ] || fail "$file is empty"
    [ "$(tail -c 1 "$file" | od -An -tu1 | tr -d ' ')" = 10 ] ||
        fail "$file must end in one LF"
    [ "$(tail -c 2 "$file" | od -An -tu1 | tr -s ' ' | sed 's/^ //')" \
        != '10 10' ] || fail "$file must not end in two LFs"
    LC_ALL=C awk -v file="$file" -v limit="$limit" '
        /[^ -~]/ { print file ":" NR ": non-printable byte" > "/dev/stderr"; bad=1 }
        length($0) > limit {
            print file ":" NR ": line exceeds " limit " bytes" > "/dev/stderr"
            bad=1
        }
        END { exit bad }
    ' "$file" || exit 1
}

source_count=$(find . -type f \( -name '*.cob' -o -name '*.cpy' \
    -o -name '*.jcl' \) -not -path './.git/*' -print | wc -l)
[ "$source_count" -gt 0 ] || fail 'no target source inputs found'

find . -type f \( -name '*.cob' -o -name '*.cpy' -o -name '*.jcl' \) \
    -not -path './.git/*' -print | LC_ALL=C sort |
while IFS= read -r file; do
    case "$file" in
        *.jcl) check_text "$file" 71 ;;
        *) check_text "$file" 72 ;;
    esac
done

for source in cobollm.cob respapi.cob jsonscan.cob http11.cob \
    copy/*.cpy test/*.cob test/fakes/*.cob; do
    if grep -Eq '[[:space:]]&([[:space:]]|$)' "$source"; then
        fail "$source uses non-Enterprise literal concatenation"
    fi
done
grep -q 'MEMBER=TSTNATIV,LIB=COBOL,OUT=OBJ' zos/test.jcl ||
    fail 'z/OS test-native helper compile step is missing'
[ "$(grep -c 'OBJ(TSTNATIV)' zos/test.jcl)" -eq 3 ] ||
    fail 'z/OS test-native helper link inventory differs'
for helper in TSTSETENV TSTUNSETENV TSTGETENV TSTENVCOMMAND TSTCLOSE \
    TSTPIPE TSTDUP TSTDUP2 TSTREAD; do
    grep -q "PROGRAM-ID[.] $helper[.]" zos/testnative.cob ||
        fail "z/OS test-native helper lacks $helper"
done
grep -Fq "'printf ENV-OK; else printf ENV-BAD; exit 1; fi'" \
    zos/testnative.cob ||
    fail 'z/OS environment child lacks nonzero failure exit'
grep -q 'MOVE 118 TO TN-LENGTH' zos/testnative.cob ||
    fail 'z/OS environment child command length differs'
for source in test/tstzagt.cob test/tstshell.cob; do
    if grep -Eq 'CALL STATIC|BY VALUE SIZE IS' "$source"; then
        fail "$source contains GNU native-call syntax"
    fi
done

grep -q 'X"68747470733A2F2F6170692E6F70656E61692E636F6D2F7631"' \
    cobollm.cob || fail 'default URL is not an ASCII byte literal'
if grep -q 'MOVE "https://api.openai.com/v1"' cobollm.cob; then
    fail 'default URL uses a native source literal'
fi

convert_line=$(grep -n "CALL 'NATUTF8'" zos/netio.cob |
    head -1 | cut -d: -f1)
resolve_line=$(grep -n 'ZN-GETADDRINFO' zos/netio.cob |
    tail -1 | cut -d: -f1)
[ -n "$convert_line" ] && [ -n "$resolve_line" ] &&
    [ "$convert_line" -lt "$resolve_line" ] ||
    fail 'z/OS hostname conversion must precede GETADDRINFO'
grep -q 'MOVE TEXT-UTF8-STRICT TO TP-OPERATION' zos/netio.cob ||
    fail 'z/OS hostname conversion is not strict'

for function in fopen fread ferror feof fclose; do
    grep -q "CALL \"$function\"" zos/launch.cob ||
        fail "launcher does not call LE $function"
done
grep -q 'WS-TASK-DD PIC X(8) VALUE X"C4C47AE3C1E2D200"' \
    zos/launch.cob || fail 'launcher does not open DD:TASK'
grep -q 'WS-READ-MODE PIC X(3) VALUE X"998200"' zos/launch.cob ||
    fail 'launcher does not request binary read mode'
grep -q 'WS-TASK-BUFFER PIC X(65536)' zos/launch.cob ||
    fail 'launcher does not probe the first overflow byte'
grep -q 'WS-TOTAL > LIMIT-TASK' zos/launch.cob ||
    fail 'launcher task capacity check is missing'
grep -q 'MOVE LOW-VALUES TO WS-TASK-BUFFER' zos/launch.cob ||
    fail 'launcher does not erase task staging'
if grep -q 'PROCEDURE DIVISION USING' zos/launch.cob; then
    fail 'launcher still accepts an argv linkage'
fi
for fixture in TEST-EXACT-BYTES TEST-CHUNKED TEST-EMPTY TEST-MINIMUM \
    TEST-BOUNDARY-MINUS TEST-BOUNDARY TEST-OVERFLOW TEST-OPEN-FAILURE \
    TEST-READ-FAILURE TEST-ZERO-PROGRESS TEST-CLOSE-FAILURE; do
    grep -q "^       $fixture[.]$" test/tstzlaunch.cob ||
        fail "launcher fixture is missing: $fixture"
done
grep -A9 '^       TEST-EMPTY[.]$' test/tstzlaunch.cob |
    grep -q 'ZF-STATUS NOT = STATUS-OK' ||
    fail 'empty TASK must reach COBOLLM as successful launcher input'
if grep -q 'STATUS-USAGE-TEXT' zos/launch.cob; then
    fail 'launcher must not classify an empty TASK as invalid text'
fi
grep -A12 '^       TEST-BOUNDARY-MINUS[.]$' test/tstzlaunch.cob |
    grep -q 'ZF-TASK-LENGTH NOT = 65534' ||
    fail 'launcher minus-one task boundary fixture differs'
grep -q 'X"40C10025C240"' test/tstzlaunch.cob ||
    fail 'launcher exact-byte fixture is missing'

grep -q 'PERFORM VALIDATE-PARAMETERS' zos/netio.cob ||
    fail 'z/OS network parameter validation is not centralized'
grep -q 'MOVE ZN-SOCKTYPE TO ZN-HINTS-SOCKTYPE' zos/netio.cob ||
    fail 'z/OS resolver hint socktype is not named'
grep -q 'MOVE ZN-PROTOCOL TO ZN-HINTS-PROTOCOL' zos/netio.cob ||
    fail 'z/OS resolver hint protocol is not named'
for operation in OPEN WRITE READ CLOSE; do
    grep -q "WHEN NET-$operation PERFORM $operation-CONNECTION" \
        zos/netio.cob || fail "z/OS dispatch uses unnamed $operation value"
done
for errno_name in ZOS-E2BIG ZOS-EILSEQ ZOS-EINVAL; do
    grep -q "WHEN $errno_name" zos/natutf8.cob ||
        fail "z/OS conversion lacks named $errno_name handling"
done
grep -q '^       ROLLBACK-NONREVERSIBLE[.]$' zos/natutf8.cob ||
    fail 'z/OS conversion lacks nonreversible rollback'
for field in WS-SAVED-OUTPUT WS-SAVED-OUT-LEFT WS-SAVED-OUT-PTR; do
    grep -q "$field" zos/natutf8.cob ||
        fail "z/OS conversion rollback omits $field"
done
grep -q 'WHEN WS-CONVERT-RESULT > ZERO AND' zos/natutf8.cob ||
    fail 'z/OS conversion does not detect positive iconv results'
grep -q '^       TEST-UTF8-UNREPRESENTABLE-STRICT[.]$' \
    test/tstztext.cob ||
    fail 'z/OS strict nonreversible fixture is missing'
grep -q 'WS-OUTPUT(2:1) NOT = LOW-VALUE' test/tstztext.cob ||
    fail 'z/OS strict nonreversible fixture does not prove rollback'
if grep -Eq 'WHEN (121|145|147)$' zos/natutf8.cob; then
    fail 'z/OS conversion dispatches on numeric errno literals'
fi
for field in NP-CONNECT-HOST-PTR NP-CONNECT-HOST-LENGTH \
    NP-VERIFY-HOST-PTR NP-VERIFY-HOST-LENGTH NP-BUFFER-PTR \
    NP-BUFFER-CAPACITY NP-REQUEST-LENGTH; do
    [ "$(grep -c "$field" zos/netio.cob)" -gt 1 ] ||
        fail "z/OS network validation omits $field"
done
capacity_line=$(grep -n 'NP-CONNECT-HOST-LENGTH > LIMIT-HOST' \
    zos/netio.cob |
    head -1 | cut -d: -f1)
pointer_line=$(grep -n 'NP-CONNECT-HOST-PTR = NULL' zos/netio.cob |
    head -1 | cut -d: -f1)
[ "$capacity_line" -lt "$pointer_line" ] ||
    fail 'z/OS host capacity must precede structural validation'
grep -q 'WS-VALIDATION-CASE > 35' test/tstznet.cob ||
    fail 'z/OS network contract fixtures are incomplete'
grep -q 'LK-CONNECT-HOST(' zos/netio.cob ||
    fail 'z/OS network does not compare endpoint host bytes'
grep -q 'LK-VERIFY-HOST(1:NP-VERIFY-HOST-LENGTH)' zos/netio.cob ||
    fail 'z/OS network does not compare verification host bytes'
grep -q '^       TEST-HOST-MISMATCH[.]$' test/tstznet.cob ||
    fail 'z/OS network endpoint mismatch fixture is missing'
grep -q '01 LK-BUFFER PIC X(65536) BASED[.]' zos/netio.cob ||
    fail 'z/OS network byte view is missing'
for function in WRITE READ; do
    grep -A2 "CALL 'EZASOKET' USING ZN-$function" zos/netio.cob |
        grep -q 'LK-BUFFER' ||
        fail "z/OS $function does not pass pointed-to buffer storage"
    if grep -A2 "CALL 'EZASOKET' USING ZN-$function" zos/netio.cob |
        grep -q 'NP-BUFFER-PTR'; then
        fail "z/OS $function passes the pointer cell"
    fi
done
text_bound_line=$(grep -n 'TP-INPUT-LENGTH > LIMIT-HISTORY' \
    zos/natutf8.cob |
    cut -d: -f1)
text_address_line=$(grep -n 'SET ADDRESS OF TP-IN' zos/natutf8.cob |
    cut -d: -f1)
[ -n "$text_bound_line" ] && [ "$text_bound_line" -lt "$text_address_line" ] ||
    fail 'z/OS text view bounds must precede address establishment'
[ "$(grep -c '16777217 TO TP-' test/tstznet.cob)" -eq 2 ] ||
    fail 'z/OS text view +1 boundary fixtures are incomplete'
if grep -q 'COBOLLM_TLS_VERIFY_HOST' test/tstztls.cob; then
    fail 'live z/OS mismatch cannot override verification hostname'
fi
grep -q 'ADDRESS OF WS-CONNECT' test/tstztls.cob ||
    fail 'live z/OS TLS test does not use one policy-bound endpoint'
grep -q 'policy/reference-ID or certificate mismatch' zos/tsttls.jcl ||
    fail 'live z/OS mismatch gate is not an external TLS mismatch'

compiler_options='CODEPAGE(1047),NOSEQ,LP(32),RENT,DATA(31),RMODE(ANY),NOTHREAD,NODLL,NODYNAM,PGMNAME(LONGMIXED),OBJECT'
for job in zos/build.jcl zos/test.jcl zos/tsttls.jcl; do
    grep -q '^//COMPILE  EXEC PGM=IGYCRCTL,REGION=0M,PARMDD=OPTIONS$' \
        "$job" || fail "$job compiler does not use valid PARMDD"
    grep -q '^//OPTIONS  DD \*$' "$job" ||
        fail "$job compiler option DD is missing"
    actual_options=$(awk '
        /^\/\/OPTIONS  DD \*$/ { reading=1; next }
        reading && /^\/\*$/ { exit }
        reading { printf "%s", $0 }
    ' "$job")
    [ "$actual_options" = "$compiler_options" ] ||
        fail "$job compiler options differ"
    if grep -q '^// PARM[.]' "$job"; then
        fail "$job uses invalid dotted PARM continuation"
    fi
    awk '
        match($0, /PARM='\''[^'\'']*'\''/) {
            value = substr($0, RSTART + 6, RLENGTH - 7)
            if (length(value) > 100) exit 1
        }
    ' "$job" || fail "$job has an EXEC PARM longer than 100 bytes"
    grep -A8 '^//SYSLIB' "$job" | grep -q 'COBOLLM.ZCOPY' ||
        fail "$job compiler cannot resolve z/OS adapter copybooks"
done

bind_options='REUS(NONE),AMODE=31,RMODE=ANY,MAP,XREF,LIST'
[ "$(grep -Fc "PARM='$bind_options'" zos/build.jcl)" -eq 1 ] ||
    fail 'production bind options differ'
[ "$(grep -c '^//BIND ' zos/build.jcl)" -eq 1 ] ||
    fail 'production build must contain one bind step'
[ "$(grep -c '^//SYSLMOD ' zos/build.jcl)" -eq 1 ] ||
    fail 'production build must contain one program-object output'
grep -q 'COBOLLM.LOAD(COBOLLM)' zos/build.jcl ||
    fail 'production PDSE output was removed'
if grep -Eq 'BINDUSS|USSOUT|SYSLMOD  DD PATH=' zos/build.jcl; then
    fail 'production build still creates a USS executable'
fi
grep -q '^//RUN      EXEC PGM=COBOLLM,REGION=0M,TIME=NOLIMIT$' \
    zos/run.jcl || fail 'production direct MVS invocation differs'
grep -q '^//STEPLIB  DD DISP=SHR,DSN=&HLQ..COBOLLM.LOAD$' \
    zos/run.jcl || fail 'production run load library differs'
[ "$(grep -c '^POSIX(ON),$' zos/run.jcl)" -eq 1 ] ||
    fail 'production POSIX option differs'
grep -q '^ENVAR("_BPXK_AUTOCVT=OFF","_CEE_ENVFILE=DD:RUNENV")$' \
    zos/run.jcl || fail 'production LE environment options differ'
grep -q '^//RUNENV   DD DISP=SHR,DSN=&ENVDSN$' zos/run.jcl ||
    fail 'production protected environment handoff is missing'
grep -q '^//TASK     DD PATH='"'"'&TASKFILE'"'"',PATHOPTS=(ORDONLY)$' \
    zos/run.jcl || fail 'production TASK byte stream differs'
for ddname in SYSPRINT SYSOUT; do
    grep -q "^//$ddname .*DD SYSOUT=\*$" zos/run.jcl ||
        fail "production output DD is missing: $ddname"
done
if grep -Eq 'BPXBATCH|BPXBATSL|STDPARM|STDIN' zos/run.jcl; then
    fail 'production run still uses a BPX launcher contract'
fi
for step in RSHELL RZOUT; do
    step_options=$(grep -A5 "^//$step " zos/test.jcl)
    printf '%s\n' "$step_options" | grep -q '^//CEEOPTS  DD \*$' ||
        fail "$step target test does not supply CEEOPTS"
    printf '%s\n' "$step_options" |
        grep -q '^POSIX(ON),ENVAR("_BPXK_AUTOCVT=OFF")$' ||
        fail "$step target test LE options differ"
done
for step in POSITIVE MISMATCH; do
    step_options=$(grep -A7 "^//$step " zos/tsttls.jcl)
    printf '%s\n' "$step_options" | grep -q '^//CEEOPTS  DD \*$' ||
        fail "$step live TLS test does not supply CEEOPTS"
    printf '%s\n' "$step_options" | grep -q '^POSIX(ON),$' ||
        fail "$step live TLS test does not enable POSIX"
    printf '%s\n' "$step_options" |
        grep -q '^ENVAR("_BPXK_AUTOCVT=OFF",' ||
        fail "$step live TLS test enables automatic conversion"
done
run_job=$(sed -n '1s|^//\([^ ]*\).*|\1|p' zos/run.jcl)
policy_job=$(awk '$1 == "Jobname" { print $2; exit }' \
    zos/attls.policy.example)
[ "$run_job" = "$policy_job" ] ||
    fail 'run job name differs from example AT-TLS policy'

for member in TSTCNTR TSTJSON TSTHTTP TSTRESP TSTZTXT TSTSHELL \
    TSTZAGT TSTZLCH TSTZNET TSTZOUT TSTZBYTE; do
    grep -q "EXEC COB,MEMBER=$member" zos/test.jcl ||
        fail "$member compile step missing"
    grep -q "EXEC LINK,MEMBER=$member" zos/test.jcl ||
        fail "$member link step missing"
    grep -q "EXEC PGM=$member" zos/test.jcl ||
        fail "$member run step missing"
done
if grep -q 'TSTAGENT' zos/test.jcl; then
    fail 'GNU orchestration driver is linked into z/OS test JCL'
fi
grep -q 'MOVE PLATFORM-ZOS TO CLI-PLATFORM' test/tstzagt.cob ||
    fail 'z/OS orchestration driver does not select z/OS'
grep -q 'PIC X VALUE X"25"' test/tstzagt.cob ||
    fail 'z/OS orchestration driver lacks native newline assertions'
grep -q 'FO-STDOUT(1:3) NOT = X"C16FC2"' test/tstzagt.cob ||
    fail 'z/OS orchestration driver lacks replacement-byte assertion'
for length in 65534 255 8191; do
    grep -q "$length" test/tstzagt.cob ||
        fail "z/OS orchestration driver lacks minus-one boundary $length"
done
grep -q 'WS-LONG-ENV(17:2031)' test/tstzagt.cob ||
    fail 'z/OS orchestration driver lacks minus-one boundary 2047'
grep -q 'X"41F09F988042"' test/fakes/respapi.cob ||
    fail 'agent response fake lacks IBM-1047 replacement fixture'
for bytes in 9900 E4E3C660F800 C9C2D460F1F0F4F700 \
    85A7858340F26E50F125 D6D7C5D5C1C96DC1D7C96DD2C5E800 \
    D6D7C5D5C1C96DD4D6C4C5D300 \
    D6D7C5D5C1C96DC2C1E2C56DE4D9D300; do
    grep -q "X\"$bytes\"" test/tstzbytes.cob ||
        fail "z/OS native byte fixture lacks $bytes"
done
grep -q 'WS-PREFIX PIC X(10) VALUE X"85A7858340F26E50F125"' \
    zos/shell.cob || fail 'z/OS shell prefix differs from target assertion'
for name in OPENAI_API_KEY OPENAI_MODEL OPENAI_BASE_URL; do
    grep -q "VALUE \"$name\"" cobollm.cob ||
        fail "production environment name differs: $name"
    grep -q "VALUE \"$name\"" test/tstzbytes.cob ||
        fail "z/OS byte fixture omits environment name: $name"
done
grep -A4 '^//LZOUT' zos/test.jcl | grep -q 'OBJ(OUTPUT)' ||
    fail 'z/OS external output capture does not link real OUTPUT'
if grep -A4 '^//LZOUT' zos/test.jcl | grep -q 'TESTOBJ(FOUTPUT)'; then
    fail 'z/OS external output capture links fake OUTPUT'
fi
grep -q 'WS-CAPTURE(1:10) NOT = WS-PROBE' test/tstzoutput.cob ||
    fail 'z/OS external output capture lacks exact byte comparison'
for source in gnu/output.cob zos/output.cob test/fakes/output.cob; do
    grep -q 'OUTPUT-STDOUT' "$source" ||
        fail "$source omits shared stdout descriptor"
    grep -q 'OUTPUT-STDERR' "$source" ||
        fail "$source omits shared stderr descriptor"
done
grep -q 'X"C1ADBDC0D0E05FA14F7C7B5B"' test/tstztext.cob ||
    fail 'z/OS text driver lacks IBM-1047 expectations'
for bytes in C16F4D6FC2 6F6F C16FC2; do
    grep -q "X\"$bytes\"" test/tstztext.cob ||
        fail "z/OS text driver lacks replacement bytes $bytes"
done
grep -q '^       TEST-CONTRACT-MATRIX[.]$' test/tstztext.cob ||
    fail 'z/OS text target contract matrix is missing'
grep -q 'WS-OP FROM TEXT-NATIVE-STRICT BY 1' test/tstztext.cob ||
    fail 'z/OS text target contract matrix omits operations'
grep -q '^       ASSERT-INPUTS-PRESERVED[.]$' test/tstztext.cob ||
    fail 'z/OS text target does not verify input preservation'
for member in FHTTP FNET FRESP FSHELL FOUTPUT FCOBOL FEZAS FSIGNAL \
    FNATUTF8 FZLIO; do
    grep -q "EXEC COB,MEMBER=$member" zos/test.jcl ||
        fail "$member fake compile step missing"
done
grep -A5 '^//LZLCH' zos/test.jcl | grep -q 'TESTOBJ(FZLIO)' ||
    fail 'z/OS launcher test does not link fake LE stdio'
grep -Fq '| `test/fakes/zlaunchio.cob` | `YOURHLQ.COBOLLM.TESTCOB(FZLIO)` | TEST |' \
    docs/reference/zos-staging-manifest.md ||
    fail 'z/OS staging manifest omits fake LE stdio'
grep -A10 '^//LAGENT' zos/test.jcl | grep -q 'TESTOBJ(FNATUTF8)' ||
    fail 'z/OS orchestration test does not link deterministic text fake'
grep -A3 '^//LTEXT' zos/test.jcl | grep -q 'OBJ(NATUTF8)' ||
    fail 'z/OS text target test does not link real NATUTF8'
if grep -Eq 'FRCTRL|FR-MODE' test/fakes/natutf8.cob; then
    fail 'z/OS text fake depends on Responses control state'
fi
grep -A2 'TP-OPERATION = TEXT-NATIVE-REPLACE' \
    test/fakes/natutf8.cob | grep -q 'TP-INPUT-LENGTH = 1' ||
    fail 'z/OS text fake loss selection is not operation-local'
grep -q '^       TEST-SHELL-OUTPUT-LOSS[.]$' test/tstzagt.cob ||
    fail 'z/OS orchestration test lacks shell-output loss fixture'
grep -q 'RP-SHELL-BUFFER(1:3) = X"EFBFBD"' \
    test/fakes/respapi.cob ||
    fail 'z/OS orchestration fake does not assert UTF-8 replacement'
grep -q 'FO-STDERR(1:136) NOT = C-LOSS-STDERR' test/tstzagt.cob ||
    fail 'z/OS orchestration test lacks exact native loss transcript'
grep -q 'FS-KEY-ENV-ABSENT NOT = FLAG-ON' test/tstzagt.cob ||
    fail 'z/OS orchestration test does not verify child key removal'
for function in INITAPI GETADDRINFO FREEADDRINFO SOCKET CONNECT IOCTL \
    WRITE READ CLOSE TERMAPI; do
    grep -q "WHEN \"$function\"" test/fakes/ezasoket.cob ||
        fail "EZASOKET fake lacks $function"
done
grep -q 'EF-QUERY-VALID' test/fakes/ezasoket.cob ||
    fail 'EZASOKET query capture missing'
grep -q 'EF-TRACE-LENGTH' test/fakes/ezasoket.cob ||
    fail 'EZASOKET lifecycle trace missing'
for operation in CLOSE FREE TERM; do
    grep -q "EF-${operation}-FAILURES" test/fakes/ezasoket.cob ||
        fail "EZASOKET fake lacks ${operation} failure injection"
    grep -q "^       TEST-${operation}-FAILURE[.]$" test/tstznet.cob ||
        fail "z/OS NET test lacks ${operation} cleanup failure"
done
grep -q '^       TEST-CONNECT-CLOSE-FAILURE[.]$' test/tstznet.cob ||
    fail 'z/OS NET test does not abort retry after close failure'
grep -q 'WS-CLEANUP-FAILED = FLAG-ON OR' zos/netio.cob ||
    fail 'z/OS NET cleanup failures do not gate later work'
for cipher in 0000 0001 0002 003B; do
    grep -q "MOVE \"$cipher\" TO TTLSI-NEG-CIPHER4" \
        test/fakes/ezasoket.cob ||
        fail "EZASOKET fake lacks rejected cipher $cipher"
done
grep -q 'EF-IOCTL-VALID NOT = FLAG-ON' test/tstznet.cob ||
    fail 'z/OS TLS test does not validate the full ioctl request'
grep -q 'WS-TLS-CASE > 12' test/tstznet.cob ||
    fail 'z/OS TLS rejection matrix is incomplete'
if grep -q 'TTLS-POL-APPLCNTRL' zos/netio.cob; then
    fail 'z/OS TLS gate accepts application-controlled policy'
fi
grep -q 'WHEN 12 MOVE 15 TO EF-MODE' test/tstznet.cob ||
    fail 'z/OS TLS test lacks application-controlled rejection'
grep -q 'MOVE 2 TO TTLSI-STAT-CONN' test/fakes/ezasoket.cob ||
    fail 'z/OS TLS fake lacks nonzero connection-state rejection'
grep -q 'MOVE 2 TO TTLSI-SEC-TYPE' test/fakes/ezasoket.cob ||
    fail 'z/OS TLS fake lacks nonzero role rejection'
grep -A2 'WHEN 16' test/fakes/ezasoket.cob |
    grep -q 'TTLS-PROT-TLSV1-2' ||
    fail 'z/OS TLS fake lacks crossed TLS 1.2 protocol fixture'
grep -A2 'WHEN 17' test/fakes/ezasoket.cob |
    grep -q 'TTLS-PROT-TLSV1-3' ||
    fail 'z/OS TLS fake lacks crossed TLS 1.3 protocol fixture'
grep -q 'WS-SIGNAL-INSTALLED NOT = FLAG-ON' zos/netio.cob ||
    fail 'z/OS signal installation state is not authoritative'
grep -A4 'WS-SIGNAL-INSTALLED NOT = FLAG-ON' zos/netio.cob |
    grep -q 'MOVE STATUS-NETWORK TO NP-STATUS' ||
    fail 'z/OS signal setup failure does not map to network status'
grep -q '^       TEST-SIGNAL-RESTORE-SUCCESS[.]$' test/tstznet.cob ||
    fail 'z/OS successful signal restoration fixture is missing'
grep -q '^       TEST-SIGNAL-RESTORE-FAILURE[.]$' test/tstznet.cob ||
    fail 'z/OS failed signal restoration fixture is missing'
grep -q 'TESTOBJ(FSIGNAL)' zos/test.jcl ||
    fail 'z/OS signal fake is not linked into the target test'
grep -q '^       INSTALL-IGNORED-SIGPIPE[.]$' test/tstztls.cob ||
    fail 'live z/OS TLS test does not establish known SIGPIPE state'
grep -q '^       TEST-RESTORED-SIGPIPE[.]$' test/tstztls.cob ||
    fail 'live z/OS TLS test lacks fresh-shell restoration check'
grep -q 'CALL "SHELL" USING SHELL-PARM' test/tstztls.cob ||
    fail 'live z/OS TLS test does not run restoration shell'
grep -q 'COMPSHL  EXEC COB,MEMBER=SHELL' zos/tsttls.jcl ||
    fail 'live z/OS TLS test does not compile SHELL'
grep -q 'Failure injection remains deterministic' zos/tsttls.jcl ||
    fail 'live z/OS signal failure limitation is undocumented'

for job in zos/build.jcl zos/tsttls.jcl; do
    grep -q 'SEZATCP(EZASOKET)' "$job" ||
        fail "$job does not bind the non-CICS EZASOKET stub"
    if grep -q 'SEZATCP(EZA[C]ICAL)' "$job"; then
        fail "$job binds the CICS EZASOKET alias"
    fi
    grep -q 'SEZATCP(EZACIC09)' "$job" ||
        fail "$job does not bind EZACIC09"
done
for step in COMPTLS BINDTLS PROVEN POSITIVE MISMATCH NOLEAK; do
    grep -q "^//$step" zos/tsttls.jcl ||
        fail "TLS job lacks $step gate"
done
grep -q 'REUS(NONE),MAP,XREF,LIST' zos/tsttls.jcl ||
    fail 'TLS binder audit options missing'
if grep -Eq 'OPENAI_API_KEY|Bearer[[:space:]]' zos/*.jcl; then
    fail 'submitted JCL must not contain credentials'
fi

validate_line=$(grep -n '# Validate the uploaded byte stream' \
    zos/stage-source.sh | cut -d: -f1)
stage_line=$(grep -n 'stage_dir=.*mktemp' zos/stage-source.sh |
    cut -d: -f1)
target_parse_line=$(grep -n '^case "\$target" in' zos/stage-source.sh |
    cut -d: -f1)
listds_line=$(grep -n 'tsocmd "LISTDS' zos/stage-source.sh |
    cut -d: -f1)
attributes_line=$(grep -n '# Target syntax and every nonmutating' \
    zos/stage-source.sh | cut -d: -f1)
target_line=$(grep -n '^cp -T .*"\$target"' zos/stage-source.sh |
    head -1 | cut -d: -f1)
[ "$validate_line" -lt "$stage_line" ] ||
    fail 'source validation must precede staging mutation'
[ "$target_parse_line" -lt "$listds_line" ] &&
    [ "$listds_line" -lt "$attributes_line" ] &&
    [ "$attributes_line" -lt "$target_line" ] ||
    fail 'target checks must precede its first cp'
for evidence in 'chtag -p' 'LISTDS' 'expected.fb80' \
    'readback.fb80' 'readback.trimmed'; do
    grep -q "$evidence" zos/stage-source.sh ||
        fail "staging gate lacks $evidence evidence"
done
for evidence in COBOLLM_RUNNING_MAIN COBOLLM_SELECTED_STACK \
    COBOLLM_POLICY_DEST COBOLLM_POLICY_SOURCE COBOLLM_POLICY_STAGE \
    COBOLLM_POLICY_PARSE_LOG COBOLLM_EFFECTIVE_POLICY \
    COBOLLM_EXPECT_JOB COBOLLM_EXPECT_HOST COBOLLM_EXPECT_PORT \
    COBOLLM_EXPECT_KEYRING COBOLLM_PEER_CAPTURE; do
    grep -q "$evidence" zos/verify-attls.sh ||
        fail "AT-TLS gate lacks $evidence evidence"
done
grep -q 'normalize_policy' zos/verify-attls.sh ||
    fail 'AT-TLS gate lacks structural normalization'
grep -q 'reject_competitors' zos/verify-attls.sh ||
    fail 'AT-TLS gate suppresses competing rules or actions'
grep -q 'source.roundtrip' zos/verify-attls.sh ||
    fail 'AT-TLS gate lacks source reverse comparison'
grep -q 'installed destination bytes differ' zos/verify-attls.sh ||
    fail 'AT-TLS gate lacks destination byte comparison'
tools/test-verify-attls.sh

check_text zos/attls.policy.example 300
[ "$(grep -c '^  TTLSEnabled On$' zos/attls.policy.example)" = 1 ] ||
    fail 'policy must contain exactly one TTLSEnabled On'
grep -q '^  V3CipherSuites4Char 1301C02F$' \
    zos/attls.policy.example || fail 'policy cipher order changed'
grep -q '^  HostReferenceIdDNS api.openai.com$' \
    zos/attls.policy.example || fail 'policy reference hostname missing'
for value in 'SSLv2 Off' 'SSLv3 Off' 'TLSv1 Off' 'TLSv1.1 Off' \
    'TLSv1.2 On' 'TLSv1.3 On' 'ClientHandshakeSNI Required' \
    'ClientHandshakeSNIMatch Required' \
    'ClientHandshakeSNIList api.openai.com' \
    'HostRefWildcardValidation On' 'HandshakeRole Client'; do
    [ "$(grep -Fc "$value" zos/attls.policy.example)" -eq 1 ] ||
        fail "policy needs one exact $value"
done
if grep -Eq 'TTLSConnectionAction|TTLSConnectionActionRef' \
    zos/attls.policy.example; then
    fail 'policy must not define a connection action'
fi

actual=$(printf '[]{}\\^~|@#$' | iconv -f UTF-8 -t IBM-1047 |
    od -An -tx1 | tr -d ' \n')
[ "$actual" = 'adbdc0d0e05fa14f7c7b5b' ] ||
    fail "IBM-1047 variant mapping differs: $actual"

printf '%s\n' 'PASS z/OS repository source gate'
