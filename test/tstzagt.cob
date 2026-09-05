       IDENTIFICATION DIVISION.
       PROGRAM-ID. TSTZAGT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY CLIPARM.
       COPY FRCTRL.
       COPY FSCTRL.
       COPY FOCTRL.
       01  WS-KEY-NAME.
           05 FILLER PIC X(14) VALUE "OPENAI_API_KEY".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-MODEL-NAME.
           05 FILLER PIC X(12) VALUE "OPENAI_MODEL".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-URL-NAME.
           05 FILLER PIC X(15) VALUE "OPENAI_BASE_URL".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-KEY-VALUE.
           05 FILLER PIC X(11) VALUE "test-secret".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-MODEL-VALUE.
           05 FILLER PIC X(8) VALUE "gpt-test".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-URL-VALUE.
           05 FILLER PIC X(15) VALUE "https://example".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-OVERWRITE PIC S9(9) COMP-5 VALUE 1.
       01  WS-NATIVE-RESULT PIC S9(9) COMP-5.
       01  WS-FAILURES PIC S9(9) COMP-5 VALUE ZERO.
       01  WS-LONG-ENV PIC X(8194).
       01  C-HAPPY-STDERR.
           05 FILLER PIC X(22) VALUE "COBOLLM shell command:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(9) VALUE "printf ok".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(21) VALUE "COBOLLM shell result:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(11) VALUE "status=exit".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(11) VALUE "exit_code=0".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(11) VALUE "signal=none".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(15) VALUE "truncated=false".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(19) VALUE "encoding_loss=false".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(7) VALUE "output:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(12) VALUE "shell output".
           05 FILLER PIC X VALUE X"25".
       01  C-LOSS-STDERR.
           05 FILLER PIC X(22) VALUE "COBOLLM shell command:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(9) VALUE "printf ok".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(21) VALUE "COBOLLM shell result:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(11) VALUE "status=exit".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(11) VALUE "exit_code=0".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(11) VALUE "signal=none".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(15) VALUE "truncated=false".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(18) VALUE "encoding_loss=true".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(7) VALUE "output:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X VALUE X"6F".
           05 FILLER PIC X VALUE X"25".
       01  C-FINAL-WARNING.
           05 FILLER PIC X(50) VALUE
               "COBOLLM: warning: final response used replacement ".
           05 FILLER PIC X(41) VALUE
               "characters during native text conversion.".
           05 FILLER PIC X VALUE X"25".
       01  C-ENCODING-STDERR.
           05 FILLER PIC X(22) VALUE "COBOLLM shell command:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(37) VALUE
               "[command unavailable: encoding error]".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(21) VALUE "COBOLLM shell result:".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(29) VALUE
               "status=command-encoding-error".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(14) VALUE "exit_code=none".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(11) VALUE "signal=none".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(15) VALUE "truncated=false".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(19) VALUE "encoding_loss=false".
           05 FILLER PIC X VALUE X"25".
           05 FILLER PIC X(7) VALUE "output:".
           05 FILLER PIC X VALUE X"25".

       PROCEDURE DIVISION.
           PERFORM TEST-HAPPY
           PERFORM TEST-SHELL-OUTPUT-LOSS
           PERFORM TEST-UNREPRESENTABLE-COMMAND
           PERFORM TEST-FINAL-REPLACEMENT
           PERFORM TEST-BOUNDARY-MINUS
           IF WS-FAILURES = ZERO
               DISPLAY "PASS ZOS AGENT"
               MOVE ZERO TO RETURN-CODE
           ELSE
               DISPLAY "FAIL ZOS AGENT"
               MOVE 1 TO RETURN-CODE
           END-IF
           GOBACK.

       TEST-HAPPY.
           PERFORM RESET-FAKES
           PERFORM SET-ENVIRONMENT
           PERFORM SETUP-CLI
           CALL "COBOLLM" USING CLI-PARM
           IF CLI-EXIT-CODE NOT = EXIT-OK OR
              FR-CALL-COUNT NOT = 2 OR
              FR-CONTINUE-COUNT NOT = 1 OR
              FR-DESTROY-COUNT NOT = 1 OR
              FR-VALID NOT = FLAG-ON OR
              FR-KEY-SEEN NOT = FLAG-ON OR
              FR-KEY-ENV-ABSENT NOT = FLAG-ON OR
              FR-DESTROY-VALID NOT = FLAG-ON OR
              FS-CALL-COUNT NOT = 1 OR FS-VALID NOT = FLAG-ON OR
              FS-KEY-ENV-ABSENT NOT = FLAG-ON OR
              FO-CALL-COUNT NOT = 8 OR
              FO-STDOUT-LENGTH NOT = 10 OR
              FO-STDOUT(1:10) NOT = "agent done" OR
              FO-STDERR-LENGTH NOT = 148 OR
              FO-STDERR(1:148) NOT = C-HAPPY-STDERR
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SHELL-OUTPUT-LOSS.
           PERFORM RESET-FAKES
           MOVE 14 TO FR-MODE
           MOVE 9 TO FS-MODE
           PERFORM SET-ENVIRONMENT
           PERFORM SETUP-CLI
           CALL "COBOLLM" USING CLI-PARM
           IF CLI-EXIT-CODE NOT = EXIT-OK OR
              FR-CALL-COUNT NOT = 2 OR
              FR-CONTINUE-COUNT NOT = 1 OR
              FR-DESTROY-COUNT NOT = 1 OR
              FR-VALID NOT = FLAG-ON OR
              FR-KEY-SEEN NOT = FLAG-ON OR
              FR-KEY-ENV-ABSENT NOT = FLAG-ON OR
              FR-DESTROY-VALID NOT = FLAG-ON OR
              FS-CALL-COUNT NOT = 1 OR FS-VALID NOT = FLAG-ON OR
              FS-KEY-ENV-ABSENT NOT = FLAG-ON OR
              FO-CALL-COUNT NOT = 8 OR
              FO-STDOUT-LENGTH NOT = 10 OR
              FO-STDOUT(1:10) NOT = "agent done" OR
              FO-STDERR-LENGTH NOT = 136 OR
              FO-STDERR(1:136) NOT = C-LOSS-STDERR
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-UNREPRESENTABLE-COMMAND.
           PERFORM RESET-FAKES
           MOVE 12 TO FR-MODE
           PERFORM SET-ENVIRONMENT
           PERFORM SETUP-CLI
           CALL "COBOLLM" USING CLI-PARM
           IF CLI-EXIT-CODE NOT = EXIT-OK OR
              FR-CALL-COUNT NOT = 2 OR
              FR-CONTINUE-COUNT NOT = 1 OR
              FR-DESTROY-COUNT NOT = 1 OR
              FR-VALID NOT = FLAG-ON OR
              FR-KEY-SEEN NOT = FLAG-ON OR
              FR-KEY-ENV-ABSENT NOT = FLAG-ON OR
              FR-DESTROY-VALID NOT = FLAG-ON OR
              FS-CALL-COUNT NOT = ZERO OR
              FO-CALL-COUNT NOT = 8 OR
              FO-STDOUT-LENGTH NOT = 10 OR
              FO-STDOUT(1:10) NOT = "agent done" OR
              FO-STDERR-LENGTH NOT = 184 OR
              FO-STDERR(1:184) NOT = C-ENCODING-STDERR
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FINAL-REPLACEMENT.
           PERFORM RESET-FAKES
           MOVE 13 TO FR-MODE
           PERFORM SET-ENVIRONMENT
           PERFORM SETUP-CLI
           CALL "COBOLLM" USING CLI-PARM
           IF CLI-EXIT-CODE NOT = EXIT-OK OR
              FR-CALL-COUNT NOT = 1 OR
              FR-DESTROY-COUNT NOT = 1 OR
              FR-KEY-SEEN NOT = FLAG-ON OR
              FR-KEY-ENV-ABSENT NOT = FLAG-ON OR
              FR-DESTROY-VALID NOT = FLAG-ON OR
              FS-CALL-COUNT NOT = ZERO OR
              FO-STDOUT-LENGTH NOT = 3 OR
              FO-STDOUT(1:3) NOT = X"C16FC2" OR
              FO-STDERR-LENGTH NOT = 92 OR
              FO-STDERR(1:92) NOT = C-FINAL-WARNING
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BOUNDARY-MINUS.
           PERFORM RESET-FAKES
           PERFORM SET-ENVIRONMENT
           PERFORM SETUP-CLI
           MOVE ALL "t" TO CLI-TASK
           MOVE 65534 TO CLI-TASK-LENGTH
           PERFORM RUN-BOUNDARY

           PERFORM RESET-FAKES
           PERFORM SET-ENVIRONMENT
           MOVE LOW-VALUES TO WS-LONG-ENV
           MOVE ALL "m" TO WS-LONG-ENV(1:255)
           CALL "TSTSETENV" USING BY REFERENCE WS-MODEL-NAME
               BY REFERENCE WS-LONG-ENV
               BY REFERENCE WS-OVERWRITE
               RETURNING WS-NATIVE-RESULT
           PERFORM SETUP-CLI
           PERFORM RUN-BOUNDARY

           PERFORM RESET-FAKES
           PERFORM SET-ENVIRONMENT
           MOVE LOW-VALUES TO WS-LONG-ENV
           MOVE ALL "k" TO WS-LONG-ENV(1:8191)
           CALL "TSTSETENV" USING BY REFERENCE WS-KEY-NAME
               BY REFERENCE WS-LONG-ENV
               BY REFERENCE WS-OVERWRITE
               RETURNING WS-NATIVE-RESULT
           PERFORM SETUP-CLI
           PERFORM RUN-BOUNDARY

           PERFORM RESET-FAKES
           PERFORM SET-ENVIRONMENT
           MOVE LOW-VALUES TO WS-LONG-ENV
           MOVE "https://example/" TO WS-LONG-ENV(1:16)
           MOVE ALL "a" TO WS-LONG-ENV(17:2031)
           CALL "TSTSETENV" USING BY REFERENCE WS-URL-NAME
               BY REFERENCE WS-LONG-ENV
               BY REFERENCE WS-OVERWRITE
               RETURNING WS-NATIVE-RESULT
           PERFORM SETUP-CLI
           PERFORM RUN-BOUNDARY.

       RUN-BOUNDARY.
           IF WS-NATIVE-RESULT NOT = ZERO
               ADD 1 TO WS-FAILURES
           END-IF
           CALL "COBOLLM" USING CLI-PARM
           IF CLI-EXIT-CODE NOT = EXIT-OK OR
              FR-CALL-COUNT NOT = 2 OR
              FR-DESTROY-COUNT NOT = 1 OR
              FS-CALL-COUNT NOT = 1
               ADD 1 TO WS-FAILURES
           END-IF.

       RESET-FAKES.
           INITIALIZE FAKE-RESP-CONTROL
           INITIALIZE FAKE-SHELL-CONTROL
           INITIALIZE FAKE-OUTPUT-CONTROL.

       SET-ENVIRONMENT.
           CALL "TSTSETENV" USING BY REFERENCE WS-KEY-NAME
               BY REFERENCE WS-KEY-VALUE
               BY REFERENCE WS-OVERWRITE
               RETURNING WS-NATIVE-RESULT
           IF WS-NATIVE-RESULT NOT = ZERO ADD 1 TO WS-FAILURES END-IF
           CALL "TSTSETENV" USING BY REFERENCE WS-MODEL-NAME
               BY REFERENCE WS-MODEL-VALUE
               BY REFERENCE WS-OVERWRITE
               RETURNING WS-NATIVE-RESULT
           IF WS-NATIVE-RESULT NOT = ZERO ADD 1 TO WS-FAILURES END-IF
           CALL "TSTSETENV" USING BY REFERENCE WS-URL-NAME
               BY REFERENCE WS-URL-VALUE
               BY REFERENCE WS-OVERWRITE
               RETURNING WS-NATIVE-RESULT
           IF WS-NATIVE-RESULT NOT = ZERO ADD 1 TO WS-FAILURES END-IF.

       SETUP-CLI.
           INITIALIZE CLI-PARM
           MOVE STATUS-OK TO CLI-STATUS
           MOVE PLATFORM-ZOS TO CLI-PLATFORM
           MOVE 1 TO CLI-ARG-COUNT
           MOVE 5 TO CLI-TASK-LENGTH
           MOVE "do it" TO CLI-TASK(1:5)
           MOVE 99 TO CLI-EXIT-CODE.

       END PROGRAM TSTZAGT.
