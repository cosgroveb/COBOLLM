       IDENTIFICATION DIVISION.
       PROGRAM-ID. TSTRESLV.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY NETPARM.
       COPY FGCTRL.
       01  WS-HOST                 PIC X(254).
       01  WS-VERIFY               PIC X(254).
       01  WS-HOST-LENGTH          PIC S9(9) COMP-5.
       01  WS-PORT                 PIC S9(9) COMP-5.
       01  WS-SAVED-CALLS          PIC S9(9) COMP-5.
       01  WS-FAILURES             PIC S9(9) COMP-5 VALUE ZERO.

       PROCEDURE DIVISION.
           INITIALIZE FAKE-GETADDR-CONTROL
           MOVE ALL "a" TO WS-HOST WS-VERIFY
           MOVE 252 TO WS-HOST-LENGTH
           MOVE 1 TO WS-PORT
           PERFORM OPEN-AND-CLOSE
           IF FG-CALL-COUNT NOT = 1 OR FG-FREE-COUNT NOT = 1 OR
              FG-VALID NOT = FLAG-ON OR FG-NODE-LENGTH NOT = 252 OR
              FG-NODE(1:252) NOT = WS-HOST(1:252) OR
              FG-NODE(253:2) NOT = LOW-VALUES OR
              FG-SERVICE-LENGTH NOT = 1 OR
              FG-SERVICE(1:1) NOT = "1" OR
              FG-SERVICE(2:5) NOT = LOW-VALUES
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE ALL "b" TO WS-HOST WS-VERIFY
           MOVE 253 TO WS-HOST-LENGTH
           MOVE 65535 TO WS-PORT
           PERFORM OPEN-AND-CLOSE
           IF FG-CALL-COUNT NOT = 2 OR FG-FREE-COUNT NOT = 2 OR
              FG-VALID NOT = FLAG-ON OR FG-NODE-LENGTH NOT = 253 OR
              FG-NODE(1:253) NOT = WS-HOST(1:253) OR
              FG-NODE(254:1) NOT = X"00" OR
              FG-SERVICE-LENGTH NOT = 5 OR
              FG-SERVICE(1:5) NOT = "65535" OR
              FG-SERVICE(6:1) NOT = X"00"
               ADD 1 TO WS-FAILURES
           END-IF

      * A short open after long staging exposes stale-byte mistakes.
           MOVE LOW-VALUES TO WS-HOST WS-VERIFY
           MOVE "x" TO WS-HOST WS-VERIFY
           MOVE 1 TO WS-HOST-LENGTH
           ACCEPT WS-PORT FROM ENVIRONMENT
               "COBOLLM_TEST_RESOLVE_PORT"
           PERFORM OPEN-AND-CLOSE
           IF FG-CALL-COUNT NOT = 3 OR FG-FREE-COUNT NOT = 3 OR
              FG-VALID NOT = FLAG-ON OR FG-NODE-LENGTH NOT = 1 OR
              FG-NODE(1:1) NOT = "x" OR
              FG-NODE(2:253) NOT = LOW-VALUES OR
              FG-SERVICE(FG-SERVICE-LENGTH + 1:
                         6 - FG-SERVICE-LENGTH) NOT = LOW-VALUES
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE FG-CALL-COUNT TO WS-SAVED-CALLS
           MOVE ALL "c" TO WS-HOST WS-VERIFY
           MOVE 254 TO WS-HOST-LENGTH
           MOVE 443 TO WS-PORT
           PERFORM OPEN-ONLY
           IF NP-STATUS NOT = STATUS-CAPACITY OR
              FG-CALL-COUNT NOT = WS-SAVED-CALLS
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE 253 TO WS-HOST-LENGTH
           MOVE ZERO TO WS-PORT
           PERFORM OPEN-ONLY
           IF NP-STATUS NOT = STATUS-INTERNAL OR
              FG-CALL-COUNT NOT = WS-SAVED-CALLS
               ADD 1 TO WS-FAILURES
           END-IF
           MOVE 65536 TO WS-PORT
           PERFORM OPEN-ONLY
           IF NP-STATUS NOT = STATUS-INTERNAL OR
              FG-CALL-COUNT NOT = WS-SAVED-CALLS
               ADD 1 TO WS-FAILURES
           END-IF

           IF WS-FAILURES = ZERO
               DISPLAY "PASS RESOLVER"
               MOVE ZERO TO RETURN-CODE
           ELSE
               DISPLAY "FAIL RESOLVER " WS-FAILURES
               MOVE 1 TO RETURN-CODE
           END-IF
           GOBACK.

       OPEN-AND-CLOSE.
           PERFORM OPEN-ONLY
           IF NP-STATUS NOT = STATUS-OK
               ADD 1 TO WS-FAILURES
           ELSE
               INITIALIZE NET-PARM
               MOVE NET-CLOSE TO NP-OPERATION
               CALL "NETIO" USING NET-PARM
               IF NP-STATUS NOT = STATUS-OK
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       OPEN-ONLY.
           INITIALIZE NET-PARM
           MOVE NET-OPEN TO NP-OPERATION
           MOVE NET-PLAINTEXT TO NP-SCHEME
           SET NP-CONNECT-HOST-PTR TO ADDRESS OF WS-HOST
           MOVE WS-HOST-LENGTH TO NP-CONNECT-HOST-LENGTH
           SET NP-VERIFY-HOST-PTR TO ADDRESS OF WS-VERIFY
           MOVE WS-HOST-LENGTH TO NP-VERIFY-HOST-LENGTH
           MOVE WS-PORT TO NP-PORT
           CALL "NETIO" USING NET-PARM.

       END PROGRAM TSTRESLV.
