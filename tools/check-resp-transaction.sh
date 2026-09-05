#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

awk '
function reject(message) {
    print "respapi.cob: " message > "/dev/stderr"
    failed = 1
}

/^       CONTINUE-REQUEST\.$/ {
    in_continue = 1
}

in_continue && /MOVE WS-HISTORY-LENGTH TO WS-OLD-HISTORY/ {
    checkpoint_count++
    if (checkpoint_count == 1) {
        inspect = 1
        next
    }
    if (checkpoint_count == 2) {
        inspect = 0
        complete = 1
        next
    }
}

!inspect || /^[[:space:]]*$/ || /^      \*/ {
    next
}

guard_step == 1 {
    if ($0 !~ /^[[:space:]]+IF WS-FAIL = FLAG-ON[[:space:]]*$/) {
        reject("transactional append is not followed by a failure check")
    }
    guard_step = 2
    next
}

guard_step == 2 {
    if ($0 !~ /^[[:space:]]+PERFORM ROLLBACK-HISTORY[[:space:]]*$/) {
        reject("append failure does not roll back history immediately")
    }
    guard_step = 3
    next
}

guard_step == 3 {
    if ($0 !~ /^[[:space:]]+EXIT PARAGRAPH[[:space:]]*$/) {
        reject("append failure does not exit before later history access")
    }
    guard_step = 4
    next
}

guard_step == 4 {
    if ($0 !~ /^[[:space:]]+END-IF[[:space:]]*$/) {
        reject("transactional append failure guard is incomplete")
    }
    guard_step = 0
    next
}

/PERFORM (APPEND-HISTORY-LITERAL|APPEND-CALL-ID|BUILD-TOOL-ENVELOPE)[[:space:]]*$/ {
    operation_count++
    guard_step = 1
}

END {
    if (!complete) {
        reject("CONTINUE-REQUEST transaction checkpoints not found")
    }
    if (guard_step != 0) {
        reject("transactional append failure guard is truncated")
    }
    if (operation_count != 6) {
        reject("expected six guarded CONTINUE-REQUEST append operations")
    }
    if (failed) {
        exit 1
    }
}
' "$repo_root/respapi.cob"

printf '%s\n' 'PASS: CONTINUE-REQUEST append rollback guards'
