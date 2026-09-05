       IDENTIFICATION DIVISION.
       PROGRAM-ID. OUTPUT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY POSIXNAT.
       01 WS-CURRENT-PTR          USAGE POINTER.
       01 WS-REMAINING            PIC 9(9) COMP-5.
       01 WS-ERRNO-PTR            USAGE POINTER.

       LINKAGE SECTION.
       COPY OUTPARM.
       01 LK-ERRNO                PIC S9(9) COMP-5.

       PROCEDURE DIVISION USING OUTPUT-PARM.
           MOVE STATUS-INTERNAL TO OP-STATUS
           MOVE ZERO TO OP-WRITTEN
           IF OP-FILE-DESCRIPTOR NOT = OUTPUT-STDOUT AND
              OP-FILE-DESCRIPTOR NOT = OUTPUT-STDERR
               GOBACK
           END-IF
           IF OP-BUFFER-LENGTH < ZERO
               GOBACK
           END-IF
           IF OP-BUFFER-LENGTH = ZERO
               MOVE STATUS-OK TO OP-STATUS
               GOBACK
           END-IF
           IF OP-BUFFER-PTR = NULL
               GOBACK
           END-IF
           SET WS-CURRENT-PTR TO OP-BUFFER-PTR
           MOVE OP-BUFFER-LENGTH TO WS-REMAINING
           PERFORM UNTIL WS-REMAINING = ZERO
               CALL "write" USING
                   BY VALUE OP-FILE-DESCRIPTOR
                   BY VALUE WS-CURRENT-PTR
                   BY VALUE WS-REMAINING
                   RETURNING ZOS-NATIVE-RESULT
               EVALUATE TRUE
                   WHEN ZOS-NATIVE-RESULT > ZERO AND
                        ZOS-NATIVE-RESULT <= WS-REMAINING
                       SET WS-CURRENT-PTR UP BY ZOS-NATIVE-RESULT
                       ADD ZOS-NATIVE-RESULT TO OP-WRITTEN
                       SUBTRACT ZOS-NATIVE-RESULT FROM WS-REMAINING
                   WHEN ZOS-NATIVE-RESULT = ZERO
                       MOVE STATUS-OUTPUT TO OP-STATUS
                       GOBACK
                   WHEN OTHER
                       CALL "__errno" RETURNING WS-ERRNO-PTR
                       IF WS-ERRNO-PTR = NULL
                           MOVE STATUS-OUTPUT TO OP-STATUS
                           GOBACK
                       END-IF
                       SET ADDRESS OF LK-ERRNO TO WS-ERRNO-PTR
                       IF LK-ERRNO NOT = ZOS-EINTR
                           MOVE STATUS-OUTPUT TO OP-STATUS
                           GOBACK
                       END-IF
               END-EVALUATE
           END-PERFORM
           MOVE STATUS-OK TO OP-STATUS
           GOBACK.

       END PROGRAM OUTPUT.
