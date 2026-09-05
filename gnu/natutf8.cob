       IDENTIFICATION DIVISION.
       PROGRAM-ID. NATUTF8.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       01 WS-POS                  PIC S9(9) COMP-5.
       01 WS-WIDTH                PIC S9(9) COMP-5.
       01 WS-NEEDED               PIC S9(9) COMP-5.
       01 WS-BYTE                 PIC S9(9) COMP-5.
       01 WS-BYTE-2               PIC S9(9) COMP-5.
       01 WS-BYTE-3               PIC S9(9) COMP-5.
       01 WS-BYTE-4               PIC S9(9) COMP-5.
       01 WS-LAST                 PIC S9(9) COMP-5.
       01 WS-VALID                PIC X.
       01 WS-REPLACE              PIC X.

       LINKAGE SECTION.
       COPY TXTPARM.
       01 TP-IN                   PIC X(16777216) BASED.
       01 TP-OUT                  PIC X(16777216) BASED.

       PROCEDURE DIVISION USING TEXT-PARM.
           MOVE STATUS-INTERNAL TO TP-STATUS
           MOVE ZERO TO TP-OUTPUT-LENGTH
           MOVE FLAG-OFF TO TP-REPLACED TP-TRUNCATED
           IF TP-OPERATION < TEXT-NATIVE-STRICT OR
              TP-OPERATION > TEXT-UTF8-REPLACE
               GOBACK
           END-IF
           IF TP-INPUT-LENGTH < ZERO OR
              TP-INPUT-LENGTH > LIMIT-HISTORY OR
              TP-OUTPUT-CAPACITY < ZERO OR
              TP-OUTPUT-CAPACITY > LIMIT-HISTORY OR
              TP-INPUT-PTR = NULL OR TP-OUTPUT-PTR = NULL
               GOBACK
           END-IF
           SET ADDRESS OF TP-IN TO TP-INPUT-PTR
           SET ADDRESS OF TP-OUT TO TP-OUTPUT-PTR
           MOVE FLAG-OFF TO WS-REPLACE
           IF TP-OPERATION = TEXT-NATIVE-REPLACE OR
              TP-OPERATION = TEXT-UTF8-REPLACE
               MOVE FLAG-ON TO WS-REPLACE
           END-IF
           MOVE 1 TO WS-POS
           PERFORM UNTIL WS-POS > TP-INPUT-LENGTH
               PERFORM VALIDATE-NEXT
               IF WS-VALID = FLAG-OFF
                   IF WS-REPLACE = FLAG-OFF
                       MOVE ZERO TO TP-OUTPUT-LENGTH
                       MOVE STATUS-TEXT-INVALID TO TP-STATUS
                       GOBACK
                   END-IF
                   MOVE 3 TO WS-NEEDED
                   IF TP-OUTPUT-LENGTH >
                      TP-OUTPUT-CAPACITY - WS-NEEDED
                       MOVE FLAG-ON TO TP-TRUNCATED
                       MOVE STATUS-CAPACITY TO TP-STATUS
                       GOBACK
                   END-IF
                   MOVE X"EF" TO
                       TP-OUT(TP-OUTPUT-LENGTH + 1:1)
                   MOVE X"BF" TO
                       TP-OUT(TP-OUTPUT-LENGTH + 2:1)
                   MOVE X"BD" TO
                       TP-OUT(TP-OUTPUT-LENGTH + 3:1)
                   ADD 3 TO TP-OUTPUT-LENGTH
                   ADD 1 TO WS-POS
                   MOVE FLAG-ON TO TP-REPLACED
               ELSE
                   MOVE WS-WIDTH TO WS-NEEDED
                   IF TP-OUTPUT-LENGTH >
                      TP-OUTPUT-CAPACITY - WS-NEEDED
                       MOVE FLAG-ON TO TP-TRUNCATED
                       MOVE STATUS-CAPACITY TO TP-STATUS
                       GOBACK
                   END-IF
                   MOVE TP-IN(WS-POS:WS-WIDTH) TO
                       TP-OUT(TP-OUTPUT-LENGTH + 1:WS-WIDTH)
                   ADD WS-WIDTH TO TP-OUTPUT-LENGTH WS-POS
               END-IF
           END-PERFORM
           MOVE STATUS-OK TO TP-STATUS
           GOBACK.

       VALIDATE-NEXT.
           MOVE FLAG-OFF TO WS-VALID
           MOVE 1 TO WS-WIDTH
           COMPUTE WS-BYTE = FUNCTION ORD(TP-IN(WS-POS:1)) - 1
           IF WS-BYTE <= 127
               MOVE FLAG-ON TO WS-VALID
               EXIT PARAGRAPH
           END-IF
           IF WS-BYTE >= 194 AND WS-BYTE <= 223
               MOVE 2 TO WS-WIDTH
               COMPUTE WS-LAST = WS-POS + 1
               IF WS-LAST <= TP-INPUT-LENGTH
                   COMPUTE WS-BYTE-2 =
                       FUNCTION ORD(TP-IN(WS-POS + 1:1)) - 1
                   IF WS-BYTE-2 >= 128 AND WS-BYTE-2 <= 191
                       MOVE FLAG-ON TO WS-VALID
                   END-IF
               END-IF
               EXIT PARAGRAPH
           END-IF
           IF WS-BYTE >= 224 AND WS-BYTE <= 239
               MOVE 3 TO WS-WIDTH
               COMPUTE WS-LAST = WS-POS + 2
               IF WS-LAST <= TP-INPUT-LENGTH
                   COMPUTE WS-BYTE-2 =
                       FUNCTION ORD(TP-IN(WS-POS + 1:1)) - 1
                   COMPUTE WS-BYTE-3 =
                       FUNCTION ORD(TP-IN(WS-POS + 2:1)) - 1
                   IF WS-BYTE-2 >= 128 AND WS-BYTE-2 <= 191 AND
                      WS-BYTE-3 >= 128 AND WS-BYTE-3 <= 191 AND
                      NOT (WS-BYTE = 224 AND WS-BYTE-2 < 160) AND
                      NOT (WS-BYTE = 237 AND WS-BYTE-2 > 159)
                       MOVE FLAG-ON TO WS-VALID
                   END-IF
               END-IF
               EXIT PARAGRAPH
           END-IF
           IF WS-BYTE >= 240 AND WS-BYTE <= 244
               MOVE 4 TO WS-WIDTH
               COMPUTE WS-LAST = WS-POS + 3
               IF WS-LAST <= TP-INPUT-LENGTH
                   COMPUTE WS-BYTE-2 =
                       FUNCTION ORD(TP-IN(WS-POS + 1:1)) - 1
                   COMPUTE WS-BYTE-3 =
                       FUNCTION ORD(TP-IN(WS-POS + 2:1)) - 1
                   COMPUTE WS-BYTE-4 =
                       FUNCTION ORD(TP-IN(WS-POS + 3:1)) - 1
                   IF WS-BYTE-2 >= 128 AND WS-BYTE-2 <= 191 AND
                      WS-BYTE-3 >= 128 AND WS-BYTE-3 <= 191 AND
                      WS-BYTE-4 >= 128 AND WS-BYTE-4 <= 191 AND
                      NOT (WS-BYTE = 240 AND WS-BYTE-2 < 144) AND
                      NOT (WS-BYTE = 244 AND WS-BYTE-2 > 143)
                       MOVE FLAG-ON TO WS-VALID
                   END-IF
               END-IF
           END-IF.

       END PROGRAM NATUTF8.
