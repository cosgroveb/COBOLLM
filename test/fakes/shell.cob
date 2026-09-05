       IDENTIFICATION DIVISION.
       PROGRAM-ID. SHELL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY FSCTRL.
       01  WS-EXPECTED-COMMAND      PIC X(9) VALUE "printf ok".
       01  WS-KEY-NAME.
           05 FILLER PIC X(14) VALUE "OPENAI_API_KEY".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-ENV-PTR               USAGE POINTER.

       LINKAGE SECTION.
       COPY SHLPARM.
       01  SP-COMMAND               PIC X(65535).
       01  SP-OUTPUT                PIC X(1048576).

       PROCEDURE DIVISION USING SHELL-PARM.
           MOVE STATUS-INTERNAL TO SP-STATUS
           MOVE ZERO TO SP-OUTPUT-LENGTH SP-RESULT-KIND
                        SP-EXIT-CODE SP-SIGNAL
           MOVE FLAG-OFF TO SP-TRUNCATED
           ADD 1 TO FS-CALL-COUNT
           CALL "getenv" USING BY REFERENCE WS-KEY-NAME
               RETURNING WS-ENV-PTR
           IF WS-ENV-PTR = NULL
               MOVE FLAG-ON TO FS-KEY-ENV-ABSENT
           END-IF
           IF SP-COMMAND-PTR = NULL OR SP-COMMAND-LENGTH < ZERO OR
              SP-OUTPUT-PTR = NULL OR SP-OUTPUT-CAPACITY < ZERO
               GOBACK
           END-IF
           SET ADDRESS OF SP-COMMAND TO SP-COMMAND-PTR
           MOVE SP-COMMAND-LENGTH TO FS-LAST-LENGTH
           IF SP-COMMAND-LENGTH <= 64
               MOVE SPACES TO FS-LAST-COMMAND
               MOVE SP-COMMAND(1:SP-COMMAND-LENGTH) TO
                   FS-LAST-COMMAND(1:SP-COMMAND-LENGTH)
           END-IF
           IF (SP-COMMAND-LENGTH = 9 OR
               (FS-MODE = 8 AND SP-COMMAND-LENGTH = 10 AND
                SP-COMMAND(10:1) = X"0A")) AND
              SP-COMMAND(1:9) = WS-EXPECTED-COMMAND
               MOVE FLAG-ON TO FS-VALID
           END-IF
           IF FS-MODE = 1
               MOVE STATUS-SHELL TO SP-STATUS
               GOBACK
           END-IF
           IF FS-VALID NOT = FLAG-ON OR SP-OUTPUT-CAPACITY < 12
               GOBACK
           END-IF
           SET ADDRESS OF SP-OUTPUT TO SP-OUTPUT-PTR
           IF FS-MODE = 9
               MOVE X"C0" TO SP-OUTPUT(1:1)
               MOVE 1 TO SP-OUTPUT-LENGTH
               MOVE SHELL-EXIT TO SP-RESULT-KIND
               MOVE STATUS-OK TO SP-STATUS
               GOBACK
           END-IF
           MOVE "shell output" TO SP-OUTPUT(1:12)
           MOVE 12 TO SP-OUTPUT-LENGTH
           IF FS-MODE = 10
               MOVE SHELL-SIGNAL TO SP-RESULT-KIND
               MOVE 15 TO SP-SIGNAL
               MOVE FLAG-ON TO SP-TRUNCATED
               MOVE STATUS-OK TO SP-STATUS
               GOBACK
           END-IF
           IF FS-MODE = 8
               MOVE X"0A" TO SP-OUTPUT(13:1)
               MOVE 13 TO SP-OUTPUT-LENGTH
           END-IF
           MOVE SHELL-EXIT TO SP-RESULT-KIND
           MOVE STATUS-OK TO SP-STATUS
           GOBACK.

       END PROGRAM SHELL.
