       IDENTIFICATION DIVISION.
       PROGRAM-ID. SHELL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY POSIXNAT.
       01 WS-INVOKE               PIC X(65546).
       01 WS-PREFIX               PIC X(10)
           VALUE X"6578656320323E26310A".
       01 WS-READ-PTR             USAGE POINTER.
       01 WS-COUNT                PIC 9(18) COMP-5.
       01 WS-WANT                 PIC 9(18) COMP-5.
       01 WS-ONE                  PIC 9(18) COMP-5 VALUE 1.
       01 WS-INT-RESULT           PIC S9(9) COMP-5.
       01 WS-WAIT                 PIC S9(9) COMP-5.
       01 WS-LOW-SEVEN            PIC S9(9) COMP-5.
       01 WS-FAILED               PIC X.

       LINKAGE SECTION.
       COPY SHLPARM.
       01 SP-COMMAND              PIC X(65535) BASED.
       01 SP-OUTPUT               PIC X(1048576) BASED.

       PROCEDURE DIVISION USING SHELL-PARM.
           MOVE STATUS-INTERNAL TO SP-STATUS
           MOVE ZERO TO SP-OUTPUT-LENGTH SP-RESULT-KIND
                        SP-EXIT-CODE SP-SIGNAL
           MOVE FLAG-OFF TO SP-TRUNCATED
           MOVE FLAG-OFF TO WS-FAILED
           SET GNU-STREAM-PTR TO NULL
           MOVE LOW-VALUES TO WS-INVOKE
           IF SP-COMMAND-PTR = NULL OR SP-OUTPUT-PTR = NULL OR
              SP-COMMAND-LENGTH < ZERO OR
              SP-COMMAND-LENGTH > LIMIT-COMMAND OR
              SP-OUTPUT-CAPACITY < ZERO OR
              SP-OUTPUT-CAPACITY > LIMIT-SHELL-OUTPUT
               GOBACK
           END-IF
           SET ADDRESS OF SP-COMMAND TO SP-COMMAND-PTR
           SET ADDRESS OF SP-OUTPUT TO SP-OUTPUT-PTR
           MOVE WS-PREFIX TO WS-INVOKE(1:LIMIT-SHELL-PREFIX)
           IF SP-COMMAND-LENGTH > ZERO
               MOVE SP-COMMAND(1:SP-COMMAND-LENGTH) TO
                   WS-INVOKE(11:SP-COMMAND-LENGTH)
           END-IF
           MOVE X"00" TO WS-INVOKE(SP-COMMAND-LENGTH + 11:1)
           CALL STATIC "popen" USING
               BY REFERENCE WS-INVOKE
               BY REFERENCE GNU-POPEN-MODE
               RETURNING GNU-STREAM-PTR
           IF GNU-STREAM-PTR = NULL
               MOVE STATUS-SHELL TO SP-STATUS
               PERFORM ERASE-STAGING
               GOBACK
           END-IF
           PERFORM UNTIL WS-FAILED = FLAG-ON
               IF SP-OUTPUT-LENGTH < SP-OUTPUT-CAPACITY
                   COMPUTE WS-WANT =
                       SP-OUTPUT-CAPACITY - SP-OUTPUT-LENGTH
                   IF WS-WANT > LIMIT-NET-CHUNK
                       MOVE LIMIT-NET-CHUNK TO WS-WANT
                   END-IF
                   SET WS-READ-PTR TO SP-OUTPUT-PTR
                   SET WS-READ-PTR UP BY SP-OUTPUT-LENGTH
               ELSE
                   MOVE LIMIT-NET-CHUNK TO WS-WANT
                   SET WS-READ-PTR TO ADDRESS OF WS-INVOKE
               END-IF
               CALL STATIC "fread" USING
                   BY VALUE WS-READ-PTR
                   BY VALUE WS-ONE
                   BY VALUE WS-WANT
                   BY VALUE GNU-STREAM-PTR
                   RETURNING WS-COUNT
               EVALUATE TRUE
                   WHEN WS-COUNT > WS-WANT
                       MOVE FLAG-ON TO WS-FAILED
                   WHEN WS-COUNT > ZERO
                       IF SP-OUTPUT-LENGTH < SP-OUTPUT-CAPACITY
                           ADD WS-COUNT TO SP-OUTPUT-LENGTH
                       ELSE
                           MOVE FLAG-ON TO SP-TRUNCATED
                       END-IF
                   WHEN OTHER
                       CALL STATIC "ferror" USING
                           BY VALUE GNU-STREAM-PTR
                           RETURNING WS-INT-RESULT
                       IF WS-INT-RESULT NOT = ZERO
                           MOVE FLAG-ON TO WS-FAILED
                       ELSE
                           CALL STATIC "feof" USING
                               BY VALUE GNU-STREAM-PTR
                               RETURNING WS-INT-RESULT
                           IF WS-INT-RESULT = ZERO
                               MOVE FLAG-ON TO WS-FAILED
                           ELSE
                               EXIT PERFORM
                           END-IF
                       END-IF
               END-EVALUATE
           END-PERFORM
           CALL STATIC "pclose" USING
               BY VALUE GNU-STREAM-PTR
               RETURNING WS-WAIT
           SET GNU-STREAM-PTR TO NULL
           IF WS-FAILED = FLAG-ON OR WS-WAIT < ZERO
               MOVE ZERO TO SP-OUTPUT-LENGTH SP-RESULT-KIND
               MOVE STATUS-SHELL TO SP-STATUS
               PERFORM ERASE-STAGING
               GOBACK
           END-IF
           COMPUTE WS-LOW-SEVEN = FUNCTION MOD(WS-WAIT 128)
           IF WS-LOW-SEVEN = ZERO
               MOVE SHELL-EXIT TO SP-RESULT-KIND
               COMPUTE SP-EXIT-CODE =
                   FUNCTION MOD(WS-WAIT / 256 256)
           ELSE
               MOVE SHELL-SIGNAL TO SP-RESULT-KIND
               MOVE WS-LOW-SEVEN TO SP-SIGNAL
           END-IF
           MOVE STATUS-OK TO SP-STATUS
           PERFORM ERASE-STAGING
           GOBACK.

       ERASE-STAGING.
           MOVE LOW-VALUES TO WS-INVOKE
           SET WS-READ-PTR TO NULL.

       END PROGRAM SHELL.
