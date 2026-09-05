       IDENTIFICATION DIVISION.
       PROGRAM-ID. ZOSLNCHR.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY CLIPARM.
       01 WS-CONTENT-LENGTH       PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01 LK-ARGC                 PIC S9(9) COMP-5.
       01 LK-LENGTH-ARRAY.
           05 LK-LENGTH-PTR       USAGE POINTER OCCURS 65536 TIMES.
       01 LK-VALUE-ARRAY.
           05 LK-VALUE-PTR        USAGE POINTER OCCURS 65536 TIMES.
       01 LK-ARG-LENGTH           PIC S9(9) COMP-5.
       01 LK-ARG-VALUE            PIC X(65536).

       PROCEDURE DIVISION USING LK-ARGC LK-LENGTH-ARRAY
           LK-VALUE-ARRAY.
           INITIALIZE CLI-PARM
           MOVE PLATFORM-ZOS TO CLI-PLATFORM
           IF LK-ARGC < 1 OR LK-ARGC > LIMIT-ZOS-ARGV
               MOVE STATUS-INTERNAL TO CLI-STATUS
               MOVE ZERO TO CLI-ARG-COUNT
           ELSE
               COMPUTE CLI-ARG-COUNT = LK-ARGC - 1
           END-IF
           IF CLI-STATUS = STATUS-OK AND CLI-ARG-COUNT = 1
               IF LK-LENGTH-PTR(2) = NULL OR
                  LK-VALUE-PTR(2) = NULL
                   MOVE STATUS-INTERNAL TO CLI-STATUS
               ELSE
                   SET ADDRESS OF LK-ARG-LENGTH TO
                       LK-LENGTH-PTR(2)
                   IF LK-ARG-LENGTH < 1
                       MOVE STATUS-INTERNAL TO CLI-STATUS
                   ELSE
                       IF LK-ARG-LENGTH > LIMIT-ZOS-ARGV
                           MOVE STATUS-CAPACITY TO CLI-STATUS
                       ELSE
                           SET ADDRESS OF LK-ARG-VALUE TO
                               LK-VALUE-PTR(2)
                       END-IF
                       IF CLI-STATUS = STATUS-OK
                           IF LK-ARG-VALUE(LK-ARG-LENGTH:1) = X"00"
                               COMPUTE WS-CONTENT-LENGTH =
                                   LK-ARG-LENGTH - 1
                               PERFORM UNTIL
                                   WS-CONTENT-LENGTH = ZERO OR
                                   LK-ARG-VALUE(
                                       WS-CONTENT-LENGTH:1)
                                       NOT = SPACE
                                   SUBTRACT 1 FROM WS-CONTENT-LENGTH
                               END-PERFORM
                               MOVE WS-CONTENT-LENGTH TO
                                   CLI-TASK-LENGTH
                               IF WS-CONTENT-LENGTH > ZERO
                                   MOVE LK-ARG-VALUE(
                                       1:WS-CONTENT-LENGTH) TO
                                       CLI-TASK(1:WS-CONTENT-LENGTH)
                               END-IF
                           ELSE
                               MOVE STATUS-INTERNAL TO CLI-STATUS
                           END-IF
                       END-IF
                   END-IF
               END-IF
           END-IF
           CALL "COBOLLM" USING CLI-PARM
           MOVE CLI-EXIT-CODE TO RETURN-CODE
           GOBACK.

       END PROGRAM ZOSLNCHR.
