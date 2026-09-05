       IDENTIFICATION DIVISION.
       PROGRAM-ID. RESPAPI.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY FRCTRL.
       01  WS-EXPECTED-OUTPUT       PIC X(12) VALUE
           X"7368656C6C206F7574707574".
       01  WS-KEY-NAME.
           05 FILLER PIC X(14) VALUE "OPENAI_API_KEY".
           05 FILLER PIC X VALUE LOW-VALUE.
       01  WS-ENV-PTR              USAGE POINTER.

       LINKAGE SECTION.
       COPY RESPPARM.
       01  RP-ACTION-BUFFER         PIC X(1048576).
       01  RP-SHELL-BUFFER          PIC X(1048576).
       01  RP-KEY-BUFFER            PIC X(8192).

       PROCEDURE DIVISION USING RESP-PARM.
           MOVE STATUS-INTERNAL TO RP-STATUS
           MOVE ACTION-NONE TO RP-ACTION
           MOVE ZERO TO RP-ACTION-LENGTH RP-ERROR-CATEGORY
                        RP-HTTP-STATUS
           IF RP-OPERATION = RESP-DESTROY
               ADD 1 TO FR-DESTROY-COUNT
               IF RP-MODEL-PTR = NULL AND RP-URL-PTR = NULL AND
                  RP-KEY-PTR = NULL AND RP-TASK-PTR = NULL AND
                  RP-SHELL-OUTPUT-PTR = NULL AND
                  RP-ACTION-PTR = NULL AND RP-KEY-LENGTH = ZERO
                   MOVE FLAG-ON TO FR-DESTROY-VALID
               END-IF
               MOVE STATUS-OK TO RP-STATUS
               GOBACK
           END-IF
           ADD 1 TO FR-CALL-COUNT
           CALL "getenv" USING BY REFERENCE WS-KEY-NAME
               RETURNING WS-ENV-PTR
           IF WS-ENV-PTR = NULL
               MOVE FLAG-ON TO FR-KEY-ENV-ABSENT
           END-IF
           IF RP-KEY-PTR NOT = NULL AND RP-KEY-LENGTH = 11
               SET ADDRESS OF RP-KEY-BUFFER TO RP-KEY-PTR
               IF RP-KEY-BUFFER(1:11) = "test-secret"
                   MOVE FLAG-ON TO FR-KEY-SEEN
               END-IF
           END-IF
           IF RP-URL-PTR NOT = NULL AND RP-URL-LENGTH = 25
               SET ADDRESS OF RP-KEY-BUFFER TO RP-URL-PTR
               IF RP-KEY-BUFFER(1:25) =
                  X"68747470733A2F2F6170692E6F70656E61692E636F6D2F7631"
                   MOVE FLAG-ON TO FR-DEFAULT-URL
               END-IF
           END-IF
           IF RP-ACTION-PTR = NULL OR RP-ACTION-CAPACITY < 10
               GOBACK
           END-IF
           SET ADDRESS OF RP-ACTION-BUFFER TO RP-ACTION-PTR
           IF RP-OPERATION = RESP-START
               PERFORM HANDLE-START
           ELSE
               IF RP-OPERATION = RESP-CONTINUE
                   PERFORM HANDLE-CONTINUE
               END-IF
           END-IF
           GOBACK.

       HANDLE-START.
           EVALUATE FR-MODE
               WHEN 4
                   MOVE ACTION-FINAL TO RP-ACTION
                   MOVE X"41FF42" TO RP-ACTION-BUFFER(1:3)
                   MOVE 3 TO RP-ACTION-LENGTH
                   MOVE STATUS-OK TO RP-STATUS
               WHEN 13
                   MOVE ACTION-FINAL TO RP-ACTION
                   MOVE X"41F09F988042" TO RP-ACTION-BUFFER(1:6)
                   MOVE 6 TO RP-ACTION-LENGTH
                   MOVE STATUS-OK TO RP-STATUS
               WHEN 5
                   MOVE STATUS-NETWORK TO RP-STATUS
                   MOVE CATEGORY-NETWORK TO RP-ERROR-CATEGORY
               WHEN 6
                   MOVE STATUS-HTTP-CODE TO RP-STATUS
                   MOVE 429 TO RP-HTTP-STATUS
                   MOVE CATEGORY-PROTOCOL TO RP-ERROR-CATEGORY
               WHEN 7
                   MOVE STATUS-CAPACITY TO RP-STATUS
                   MOVE CATEGORY-CAPACITY TO RP-ERROR-CATEGORY
               WHEN 3
                   MOVE ACTION-SHELL TO RP-ACTION
                   MOVE X"746573742D736563726574001B0D0A5C6E" TO
                       RP-ACTION-BUFFER(1:17)
                   MOVE 17 TO RP-ACTION-LENGTH
                   MOVE STATUS-OK TO RP-STATUS
               WHEN 11
                   MOVE ACTION-SHELL TO RP-ACTION
                   MOVE X"746573742D736563726574001B0D0A5C6E0A" TO
                       RP-ACTION-BUFFER(1:18)
                   MOVE 18 TO RP-ACTION-LENGTH
                   MOVE STATUS-OK TO RP-STATUS
               WHEN 12
                   MOVE ACTION-SHELL TO RP-ACTION
                   MOVE X"F09F9880" TO RP-ACTION-BUFFER(1:4)
                   MOVE 4 TO RP-ACTION-LENGTH
                   MOVE STATUS-OK TO RP-STATUS
               WHEN 8
                   MOVE ACTION-SHELL TO RP-ACTION
                   MOVE X"7072696E7466206F6B0A" TO
                       RP-ACTION-BUFFER(1:10)
                   MOVE 10 TO RP-ACTION-LENGTH
                   MOVE STATUS-OK TO RP-STATUS
               WHEN OTHER
                   MOVE ACTION-SHELL TO RP-ACTION
                   MOVE X"7072696E7466206F6B" TO RP-ACTION-BUFFER(1:9)
                   MOVE 9 TO RP-ACTION-LENGTH
                   MOVE STATUS-OK TO RP-STATUS
           END-EVALUATE.

       HANDLE-CONTINUE.
           ADD 1 TO FR-CONTINUE-COUNT
           IF FR-MODE = 3 OR FR-MODE = 11 OR FR-MODE = 12
               IF RP-SHELL-STATUS = SHELL-COMMAND-ENCODING AND
                  RP-SHELL-EXIT = ZERO AND
                  RP-SHELL-SIGNAL = ZERO AND
                  RP-SHELL-TRUNCATED = FLAG-OFF AND
                  RP-SHELL-ENCODING-LOSS = FLAG-OFF AND
                  RP-SHELL-OUTPUT-PTR = NULL AND
                  RP-SHELL-OUTPUT-LENGTH = ZERO
                   MOVE FLAG-ON TO FR-VALID
               END-IF
           ELSE
               IF FR-MODE = 10 AND
                  RP-SHELL-STATUS = SHELL-SIGNAL AND
                  RP-SHELL-EXIT = ZERO AND
                  RP-SHELL-SIGNAL = 15 AND
                  RP-SHELL-TRUNCATED = FLAG-ON AND
                  RP-SHELL-OUTPUT-LENGTH = 12
                   SET ADDRESS OF RP-SHELL-BUFFER TO
                       RP-SHELL-OUTPUT-PTR
                   IF RP-SHELL-BUFFER(1:12) = WS-EXPECTED-OUTPUT
                       MOVE FLAG-ON TO FR-VALID
                   END-IF
               ELSE
               IF RP-SHELL-STATUS = SHELL-EXIT AND
                  RP-SHELL-EXIT = ZERO AND
                  RP-SHELL-SIGNAL = ZERO AND
                  RP-SHELL-TRUNCATED = FLAG-OFF AND
                  RP-SHELL-OUTPUT-PTR NOT = NULL AND
                   (RP-SHELL-OUTPUT-LENGTH = 12 OR
                   (FR-MODE = 8 AND RP-SHELL-OUTPUT-LENGTH = 13) OR
                   ((FR-MODE = 9 OR FR-MODE = 14) AND
                    RP-SHELL-OUTPUT-LENGTH = 3 AND
                    RP-SHELL-ENCODING-LOSS = FLAG-ON))
                   SET ADDRESS OF RP-SHELL-BUFFER TO
                       RP-SHELL-OUTPUT-PTR
                   IF ((FR-MODE = 9 OR FR-MODE = 14) AND
                       RP-SHELL-BUFFER(1:3) = X"EFBFBD") OR
                      (FR-MODE NOT = 9 AND FR-MODE NOT = 14 AND
                       RP-SHELL-ENCODING-LOSS = FLAG-OFF AND
                       RP-SHELL-BUFFER(1:12) = WS-EXPECTED-OUTPUT AND
                       (FR-MODE NOT = 8 OR
                        RP-SHELL-BUFFER(13:1) = X"0A"))
                       MOVE FLAG-ON TO FR-VALID
                   END-IF
               END-IF
               END-IF
           END-IF
           IF FR-VALID NOT = FLAG-ON
               MOVE STATUS-INTERNAL TO RP-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE ACTION-FINAL TO RP-ACTION
           MOVE X"6167656E7420646F6E65" TO RP-ACTION-BUFFER(1:10)
           MOVE 10 TO RP-ACTION-LENGTH
           MOVE STATUS-OK TO RP-STATUS.

       END PROGRAM RESPAPI.
