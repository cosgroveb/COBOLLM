       IDENTIFICATION DIVISION.
       PROGRAM-ID. JSONSCAN IS RECURSIVE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       01  WS-INTERNAL-TOKEN        PIC X VALUE X'4A'.
       LOCAL-STORAGE SECTION.
       01  WS-CURSOR               PIC S9(9) COMP-5.
       01  WS-START                PIC S9(9) COMP-5.
       01  WS-SCAN                 PIC S9(9) COMP-5.
       01  WS-SAVE                 PIC S9(9) COMP-5.
       01  WS-NEXT                 PIC S9(9) COMP-5.
       01  WS-LENGTH               PIC S9(9) COMP-5.
       01  WS-OUT                  PIC S9(9) COMP-5.
       01  WS-DIGITS               PIC S9(9) COMP-5.
       01  WS-DEPTH                PIC S9(9) COMP-5.
       01  WS-VALUE                PIC S9(9) COMP-5.
       01  WS-HIGH                 PIC S9(9) COMP-5.
       01  WS-LOW                  PIC S9(9) COMP-5.
       01  WS-WIDTH                PIC S9(9) COMP-5.
       01  WS-ERROR                PIC X VALUE X'00'.
       01  WS-CHAR                 PIC X.
       01  WS-OBJECT-START         PIC S9(9) COMP-5.
       01  WS-OBJECT-END           PIC S9(9) COMP-5.
       01  WS-CURRENT-NAME         PIC S9(9) COMP-5.
       01  WS-PRIOR-CURSOR         PIC S9(9) COMP-5.
       01  WS-A-CURSOR             PIC S9(9) COMP-5.
       01  WS-B-CURSOR             PIC S9(9) COMP-5.
       01  WS-A-SCALAR             PIC S9(9) COMP-5.
       01  WS-B-SCALAR             PIC S9(9) COMP-5.
       01  WS-ITER-CURSOR          PIC S9(9) COMP-5.
       01  WS-ITER-SCALAR          PIC S9(9) COMP-5.
       01  WS-BYTE-ONE             PIC S9(9) COMP-5.
       01  WS-BYTE-TWO             PIC S9(9) COMP-5.
       01  WS-BYTE-THREE           PIC S9(9) COMP-5.
       01  WS-BYTE-FOUR            PIC S9(9) COMP-5.
       01  WS-A-END                PIC X.
       01  WS-B-END                PIC X.
       01  WS-ITER-END             PIC X.
       01  WS-NAMES-EQUAL          PIC X.
       01  WS-ITERATOR             PIC X.
           88 WS-ITERATOR-A        VALUE X'41'.
           88 WS-ITERATOR-B        VALUE X'42'.
       01  WS-B-PLAIN              PIC X.
       01  WS-INTERNAL-CALL        PIC X.
       01  WS-INTERNAL-PTR          USAGE POINTER.
       01  LOCAL-JSON-PARM.
           05 L-OPERATION          PIC S9(9) COMP-5.
           05 L-STATUS             PIC S9(9) COMP-5.
           05 L-INPUT-PTR          USAGE POINTER.
           05 L-INPUT-LENGTH       PIC S9(9) COMP-5.
           05 L-CURSOR             PIC S9(9) COMP-5.
           05 L-NAME-PTR           USAGE POINTER.
           05 L-NAME-LENGTH        PIC S9(9) COMP-5.
           05 L-OUTPUT-PTR         USAGE POINTER.
           05 L-OUTPUT-CAPACITY    PIC S9(9) COMP-5.
           05 L-OUTPUT-LENGTH      PIC S9(9) COMP-5.
           05 L-NEXT-CURSOR        PIC S9(9) COMP-5.
           05 L-SPAN-START         PIC S9(9) COMP-5.
           05 L-SPAN-LENGTH        PIC S9(9) COMP-5.
           05 L-DEPTH              PIC S9(9) COMP-5.
           05 L-FOUND              PIC X.
           05 L-END                PIC X.

       LINKAGE SECTION.
       COPY JSONPARM.
       01  INPUT-AREA.
           05 INPUT-BYTE PIC X OCCURS 8388608 TIMES.
       01  NAME-AREA.
           05 NAME-BYTE PIC X OCCURS 8388608 TIMES.
       01  OUTPUT-AREA.
           05 OUTPUT-BYTE PIC X OCCURS 16777216 TIMES.

       PROCEDURE DIVISION USING JSON-PARM.
       MAIN.
           MOVE STATUS-INTERNAL TO JP-STATUS
           MOVE 0 TO JP-OUTPUT-LENGTH JP-NEXT-CURSOR
                     JP-SPAN-START JP-SPAN-LENGTH
           MOVE FLAG-OFF TO JP-FOUND JP-END
           MOVE FLAG-OFF TO WS-ERROR
           MOVE FLAG-OFF TO WS-INTERNAL-CALL
           MOVE 0 TO WS-DEPTH
           SET WS-INTERNAL-PTR TO ADDRESS OF WS-INTERNAL-TOKEN
           IF JP-OPERATION = JSON-SKIP-VALUE
             AND JP-NAME-PTR = WS-INTERNAL-PTR
               IF JP-DEPTH < 0 OR JP-DEPTH > LIMIT-JSON-DEPTH
                   MOVE STATUS-JSON TO JP-STATUS
                   GOBACK
               END-IF
               MOVE JP-DEPTH TO WS-DEPTH
               MOVE FLAG-ON TO WS-INTERNAL-CALL
           END-IF
           MOVE 0 TO JP-DEPTH
           EVALUATE JP-OPERATION
               WHEN JSON-ESCAPE
               WHEN JSON-DECODE
               WHEN JSON-FIND-MEMBER
               WHEN JSON-NEXT-ELEMENT
               WHEN JSON-SKIP-VALUE
                   PERFORM VALIDATE-CALL
               WHEN OTHER
                   GOBACK
           END-EVALUATE
           IF JP-STATUS NOT = STATUS-OK GOBACK END-IF
           SET ADDRESS OF INPUT-AREA TO JP-INPUT-PTR
           IF JP-INPUT-LENGTH >= 3
               IF INPUT-BYTE(1) = X'EF'
                   AND INPUT-BYTE(2) = X'BB'
                   AND INPUT-BYTE(3) = X'BF'
                   MOVE STATUS-JSON TO JP-STATUS
                   GOBACK
               END-IF
           END-IF
           EVALUATE JP-OPERATION
               WHEN JSON-ESCAPE
                   PERFORM DO-ESCAPE
               WHEN JSON-DECODE
                   PERFORM DO-DECODE
               WHEN JSON-FIND-MEMBER
                   PERFORM DO-FIND
               WHEN JSON-NEXT-ELEMENT
                   PERFORM DO-NEXT
               WHEN JSON-SKIP-VALUE
                   PERFORM DO-SKIP
               WHEN OTHER CONTINUE
           END-EVALUATE
           GOBACK.

       VALIDATE-CALL.
           MOVE STATUS-JSON TO JP-STATUS
           IF JP-INPUT-PTR = NULL
             OR JP-INPUT-LENGTH < 0
             OR JP-INPUT-LENGTH > LIMIT-RESPONSE
               EXIT PARAGRAPH
           END-IF
           EVALUATE JP-OPERATION
               WHEN JSON-ESCAPE
                   IF JP-CURSOR NOT = 1
                     OR JP-NAME-PTR NOT = NULL
                     OR JP-NAME-LENGTH NOT = 0
                     OR JP-OUTPUT-PTR = NULL
                     OR JP-OUTPUT-CAPACITY < 0
                     OR JP-OUTPUT-CAPACITY > LIMIT-HISTORY
                       EXIT PARAGRAPH
                   END-IF
               WHEN JSON-DECODE
                   IF JP-CURSOR < 1
                     OR JP-CURSOR > JP-INPUT-LENGTH
                     OR JP-NAME-PTR NOT = NULL
                     OR JP-NAME-LENGTH NOT = 0
                     OR JP-OUTPUT-PTR = NULL
                     OR JP-OUTPUT-CAPACITY < 0
                     OR JP-OUTPUT-CAPACITY > LIMIT-HISTORY
                       EXIT PARAGRAPH
                   END-IF
               WHEN JSON-FIND-MEMBER
                   IF JP-CURSOR < 1
                     OR JP-CURSOR > JP-INPUT-LENGTH
                     OR JP-NAME-PTR = NULL
                     OR JP-NAME-LENGTH < 0
                     OR JP-NAME-LENGTH > LIMIT-RESPONSE
                     OR JP-OUTPUT-PTR NOT = NULL
                     OR JP-OUTPUT-CAPACITY NOT = 0
                       EXIT PARAGRAPH
                   END-IF
               WHEN JSON-NEXT-ELEMENT
                   IF JP-CURSOR < 1
                     OR JP-CURSOR > JP-INPUT-LENGTH
                     OR JP-NAME-PTR NOT = NULL
                     OR JP-NAME-LENGTH NOT = 0
                     OR JP-OUTPUT-PTR NOT = NULL
                     OR JP-OUTPUT-CAPACITY NOT = 0
                       EXIT PARAGRAPH
                   END-IF
               WHEN JSON-SKIP-VALUE
                   IF JP-CURSOR < 1
                     OR JP-CURSOR > JP-INPUT-LENGTH
                     OR JP-NAME-LENGTH NOT = 0
                     OR JP-OUTPUT-PTR NOT = NULL
                     OR JP-OUTPUT-CAPACITY NOT = 0
                       EXIT PARAGRAPH
                   END-IF
                   IF WS-INTERNAL-CALL = FLAG-OFF
                     AND JP-NAME-PTR NOT = NULL
                       EXIT PARAGRAPH
                   END-IF
           END-EVALUATE
           MOVE STATUS-OK TO JP-STATUS.

       DO-ESCAPE.
           SET ADDRESS OF OUTPUT-AREA TO JP-OUTPUT-PTR
           MOVE 1 TO WS-CURSOR
           MOVE 0 TO WS-OUT
           PERFORM UNTIL WS-CURSOR > JP-INPUT-LENGTH
               PERFORM VALIDATE-UTF8
               IF WS-ERROR = FLAG-ON
                   MOVE STATUS-JSON TO JP-STATUS
                   MOVE 0 TO JP-OUTPUT-LENGTH
                   EXIT PERFORM
               END-IF
               EVALUATE INPUT-BYTE(WS-CURSOR)
                   WHEN X'22'
                       MOVE 2 TO WS-LENGTH
                       PERFORM REQUIRE-OUTPUT
                       IF WS-ERROR = FLAG-OFF
                           MOVE X'5C' TO OUTPUT-BYTE(WS-OUT + 1)
                           MOVE X'22' TO OUTPUT-BYTE(WS-OUT + 2)
                       END-IF
                   WHEN X'5C'
                       MOVE 2 TO WS-LENGTH
                       PERFORM REQUIRE-OUTPUT
                       IF WS-ERROR = FLAG-OFF
                           MOVE X'5C' TO OUTPUT-BYTE(WS-OUT + 1)
                           MOVE X'5C' TO OUTPUT-BYTE(WS-OUT + 2)
                       END-IF
                   WHEN X'08'
                       MOVE X'62' TO WS-CHAR
                       PERFORM EMIT-SHORT-ESCAPE
                   WHEN X'0C'
                       MOVE X'66' TO WS-CHAR
                       PERFORM EMIT-SHORT-ESCAPE
                   WHEN X'0A'
                       MOVE X'6E' TO WS-CHAR
                       PERFORM EMIT-SHORT-ESCAPE
                   WHEN X'0D'
                       MOVE X'72' TO WS-CHAR
                       PERFORM EMIT-SHORT-ESCAPE
                   WHEN X'09'
                       MOVE X'74' TO WS-CHAR
                       PERFORM EMIT-SHORT-ESCAPE
                   WHEN OTHER
                       IF INPUT-BYTE(WS-CURSOR) < X'20'
                           MOVE 6 TO WS-LENGTH
                           PERFORM REQUIRE-OUTPUT
                           IF WS-ERROR = FLAG-OFF
                               MOVE X'5C753030' TO
                                   OUTPUT-AREA(WS-OUT + 1:4)
                               PERFORM EMIT-HEX-LOW-BYTE
                           END-IF
                       ELSE
                           MOVE WS-WIDTH TO WS-LENGTH
                           PERFORM REQUIRE-OUTPUT
                           IF WS-ERROR = FLAG-OFF
                               MOVE INPUT-AREA(WS-CURSOR:WS-WIDTH)
                                 TO OUTPUT-AREA(WS-OUT + 1:WS-WIDTH)
                           END-IF
                       END-IF
               END-EVALUATE
               IF WS-ERROR = FLAG-ON
                   MOVE STATUS-CAPACITY TO JP-STATUS
                   MOVE 0 TO JP-OUTPUT-LENGTH
                   EXIT PERFORM
               END-IF
               ADD WS-LENGTH TO WS-OUT
               ADD WS-WIDTH TO WS-CURSOR
           END-PERFORM
           IF JP-STATUS = STATUS-OK
               MOVE WS-OUT TO JP-OUTPUT-LENGTH
               COMPUTE JP-NEXT-CURSOR = JP-INPUT-LENGTH + 1
           END-IF.

       EMIT-SHORT-ESCAPE.
           MOVE 2 TO WS-LENGTH
           PERFORM REQUIRE-OUTPUT
           IF WS-ERROR = FLAG-OFF
               MOVE X'5C' TO OUTPUT-BYTE(WS-OUT + 1)
               MOVE WS-CHAR TO OUTPUT-BYTE(WS-OUT + 2)
           END-IF.

       EMIT-HEX-LOW-BYTE.
           COMPUTE WS-VALUE = FUNCTION ORD(INPUT-BYTE(WS-CURSOR))
               - 1
           DIVIDE WS-VALUE BY 16 GIVING WS-HIGH REMAINDER WS-LOW
           MOVE WS-HIGH TO WS-VALUE
           PERFORM HEX-VALUE
           MOVE WS-CHAR TO OUTPUT-BYTE(WS-OUT + 5)
           MOVE WS-LOW TO WS-VALUE
           PERFORM HEX-VALUE
           MOVE WS-CHAR TO OUTPUT-BYTE(WS-OUT + 6).

       HEX-VALUE.
           IF WS-VALUE < 10
               COMPUTE WS-VALUE = WS-VALUE + 48
           ELSE
               COMPUTE WS-VALUE = WS-VALUE + 55
           END-IF
           MOVE FUNCTION CHAR(WS-VALUE + 1) TO WS-CHAR.

       REQUIRE-OUTPUT.
           IF WS-OUT > JP-OUTPUT-CAPACITY - WS-LENGTH
               MOVE FLAG-ON TO WS-ERROR
               MOVE STATUS-CAPACITY TO JP-STATUS
           END-IF.

       DO-DECODE.
           SET ADDRESS OF OUTPUT-AREA TO JP-OUTPUT-PTR
           MOVE JP-CURSOR TO WS-CURSOR
           MOVE 0 TO WS-OUT
           PERFORM DECODE-STRING
           IF WS-ERROR = FLAG-ON
               IF JP-STATUS = STATUS-OK
                   MOVE STATUS-JSON TO JP-STATUS
               END-IF
               MOVE 0 TO JP-OUTPUT-LENGTH
           ELSE
               MOVE WS-OUT TO JP-OUTPUT-LENGTH
               MOVE WS-CURSOR TO JP-NEXT-CURSOR
           END-IF.

       DECODE-STRING.
           IF WS-CURSOR < 1 OR WS-CURSOR > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           IF INPUT-BYTE(WS-CURSOR) NOT = X'22'
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-CURSOR
           PERFORM UNTIL WS-CURSOR > JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'22'
                   ADD 1 TO WS-CURSOR
                   EXIT PARAGRAPH
               END-IF
               IF INPUT-BYTE(WS-CURSOR) = X'5C'
                   PERFORM DECODE-ESCAPE
               ELSE
                   IF INPUT-BYTE(WS-CURSOR) < X'20'
                       MOVE FLAG-ON TO WS-ERROR
                   ELSE
                       PERFORM VALIDATE-UTF8
                       IF WS-ERROR = FLAG-OFF
                           MOVE WS-WIDTH TO WS-LENGTH
                           PERFORM REQUIRE-OUTPUT
                           IF WS-ERROR = FLAG-OFF
                               MOVE INPUT-AREA(WS-CURSOR:WS-WIDTH)
                                 TO OUTPUT-AREA(WS-OUT + 1:WS-WIDTH)
                               ADD WS-WIDTH TO WS-OUT
                               ADD WS-WIDTH TO WS-CURSOR
                           END-IF
                       END-IF
                   END-IF
               END-IF
               IF WS-ERROR = FLAG-ON
                   EXIT PARAGRAPH
               END-IF
           END-PERFORM
           MOVE FLAG-ON TO WS-ERROR.

       DECODE-ESCAPE.
           COMPUTE WS-NEXT = WS-CURSOR + 1
           IF WS-NEXT > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-CURSOR
           EVALUATE INPUT-BYTE(WS-CURSOR)
               WHEN X'22' MOVE X'22' TO WS-CHAR
               WHEN X'5C' MOVE X'5C' TO WS-CHAR
               WHEN X'2F' MOVE X'2F' TO WS-CHAR
               WHEN X'62' MOVE X'08' TO WS-CHAR
               WHEN X'66' MOVE X'0C' TO WS-CHAR
               WHEN X'6E' MOVE X'0A' TO WS-CHAR
               WHEN X'72' MOVE X'0D' TO WS-CHAR
               WHEN X'74' MOVE X'09' TO WS-CHAR
               WHEN X'75'
                   ADD 1 TO WS-CURSOR
                   PERFORM READ-HEX4
                   IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
                   MOVE WS-VALUE TO WS-HIGH
                   IF WS-HIGH >= 55296 AND WS-HIGH <= 56319
                       COMPUTE WS-NEXT = WS-CURSOR + 1
                       IF WS-NEXT > JP-INPUT-LENGTH
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                       END-IF
                       IF INPUT-BYTE(WS-CURSOR) NOT = X'5C'
                           OR INPUT-BYTE(WS-CURSOR + 1) NOT = X'75'
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                       END-IF
                       ADD 2 TO WS-CURSOR
                       PERFORM READ-HEX4
                       IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
                       MOVE WS-VALUE TO WS-LOW
                       IF WS-LOW < 56320 OR WS-LOW > 57343
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                       END-IF
                       SUBTRACT 55296 FROM WS-HIGH
                       MULTIPLY 1024 BY WS-HIGH
                       MOVE 65536 TO WS-VALUE
                       ADD WS-HIGH TO WS-VALUE
                       ADD WS-LOW TO WS-VALUE
                       SUBTRACT 56320 FROM WS-VALUE
                   ELSE
                       IF WS-HIGH >= 56320 AND WS-HIGH <= 57343
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                       END-IF
                       MOVE WS-HIGH TO WS-VALUE
                   END-IF
                   PERFORM EMIT-UTF8
                   EXIT PARAGRAPH
               WHEN OTHER
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
           END-EVALUATE
           MOVE 1 TO WS-LENGTH
           PERFORM REQUIRE-OUTPUT
           IF WS-ERROR = FLAG-OFF
               MOVE WS-CHAR TO OUTPUT-BYTE(WS-OUT + 1)
               ADD 1 TO WS-OUT WS-CURSOR
           END-IF.

       READ-HEX4.
           MOVE 0 TO WS-VALUE
           PERFORM 4 TIMES
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               COMPUTE WS-VALUE = WS-VALUE * 16
               EVALUATE TRUE
                   WHEN INPUT-BYTE(WS-CURSOR) >= X'30'
                    AND INPUT-BYTE(WS-CURSOR) <= X'39'
                       COMPUTE WS-LOW =
                           FUNCTION ORD(INPUT-BYTE(WS-CURSOR))
                           - FUNCTION ORD(X'30')
                       ADD WS-LOW TO WS-VALUE
                   WHEN INPUT-BYTE(WS-CURSOR) >= X'41'
                    AND INPUT-BYTE(WS-CURSOR) <= X'46'
                       COMPUTE WS-LOW =
                           FUNCTION ORD(INPUT-BYTE(WS-CURSOR))
                           - FUNCTION ORD(X'41') + 10
                       ADD WS-LOW TO WS-VALUE
                   WHEN INPUT-BYTE(WS-CURSOR) >= X'61'
                    AND INPUT-BYTE(WS-CURSOR) <= X'66'
                       COMPUTE WS-LOW =
                           FUNCTION ORD(INPUT-BYTE(WS-CURSOR))
                           - FUNCTION ORD(X'61') + 10
                       ADD WS-LOW TO WS-VALUE
                   WHEN OTHER
                       MOVE FLAG-ON TO WS-ERROR
                       EXIT PERFORM
               END-EVALUATE
               ADD 1 TO WS-CURSOR
           END-PERFORM.

       EMIT-UTF8.
           EVALUATE TRUE
               WHEN WS-VALUE <= 127
                   MOVE 1 TO WS-LENGTH
               WHEN WS-VALUE <= 2047
                   MOVE 2 TO WS-LENGTH
               WHEN WS-VALUE <= 65535
                   MOVE 3 TO WS-LENGTH
               WHEN OTHER
                   MOVE 4 TO WS-LENGTH
           END-EVALUATE
           PERFORM REQUIRE-OUTPUT
           IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
           EVALUATE WS-LENGTH
               WHEN 1
                   COMPUTE WS-HIGH = WS-VALUE + 1
                   MOVE FUNCTION CHAR(WS-HIGH)
                     TO OUTPUT-BYTE(WS-OUT + 1)
               WHEN 2
                   DIVIDE 64 INTO WS-VALUE GIVING WS-HIGH
                   ADD 192 TO WS-HIGH
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 1)
                   COMPUTE WS-HIGH = 128 + FUNCTION MOD(WS-VALUE, 64)
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 2)
               WHEN 3
                   DIVIDE 4096 INTO WS-VALUE GIVING WS-HIGH
                   ADD 224 TO WS-HIGH
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 1)
                   DIVIDE 64 INTO WS-VALUE GIVING WS-HIGH
                   COMPUTE WS-HIGH = FUNCTION MOD(WS-HIGH, 64)
                   ADD 128 TO WS-HIGH
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 2)
                   COMPUTE WS-HIGH = 128 + FUNCTION MOD(WS-VALUE, 64)
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 3)
               WHEN 4
                   DIVIDE 262144 INTO WS-VALUE GIVING WS-HIGH
                   ADD 240 TO WS-HIGH
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 1)
                   DIVIDE 4096 INTO WS-VALUE GIVING WS-HIGH
                   COMPUTE WS-HIGH = FUNCTION MOD(WS-HIGH, 64)
                   ADD 128 TO WS-HIGH
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 2)
                   DIVIDE 64 INTO WS-VALUE GIVING WS-HIGH
                   COMPUTE WS-HIGH = FUNCTION MOD(WS-HIGH, 64)
                   ADD 128 TO WS-HIGH
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 3)
                   COMPUTE WS-HIGH = 128 + FUNCTION MOD(WS-VALUE, 64)
                   MOVE FUNCTION CHAR(WS-HIGH + 1)
                     TO OUTPUT-BYTE(WS-OUT + 4)
           END-EVALUATE
           ADD WS-LENGTH TO WS-OUT.

       DO-SKIP.
           MOVE JP-CURSOR TO WS-CURSOR
           PERFORM SKIP-SPACE
           MOVE WS-CURSOR TO WS-START
           PERFORM SKIP-VALUE
           IF WS-ERROR = FLAG-ON
               MOVE STATUS-JSON TO JP-STATUS
           ELSE
               MOVE WS-CURSOR TO WS-SAVE
               PERFORM SKIP-SPACE
               MOVE WS-CURSOR TO JP-NEXT-CURSOR
               MOVE WS-START TO JP-SPAN-START
               COMPUTE JP-SPAN-LENGTH = WS-SAVE - WS-START
           END-IF.

       SKIP-VALUE.
           IF WS-CURSOR > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           EVALUATE INPUT-BYTE(WS-CURSOR)
               WHEN X'22'
                   PERFORM SCAN-STRING
               WHEN X'7B'
                   PERFORM SKIP-OBJECT
               WHEN X'5B'
                   PERFORM SKIP-ARRAY
               WHEN X'74'
                   PERFORM SKIP-TRUE
               WHEN X'66'
                   PERFORM SKIP-FALSE
               WHEN X'6E'
                   PERFORM SKIP-NULL
               WHEN X'2D'
                   PERFORM SKIP-NUMBER
               WHEN X'30' THRU X'39'
                   PERFORM SKIP-NUMBER
               WHEN OTHER
                   MOVE FLAG-ON TO WS-ERROR
           END-EVALUATE.

       SKIP-OBJECT.
           IF WS-DEPTH >= LIMIT-JSON-DEPTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           MOVE WS-CURSOR TO WS-OBJECT-START
           ADD 1 TO WS-DEPTH WS-CURSOR
           PERFORM SKIP-SPACE
           IF WS-CURSOR <= JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'7D'
                   ADD 1 TO WS-CURSOR
                   SUBTRACT 1 FROM WS-DEPTH
                   EXIT PARAGRAPH
               END-IF
           END-IF
           PERFORM UNTIL WS-ERROR = FLAG-ON
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) NOT = X'22'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               PERFORM RECORD-OBJECT-NAME
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               PERFORM SCAN-STRING
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               PERFORM SKIP-SPACE
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) NOT = X'3A'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-CURSOR
               PERFORM SKIP-SPACE
               PERFORM CALL-SKIP-VALUE
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               PERFORM SKIP-SPACE
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) = X'7D'
                   ADD 1 TO WS-CURSOR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) NOT = X'2C'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-CURSOR
               PERFORM SKIP-SPACE
           END-PERFORM
           SUBTRACT 1 FROM WS-DEPTH.

       SKIP-ARRAY.
           IF WS-DEPTH >= LIMIT-JSON-DEPTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-DEPTH WS-CURSOR
           PERFORM SKIP-SPACE
           IF WS-CURSOR <= JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'5D'
                   ADD 1 TO WS-CURSOR
                   SUBTRACT 1 FROM WS-DEPTH
                   EXIT PARAGRAPH
               END-IF
           END-IF
           PERFORM UNTIL WS-ERROR = FLAG-ON
               PERFORM CALL-SKIP-VALUE
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               PERFORM SKIP-SPACE
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) = X'5D'
                   ADD 1 TO WS-CURSOR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) NOT = X'2C'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-CURSOR
               PERFORM SKIP-SPACE
           END-PERFORM
           SUBTRACT 1 FROM WS-DEPTH.

       RECORD-OBJECT-NAME.
           MOVE WS-CURSOR TO WS-CURRENT-NAME
           COMPUTE WS-PRIOR-CURSOR = WS-OBJECT-START + 1
           PERFORM SKIP-PRIOR-SPACE
           PERFORM UNTIL WS-PRIOR-CURSOR >= WS-CURRENT-NAME
               IF INPUT-BYTE(WS-PRIOR-CURSOR) NOT = X'22'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               MOVE WS-PRIOR-CURSOR TO WS-A-CURSOR
               MOVE WS-CURRENT-NAME TO WS-B-CURSOR
               MOVE FLAG-OFF TO WS-B-PLAIN
               PERFORM COMPARE-NAMES
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               IF WS-NAMES-EQUAL = FLAG-ON
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               MOVE WS-PRIOR-CURSOR TO WS-CURSOR
               PERFORM SCAN-STRING
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               MOVE WS-CURSOR TO WS-PRIOR-CURSOR
               PERFORM SKIP-PRIOR-SPACE
               IF WS-PRIOR-CURSOR > JP-INPUT-LENGTH
                 OR INPUT-BYTE(WS-PRIOR-CURSOR) NOT = X'3A'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-PRIOR-CURSOR
               PERFORM SKIP-PRIOR-SPACE
               INITIALIZE LOCAL-JSON-PARM
               MOVE JSON-SKIP-VALUE TO L-OPERATION
               SET L-INPUT-PTR TO JP-INPUT-PTR
               MOVE JP-INPUT-LENGTH TO L-INPUT-LENGTH
               MOVE WS-PRIOR-CURSOR TO L-CURSOR
               MOVE WS-DEPTH TO L-DEPTH
               SET L-NAME-PTR TO ADDRESS OF WS-INTERNAL-TOKEN
               CALL "JSONSCAN" USING LOCAL-JSON-PARM
               IF L-STATUS NOT = STATUS-OK
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               MOVE L-NEXT-CURSOR TO WS-PRIOR-CURSOR
               PERFORM SKIP-PRIOR-SPACE
               IF WS-PRIOR-CURSOR < WS-CURRENT-NAME
                   IF INPUT-BYTE(WS-PRIOR-CURSOR) NOT = X'2C'
                       MOVE FLAG-ON TO WS-ERROR
                       EXIT PERFORM
                   END-IF
                   ADD 1 TO WS-PRIOR-CURSOR
                   PERFORM SKIP-PRIOR-SPACE
               END-IF
           END-PERFORM
           MOVE WS-CURRENT-NAME TO WS-CURSOR.

       SKIP-PRIOR-SPACE.
           PERFORM UNTIL WS-PRIOR-CURSOR > JP-INPUT-LENGTH
             OR (INPUT-BYTE(WS-PRIOR-CURSOR) NOT = X'20'
             AND INPUT-BYTE(WS-PRIOR-CURSOR) NOT = X'09'
             AND INPUT-BYTE(WS-PRIOR-CURSOR) NOT = X'0A'
             AND INPUT-BYTE(WS-PRIOR-CURSOR) NOT = X'0D')
               ADD 1 TO WS-PRIOR-CURSOR
           END-PERFORM.

       COMPARE-NAMES.
           MOVE FLAG-ON TO WS-NAMES-EQUAL
           MOVE FLAG-OFF TO WS-A-END WS-B-END
           ADD 1 TO WS-A-CURSOR
           IF WS-B-PLAIN = FLAG-OFF ADD 1 TO WS-B-CURSOR END-IF
           PERFORM UNTIL WS-NAMES-EQUAL = FLAG-OFF
             OR (WS-A-END = FLAG-ON AND WS-B-END = FLAG-ON)
               SET WS-ITERATOR-A TO TRUE
               PERFORM NEXT-NAME-SCALAR
               MOVE WS-ITER-SCALAR TO WS-A-SCALAR
               MOVE WS-ITER-END TO WS-A-END
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               SET WS-ITERATOR-B TO TRUE
               PERFORM NEXT-NAME-SCALAR
               MOVE WS-ITER-SCALAR TO WS-B-SCALAR
               MOVE WS-ITER-END TO WS-B-END
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               IF WS-A-END NOT = WS-B-END
                   MOVE FLAG-OFF TO WS-NAMES-EQUAL
               ELSE
                   IF WS-A-END = FLAG-OFF
                     AND WS-A-SCALAR NOT = WS-B-SCALAR
                       MOVE FLAG-OFF TO WS-NAMES-EQUAL
                   END-IF
               END-IF
           END-PERFORM.

       NEXT-NAME-SCALAR.
           MOVE FLAG-OFF TO WS-ITER-END
           IF WS-ITERATOR-A
               MOVE WS-A-CURSOR TO WS-ITER-CURSOR
               PERFORM NEXT-JSON-SCALAR
               MOVE WS-ITER-CURSOR TO WS-A-CURSOR
           ELSE
               MOVE WS-B-CURSOR TO WS-ITER-CURSOR
               IF WS-B-PLAIN = FLAG-ON
                   PERFORM NEXT-PLAIN-SCALAR
               ELSE
                   PERFORM NEXT-JSON-SCALAR
               END-IF
               MOVE WS-ITER-CURSOR TO WS-B-CURSOR
           END-IF.

       NEXT-JSON-SCALAR.
           IF WS-ITER-CURSOR > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           IF INPUT-BYTE(WS-ITER-CURSOR) = X'22'
               ADD 1 TO WS-ITER-CURSOR
               MOVE FLAG-ON TO WS-ITER-END
               EXIT PARAGRAPH
           END-IF
           IF INPUT-BYTE(WS-ITER-CURSOR) = X'5C'
               PERFORM NEXT-ESCAPED-SCALAR
           ELSE
               PERFORM NEXT-RAW-SCALAR
           END-IF.

       NEXT-PLAIN-SCALAR.
           IF WS-ITER-CURSOR > JP-NAME-LENGTH
               MOVE FLAG-ON TO WS-ITER-END
               EXIT PARAGRAPH
           END-IF
           PERFORM NEXT-RAW-NAME-SCALAR.

       NEXT-ESCAPED-SCALAR.
           ADD 1 TO WS-ITER-CURSOR
           IF WS-ITER-CURSOR > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           EVALUATE INPUT-BYTE(WS-ITER-CURSOR)
               WHEN X'22' MOVE 34 TO WS-ITER-SCALAR
               WHEN X'5C' MOVE 92 TO WS-ITER-SCALAR
               WHEN X'2F' MOVE 47 TO WS-ITER-SCALAR
               WHEN X'62' MOVE 8 TO WS-ITER-SCALAR
               WHEN X'66' MOVE 12 TO WS-ITER-SCALAR
               WHEN X'6E' MOVE 10 TO WS-ITER-SCALAR
               WHEN X'72' MOVE 13 TO WS-ITER-SCALAR
               WHEN X'74' MOVE 9 TO WS-ITER-SCALAR
               WHEN X'75'
                   ADD 1 TO WS-ITER-CURSOR
                   PERFORM READ-ITER-HEX4
                   IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
                   MOVE WS-ITER-SCALAR TO WS-HIGH
                   IF WS-HIGH >= 55296 AND WS-HIGH <= 56319
                       COMPUTE WS-NEXT = WS-ITER-CURSOR + 1
                       IF WS-NEXT > JP-INPUT-LENGTH
                         OR INPUT-BYTE(WS-ITER-CURSOR) NOT = X'5C'
                         OR INPUT-BYTE(WS-ITER-CURSOR + 1) NOT = X'75'
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                       END-IF
                       ADD 2 TO WS-ITER-CURSOR
                       PERFORM READ-ITER-HEX4
                       IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
                       MOVE WS-ITER-SCALAR TO WS-LOW
                       IF WS-LOW < 56320 OR WS-LOW > 57343
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                       END-IF
                       SUBTRACT 55296 FROM WS-HIGH
                       MULTIPLY 1024 BY WS-HIGH
                       MOVE 65536 TO WS-ITER-SCALAR
                       ADD WS-HIGH TO WS-ITER-SCALAR
                       ADD WS-LOW TO WS-ITER-SCALAR
                       SUBTRACT 56320 FROM WS-ITER-SCALAR
                   ELSE
                       IF WS-HIGH >= 56320 AND WS-HIGH <= 57343
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                       END-IF
                   END-IF
                   EXIT PARAGRAPH
               WHEN OTHER
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
           END-EVALUATE
           ADD 1 TO WS-ITER-CURSOR.

       READ-ITER-HEX4.
           MOVE 0 TO WS-ITER-SCALAR
           PERFORM 4 TIMES
               IF WS-ITER-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               COMPUTE WS-ITER-SCALAR = WS-ITER-SCALAR * 16
               EVALUATE TRUE
                   WHEN INPUT-BYTE(WS-ITER-CURSOR) >= X'30'
                    AND INPUT-BYTE(WS-ITER-CURSOR) <= X'39'
                       COMPUTE WS-LOW =
                           FUNCTION ORD(INPUT-BYTE(WS-ITER-CURSOR))
                           - FUNCTION ORD(X'30')
                   WHEN INPUT-BYTE(WS-ITER-CURSOR) >= X'41'
                    AND INPUT-BYTE(WS-ITER-CURSOR) <= X'46'
                       COMPUTE WS-LOW =
                           FUNCTION ORD(INPUT-BYTE(WS-ITER-CURSOR))
                           - FUNCTION ORD(X'41') + 10
                   WHEN INPUT-BYTE(WS-ITER-CURSOR) >= X'61'
                    AND INPUT-BYTE(WS-ITER-CURSOR) <= X'66'
                       COMPUTE WS-LOW =
                           FUNCTION ORD(INPUT-BYTE(WS-ITER-CURSOR))
                           - FUNCTION ORD(X'61') + 10
                   WHEN OTHER
                       MOVE FLAG-ON TO WS-ERROR
                       EXIT PERFORM
               END-EVALUATE
               ADD WS-LOW TO WS-ITER-SCALAR
               ADD 1 TO WS-ITER-CURSOR
           END-PERFORM.

       NEXT-RAW-SCALAR.
           IF INPUT-BYTE(WS-ITER-CURSOR) < X'20'
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           PERFORM DECODE-RAW-SCALAR.

       NEXT-RAW-NAME-SCALAR.
           SET ADDRESS OF INPUT-AREA TO JP-NAME-PTR
           PERFORM DECODE-RAW-SCALAR
           SET ADDRESS OF INPUT-AREA TO JP-INPUT-PTR.

       DECODE-RAW-SCALAR.
           COMPUTE WS-BYTE-ONE =
               FUNCTION ORD(INPUT-BYTE(WS-ITER-CURSOR)) - 1
           EVALUATE TRUE
               WHEN WS-BYTE-ONE <= 127
                   MOVE 1 TO WS-WIDTH
               WHEN WS-BYTE-ONE >= 194 AND WS-BYTE-ONE <= 223
                   MOVE 2 TO WS-WIDTH
               WHEN WS-BYTE-ONE >= 224 AND WS-BYTE-ONE <= 239
                   MOVE 3 TO WS-WIDTH
               WHEN WS-BYTE-ONE >= 240 AND WS-BYTE-ONE <= 244
                   MOVE 4 TO WS-WIDTH
               WHEN OTHER
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
           END-EVALUATE
           IF WS-B-PLAIN = FLAG-ON AND WS-ITERATOR-B
               IF WS-ITER-CURSOR > JP-NAME-LENGTH - WS-WIDTH + 1
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
               END-IF
           ELSE
               IF WS-ITER-CURSOR > JP-INPUT-LENGTH - WS-WIDTH + 1
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
               END-IF
           END-IF
           MOVE 0 TO WS-BYTE-TWO WS-BYTE-THREE WS-BYTE-FOUR
           IF WS-WIDTH > 1
               COMPUTE WS-BYTE-TWO =
                   FUNCTION ORD(INPUT-BYTE(WS-ITER-CURSOR + 1)) - 1
               IF WS-BYTE-TWO < 128 OR WS-BYTE-TWO > 191
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF
           IF WS-WIDTH > 2
               COMPUTE WS-BYTE-THREE =
                   FUNCTION ORD(INPUT-BYTE(WS-ITER-CURSOR + 2)) - 1
               IF WS-BYTE-THREE < 128 OR WS-BYTE-THREE > 191
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF
           IF WS-WIDTH > 3
               COMPUTE WS-BYTE-FOUR =
                   FUNCTION ORD(INPUT-BYTE(WS-ITER-CURSOR + 3)) - 1
               IF WS-BYTE-FOUR < 128 OR WS-BYTE-FOUR > 191
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF
           IF WS-WIDTH = 3
               IF WS-BYTE-ONE = 224 AND WS-BYTE-TWO < 160
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
               IF WS-BYTE-ONE = 237 AND WS-BYTE-TWO > 159
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF
           IF WS-WIDTH = 4
               IF WS-BYTE-ONE = 240 AND WS-BYTE-TWO < 144
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
               IF WS-BYTE-ONE = 244 AND WS-BYTE-TWO > 143
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF
           IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
           EVALUATE WS-WIDTH
               WHEN 1
                   MOVE WS-BYTE-ONE TO WS-ITER-SCALAR
               WHEN 2
                   SUBTRACT 192 FROM WS-BYTE-ONE
                   MULTIPLY 64 BY WS-BYTE-ONE
                   MOVE WS-BYTE-ONE TO WS-ITER-SCALAR
                   ADD WS-BYTE-TWO TO WS-ITER-SCALAR
                   SUBTRACT 128 FROM WS-ITER-SCALAR
               WHEN 3
                   SUBTRACT 224 FROM WS-BYTE-ONE
                   MULTIPLY 4096 BY WS-BYTE-ONE
                   SUBTRACT 128 FROM WS-BYTE-TWO
                   MULTIPLY 64 BY WS-BYTE-TWO
                   MOVE WS-BYTE-ONE TO WS-ITER-SCALAR
                   ADD WS-BYTE-TWO TO WS-ITER-SCALAR
                   ADD WS-BYTE-THREE TO WS-ITER-SCALAR
                   SUBTRACT 128 FROM WS-ITER-SCALAR
               WHEN 4
                   SUBTRACT 240 FROM WS-BYTE-ONE
                   MULTIPLY 262144 BY WS-BYTE-ONE
                   SUBTRACT 128 FROM WS-BYTE-TWO
                   MULTIPLY 4096 BY WS-BYTE-TWO
                   SUBTRACT 128 FROM WS-BYTE-THREE
                   MULTIPLY 64 BY WS-BYTE-THREE
                   MOVE WS-BYTE-ONE TO WS-ITER-SCALAR
                   ADD WS-BYTE-TWO TO WS-ITER-SCALAR
                   ADD WS-BYTE-THREE TO WS-ITER-SCALAR
                   ADD WS-BYTE-FOUR TO WS-ITER-SCALAR
                   SUBTRACT 128 FROM WS-ITER-SCALAR
           END-EVALUATE
           ADD WS-WIDTH TO WS-ITER-CURSOR.

       CALL-SKIP-VALUE.
           INITIALIZE LOCAL-JSON-PARM
           MOVE JSON-SKIP-VALUE TO L-OPERATION
           SET L-INPUT-PTR TO JP-INPUT-PTR
           MOVE JP-INPUT-LENGTH TO L-INPUT-LENGTH
           MOVE WS-CURSOR TO L-CURSOR
           MOVE WS-DEPTH TO L-DEPTH
           SET L-NAME-PTR TO ADDRESS OF WS-INTERNAL-TOKEN
           CALL "JSONSCAN" USING LOCAL-JSON-PARM
           IF L-STATUS NOT = STATUS-OK
               MOVE FLAG-ON TO WS-ERROR
           ELSE
               MOVE L-NEXT-CURSOR TO WS-CURSOR
           END-IF.

       SCAN-STRING.
           IF INPUT-BYTE(WS-CURSOR) NOT = X'22'
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-CURSOR
           PERFORM UNTIL WS-CURSOR > JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'22'
                   ADD 1 TO WS-CURSOR
                   EXIT PARAGRAPH
               END-IF
               IF INPUT-BYTE(WS-CURSOR) < X'20'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
               END-IF
               IF INPUT-BYTE(WS-CURSOR) = X'5C'
                   ADD 1 TO WS-CURSOR
                   IF WS-CURSOR > JP-INPUT-LENGTH
                       MOVE FLAG-ON TO WS-ERROR
                       EXIT PARAGRAPH
                   END-IF
                   EVALUATE TRUE
                       WHEN INPUT-BYTE(WS-CURSOR) = X'22'
                         OR INPUT-BYTE(WS-CURSOR) = X'5C'
                         OR INPUT-BYTE(WS-CURSOR) = X'2F'
                         OR INPUT-BYTE(WS-CURSOR) = X'62'
                         OR INPUT-BYTE(WS-CURSOR) = X'66'
                         OR INPUT-BYTE(WS-CURSOR) = X'6E'
                         OR INPUT-BYTE(WS-CURSOR) = X'72'
                         OR INPUT-BYTE(WS-CURSOR) = X'74'
                           ADD 1 TO WS-CURSOR
                       WHEN INPUT-BYTE(WS-CURSOR) = X'75'
                           ADD 1 TO WS-CURSOR
                           PERFORM READ-HEX4
                           IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
                           MOVE WS-VALUE TO WS-HIGH
                           IF WS-HIGH >= 55296 AND WS-HIGH <= 56319
                               COMPUTE WS-NEXT = WS-CURSOR + 1
                               IF WS-NEXT > JP-INPUT-LENGTH
                                   MOVE FLAG-ON TO WS-ERROR
                                   EXIT PARAGRAPH
                               END-IF
                               IF INPUT-BYTE(WS-CURSOR) NOT = X'5C'
                                  OR INPUT-BYTE(WS-CURSOR + 1)
                                      NOT = X'75'
                                   MOVE FLAG-ON TO WS-ERROR
                                   EXIT PARAGRAPH
                               END-IF
                               ADD 2 TO WS-CURSOR
                               PERFORM READ-HEX4
                               IF WS-VALUE < 56320 OR WS-VALUE > 57343
                                   MOVE FLAG-ON TO WS-ERROR
                                   EXIT PARAGRAPH
                               END-IF
                           ELSE
                               IF WS-HIGH >= 56320 AND WS-HIGH <= 57343
                                   MOVE FLAG-ON TO WS-ERROR
                                   EXIT PARAGRAPH
                               END-IF
                           END-IF
                       WHEN OTHER
                           MOVE FLAG-ON TO WS-ERROR
                           EXIT PARAGRAPH
                   END-EVALUATE
               ELSE
                   PERFORM VALIDATE-UTF8
                   ADD WS-WIDTH TO WS-CURSOR
               END-IF
               IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
           END-PERFORM
           MOVE FLAG-ON TO WS-ERROR.

       SKIP-TRUE.
           COMPUTE WS-NEXT = WS-CURSOR + 3
           IF WS-NEXT > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
           ELSE
               IF INPUT-AREA(WS-CURSOR:4) = X'74727565'
                   ADD 4 TO WS-CURSOR
               ELSE
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF.
       SKIP-FALSE.
           COMPUTE WS-NEXT = WS-CURSOR + 4
           IF WS-NEXT > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
           ELSE
               IF INPUT-AREA(WS-CURSOR:5) = X'66616C7365'
                   ADD 5 TO WS-CURSOR
               ELSE
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF.
       SKIP-NULL.
           COMPUTE WS-NEXT = WS-CURSOR + 3
           IF WS-NEXT > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
           ELSE
               IF INPUT-AREA(WS-CURSOR:4) = X'6E756C6C'
                   ADD 4 TO WS-CURSOR
               ELSE
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF.

       SKIP-NUMBER.
           IF INPUT-BYTE(WS-CURSOR) = X'2D'
               ADD 1 TO WS-CURSOR
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
               END-IF
           END-IF
           IF INPUT-BYTE(WS-CURSOR) = X'30'
               ADD 1 TO WS-CURSOR
               IF WS-CURSOR <= JP-INPUT-LENGTH
                   IF INPUT-BYTE(WS-CURSOR) >= X'30'
                     AND INPUT-BYTE(WS-CURSOR) <= X'39'
                       MOVE FLAG-ON TO WS-ERROR
                       EXIT PARAGRAPH
                   END-IF
               END-IF
           ELSE
               IF INPUT-BYTE(WS-CURSOR) < X'31'
                 OR INPUT-BYTE(WS-CURSOR) > X'39'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
               END-IF
               PERFORM UNTIL WS-CURSOR > JP-INPUT-LENGTH
                   IF INPUT-BYTE(WS-CURSOR) < X'30'
                     OR INPUT-BYTE(WS-CURSOR) > X'39'
                       EXIT PERFORM
                   END-IF
                   ADD 1 TO WS-CURSOR
               END-PERFORM
           END-IF
           IF WS-CURSOR <= JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'2E'
                   ADD 1 TO WS-CURSOR
                   MOVE 0 TO WS-DIGITS
                   PERFORM UNTIL WS-CURSOR > JP-INPUT-LENGTH
                       IF INPUT-BYTE(WS-CURSOR) < X'30'
                         OR INPUT-BYTE(WS-CURSOR) > X'39'
                           EXIT PERFORM
                       END-IF
                       ADD 1 TO WS-DIGITS WS-CURSOR
                   END-PERFORM
                   IF WS-DIGITS = 0
                       MOVE FLAG-ON TO WS-ERROR
                       EXIT PARAGRAPH
                   END-IF
               END-IF
           END-IF
           IF WS-CURSOR <= JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'65'
                 OR INPUT-BYTE(WS-CURSOR) = X'45'
                   ADD 1 TO WS-CURSOR
                   IF WS-CURSOR <= JP-INPUT-LENGTH
                       IF INPUT-BYTE(WS-CURSOR) = X'2B'
                         OR INPUT-BYTE(WS-CURSOR) = X'2D'
                           ADD 1 TO WS-CURSOR
                       END-IF
                   END-IF
                   MOVE 0 TO WS-DIGITS
                   PERFORM UNTIL WS-CURSOR > JP-INPUT-LENGTH
                       IF INPUT-BYTE(WS-CURSOR) < X'30'
                         OR INPUT-BYTE(WS-CURSOR) > X'39'
                           EXIT PERFORM
                       END-IF
                       ADD 1 TO WS-DIGITS WS-CURSOR
                   END-PERFORM
                   IF WS-DIGITS = 0
                       MOVE FLAG-ON TO WS-ERROR
                   END-IF
               END-IF
           END-IF.

       SKIP-SPACE.
           PERFORM UNTIL WS-CURSOR > JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'20'
                 OR INPUT-BYTE(WS-CURSOR) = X'09'
                 OR INPUT-BYTE(WS-CURSOR) = X'0A'
                 OR INPUT-BYTE(WS-CURSOR) = X'0D'
                   ADD 1 TO WS-CURSOR
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       VALIDATE-UTF8.
           MOVE 1 TO WS-WIDTH
           COMPUTE WS-VALUE = FUNCTION ORD(INPUT-BYTE(WS-CURSOR)) - 1
           EVALUATE TRUE
               WHEN WS-VALUE <= 127
                   CONTINUE
               WHEN WS-VALUE >= 194 AND WS-VALUE <= 223
                   MOVE 2 TO WS-WIDTH
               WHEN WS-VALUE >= 224 AND WS-VALUE <= 239
                   MOVE 3 TO WS-WIDTH
               WHEN WS-VALUE >= 240 AND WS-VALUE <= 244
                   MOVE 4 TO WS-WIDTH
               WHEN OTHER
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PARAGRAPH
           END-EVALUATE
           COMPUTE WS-NEXT = WS-CURSOR + WS-WIDTH
           SUBTRACT 1 FROM WS-NEXT
           IF WS-NEXT > JP-INPUT-LENGTH
               MOVE FLAG-ON TO WS-ERROR
               EXIT PARAGRAPH
           END-IF
           IF WS-WIDTH > 1
               COMPUTE WS-SCAN = WS-CURSOR + 1
               COMPUTE WS-NEXT = WS-CURSOR + WS-WIDTH - 1
               PERFORM UNTIL WS-SCAN > WS-NEXT
                   IF INPUT-BYTE(WS-SCAN) < X'80'
                     OR INPUT-BYTE(WS-SCAN) > X'BF'
                       MOVE FLAG-ON TO WS-ERROR
                   END-IF
                   ADD 1 TO WS-SCAN
               END-PERFORM
           END-IF
           IF WS-ERROR = FLAG-ON EXIT PARAGRAPH END-IF
           IF WS-WIDTH = 3
               IF INPUT-BYTE(WS-CURSOR) = X'E0'
                 AND INPUT-BYTE(WS-CURSOR + 1) < X'A0'
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
               IF INPUT-BYTE(WS-CURSOR) = X'ED'
                 AND INPUT-BYTE(WS-CURSOR + 1) > X'9F'
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF
           IF WS-WIDTH = 4
               IF INPUT-BYTE(WS-CURSOR) = X'F0'
                 AND INPUT-BYTE(WS-CURSOR + 1) < X'90'
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
               IF INPUT-BYTE(WS-CURSOR) = X'F4'
                 AND INPUT-BYTE(WS-CURSOR + 1) > X'8F'
                   MOVE FLAG-ON TO WS-ERROR
               END-IF
           END-IF.

       DO-FIND.
           SET ADDRESS OF NAME-AREA TO JP-NAME-PTR
           MOVE JP-CURSOR TO WS-CURSOR
           PERFORM SKIP-SPACE
           IF WS-CURSOR > JP-INPUT-LENGTH
               MOVE STATUS-JSON TO JP-STATUS
               EXIT PARAGRAPH
           END-IF
           IF INPUT-BYTE(WS-CURSOR) NOT = X'7B'
               MOVE STATUS-JSON TO JP-STATUS
               EXIT PARAGRAPH
           END-IF
           INITIALIZE LOCAL-JSON-PARM
           MOVE JSON-SKIP-VALUE TO L-OPERATION
           SET L-INPUT-PTR TO JP-INPUT-PTR
           MOVE JP-INPUT-LENGTH TO L-INPUT-LENGTH
           MOVE WS-CURSOR TO L-CURSOR
           CALL "JSONSCAN" USING LOCAL-JSON-PARM
           IF L-STATUS NOT = STATUS-OK
               MOVE STATUS-JSON TO JP-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE L-NEXT-CURSOR TO WS-OBJECT-END
           ADD 1 TO WS-CURSOR
           PERFORM SKIP-SPACE
           IF WS-CURSOR <= JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'7D'
                   ADD 1 TO WS-CURSOR
                   MOVE WS-CURSOR TO JP-NEXT-CURSOR
                   EXIT PARAGRAPH
               END-IF
           END-IF
           PERFORM UNTIL WS-ERROR = FLAG-ON
               MOVE WS-CURSOR TO WS-START
               MOVE WS-START TO WS-A-CURSOR
               MOVE 1 TO WS-B-CURSOR
               MOVE FLAG-ON TO WS-B-PLAIN
               PERFORM COMPARE-NAMES
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               MOVE WS-START TO WS-CURSOR
               PERFORM SCAN-STRING
               IF WS-ERROR = FLAG-ON EXIT PERFORM END-IF
               PERFORM SKIP-SPACE
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) NOT = X'3A'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-CURSOR
               PERFORM SKIP-SPACE
               MOVE WS-CURSOR TO WS-SAVE
               INITIALIZE LOCAL-JSON-PARM
               MOVE JSON-SKIP-VALUE TO L-OPERATION
               SET L-INPUT-PTR TO JP-INPUT-PTR
               MOVE JP-INPUT-LENGTH TO L-INPUT-LENGTH
               MOVE WS-CURSOR TO L-CURSOR
               CALL "JSONSCAN" USING LOCAL-JSON-PARM
               IF L-STATUS NOT = STATUS-OK
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               MOVE L-NEXT-CURSOR TO WS-CURSOR
               IF WS-NAMES-EQUAL = FLAG-ON
                   MOVE FLAG-ON TO JP-FOUND
                   MOVE L-SPAN-START TO JP-SPAN-START
                   MOVE L-SPAN-LENGTH TO JP-SPAN-LENGTH
               END-IF
               PERFORM SKIP-SPACE
               IF WS-CURSOR > JP-INPUT-LENGTH
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) = X'7D'
                   ADD 1 TO WS-CURSOR
                   EXIT PERFORM
               END-IF
               IF INPUT-BYTE(WS-CURSOR) NOT = X'2C'
                   MOVE FLAG-ON TO WS-ERROR
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-CURSOR
               PERFORM SKIP-SPACE
           END-PERFORM
           IF WS-ERROR = FLAG-ON
               MOVE STATUS-JSON TO JP-STATUS
               MOVE FLAG-OFF TO JP-FOUND
               MOVE 0 TO JP-SPAN-START JP-SPAN-LENGTH
           ELSE
               MOVE WS-OBJECT-END TO JP-NEXT-CURSOR
           END-IF.

       DO-NEXT.
           MOVE JP-CURSOR TO WS-CURSOR
           PERFORM SKIP-SPACE
           IF WS-CURSOR > JP-INPUT-LENGTH
               MOVE STATUS-JSON TO JP-STATUS
               EXIT PARAGRAPH
           END-IF
           IF INPUT-BYTE(WS-CURSOR) = X'5B'
               ADD 1 TO WS-CURSOR
               PERFORM SKIP-SPACE
           ELSE
               IF INPUT-BYTE(WS-CURSOR) = X'2C'
                   ADD 1 TO WS-CURSOR
                   PERFORM SKIP-SPACE
               END-IF
           END-IF
           IF WS-CURSOR <= JP-INPUT-LENGTH
               IF INPUT-BYTE(WS-CURSOR) = X'5D'
                   MOVE FLAG-ON TO JP-END
                   ADD 1 TO WS-CURSOR
                   MOVE WS-CURSOR TO JP-NEXT-CURSOR
                   EXIT PARAGRAPH
               END-IF
           END-IF
           MOVE WS-CURSOR TO WS-START
           PERFORM SKIP-VALUE
           IF WS-ERROR = FLAG-ON
               MOVE STATUS-JSON TO JP-STATUS
           ELSE
               MOVE WS-START TO JP-SPAN-START
               COMPUTE JP-SPAN-LENGTH = WS-CURSOR - WS-START
               PERFORM SKIP-SPACE
               MOVE WS-CURSOR TO JP-NEXT-CURSOR
           END-IF.

       END PROGRAM JSONSCAN.
