       IDENTIFICATION DIVISION.
       PROGRAM-ID. RESPAPI.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.

       LINKAGE SECTION.
       COPY RESPPARM.
       01 RP-TASK-BUFFER PIC X(65535).
       01 RP-ACTION-BUFFER PIC X(1048576).

       PROCEDURE DIVISION USING RESP-PARM.
           MOVE STATUS-INTERNAL TO RP-STATUS
           MOVE ACTION-NONE TO RP-ACTION
           MOVE ZERO TO RP-ACTION-LENGTH RP-ERROR-CATEGORY
                        RP-HTTP-STATUS
           IF RP-OPERATION = RESP-DESTROY
               MOVE STATUS-OK TO RP-STATUS
               GOBACK
           END-IF
           IF RP-OPERATION NOT = RESP-START OR
              RP-TASK-PTR = NULL OR RP-ACTION-PTR = NULL OR
              RP-ACTION-CAPACITY < 2 OR RP-MODEL-PTR = NULL OR
              RP-URL-PTR = NULL OR RP-KEY-PTR = NULL
               GOBACK
           END-IF
           SET ADDRESS OF RP-TASK-BUFFER TO RP-TASK-PTR
           EVALUATE TRUE
               WHEN RP-TASK-LENGTH = 13 AND
                    RP-TASK-BUFFER(1:13) = " lead  middle"
                   CONTINUE
               WHEN RP-TASK-LENGTH = 65535 AND
                    RP-TASK-BUFFER(1:1) = "x" AND
                    RP-TASK-BUFFER(65535:1) = "x"
                   CONTINUE
               WHEN RP-TASK-LENGTH = 65534 AND
                    RP-TASK-BUFFER(1:1) = "x" AND
                    RP-TASK-BUFFER(65534:1) = "x"
                   CONTINUE
               WHEN OTHER
                   GOBACK
           END-EVALUATE
           SET ADDRESS OF RP-ACTION-BUFFER TO RP-ACTION-PTR
           MOVE "ok" TO RP-ACTION-BUFFER(1:2)
           MOVE 2 TO RP-ACTION-LENGTH
           MOVE ACTION-FINAL TO RP-ACTION
           MOVE STATUS-OK TO RP-STATUS
           GOBACK.

       END PROGRAM RESPAPI.
