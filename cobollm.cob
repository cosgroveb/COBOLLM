       IDENTIFICATION DIVISION.
       PROGRAM-ID. COBOLLM.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY RESPPARM.
       COPY HTTPPARM.
       COPY TXTPARM.
       COPY SHLPARM.
       COPY OUTPARM.
       01 WS-KEY-NAME.
           05 FILLER PIC X(14) VALUE "OPENAI_API_KEY".
           05 FILLER PIC X VALUE LOW-VALUE.
       01 WS-MODEL-NAME.
           05 FILLER PIC X(12) VALUE "OPENAI_MODEL".
           05 FILLER PIC X VALUE LOW-VALUE.
       01 WS-URL-NAME.
           05 FILLER PIC X(15) VALUE "OPENAI_BASE_URL".
           05 FILLER PIC X VALUE LOW-VALUE.
       01 WS-DEFAULT-URL PIC X(25) VALUE
           X"68747470733A2F2F6170692E6F70656E61692E636F6D2F7631".
       01 WS-ENV-PTR              USAGE POINTER.
       01 WS-ENV-LENGTH           PIC S9(9) COMP-5.
       01 WS-ENV-LIMIT            PIC S9(9) COMP-5.
       01 WS-NATIVE-RESULT        PIC S9(9) COMP-5.
       01 WS-NATIVE-STAGING       PIC X(8193).
       01 WS-TASK-UTF8            PIC X(65535).
       01 WS-MODEL-UTF8           PIC X(256).
       01 WS-URL-UTF8             PIC X(2048).
       01 WS-KEY-UTF8             PIC X(8192).
       01 WS-MODEL-LENGTH         PIC S9(9) COMP-5.
       01 WS-URL-LENGTH           PIC S9(9) COMP-5.
       01 WS-KEY-LENGTH           PIC S9(9) COMP-5.
       01 WS-ACTION               PIC X(1048576).
       01 WS-NATIVE-COMMAND       PIC X(65535).
       01 WS-SHELL-NATIVE         PIC X(1048576).
       01 WS-SHELL-UTF8           PIC X(1048576).
       01 WS-FINAL-NATIVE         PIC X(3145728).
       01 WS-DIAG                 PIC X(320).
       01 WS-DIAG-LENGTH          PIC S9(9) COMP-5.
       01 WS-FAIL-STATUS          PIC S9(9) COMP-5.
       01 WS-I                    PIC S9(9) COMP-5.
       01 WS-BYTE                 PIC S9(9) COMP-5.
       01 WS-NUL-FOUND            PIC X.
       01 WS-RESP-INITIALIZED     PIC X.
       01 WS-DONE                 PIC X.
       01 WS-OUTPUT-FAILED        PIC X.
       01 WS-NATIVE-NEWLINE       PIC X.
       01 WS-COMMAND-LENGTH       PIC S9(9) COMP-5.
       01 WS-SHELL-UTF8-LENGTH    PIC S9(9) COMP-5.
       01 WS-TASK-UTF8-LENGTH     PIC S9(9) COMP-5.
       01 WS-HTTP-STATUS          PIC S9(9) COMP-5.
       01 WS-HTTP-STATUS-DISPLAY  PIC 999.
       01 WS-ACTIVITY-LENGTH      PIC S9(9) COMP-5.
       01 WS-RESULT-NUMBER        PIC ZZ9.
       01 WS-RESULT-NUMBER-START  PIC S9(9) COMP-5.
       01 WS-RESULT-NUMBER-LENGTH PIC S9(9) COMP-5.

       LINKAGE SECTION.
       COPY CLIPARM.
       01 WS-ENV-VIEW             PIC X(8193).

       PROCEDURE DIVISION USING CLI-PARM.
           MOVE EXIT-INTERNAL TO CLI-EXIT-CODE
           MOVE STATUS-INTERNAL TO WS-FAIL-STATUS
           MOVE FLAG-OFF TO WS-RESP-INITIALIZED WS-DONE
                            WS-OUTPUT-FAILED
           EVALUATE CLI-PLATFORM
               WHEN PLATFORM-GNU
                   MOVE X"0A" TO WS-NATIVE-NEWLINE
               WHEN PLATFORM-ZOS
                   MOVE X"25" TO WS-NATIVE-NEWLINE
               WHEN OTHER
                   GO TO FAIL-AND-CLEAN
           END-EVALUATE
           IF CLI-STATUS NOT = STATUS-OK
               MOVE CLI-STATUS TO WS-FAIL-STATUS
               GO TO FAIL-AND-CLEAN
           END-IF
           IF CLI-ARG-COUNT NOT = 1 OR CLI-TASK-LENGTH < 1
               MOVE STATUS-USAGE-COUNT TO WS-FAIL-STATUS
               GO TO FAIL-AND-CLEAN
           END-IF
           IF CLI-TASK-LENGTH > LIMIT-TASK
               MOVE STATUS-CAPACITY TO WS-FAIL-STATUS
               GO TO FAIL-AND-CLEAN
           END-IF
           PERFORM CONVERT-TASK
           IF WS-FAIL-STATUS NOT = STATUS-OK
               GO TO FAIL-AND-CLEAN
           END-IF
           PERFORM READ-MODEL
           IF WS-FAIL-STATUS NOT = STATUS-OK
               GO TO FAIL-AND-CLEAN
           END-IF
           PERFORM READ-URL
           IF WS-FAIL-STATUS NOT = STATUS-OK
               GO TO FAIL-AND-CLEAN
           END-IF
           PERFORM READ-KEY
           IF WS-FAIL-STATUS NOT = STATUS-OK
               GO TO FAIL-AND-CLEAN
           END-IF
           PERFORM CHECK-KEY
           IF WS-FAIL-STATUS NOT = STATUS-OK
               GO TO FAIL-AND-CLEAN
           END-IF
           PERFORM REMOVE-KEY-ENV
           IF WS-NATIVE-RESULT NOT = ZERO OR WS-ENV-PTR NOT = NULL
               MOVE STATUS-INTERNAL TO WS-FAIL-STATUS
               GO TO FAIL-AND-CLEAN
           END-IF
           MOVE LOW-VALUES TO WS-NATIVE-STAGING
           PERFORM PREFLIGHT-URL
           IF WS-FAIL-STATUS NOT = STATUS-OK
               GO TO FAIL-AND-CLEAN
           END-IF
           IF HP-PLAINTEXT = FLAG-ON
               IF CLI-PLATFORM = PLATFORM-ZOS
                   MOVE STATUS-CONFIG-ZOS-HTTPS TO WS-FAIL-STATUS
                   GO TO FAIL-AND-CLEAN
               END-IF
               PERFORM WRITE-PLAINTEXT-WARNING
               IF WS-OUTPUT-FAILED = FLAG-ON
                   MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
                   GO TO FAIL-AND-CLEAN
               END-IF
           END-IF
           MOVE FLAG-ON TO WS-RESP-INITIALIZED
           PERFORM START-RESPONSES
           IF WS-FAIL-STATUS NOT = STATUS-OK
               GO TO FAIL-AND-CLEAN
           END-IF
           PERFORM UNTIL WS-DONE = FLAG-ON
               EVALUATE RP-ACTION
                   WHEN ACTION-SHELL
                       PERFORM RUN-SHELL-ACTION
                       IF WS-FAIL-STATUS NOT = STATUS-OK
                           GO TO FAIL-AND-CLEAN
                       END-IF
                   WHEN ACTION-FINAL
                       PERFORM WRITE-FINAL
                       IF WS-FAIL-STATUS NOT = STATUS-OK
                           GO TO FAIL-AND-CLEAN
                       END-IF
                       MOVE FLAG-ON TO WS-DONE
                   WHEN OTHER
                       MOVE STATUS-RESPONSES TO WS-FAIL-STATUS
                       GO TO FAIL-AND-CLEAN
               END-EVALUATE
           END-PERFORM
           MOVE EXIT-OK TO CLI-EXIT-CODE
           PERFORM CLEANUP
           GOBACK.

       CONVERT-TASK.
           INITIALIZE TEXT-PARM
           MOVE TEXT-NATIVE-STRICT TO TP-OPERATION
           SET TP-INPUT-PTR TO ADDRESS OF CLI-TASK
           MOVE CLI-TASK-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF WS-TASK-UTF8
           MOVE LIMIT-TASK TO TP-OUTPUT-CAPACITY
           CALL "NATUTF8" USING TEXT-PARM
           EVALUATE TRUE
               WHEN TP-STATUS = STATUS-TEXT-INVALID
                   MOVE STATUS-USAGE-TEXT TO WS-FAIL-STATUS
               WHEN TP-STATUS NOT = STATUS-OK
                   MOVE TP-STATUS TO WS-FAIL-STATUS
               WHEN OTHER
                   MOVE STATUS-OK TO WS-FAIL-STATUS
                   MOVE TP-OUTPUT-LENGTH TO WS-TASK-UTF8-LENGTH
           END-EVALUATE.

       READ-MODEL.
           CALL "getenv" USING BY REFERENCE WS-MODEL-NAME
               RETURNING WS-ENV-PTR
           IF WS-ENV-PTR = NULL
               MOVE STATUS-CONFIG-MODEL TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE LIMIT-MODEL TO WS-ENV-LIMIT
           PERFORM COPY-ENV
           IF WS-FAIL-STATUS NOT = STATUS-OK EXIT PARAGRAPH END-IF
           IF WS-ENV-LENGTH = ZERO
               MOVE STATUS-CONFIG-MODEL TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           PERFORM CONVERT-MODEL.

       CONVERT-MODEL.
           INITIALIZE TEXT-PARM
           MOVE TEXT-NATIVE-STRICT TO TP-OPERATION
           SET TP-INPUT-PTR TO ADDRESS OF WS-NATIVE-STAGING
           MOVE WS-ENV-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF WS-MODEL-UTF8
           MOVE LIMIT-MODEL TO TP-OUTPUT-CAPACITY
           CALL "NATUTF8" USING TEXT-PARM
           IF TP-STATUS = STATUS-TEXT-INVALID
               MOVE STATUS-CONFIG-MODEL TO WS-FAIL-STATUS
           ELSE
               MOVE TP-STATUS TO WS-FAIL-STATUS
               MOVE TP-OUTPUT-LENGTH TO WS-MODEL-LENGTH
           END-IF
           MOVE LOW-VALUES TO WS-NATIVE-STAGING.

       READ-URL.
           CALL "getenv" USING BY REFERENCE WS-URL-NAME
               RETURNING WS-ENV-PTR
           IF WS-ENV-PTR = NULL
               MOVE WS-DEFAULT-URL TO WS-URL-UTF8
               MOVE 25 TO WS-URL-LENGTH
               MOVE STATUS-OK TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE LIMIT-URL TO WS-ENV-LIMIT
           PERFORM COPY-ENV
           IF WS-FAIL-STATUS NOT = STATUS-OK EXIT PARAGRAPH END-IF
           IF WS-ENV-LENGTH = ZERO
               MOVE STATUS-CONFIG-URL TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           INITIALIZE TEXT-PARM
           MOVE TEXT-NATIVE-STRICT TO TP-OPERATION
           SET TP-INPUT-PTR TO ADDRESS OF WS-NATIVE-STAGING
           MOVE WS-ENV-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF WS-URL-UTF8
           MOVE LIMIT-URL TO TP-OUTPUT-CAPACITY
           CALL "NATUTF8" USING TEXT-PARM
           IF TP-STATUS = STATUS-TEXT-INVALID
               MOVE STATUS-CONFIG-URL TO WS-FAIL-STATUS
           ELSE
               MOVE TP-STATUS TO WS-FAIL-STATUS
               MOVE TP-OUTPUT-LENGTH TO WS-URL-LENGTH
           END-IF
           MOVE LOW-VALUES TO WS-NATIVE-STAGING.

       READ-KEY.
           CALL "getenv" USING BY REFERENCE WS-KEY-NAME
               RETURNING WS-ENV-PTR
           IF WS-ENV-PTR = NULL
               MOVE STATUS-CONFIG-KEY TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE LIMIT-KEY TO WS-ENV-LIMIT
           PERFORM COPY-ENV
           IF WS-FAIL-STATUS NOT = STATUS-OK EXIT PARAGRAPH END-IF
           IF WS-ENV-LENGTH = ZERO
               MOVE STATUS-CONFIG-KEY TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           INITIALIZE TEXT-PARM
           MOVE TEXT-NATIVE-STRICT TO TP-OPERATION
           SET TP-INPUT-PTR TO ADDRESS OF WS-NATIVE-STAGING
           MOVE WS-ENV-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF WS-KEY-UTF8
           MOVE LIMIT-KEY TO TP-OUTPUT-CAPACITY
           CALL "NATUTF8" USING TEXT-PARM
           IF TP-STATUS = STATUS-TEXT-INVALID
               MOVE STATUS-CONFIG-KEY TO WS-FAIL-STATUS
           ELSE
               MOVE TP-STATUS TO WS-FAIL-STATUS
               MOVE TP-OUTPUT-LENGTH TO WS-KEY-LENGTH
           END-IF
           MOVE LOW-VALUES TO WS-NATIVE-STAGING.

       COPY-ENV.
           MOVE LOW-VALUES TO WS-NATIVE-STAGING
           MOVE ZERO TO WS-ENV-LENGTH
           MOVE FLAG-OFF TO WS-NUL-FOUND
           SET ADDRESS OF WS-ENV-VIEW TO WS-ENV-PTR
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-ENV-LIMIT + 1 OR
                     WS-NUL-FOUND = FLAG-ON
               IF WS-ENV-VIEW(WS-I:1) = X"00"
                   MOVE FLAG-ON TO WS-NUL-FOUND
               ELSE
                   IF WS-I <= WS-ENV-LIMIT
                       MOVE WS-ENV-VIEW(WS-I:1) TO
                           WS-NATIVE-STAGING(WS-I:1)
                       MOVE WS-I TO WS-ENV-LENGTH
                   END-IF
               END-IF
           END-PERFORM
           IF WS-NUL-FOUND = FLAG-OFF
               MOVE STATUS-CAPACITY TO WS-FAIL-STATUS
           ELSE
               MOVE STATUS-OK TO WS-FAIL-STATUS
           END-IF.

       CHECK-KEY.
           MOVE STATUS-OK TO WS-FAIL-STATUS
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-KEY-LENGTH OR
                     WS-FAIL-STATUS NOT = STATUS-OK
               COMPUTE WS-BYTE =
                   FUNCTION ORD(WS-KEY-UTF8(WS-I:1)) - 1
               IF WS-BYTE < 33 OR WS-BYTE > 126
                   MOVE STATUS-CONFIG-KEY TO WS-FAIL-STATUS
               END-IF
           END-PERFORM.

       REMOVE-KEY-ENV.
           CALL "unsetenv" USING BY REFERENCE WS-KEY-NAME
               RETURNING WS-NATIVE-RESULT
           SET WS-ENV-PTR TO NULL
           IF WS-NATIVE-RESULT = ZERO
               CALL "getenv" USING BY REFERENCE WS-KEY-NAME
                   RETURNING WS-ENV-PTR
           END-IF.

       PREFLIGHT-URL.
           INITIALIZE HTTP-PARM
           MOVE HTTP-PREFLIGHT TO HP-OPERATION
           SET HP-URL-PTR TO ADDRESS OF WS-URL-UTF8
           MOVE WS-URL-LENGTH TO HP-URL-LENGTH
           SET HP-KEY-PTR HP-BODY-PTR HP-RESPONSE-PTR TO NULL
           CALL "HTTP11" USING HTTP-PARM
           MOVE HP-STATUS TO WS-FAIL-STATUS.

       START-RESPONSES.
           INITIALIZE RESP-PARM
           MOVE RESP-START TO RP-OPERATION
           SET RP-MODEL-PTR TO ADDRESS OF WS-MODEL-UTF8
           MOVE WS-MODEL-LENGTH TO RP-MODEL-LENGTH
           SET RP-URL-PTR TO ADDRESS OF WS-URL-UTF8
           MOVE WS-URL-LENGTH TO RP-URL-LENGTH
           SET RP-KEY-PTR TO ADDRESS OF WS-KEY-UTF8
           MOVE WS-KEY-LENGTH TO RP-KEY-LENGTH
           SET RP-TASK-PTR TO ADDRESS OF WS-TASK-UTF8
           MOVE WS-TASK-UTF8-LENGTH TO RP-TASK-LENGTH
           SET RP-SHELL-OUTPUT-PTR TO NULL
           SET RP-ACTION-PTR TO ADDRESS OF WS-ACTION
           MOVE LIMIT-FINAL TO RP-ACTION-CAPACITY
           CALL "RESPAPI" USING RESP-PARM
           SET RP-KEY-PTR TO NULL
           MOVE ZERO TO RP-KEY-LENGTH
           MOVE RP-HTTP-STATUS TO WS-HTTP-STATUS
           MOVE RP-STATUS TO WS-FAIL-STATUS.

       RUN-SHELL-ACTION.
           MOVE STATUS-OK TO WS-FAIL-STATUS
           MOVE RP-ACTION-LENGTH TO WS-COMMAND-LENGTH
           PERFORM VARYING WS-I FROM 1 BY 1
               UNTIL WS-I > WS-COMMAND-LENGTH OR
                     WS-FAIL-STATUS NOT = STATUS-OK
               IF WS-ACTION(WS-I:1) = X"00"
                   MOVE STATUS-TEXT-INVALID TO WS-FAIL-STATUS
               END-IF
           END-PERFORM
           INITIALIZE RESP-PARM
           MOVE ZERO TO RP-SHELL-EXIT RP-SHELL-SIGNAL
                        RP-SHELL-OUTPUT-LENGTH
           MOVE FLAG-OFF TO RP-SHELL-TRUNCATED
                            RP-SHELL-ENCODING-LOSS
           SET RP-SHELL-OUTPUT-PTR TO NULL
           IF WS-FAIL-STATUS = STATUS-TEXT-INVALID
               MOVE SHELL-COMMAND-ENCODING TO RP-SHELL-STATUS
               PERFORM WRITE-ENCODING-COMMAND
               IF WS-OUTPUT-FAILED = FLAG-ON
                   MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
                   EXIT PARAGRAPH
               END-IF
               PERFORM WRITE-RESULT-ACTIVITY
               IF WS-OUTPUT-FAILED = FLAG-ON
                   MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
                   EXIT PARAGRAPH
               END-IF
           ELSE
               PERFORM CONVERT-COMMAND
               EVALUATE TRUE
                   WHEN TP-STATUS = STATUS-TEXT-INVALID
                       MOVE SHELL-COMMAND-ENCODING TO
                           RP-SHELL-STATUS
                       PERFORM WRITE-ENCODING-COMMAND
                       IF WS-OUTPUT-FAILED = FLAG-ON
                           MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
                           EXIT PARAGRAPH
                       END-IF
                       PERFORM WRITE-RESULT-ACTIVITY
                       IF WS-OUTPUT-FAILED = FLAG-ON
                           MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
                           EXIT PARAGRAPH
                       END-IF
                   WHEN TP-STATUS NOT = STATUS-OK
                       MOVE TP-STATUS TO WS-FAIL-STATUS
                       EXIT PARAGRAPH
                   WHEN OTHER
                       PERFORM WRITE-COMMAND-ACTIVITY
                       IF WS-OUTPUT-FAILED = FLAG-ON
                           MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
                           EXIT PARAGRAPH
                       END-IF
                       PERFORM EXECUTE-SHELL
                       IF SP-STATUS NOT = STATUS-OK
                           MOVE SP-STATUS TO WS-FAIL-STATUS
                           EXIT PARAGRAPH
                       END-IF
                       PERFORM CONVERT-SHELL-OUTPUT
                       IF WS-FAIL-STATUS NOT = STATUS-OK
                           EXIT PARAGRAPH
                       END-IF
                       MOVE SP-RESULT-KIND TO RP-SHELL-STATUS
                       MOVE SP-EXIT-CODE TO RP-SHELL-EXIT
                       MOVE SP-SIGNAL TO RP-SHELL-SIGNAL
                       MOVE SP-TRUNCATED TO RP-SHELL-TRUNCATED
                       IF TP-TRUNCATED = FLAG-ON
                           MOVE FLAG-ON TO RP-SHELL-TRUNCATED
                       END-IF
                       MOVE TP-REPLACED TO RP-SHELL-ENCODING-LOSS
                       SET RP-SHELL-OUTPUT-PTR TO
                           ADDRESS OF WS-SHELL-UTF8
                       MOVE WS-SHELL-UTF8-LENGTH TO
                           RP-SHELL-OUTPUT-LENGTH
                       PERFORM WRITE-RESULT-ACTIVITY
                       IF WS-OUTPUT-FAILED = FLAG-ON
                           MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
                           EXIT PARAGRAPH
                       END-IF
               END-EVALUATE
           END-IF
           MOVE RESP-CONTINUE TO RP-OPERATION
           SET RP-MODEL-PTR TO ADDRESS OF WS-MODEL-UTF8
           MOVE WS-MODEL-LENGTH TO RP-MODEL-LENGTH
           SET RP-URL-PTR TO ADDRESS OF WS-URL-UTF8
           MOVE WS-URL-LENGTH TO RP-URL-LENGTH
           SET RP-KEY-PTR TO ADDRESS OF WS-KEY-UTF8
           MOVE WS-KEY-LENGTH TO RP-KEY-LENGTH
           SET RP-TASK-PTR TO NULL
           SET RP-ACTION-PTR TO ADDRESS OF WS-ACTION
           MOVE LIMIT-FINAL TO RP-ACTION-CAPACITY
           CALL "RESPAPI" USING RESP-PARM
           SET RP-KEY-PTR TO NULL
           MOVE ZERO TO RP-KEY-LENGTH
           MOVE RP-HTTP-STATUS TO WS-HTTP-STATUS
           MOVE RP-STATUS TO WS-FAIL-STATUS.

       CONVERT-COMMAND.
           INITIALIZE TEXT-PARM
           MOVE TEXT-UTF8-STRICT TO TP-OPERATION
           SET TP-INPUT-PTR TO ADDRESS OF WS-ACTION
           MOVE WS-COMMAND-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF WS-NATIVE-COMMAND
           MOVE LIMIT-COMMAND TO TP-OUTPUT-CAPACITY
           CALL "NATUTF8" USING TEXT-PARM
           MOVE TP-OUTPUT-LENGTH TO WS-COMMAND-LENGTH.

       EXECUTE-SHELL.
           INITIALIZE SHELL-PARM
           SET SP-COMMAND-PTR TO ADDRESS OF WS-NATIVE-COMMAND
           MOVE WS-COMMAND-LENGTH TO SP-COMMAND-LENGTH
           SET SP-OUTPUT-PTR TO ADDRESS OF WS-SHELL-NATIVE
           MOVE LIMIT-SHELL-OUTPUT TO SP-OUTPUT-CAPACITY
           CALL "SHELL" USING SHELL-PARM.

       CONVERT-SHELL-OUTPUT.
           INITIALIZE TEXT-PARM
           MOVE TEXT-NATIVE-REPLACE TO TP-OPERATION
           SET TP-INPUT-PTR TO ADDRESS OF WS-SHELL-NATIVE
           MOVE SP-OUTPUT-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF WS-SHELL-UTF8
           MOVE LIMIT-SHELL-OUTPUT TO TP-OUTPUT-CAPACITY
           CALL "NATUTF8" USING TEXT-PARM
           IF TP-STATUS NOT = STATUS-OK AND
              TP-STATUS NOT = STATUS-CAPACITY
               MOVE TP-STATUS TO WS-FAIL-STATUS
           END-IF
           MOVE TP-OUTPUT-LENGTH TO WS-SHELL-UTF8-LENGTH.

       WRITE-FINAL.
           INITIALIZE TEXT-PARM
           MOVE TEXT-UTF8-REPLACE TO TP-OPERATION
           SET TP-INPUT-PTR TO ADDRESS OF WS-ACTION
           MOVE RP-ACTION-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF WS-FINAL-NATIVE
           MOVE LIMIT-FINAL-NATIVE TO TP-OUTPUT-CAPACITY
           CALL "NATUTF8" USING TEXT-PARM
           IF TP-STATUS NOT = STATUS-OK
               MOVE TP-STATUS TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           IF TP-REPLACED = FLAG-ON
               PERFORM WRITE-FINAL-WARNING
           END-IF
           IF WS-OUTPUT-FAILED = FLAG-ON
               MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
               EXIT PARAGRAPH
           END-IF
           SET OP-BUFFER-PTR TO ADDRESS OF WS-FINAL-NATIVE
           MOVE TP-OUTPUT-LENGTH TO OP-BUFFER-LENGTH
           MOVE OUTPUT-STDOUT TO OP-FILE-DESCRIPTOR
           CALL "OUTPUT" USING OUTPUT-PARM
           IF OP-STATUS NOT = STATUS-OK
               MOVE STATUS-OUTPUT TO WS-FAIL-STATUS
           ELSE
               MOVE STATUS-OK TO WS-FAIL-STATUS
           END-IF.

       WRITE-COMMAND-ACTIVITY.
           MOVE "COBOLLM shell command:" TO WS-DIAG
           MOVE 22 TO WS-DIAG-LENGTH
           PERFORM WRITE-DIAG-LINE
           IF WS-OUTPUT-FAILED = FLAG-ON EXIT PARAGRAPH END-IF
           SET OP-BUFFER-PTR TO ADDRESS OF WS-NATIVE-COMMAND
           MOVE WS-COMMAND-LENGTH TO OP-BUFFER-LENGTH
           MOVE OUTPUT-STDERR TO OP-FILE-DESCRIPTOR
           CALL "OUTPUT" USING OUTPUT-PARM
           IF OP-STATUS NOT = STATUS-OK
               MOVE FLAG-ON TO WS-OUTPUT-FAILED
           END-IF
           IF WS-OUTPUT-FAILED = FLAG-OFF AND
              (WS-COMMAND-LENGTH = ZERO OR
               WS-NATIVE-COMMAND(WS-COMMAND-LENGTH:1) NOT =
                   WS-NATIVE-NEWLINE)
               PERFORM WRITE-NEWLINE
           END-IF.

       WRITE-ENCODING-COMMAND.
           MOVE "COBOLLM shell command:" TO WS-DIAG
           MOVE 22 TO WS-DIAG-LENGTH
           PERFORM WRITE-DIAG-LINE
           IF WS-OUTPUT-FAILED = FLAG-ON EXIT PARAGRAPH END-IF
           MOVE "[command unavailable: encoding error]" TO WS-DIAG
           MOVE 37 TO WS-DIAG-LENGTH
           PERFORM WRITE-DIAG-LINE.

       WRITE-RESULT-ACTIVITY.
           PERFORM BUILD-RESULT-ACTIVITY
           IF WS-OUTPUT-FAILED = FLAG-ON EXIT PARAGRAPH END-IF
           MOVE "COBOLLM shell result:" TO WS-DIAG
           MOVE 21 TO WS-DIAG-LENGTH
           PERFORM WRITE-DIAG-LINE
           IF WS-OUTPUT-FAILED = FLAG-ON EXIT PARAGRAPH END-IF
           SET OP-BUFFER-PTR TO ADDRESS OF WS-FINAL-NATIVE
           MOVE WS-ACTIVITY-LENGTH TO OP-BUFFER-LENGTH
           MOVE OUTPUT-STDERR TO OP-FILE-DESCRIPTOR
           CALL "OUTPUT" USING OUTPUT-PARM
           IF OP-STATUS NOT = STATUS-OK
               MOVE FLAG-ON TO WS-OUTPUT-FAILED
           END-IF
           IF WS-OUTPUT-FAILED = FLAG-OFF AND
              (WS-ACTIVITY-LENGTH = ZERO OR
               WS-FINAL-NATIVE(WS-ACTIVITY-LENGTH:1) NOT =
                   WS-NATIVE-NEWLINE)
               PERFORM WRITE-NEWLINE
           END-IF.

       BUILD-RESULT-ACTIVITY.
           MOVE LOW-VALUES TO WS-FINAL-NATIVE
           MOVE ZERO TO WS-ACTIVITY-LENGTH
           EVALUATE RP-SHELL-STATUS
               WHEN SHELL-EXIT
                   MOVE "status=exit" TO WS-DIAG
                   MOVE 11 TO WS-DIAG-LENGTH
                   PERFORM APPEND-ACTIVITY-LINE
                   MOVE "exit_code=" TO WS-DIAG
                   MOVE 10 TO WS-DIAG-LENGTH
                   PERFORM FORMAT-RESULT-NUMBER
                   PERFORM APPEND-ACTIVITY-NUMBER-LINE
                   MOVE "signal=none" TO WS-DIAG
                   MOVE 11 TO WS-DIAG-LENGTH
                   PERFORM APPEND-ACTIVITY-LINE
               WHEN SHELL-SIGNAL
                   MOVE "status=signal" TO WS-DIAG
                   MOVE 13 TO WS-DIAG-LENGTH
                   PERFORM APPEND-ACTIVITY-LINE
                   MOVE "exit_code=none" TO WS-DIAG
                   MOVE 14 TO WS-DIAG-LENGTH
                   PERFORM APPEND-ACTIVITY-LINE
                   MOVE "signal=" TO WS-DIAG
                   MOVE 7 TO WS-DIAG-LENGTH
                   PERFORM FORMAT-RESULT-NUMBER
                   PERFORM APPEND-ACTIVITY-NUMBER-LINE
               WHEN SHELL-COMMAND-ENCODING
                   MOVE "status=command-encoding-error" TO WS-DIAG
                   MOVE 29 TO WS-DIAG-LENGTH
                   PERFORM APPEND-ACTIVITY-LINE
                   MOVE "exit_code=none" TO WS-DIAG
                   MOVE 14 TO WS-DIAG-LENGTH
                   PERFORM APPEND-ACTIVITY-LINE
                   MOVE "signal=none" TO WS-DIAG
                   MOVE 11 TO WS-DIAG-LENGTH
                   PERFORM APPEND-ACTIVITY-LINE
           END-EVALUATE
           MOVE "truncated=false" TO WS-DIAG
           IF RP-SHELL-TRUNCATED = FLAG-ON
               MOVE "truncated=true" TO WS-DIAG
               MOVE 14 TO WS-DIAG-LENGTH
           ELSE
               MOVE 15 TO WS-DIAG-LENGTH
           END-IF
           PERFORM APPEND-ACTIVITY-LINE
           MOVE "encoding_loss=false" TO WS-DIAG
           IF RP-SHELL-ENCODING-LOSS = FLAG-ON
               MOVE "encoding_loss=true" TO WS-DIAG
               MOVE 18 TO WS-DIAG-LENGTH
           ELSE
               MOVE 19 TO WS-DIAG-LENGTH
           END-IF
           PERFORM APPEND-ACTIVITY-LINE
           MOVE "output:" TO WS-DIAG
           MOVE 7 TO WS-DIAG-LENGTH
           PERFORM APPEND-ACTIVITY-LINE
           IF RP-SHELL-OUTPUT-LENGTH > ZERO
               INITIALIZE TEXT-PARM
               MOVE TEXT-UTF8-REPLACE TO TP-OPERATION
               SET TP-INPUT-PTR TO ADDRESS OF WS-SHELL-UTF8
               MOVE RP-SHELL-OUTPUT-LENGTH TO TP-INPUT-LENGTH
               SET TP-OUTPUT-PTR TO ADDRESS OF WS-FINAL-NATIVE
               SET TP-OUTPUT-PTR UP BY WS-ACTIVITY-LENGTH
               COMPUTE TP-OUTPUT-CAPACITY =
                   LIMIT-FINAL-NATIVE - WS-ACTIVITY-LENGTH
               CALL "NATUTF8" USING TEXT-PARM
               IF TP-STATUS NOT = STATUS-OK
                   MOVE FLAG-ON TO WS-OUTPUT-FAILED
                   EXIT PARAGRAPH
               END-IF
               ADD TP-OUTPUT-LENGTH TO WS-ACTIVITY-LENGTH
           END-IF.

       FORMAT-RESULT-NUMBER.
           IF RP-SHELL-STATUS = SHELL-EXIT
               MOVE RP-SHELL-EXIT TO WS-RESULT-NUMBER
           ELSE
               MOVE RP-SHELL-SIGNAL TO WS-RESULT-NUMBER
           END-IF
           MOVE 1 TO WS-RESULT-NUMBER-START
           PERFORM UNTIL WS-RESULT-NUMBER-START > 2 OR
               WS-RESULT-NUMBER(WS-RESULT-NUMBER-START:1) NOT = SPACE
               ADD 1 TO WS-RESULT-NUMBER-START
           END-PERFORM
           COMPUTE WS-RESULT-NUMBER-LENGTH =
               4 - WS-RESULT-NUMBER-START.

       APPEND-ACTIVITY-NUMBER-LINE.
           MOVE WS-DIAG(1:WS-DIAG-LENGTH) TO
               WS-FINAL-NATIVE(WS-ACTIVITY-LENGTH + 1:
                               WS-DIAG-LENGTH)
           ADD WS-DIAG-LENGTH TO WS-ACTIVITY-LENGTH
           MOVE WS-RESULT-NUMBER(
               WS-RESULT-NUMBER-START:WS-RESULT-NUMBER-LENGTH) TO
               WS-FINAL-NATIVE(WS-ACTIVITY-LENGTH + 1:
                               WS-RESULT-NUMBER-LENGTH)
           ADD WS-RESULT-NUMBER-LENGTH TO WS-ACTIVITY-LENGTH
           MOVE WS-NATIVE-NEWLINE TO
               WS-FINAL-NATIVE(WS-ACTIVITY-LENGTH + 1:1)
           ADD 1 TO WS-ACTIVITY-LENGTH.

       APPEND-ACTIVITY-LINE.
           MOVE WS-DIAG(1:WS-DIAG-LENGTH) TO
               WS-FINAL-NATIVE(WS-ACTIVITY-LENGTH + 1:
                               WS-DIAG-LENGTH)
           ADD WS-DIAG-LENGTH TO WS-ACTIVITY-LENGTH
           MOVE WS-NATIVE-NEWLINE TO
               WS-FINAL-NATIVE(WS-ACTIVITY-LENGTH + 1:1)
           ADD 1 TO WS-ACTIVITY-LENGTH.

       WRITE-PLAINTEXT-WARNING.
           MOVE SPACES TO WS-DIAG
           STRING
               "COBOLLM: warning: HTTP sends the API key, task, "
               "commands, and command output without encryption."
               DELIMITED BY SIZE INTO WS-DIAG
           END-STRING
           MOVE 96 TO WS-DIAG-LENGTH
           PERFORM WRITE-DIAG-LINE.

       WRITE-FINAL-WARNING.
           MOVE SPACES TO WS-DIAG
           STRING
               "COBOLLM: warning: final response used replacement "
               "characters during native text conversion."
               DELIMITED BY SIZE INTO WS-DIAG
           END-STRING
           MOVE 91 TO WS-DIAG-LENGTH
           PERFORM WRITE-DIAG-LINE.

       WRITE-DIAG-LINE.
           SET OP-BUFFER-PTR TO ADDRESS OF WS-DIAG
           MOVE WS-DIAG-LENGTH TO OP-BUFFER-LENGTH
           MOVE OUTPUT-STDERR TO OP-FILE-DESCRIPTOR
           CALL "OUTPUT" USING OUTPUT-PARM
           IF OP-STATUS NOT = STATUS-OK
               MOVE FLAG-ON TO WS-OUTPUT-FAILED
           ELSE
               PERFORM WRITE-NEWLINE
           END-IF.

       WRITE-NEWLINE.
           SET OP-BUFFER-PTR TO ADDRESS OF WS-NATIVE-NEWLINE
           MOVE 1 TO OP-BUFFER-LENGTH
           MOVE OUTPUT-STDERR TO OP-FILE-DESCRIPTOR
           CALL "OUTPUT" USING OUTPUT-PARM
           IF OP-STATUS NOT = STATUS-OK
               MOVE FLAG-ON TO WS-OUTPUT-FAILED
           END-IF.

       FAIL-AND-CLEAN.
           PERFORM WRITE-TERMINAL-DIAGNOSTIC
           EVALUATE WS-FAIL-STATUS
               WHEN STATUS-USAGE-COUNT
               WHEN STATUS-USAGE-TEXT
               WHEN STATUS-CONFIG-KEY
               WHEN STATUS-CONFIG-MODEL
               WHEN STATUS-CONFIG-URL
               WHEN STATUS-CONFIG-ZOS-HTTPS
                   MOVE EXIT-USAGE TO CLI-EXIT-CODE
               WHEN STATUS-JSON
               WHEN STATUS-HTTP
               WHEN STATUS-RESPONSES
               WHEN STATUS-HTTP-CODE
                   MOVE EXIT-PROTOCOL TO CLI-EXIT-CODE
               WHEN STATUS-NETWORK
                   MOVE EXIT-NETWORK TO CLI-EXIT-CODE
               WHEN STATUS-SHELL
                   MOVE EXIT-SHELL TO CLI-EXIT-CODE
               WHEN STATUS-CAPACITY
               WHEN STATUS-TEXT-FATAL
                   MOVE EXIT-CAPACITY TO CLI-EXIT-CODE
               WHEN OTHER
                   MOVE EXIT-INTERNAL TO CLI-EXIT-CODE
           END-EVALUATE
           PERFORM CLEANUP
           GOBACK.

       WRITE-TERMINAL-DIAGNOSTIC.
           MOVE SPACES TO WS-DIAG
           EVALUATE WS-FAIL-STATUS
               WHEN STATUS-USAGE-COUNT
                   STRING
                       "COBOLLM: usage: expected exactly one "
                           DELIMITED BY SIZE
                       "nonempty task" DELIMITED BY SIZE
                       INTO WS-DIAG
                   END-STRING
                   MOVE 50 TO WS-DIAG-LENGTH
               WHEN STATUS-USAGE-TEXT
                   MOVE "COBOLLM: usage: task is not valid UTF-8"
                       TO WS-DIAG
                   MOVE 39 TO WS-DIAG-LENGTH
               WHEN STATUS-CONFIG-KEY
                   STRING
                       "COBOLLM: config: OPENAI_API_KEY is "
                           DELIMITED BY SIZE
                       "missing or invalid" DELIMITED BY SIZE
                       INTO WS-DIAG
                   END-STRING
                   MOVE 53 TO WS-DIAG-LENGTH
               WHEN STATUS-CONFIG-MODEL
                   STRING
                       "COBOLLM: config: OPENAI_MODEL is "
                           DELIMITED BY SIZE
                       "missing or invalid" DELIMITED BY SIZE
                       INTO WS-DIAG
                   END-STRING
                   MOVE 51 TO WS-DIAG-LENGTH
               WHEN STATUS-CONFIG-URL
                   MOVE "COBOLLM: config: OPENAI_BASE_URL is invalid"
                       TO WS-DIAG
                   MOVE 43 TO WS-DIAG-LENGTH
               WHEN STATUS-CONFIG-ZOS-HTTPS
                   STRING
                       "COBOLLM: config: z/OS requires an https "
                           DELIMITED BY SIZE
                       "base URL" DELIMITED BY SIZE
                       INTO WS-DIAG
                   END-STRING
                   MOVE 48 TO WS-DIAG-LENGTH
               WHEN STATUS-JSON
                   MOVE "COBOLLM: protocol: invalid JSON response"
                       TO WS-DIAG
                   MOVE 40 TO WS-DIAG-LENGTH
               WHEN STATUS-HTTP
                   MOVE "COBOLLM: protocol: invalid HTTP response"
                       TO WS-DIAG
                   MOVE 40 TO WS-DIAG-LENGTH
               WHEN STATUS-RESPONSES
                   STRING
                       "COBOLLM: protocol: unsupported Responses "
                           DELIMITED BY SIZE
                       "response" DELIMITED BY SIZE
                       INTO WS-DIAG
                   END-STRING
                   MOVE 49 TO WS-DIAG-LENGTH
               WHEN STATUS-NETWORK
                   MOVE "COBOLLM: network: connection failed"
                       TO WS-DIAG
                   MOVE 35 TO WS-DIAG-LENGTH
               WHEN STATUS-SHELL
                   MOVE "COBOLLM: shell: execution failed"
                       TO WS-DIAG
                   MOVE 32 TO WS-DIAG-LENGTH
               WHEN STATUS-CAPACITY
                   STRING
                       "COBOLLM: capacity: fixed buffer limit "
                           DELIMITED BY SIZE
                       "exceeded" DELIMITED BY SIZE
                       INTO WS-DIAG
                   END-STRING
                   MOVE 46 TO WS-DIAG-LENGTH
               WHEN STATUS-OUTPUT
                   MOVE "COBOLLM: internal: output write failed"
                       TO WS-DIAG
                   MOVE 38 TO WS-DIAG-LENGTH
               WHEN STATUS-TEXT-FATAL
                   MOVE "COBOLLM: capacity: text conversion failed"
                       TO WS-DIAG
                   MOVE 41 TO WS-DIAG-LENGTH
               WHEN OTHER
                   MOVE "COBOLLM: internal: invariant failure"
                       TO WS-DIAG
                   MOVE 36 TO WS-DIAG-LENGTH
           END-EVALUATE
           IF WS-FAIL-STATUS = STATUS-HTTP-CODE
               MOVE WS-HTTP-STATUS TO WS-HTTP-STATUS-DISPLAY
               STRING "COBOLLM: protocol: HTTP status "
                   WS-HTTP-STATUS-DISPLAY
                   DELIMITED BY SIZE INTO WS-DIAG
               END-STRING
               MOVE 34 TO WS-DIAG-LENGTH
           END-IF
           SET OP-BUFFER-PTR TO ADDRESS OF WS-DIAG
           MOVE WS-DIAG-LENGTH TO OP-BUFFER-LENGTH
           MOVE OUTPUT-STDERR TO OP-FILE-DESCRIPTOR
           CALL "OUTPUT" USING OUTPUT-PARM
           IF OP-STATUS = STATUS-OK PERFORM WRITE-NEWLINE END-IF.

       CLEANUP.
           IF WS-RESP-INITIALIZED = FLAG-ON
               INITIALIZE RESP-PARM
               MOVE RESP-DESTROY TO RP-OPERATION
               SET RP-MODEL-PTR RP-URL-PTR RP-KEY-PTR
                   RP-TASK-PTR RP-SHELL-OUTPUT-PTR
                   RP-ACTION-PTR TO NULL
               CALL "RESPAPI" USING RESP-PARM
           END-IF
           MOVE LOW-VALUES TO WS-NATIVE-STAGING WS-KEY-UTF8
                              WS-ACTION WS-NATIVE-COMMAND
                              WS-SHELL-NATIVE WS-SHELL-UTF8
                              WS-FINAL-NATIVE
           SET RP-KEY-PTR TO NULL
           MOVE ZERO TO RP-KEY-LENGTH
           SET WS-ENV-PTR TO NULL
           SET ADDRESS OF WS-ENV-VIEW TO NULL
           PERFORM REMOVE-KEY-ENV
           IF WS-NATIVE-RESULT NOT = ZERO OR WS-ENV-PTR NOT = NULL OR
              ADDRESS OF WS-ENV-VIEW NOT = NULL
               MOVE EXIT-INTERNAL TO CLI-EXIT-CODE
           END-IF.

       END PROGRAM COBOLLM.
