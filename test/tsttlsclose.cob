       IDENTIFICATION DIVISION.
       PROGRAM-ID. TSTTLSCL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY NETPARM.
       01  TEST-HOST               PIC X(9) VALUE "127.0.0.1".
       01  TEST-VERIFY             PIC X(9) VALUE "localhost".
       01  TEST-PORT               PIC 9(5).
       01  TEST-FAILURES           PIC S9(9) COMP-5 VALUE ZERO.
       COPY FTCTRL.

       PROCEDURE DIVISION.
           ACCEPT TEST-PORT FROM ENVIRONMENT
               "COBOLLM_TEST_TLS_CLOSE_PORT"
           INITIALIZE FAKE-TLS-CLOSE-CONTROL
           MOVE FLAG-ON TO FT-VALID
           PERFORM 2 TIMES
               INITIALIZE NET-PARM
               MOVE NET-OPEN TO NP-OPERATION
               MOVE NET-TLS TO NP-SCHEME
               SET NP-CONNECT-HOST-PTR TO ADDRESS OF TEST-HOST
               MOVE 9 TO NP-CONNECT-HOST-LENGTH
               SET NP-VERIFY-HOST-PTR TO ADDRESS OF TEST-VERIFY
               MOVE 9 TO NP-VERIFY-HOST-LENGTH
               MOVE TEST-PORT TO NP-PORT
               CALL "NETIO" USING NET-PARM
               IF NP-STATUS NOT = STATUS-OK
                   ADD 1 TO TEST-FAILURES
               ELSE
                   INITIALIZE NET-PARM
                   MOVE NET-CLOSE TO NP-OPERATION
                   CALL "NETIO" USING NET-PARM
                   IF NP-STATUS NOT = STATUS-OK
                       ADD 1 TO TEST-FAILURES
                   END-IF
               END-IF
           END-PERFORM
           IF FT-VALID NOT = FLAG-ON OR
              FT-PENDING NOT = FLAG-OFF OR
              FT-SHUTDOWN-COUNT NOT = 4 OR
              FT-GET-ERROR-COUNT NOT = 3
               ADD 1 TO TEST-FAILURES
           END-IF
           IF TEST-FAILURES = ZERO
               DISPLAY "PASS TLS CLOSE"
               MOVE ZERO TO RETURN-CODE
           ELSE
               DISPLAY "FAIL TLS CLOSE " TEST-FAILURES " "
                   FT-SHUTDOWN-COUNT " " FT-GET-ERROR-COUNT
               MOVE 1 TO RETURN-CODE
           END-IF
           GOBACK.

       END PROGRAM TSTTLSCL.
