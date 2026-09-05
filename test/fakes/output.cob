       IDENTIFICATION DIVISION.
       PROGRAM-ID. OUTPUT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY FOCTRL.

       LINKAGE SECTION.
       COPY OUTPARM.
       01  OP-BUFFER                PIC X(16777216).

       PROCEDURE DIVISION USING OUTPUT-PARM.
           MOVE STATUS-INTERNAL TO OP-STATUS
           MOVE ZERO TO OP-WRITTEN
           ADD 1 TO FO-CALL-COUNT
           IF FO-FAIL-CALL > ZERO AND
              FO-CALL-COUNT = FO-FAIL-CALL
               MOVE STATUS-OUTPUT TO OP-STATUS
               GOBACK
           END-IF
           IF OP-BUFFER-LENGTH < ZERO OR
              (OP-BUFFER-LENGTH > ZERO AND OP-BUFFER-PTR = NULL)
               GOBACK
           END-IF
           IF OP-FILE-DESCRIPTOR NOT = OUTPUT-STDOUT AND
              OP-FILE-DESCRIPTOR NOT = OUTPUT-STDERR
               GOBACK
           END-IF
           IF OP-BUFFER-LENGTH > ZERO
               SET ADDRESS OF OP-BUFFER TO OP-BUFFER-PTR
               IF OP-FILE-DESCRIPTOR = OUTPUT-STDOUT
                   IF FO-STDOUT-LENGTH > 8192 - OP-BUFFER-LENGTH
                       MOVE STATUS-CAPACITY TO OP-STATUS
                       GOBACK
                   END-IF
                   MOVE OP-BUFFER(1:OP-BUFFER-LENGTH) TO
                       FO-STDOUT(FO-STDOUT-LENGTH + 1:
                           OP-BUFFER-LENGTH)
                   ADD OP-BUFFER-LENGTH TO FO-STDOUT-LENGTH
               ELSE
                   IF FO-STDERR-LENGTH > 8192 - OP-BUFFER-LENGTH
                       MOVE STATUS-CAPACITY TO OP-STATUS
                       GOBACK
                   END-IF
                   MOVE OP-BUFFER(1:OP-BUFFER-LENGTH) TO
                       FO-STDERR(FO-STDERR-LENGTH + 1:
                           OP-BUFFER-LENGTH)
                   ADD OP-BUFFER-LENGTH TO FO-STDERR-LENGTH
               END-IF
           END-IF
           MOVE OP-BUFFER-LENGTH TO OP-WRITTEN
           MOVE STATUS-OK TO OP-STATUS
           GOBACK.

       END PROGRAM OUTPUT.
