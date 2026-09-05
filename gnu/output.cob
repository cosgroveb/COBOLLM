       IDENTIFICATION DIVISION.
       PROGRAM-ID. OUTPUT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY POSIXNAT.
       01 WS-CURRENT-PTR          USAGE POINTER.
       01 WS-REMAINING            PIC 9(18) COMP-5.
       01 WS-ERRNO                PIC S9(9) COMP-5 BASED.

       LINKAGE SECTION.
       COPY OUTPARM.

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
               CALL STATIC "write" USING
                   BY VALUE SIZE IS 4 OP-FILE-DESCRIPTOR
                   BY VALUE WS-CURRENT-PTR
                   BY VALUE WS-REMAINING
                   RETURNING GNU-NATIVE-RESULT
               IF GNU-NATIVE-RESULT > ZERO
                   IF GNU-NATIVE-RESULT > WS-REMAINING
                       MOVE STATUS-OUTPUT TO OP-STATUS
                       GOBACK
                   END-IF
                   SET WS-CURRENT-PTR UP BY GNU-NATIVE-RESULT
                   ADD GNU-NATIVE-RESULT TO OP-WRITTEN
                   SUBTRACT GNU-NATIVE-RESULT FROM WS-REMAINING
               ELSE
                   IF GNU-NATIVE-RESULT = ZERO
                       MOVE STATUS-OUTPUT TO OP-STATUS
                       GOBACK
                   END-IF
                   CALL STATIC "__errno_location"
                       RETURNING GNU-ERRNO-PTR
                   IF GNU-ERRNO-PTR = NULL
                       MOVE STATUS-OUTPUT TO OP-STATUS
                       GOBACK
                   END-IF
                   SET ADDRESS OF WS-ERRNO TO GNU-ERRNO-PTR
                   IF WS-ERRNO NOT = GNU-EINTR
                       MOVE STATUS-OUTPUT TO OP-STATUS
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM
           MOVE STATUS-OK TO OP-STATUS
           GOBACK.

       END PROGRAM OUTPUT.
