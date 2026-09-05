       IDENTIFICATION DIVISION.
       PROGRAM-ID. TSTNET.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY NETPARM.
       COPY SHLPARM.
       COPY POSIXNAT.
       COPY NETNAT.
       01 WS-CONNECT-HOST         PIC X(253).
       01 WS-VERIFY-HOST          PIC X(253).
       01 WS-BUFFER               PIC X(65536).
       01 WS-RECEIVED             PIC X(128).
       01 WS-EXPECTED             PIC X(128).
       01 WS-RECEIVED-LENGTH      PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-EXPECTED-LENGTH      PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-READ-COUNT           PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-WRITTEN              PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-WRITE-REMAINING      PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-CONNECT-PTR          USAGE POINTER.
       01 WS-VERIFY-PTR           USAGE POINTER.
       01 WS-BUFFER-PTR           USAGE POINTER.
       01 WS-PLAIN-PORT           PIC 9(5).
       01 WS-TLS-PORT             PIC 9(5).
       01 WS-MISMATCH-PORT        PIC 9(5).
       01 WS-UNTRUSTED-PORT       PIC 9(5).
       01 WS-RESET-PORT           PIC 9(5).
       01 WS-CURRENT-PORT         PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-CURRENT-SCHEME       PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-CURRENT-VERIFY       PIC X(16).
       01 WS-CURRENT-VERIFY-LEN   PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-ARG-COUNT            PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-MODE                 PIC X(8).
       01 WS-PORT-ARG             PIC X(5).
       01 WS-PUBLIC-VALID         PIC X VALUE X'00'.
       01 WS-PUBLIC-DIGIT         PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-PUBLIC-INDEX         PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-FAILURES             PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-VALIDATION-CASE      PIC S9(9) COMP-5 VALUE ZERO.
       01 WS-SIGNAL-INSTALLED     PIC X VALUE X"00".
       01 WS-NULL                 USAGE POINTER.
       01 WS-SIGNAL-RESULT        PIC S9(9) COMP-5.
       01 WS-ORIGINAL-ACTION      PIC X(152).
       01 WS-SIGNAL-COMMAND       PIC X(29) VALUE
           "kill -PIPE $$; printf PIPE-OK".
       01 WS-SIGNAL-OUTPUT        PIC X(16).

       PROCEDURE DIVISION.
           ACCEPT WS-ARG-COUNT FROM ARGUMENT-NUMBER
           IF WS-ARG-COUNT = 4
               ACCEPT WS-MODE FROM ARGUMENT-VALUE
               ACCEPT WS-CONNECT-HOST FROM ARGUMENT-VALUE
               ACCEPT WS-VERIFY-HOST FROM ARGUMENT-VALUE
               ACCEPT WS-PORT-ARG FROM ARGUMENT-VALUE
               PERFORM TEST-PUBLIC
               GOBACK
           END-IF
           ACCEPT WS-PLAIN-PORT FROM ENVIRONMENT
               "COBOLLM_TEST_PLAIN_PORT"
           ACCEPT WS-TLS-PORT FROM ENVIRONMENT
               "COBOLLM_TEST_TLS_PORT"
           ACCEPT WS-MISMATCH-PORT FROM ENVIRONMENT
               "COBOLLM_TEST_MISMATCH_PORT"
           ACCEPT WS-UNTRUSTED-PORT FROM ENVIRONMENT
               "COBOLLM_TEST_UNTRUSTED_PORT"
           ACCEPT WS-RESET-PORT FROM ENVIRONMENT
               "COBOLLM_TEST_RESET_PORT"
           PERFORM INSTALL-IGNORED-SIGPIPE
           PERFORM TEST-RESET-AND-POINTERS
           PERFORM TEST-CLOSED-OPERATIONS

           MOVE WS-PLAIN-PORT TO WS-CURRENT-PORT
           MOVE NET-PLAINTEXT TO WS-CURRENT-SCHEME
           MOVE "127.0.0.1" TO WS-CURRENT-VERIFY
           MOVE 9 TO WS-CURRENT-VERIFY-LEN
           PERFORM OPEN-CURRENT
           IF NP-STATUS = STATUS-OK
               PERFORM TEST-SECOND-OPEN
               PERFORM TEST-ACTIVE-PARAMETERS
               PERFORM WRITE-REQUEST
               MOVE "PLAIN-OK" TO WS-EXPECTED
               MOVE 8 TO WS-EXPECTED-LENGTH
               PERFORM READ-EXPECTED-TO-EOF
               PERFORM CLOSE-CURRENT
           ELSE
               DISPLAY "plain open status " NP-STATUS
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE WS-TLS-PORT TO WS-CURRENT-PORT
           MOVE NET-TLS TO WS-CURRENT-SCHEME
           MOVE "localhost" TO WS-CURRENT-VERIFY
           MOVE 9 TO WS-CURRENT-VERIFY-LEN
           PERFORM OPEN-CURRENT
           IF NP-STATUS = STATUS-OK
               PERFORM WRITE-REQUEST
               MOVE "TLS-CLOSE-OK" TO WS-EXPECTED
               MOVE 12 TO WS-EXPECTED-LENGTH
               PERFORM READ-EXPECTED-TO-EOF
               PERFORM CLOSE-CURRENT
           ELSE
               DISPLAY "tls open status " NP-STATUS
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE WS-MISMATCH-PORT TO WS-CURRENT-PORT
           MOVE NET-TLS TO WS-CURRENT-SCHEME
           MOVE "not-localhost" TO WS-CURRENT-VERIFY
           MOVE 13 TO WS-CURRENT-VERIFY-LEN
           PERFORM EXPECT-OPEN-FAILURE

           MOVE WS-UNTRUSTED-PORT TO WS-CURRENT-PORT
           MOVE NET-TLS TO WS-CURRENT-SCHEME
           MOVE "localhost" TO WS-CURRENT-VERIFY
           MOVE 9 TO WS-CURRENT-VERIFY-LEN
           PERFORM EXPECT-OPEN-FAILURE

           MOVE WS-RESET-PORT TO WS-CURRENT-PORT
           MOVE NET-PLAINTEXT TO WS-CURRENT-SCHEME
           MOVE "127.0.0.1" TO WS-CURRENT-VERIFY
           MOVE 9 TO WS-CURRENT-VERIFY-LEN
           PERFORM OPEN-CURRENT
           IF NP-STATUS = STATUS-OK
               INITIALIZE NET-PARM
               MOVE NET-READ TO NP-OPERATION
               SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
               MOVE 16 TO NP-BUFFER-CAPACITY
               CALL "NETIO" USING NET-PARM
               IF NP-STATUS NOT = STATUS-NETWORK
                   DISPLAY "reset read status " NP-STATUS
                   ADD 1 TO WS-FAILURES
               END-IF
               PERFORM CLOSE-CURRENT
           ELSE
               DISPLAY "reuse open status " NP-STATUS
               ADD 1 TO WS-FAILURES
           END-IF

      * Success after failures exposes retained active/TLS state.
           MOVE WS-TLS-PORT TO WS-CURRENT-PORT
           MOVE NET-TLS TO WS-CURRENT-SCHEME
           MOVE "localhost" TO WS-CURRENT-VERIFY
           MOVE 9 TO WS-CURRENT-VERIFY-LEN
           PERFORM OPEN-CURRENT
           IF NP-STATUS = STATUS-OK
               PERFORM WRITE-REQUEST
               MOVE "TLS-CLOSE-OK" TO WS-EXPECTED
               MOVE 12 TO WS-EXPECTED-LENGTH
               PERFORM READ-EXPECTED-TO-EOF
               PERFORM CLOSE-CURRENT
           ELSE
               ADD 1 TO WS-FAILURES
           END-IF

           PERFORM TEST-RESTORED-SIGPIPE
           PERFORM RESTORE-ORIGINAL-SIGPIPE

           IF WS-FAILURES = ZERO
               DISPLAY "PASS NET"
               MOVE ZERO TO RETURN-CODE
           ELSE
               DISPLAY "FAIL NET " WS-FAILURES
               MOVE 1 TO RETURN-CODE
           END-IF
           GOBACK.

       TEST-PUBLIC.
           MOVE FLAG-ON TO WS-PUBLIC-VALID
           MOVE 253 TO WS-EXPECTED-LENGTH
           PERFORM UNTIL WS-EXPECTED-LENGTH = ZERO OR
               WS-CONNECT-HOST(WS-EXPECTED-LENGTH:1) NOT = SPACE
               SUBTRACT 1 FROM WS-EXPECTED-LENGTH
           END-PERFORM
           MOVE 253 TO WS-CURRENT-VERIFY-LEN
           PERFORM UNTIL WS-CURRENT-VERIFY-LEN = ZERO OR
               WS-VERIFY-HOST(WS-CURRENT-VERIFY-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-CURRENT-VERIFY-LEN
           END-PERFORM
           MOVE ZERO TO WS-CURRENT-PORT
           PERFORM VARYING WS-PUBLIC-INDEX FROM 1 BY 1
               UNTIL WS-PUBLIC-INDEX > 5
               IF WS-PORT-ARG(WS-PUBLIC-INDEX:1) = SPACE
                   CONTINUE
               ELSE
                   COMPUTE WS-PUBLIC-DIGIT =
                       FUNCTION ORD(
                           WS-PORT-ARG(WS-PUBLIC-INDEX:1)) - 49
                   IF WS-PUBLIC-DIGIT < ZERO OR
                      WS-PUBLIC-DIGIT > 9
                       MOVE FLAG-OFF TO WS-PUBLIC-VALID
                   ELSE
                       MULTIPLY 10 BY WS-CURRENT-PORT
                       ADD WS-PUBLIC-DIGIT TO WS-CURRENT-PORT
                   END-IF
               END-IF
           END-PERFORM
           IF WS-MODE(1:6) NOT = "public" OR
              WS-EXPECTED-LENGTH < 1 OR
              WS-CURRENT-VERIFY-LEN < 1 OR
              WS-CURRENT-PORT < 1 OR WS-CURRENT-PORT > 65535
               MOVE FLAG-OFF TO WS-PUBLIC-VALID
           END-IF
           IF WS-PUBLIC-VALID = FLAG-ON
               INITIALIZE NET-PARM
               MOVE NET-OPEN TO NP-OPERATION
               MOVE NET-TLS TO NP-SCHEME
               SET NP-CONNECT-HOST-PTR TO
                   ADDRESS OF WS-CONNECT-HOST
               MOVE WS-EXPECTED-LENGTH TO NP-CONNECT-HOST-LENGTH
               SET NP-VERIFY-HOST-PTR TO ADDRESS OF WS-VERIFY-HOST
               MOVE WS-CURRENT-VERIFY-LEN TO NP-VERIFY-HOST-LENGTH
               MOVE WS-CURRENT-PORT TO NP-PORT
               CALL "NETIO" USING NET-PARM
               IF NP-STATUS = STATUS-OK
                   INITIALIZE NET-PARM
                   MOVE NET-CLOSE TO NP-OPERATION
                   CALL "NETIO" USING NET-PARM
                   IF NP-STATUS NOT = STATUS-OK
                       MOVE FLAG-OFF TO WS-PUBLIC-VALID
                   END-IF
               ELSE
                   MOVE FLAG-OFF TO WS-PUBLIC-VALID
               END-IF
           END-IF
           IF WS-PUBLIC-VALID = FLAG-ON
               DISPLAY "PASS NET PUBLIC"
               MOVE ZERO TO RETURN-CODE
           ELSE
               DISPLAY "FAIL NET PUBLIC"
               MOVE 1 TO RETURN-CODE
           END-IF.

       INSTALL-IGNORED-SIGPIPE.
           SET WS-NULL TO NULL
           MOVE LOW-VALUES TO WS-ORIGINAL-ACTION
                              GNU-SIGACTION-RECORD
           CALL STATIC "sigaction" USING
               BY VALUE SIZE IS 4 GNU-SIGPIPE
               BY VALUE WS-NULL
               BY REFERENCE WS-ORIGINAL-ACTION
               RETURNING WS-SIGNAL-RESULT
           IF WS-SIGNAL-RESULT NOT = ZERO
               ADD 1 TO WS-FAILURES
               EXIT PARAGRAPH
           END-IF
           CALL STATIC "sigemptyset" USING
               BY REFERENCE GNU-SA-MASK
               RETURNING WS-SIGNAL-RESULT
           IF WS-SIGNAL-RESULT NOT = ZERO
               ADD 1 TO WS-FAILURES
               EXIT PARAGRAPH
           END-IF
           MOVE GNU-SIG-IGN TO GNU-SA-HANDLER
           CALL STATIC "sigaction" USING
               BY VALUE SIZE IS 4 GNU-SIGPIPE
               BY REFERENCE GNU-SIGACTION-RECORD
               BY VALUE WS-NULL
               RETURNING WS-SIGNAL-RESULT
           IF WS-SIGNAL-RESULT = ZERO
               MOVE FLAG-ON TO WS-SIGNAL-INSTALLED
           ELSE
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-RESTORED-SIGPIPE.
           IF WS-SIGNAL-INSTALLED NOT = FLAG-ON EXIT PARAGRAPH END-IF
           MOVE LOW-VALUES TO WS-SIGNAL-OUTPUT
           INITIALIZE SHELL-PARM
           SET SP-COMMAND-PTR TO ADDRESS OF WS-SIGNAL-COMMAND
           MOVE 29 TO SP-COMMAND-LENGTH
           SET SP-OUTPUT-PTR TO ADDRESS OF WS-SIGNAL-OUTPUT
           MOVE 16 TO SP-OUTPUT-CAPACITY
           CALL "SHELL" USING SHELL-PARM
           IF SP-STATUS NOT = STATUS-OK OR
              SP-RESULT-KIND NOT = SHELL-EXIT OR
              SP-EXIT-CODE NOT = ZERO OR
              SP-OUTPUT-LENGTH NOT = 7 OR
              WS-SIGNAL-OUTPUT(1:7) NOT = "PIPE-OK"
               ADD 1 TO WS-FAILURES
           END-IF.

       RESTORE-ORIGINAL-SIGPIPE.
           IF WS-SIGNAL-INSTALLED = FLAG-ON
               CALL STATIC "sigaction" USING
                   BY VALUE SIZE IS 4 GNU-SIGPIPE
                   BY REFERENCE WS-ORIGINAL-ACTION
                   BY VALUE WS-NULL
                   RETURNING WS-SIGNAL-RESULT
               IF WS-SIGNAL-RESULT NOT = ZERO
                   ADD 1 TO WS-FAILURES
               END-IF
               MOVE FLAG-OFF TO WS-SIGNAL-INSTALLED
           END-IF.

       TEST-RESET-AND-POINTERS.
           INITIALIZE NET-PARM
           MOVE NET-OPEN TO NP-OPERATION
           MOVE 777 TO NP-STATUS NP-TRANSFERRED
           MOVE X"FF" TO NP-EOF
           MOVE NET-TLS TO NP-SCHEME
           MOVE 443 TO NP-PORT
           MOVE 9 TO NP-CONNECT-HOST-LENGTH
           MOVE 9 TO NP-VERIFY-HOST-LENGTH
           CALL "NETIO" USING NET-PARM
           IF NP-STATUS NOT = STATUS-INTERNAL OR
              NP-TRANSFERRED NOT = ZERO OR NP-EOF NOT = FLAG-OFF OR
              NP-OPERATION NOT = NET-OPEN OR NP-SCHEME NOT = NET-TLS OR
              NP-PORT NOT = 443 OR NP-CONNECT-HOST-LENGTH NOT = 9 OR
              NP-VERIFY-HOST-LENGTH NOT = 9 OR
              NP-CONNECT-HOST-PTR NOT = NULL OR
              NP-VERIFY-HOST-PTR NOT = NULL
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM TEST-OPEN-PARAMETERS.

       TEST-OPEN-PARAMETERS.
           PERFORM VARYING WS-VALIDATION-CASE FROM 1 BY 1
               UNTIL WS-VALIDATION-CASE > 8
               INITIALIZE NET-PARM
               MOVE NET-OPEN TO NP-OPERATION
               MOVE NET-TLS TO NP-SCHEME
               SET NP-CONNECT-HOST-PTR TO
                   ADDRESS OF WS-CONNECT-HOST
               SET NP-VERIFY-HOST-PTR TO ADDRESS OF WS-VERIFY-HOST
               MOVE 9 TO NP-CONNECT-HOST-LENGTH
                         NP-VERIFY-HOST-LENGTH
               MOVE 443 TO NP-PORT
               EVALUATE WS-VALIDATION-CASE
                   WHEN 1
                       SET NP-CONNECT-HOST-PTR TO NULL
                   WHEN 2
                       SET NP-VERIFY-HOST-PTR TO NULL
                   WHEN 3
                       MOVE ZERO TO NP-CONNECT-HOST-LENGTH
                   WHEN 4
                       MOVE ZERO TO NP-VERIFY-HOST-LENGTH
                   WHEN 5
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 1 TO NP-BUFFER-CAPACITY
                                 NP-REQUEST-LENGTH
                   WHEN 6
                       MOVE ZERO TO NP-PORT
                   WHEN 7
                       MOVE ZERO TO NP-SCHEME
                   WHEN 8
                       MOVE 254 TO NP-CONNECT-HOST-LENGTH
                                   NP-VERIFY-HOST-LENGTH
                       SET NP-CONNECT-HOST-PTR
                           NP-VERIFY-HOST-PTR TO NULL
               END-EVALUATE
               CALL "NETIO" USING NET-PARM
               IF WS-VALIDATION-CASE = 8
                   IF NP-STATUS NOT = STATUS-CAPACITY
                       ADD 1 TO WS-FAILURES
                   END-IF
               ELSE
                   IF NP-STATUS NOT = STATUS-INTERNAL
                       ADD 1 TO WS-FAILURES
                   END-IF
               END-IF
           END-PERFORM.

       TEST-ACTIVE-PARAMETERS.
           PERFORM VARYING WS-VALIDATION-CASE FROM 1 BY 1
               UNTIL WS-VALIDATION-CASE > 12
               INITIALIZE NET-PARM
               EVALUATE WS-VALIDATION-CASE
                   WHEN 1
                       MOVE NET-WRITE TO NP-OPERATION
                       SET NP-CONNECT-HOST-PTR TO
                           ADDRESS OF WS-CONNECT-HOST
                       SET NP-VERIFY-HOST-PTR TO
                           ADDRESS OF WS-VERIFY-HOST
                       MOVE 1 TO NP-CONNECT-HOST-LENGTH
                                 NP-VERIFY-HOST-LENGTH
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 1 TO NP-BUFFER-CAPACITY
                                 NP-REQUEST-LENGTH
                   WHEN 2
                       MOVE NET-WRITE TO NP-OPERATION
                       MOVE 1 TO NP-BUFFER-CAPACITY
                                 NP-REQUEST-LENGTH
                   WHEN 3
                       MOVE NET-WRITE TO NP-OPERATION
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE -1 TO NP-BUFFER-CAPACITY
                   WHEN 4
                       MOVE NET-WRITE TO NP-OPERATION
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE -1 TO NP-REQUEST-LENGTH
                   WHEN 5
                       MOVE NET-WRITE TO NP-OPERATION
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 1 TO NP-BUFFER-CAPACITY
                       MOVE 2 TO NP-REQUEST-LENGTH
                   WHEN 6
                       MOVE NET-READ TO NP-OPERATION
                       SET NP-CONNECT-HOST-PTR TO
                           ADDRESS OF WS-CONNECT-HOST
                       SET NP-VERIFY-HOST-PTR TO
                           ADDRESS OF WS-VERIFY-HOST
                       MOVE 1 TO NP-CONNECT-HOST-LENGTH
                                 NP-VERIFY-HOST-LENGTH
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 1 TO NP-BUFFER-CAPACITY
                   WHEN 7
                       MOVE NET-READ TO NP-OPERATION
                       MOVE 1 TO NP-BUFFER-CAPACITY
                   WHEN 8
                       MOVE NET-READ TO NP-OPERATION
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                   WHEN 9
                       MOVE NET-READ TO NP-OPERATION
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 65537 TO NP-BUFFER-CAPACITY
                   WHEN 10
                       MOVE NET-READ TO NP-OPERATION
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 1 TO NP-BUFFER-CAPACITY
                                 NP-REQUEST-LENGTH
                   WHEN 11
                       MOVE NET-CLOSE TO NP-OPERATION
                       SET NP-CONNECT-HOST-PTR TO
                           ADDRESS OF WS-CONNECT-HOST
                       SET NP-VERIFY-HOST-PTR TO
                           ADDRESS OF WS-VERIFY-HOST
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 1 TO NP-CONNECT-HOST-LENGTH
                                 NP-VERIFY-HOST-LENGTH
                                 NP-BUFFER-CAPACITY
                                 NP-REQUEST-LENGTH
                   WHEN 12
                       MOVE NET-WRITE TO NP-OPERATION
                       SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
                       MOVE 65537 TO NP-BUFFER-CAPACITY
                       MOVE 1 TO NP-REQUEST-LENGTH
               END-EVALUATE
               MOVE 777 TO NP-STATUS NP-TRANSFERRED
               MOVE X"FF" TO NP-EOF
               CALL "NETIO" USING NET-PARM
               IF NP-STATUS NOT = STATUS-INTERNAL OR
                  NP-TRANSFERRED NOT = ZERO OR
                  NP-EOF NOT = FLAG-OFF
                   ADD 1 TO WS-FAILURES
               END-IF
           END-PERFORM.

       TEST-CLOSED-OPERATIONS.
           INITIALIZE NET-PARM
           MOVE NET-WRITE TO NP-OPERATION
           SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
           SET WS-BUFFER-PTR TO NP-BUFFER-PTR
           MOVE 16 TO NP-BUFFER-CAPACITY
           MOVE 3 TO NP-REQUEST-LENGTH
           MOVE 777 TO NP-STATUS NP-TRANSFERRED
           MOVE X"FF" TO NP-EOF
           CALL "NETIO" USING NET-PARM
           IF NP-STATUS NOT = STATUS-INTERNAL OR
              NP-TRANSFERRED NOT = ZERO OR NP-EOF NOT = FLAG-OFF OR
              NP-BUFFER-PTR NOT = WS-BUFFER-PTR OR
              NP-BUFFER-CAPACITY NOT = 16 OR
              NP-REQUEST-LENGTH NOT = 3
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE NET-PARM
           MOVE NET-READ TO NP-OPERATION
           SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
           SET WS-BUFFER-PTR TO NP-BUFFER-PTR
           MOVE 16 TO NP-BUFFER-CAPACITY
           MOVE 777 TO NP-STATUS NP-TRANSFERRED
           MOVE X"FF" TO NP-EOF
           CALL "NETIO" USING NET-PARM
           IF NP-STATUS NOT = STATUS-INTERNAL OR
              NP-TRANSFERRED NOT = ZERO OR NP-EOF NOT = FLAG-OFF OR
              NP-BUFFER-PTR NOT = WS-BUFFER-PTR OR
              NP-BUFFER-CAPACITY NOT = 16 OR
              NP-REQUEST-LENGTH NOT = ZERO
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SECOND-OPEN.
           PERFORM OPEN-CURRENT
           IF NP-STATUS NOT = STATUS-INTERNAL OR
              NP-TRANSFERRED NOT = ZERO OR NP-EOF NOT = FLAG-OFF
               ADD 1 TO WS-FAILURES
           END-IF.

       OPEN-CURRENT.
           MOVE "127.0.0.1" TO WS-CONNECT-HOST
           MOVE SPACES TO WS-VERIFY-HOST
           MOVE WS-CURRENT-VERIFY(1:WS-CURRENT-VERIFY-LEN) TO
               WS-VERIFY-HOST(1:WS-CURRENT-VERIFY-LEN)
           INITIALIZE NET-PARM
           MOVE NET-OPEN TO NP-OPERATION
           MOVE WS-CURRENT-SCHEME TO NP-SCHEME
           SET NP-CONNECT-HOST-PTR TO ADDRESS OF WS-CONNECT-HOST
           SET WS-CONNECT-PTR TO NP-CONNECT-HOST-PTR
           MOVE 9 TO NP-CONNECT-HOST-LENGTH
           SET NP-VERIFY-HOST-PTR TO ADDRESS OF WS-VERIFY-HOST
           SET WS-VERIFY-PTR TO NP-VERIFY-HOST-PTR
           MOVE WS-CURRENT-VERIFY-LEN TO NP-VERIFY-HOST-LENGTH
           MOVE WS-CURRENT-PORT TO NP-PORT
           CALL "NETIO" USING NET-PARM
           IF NP-TRANSFERRED NOT = ZERO OR NP-EOF NOT = FLAG-OFF OR
              NP-SCHEME NOT = WS-CURRENT-SCHEME OR
              NP-CONNECT-HOST-LENGTH NOT = 9 OR
              NP-VERIFY-HOST-LENGTH NOT = WS-CURRENT-VERIFY-LEN OR
              NP-PORT NOT = WS-CURRENT-PORT OR
              NP-CONNECT-HOST-PTR NOT = WS-CONNECT-PTR OR
              NP-VERIFY-HOST-PTR NOT = WS-VERIFY-PTR
               ADD 1 TO WS-FAILURES
           END-IF.

       EXPECT-OPEN-FAILURE.
           PERFORM OPEN-CURRENT
           IF NP-STATUS NOT = STATUS-NETWORK
               DISPLAY "expected open failure status " NP-STATUS
               ADD 1 TO WS-FAILURES
               IF NP-STATUS = STATUS-OK
                   PERFORM CLOSE-CURRENT
               END-IF
           END-IF.

       WRITE-REQUEST.
           MOVE LOW-VALUES TO WS-BUFFER
           MOVE "GET / HTTP/1.1" TO WS-BUFFER(1:14)
           MOVE X"0D0A" TO WS-BUFFER(15:2)
           MOVE "Authorization: test" TO WS-BUFFER(17:19)
           MOVE X"0D0A0D0A" TO WS-BUFFER(36:4)
           MOVE ZERO TO WS-WRITTEN
           PERFORM UNTIL WS-WRITTEN = 39
               COMPUTE WS-WRITE-REMAINING = 39 - WS-WRITTEN
               SET WS-BUFFER-PTR TO ADDRESS OF WS-BUFFER
               SET WS-BUFFER-PTR UP BY WS-WRITTEN
               INITIALIZE NET-PARM
               MOVE NET-WRITE TO NP-OPERATION
               SET NP-BUFFER-PTR TO WS-BUFFER-PTR
               MOVE WS-WRITE-REMAINING TO NP-BUFFER-CAPACITY
               MOVE WS-WRITE-REMAINING TO NP-REQUEST-LENGTH
               CALL "NETIO" USING NET-PARM
               IF NP-STATUS NOT = STATUS-OK OR
                  NP-TRANSFERRED < 1 OR
                  NP-TRANSFERRED > WS-WRITE-REMAINING OR
                  NP-BUFFER-PTR NOT = WS-BUFFER-PTR OR
                  NP-BUFFER-CAPACITY NOT = WS-WRITE-REMAINING OR
                  NP-REQUEST-LENGTH NOT = WS-WRITE-REMAINING
                   DISPLAY "write status/count " NP-STATUS " "
                       NP-TRANSFERRED
                   ADD 1 TO WS-FAILURES
                   MOVE 39 TO WS-WRITTEN
               ELSE
                   ADD NP-TRANSFERRED TO WS-WRITTEN
               END-IF
           END-PERFORM.

       READ-EXPECTED-TO-EOF.
           MOVE LOW-VALUES TO WS-RECEIVED
           MOVE ZERO TO WS-RECEIVED-LENGTH WS-READ-COUNT
           MOVE FLAG-OFF TO NP-EOF
           PERFORM UNTIL NP-EOF = FLAG-ON OR WS-READ-COUNT > 100
               ADD 1 TO WS-READ-COUNT
               MOVE LOW-VALUES TO WS-BUFFER
               INITIALIZE NET-PARM
               MOVE NET-READ TO NP-OPERATION
               SET NP-BUFFER-PTR TO ADDRESS OF WS-BUFFER
               SET WS-BUFFER-PTR TO NP-BUFFER-PTR
               MOVE 3 TO NP-BUFFER-CAPACITY
               CALL "NETIO" USING NET-PARM
               EVALUATE TRUE
                   WHEN NP-STATUS NOT = STATUS-OK OR
                        NP-TRANSFERRED < ZERO OR
                        NP-TRANSFERRED > 3 OR
                        NP-BUFFER-PTR NOT = WS-BUFFER-PTR OR
                        NP-BUFFER-CAPACITY NOT = 3
                       DISPLAY "read status/count " NP-STATUS " "
                           NP-TRANSFERRED
                       ADD 1 TO WS-FAILURES
                       MOVE FLAG-ON TO NP-EOF
                   WHEN NP-TRANSFERRED > ZERO
                       IF WS-RECEIVED-LENGTH > 128 - NP-TRANSFERRED
                           ADD 1 TO WS-FAILURES
                           MOVE FLAG-ON TO NP-EOF
                       ELSE
                           MOVE WS-BUFFER(1:NP-TRANSFERRED) TO
                               WS-RECEIVED(WS-RECEIVED-LENGTH + 1:
                                           NP-TRANSFERRED)
                           ADD NP-TRANSFERRED TO WS-RECEIVED-LENGTH
                       END-IF
               END-EVALUATE
           END-PERFORM
           IF WS-READ-COUNT > 100 OR
              WS-RECEIVED-LENGTH NOT = WS-EXPECTED-LENGTH OR
              WS-RECEIVED(1:WS-EXPECTED-LENGTH) NOT =
                  WS-EXPECTED(1:WS-EXPECTED-LENGTH)
               DISPLAY "read expected lengths " WS-RECEIVED-LENGTH " "
                   WS-EXPECTED-LENGTH
               ADD 1 TO WS-FAILURES
           END-IF.

       CLOSE-CURRENT.
           INITIALIZE NET-PARM
           MOVE NET-CLOSE TO NP-OPERATION
           CALL "NETIO" USING NET-PARM
           IF NP-STATUS NOT = STATUS-OK OR
              NP-TRANSFERRED NOT = ZERO OR NP-EOF NOT = FLAG-OFF OR
              NP-BUFFER-PTR NOT = NULL OR
              NP-CONNECT-HOST-PTR NOT = NULL OR
              NP-VERIFY-HOST-PTR NOT = NULL
               ADD 1 TO WS-FAILURES
           END-IF.

       END PROGRAM TSTNET.
