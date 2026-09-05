       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZOSLNCHR.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY CLIPARM.
       COPY POSIXNAT.
       01 WS-TASK-DD PIC X(8) VALUE X"C4C47AE3C1E2D200".
       01 WS-READ-MODE PIC X(3) VALUE X"998200".
       01 WS-TASK-BUFFER PIC X(65536).
       01 WS-READ-PTR USAGE POINTER.
       01 WS-COUNT PIC 9(9) COMP-5.
       01 WS-WANT PIC 9(9) COMP-5.
       01 WS-TOTAL PIC 9(9) COMP-5.
       01 WS-INT-RESULT PIC S9(9) COMP-5.
       01 WS-DONE PIC X.
       01 WS-FAILED PIC X.

       PROCEDURE DIVISION.
           INITIALIZE CLI-PARM
           MOVE PLATFORM-ZOS TO CLI-PLATFORM
           MOVE 1 TO CLI-ARG-COUNT
           MOVE LOW-VALUES TO WS-TASK-BUFFER
           SET ZOS-STREAM-PTR WS-READ-PTR TO NULL
           MOVE ZERO TO WS-TOTAL
           MOVE FLAG-OFF TO WS-DONE WS-FAILED
           CALL "fopen" USING
               BY VALUE ADDRESS OF WS-TASK-DD
               BY VALUE ADDRESS OF WS-READ-MODE
               RETURNING ZOS-STREAM-PTR
           IF ZOS-STREAM-PTR = NULL
               MOVE FLAG-ON TO WS-FAILED
           ELSE
               PERFORM READ-TASK
               CALL "fclose" USING BY VALUE ZOS-STREAM-PTR
                   RETURNING WS-INT-RESULT
               SET ZOS-STREAM-PTR TO NULL
               IF WS-INT-RESULT NOT = ZERO
                   MOVE FLAG-ON TO WS-FAILED
               END-IF
           END-IF
           IF WS-FAILED = FLAG-ON
               MOVE STATUS-INTERNAL TO CLI-STATUS
           ELSE
               IF WS-TOTAL > LIMIT-TASK
                   MOVE STATUS-CAPACITY TO CLI-STATUS
               ELSE
                   MOVE WS-TOTAL TO CLI-TASK-LENGTH
                   IF WS-TOTAL > ZERO
                       MOVE WS-TASK-BUFFER(1:WS-TOTAL) TO
                           CLI-TASK(1:WS-TOTAL)
                   END-IF
               END-IF
           END-IF
           MOVE LOW-VALUES TO WS-TASK-BUFFER
           SET WS-READ-PTR TO NULL
           CALL "COBOLLM" USING CLI-PARM
           MOVE CLI-EXIT-CODE TO RETURN-CODE
           GOBACK.

       READ-TASK.
           PERFORM UNTIL WS-DONE = FLAG-ON
               COMPUTE WS-WANT = 65536 - WS-TOTAL
               SET WS-READ-PTR TO ADDRESS OF WS-TASK-BUFFER
               SET WS-READ-PTR UP BY WS-TOTAL
               CALL "fread" USING
                   BY VALUE WS-READ-PTR BY VALUE 1 BY VALUE WS-WANT
                   BY VALUE ZOS-STREAM-PTR RETURNING WS-COUNT
               EVALUATE TRUE
                   WHEN WS-COUNT > WS-WANT
                       MOVE FLAG-ON TO WS-FAILED WS-DONE
                   WHEN WS-COUNT > ZERO
                       ADD WS-COUNT TO WS-TOTAL
                       IF WS-TOTAL = 65536
                           MOVE FLAG-ON TO WS-DONE
                       END-IF
                   WHEN OTHER
                       CALL "ferror" USING BY VALUE ZOS-STREAM-PTR
                           RETURNING WS-INT-RESULT
                       IF WS-INT-RESULT NOT = ZERO
                           MOVE FLAG-ON TO WS-FAILED WS-DONE
                       ELSE
                           CALL "feof" USING BY VALUE ZOS-STREAM-PTR
                               RETURNING WS-INT-RESULT
                           IF WS-INT-RESULT = ZERO
                               MOVE FLAG-ON TO WS-FAILED
                           END-IF
                           MOVE FLAG-ON TO WS-DONE
                       END-IF
               END-EVALUATE
           END-PERFORM.

       END PROGRAM ZOSLNCHR.
