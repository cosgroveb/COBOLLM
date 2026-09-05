       IDENTIFICATION DIVISION.
       PROGRAM-ID. NATUTF8.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY POSIXNAT.
       01 WS-CONVERTER USAGE POINTER.
       01 WS-INVALID-CONVERTER USAGE POINTER VALUE -1.
       01 WS-IN-PTR USAGE POINTER.
       01 WS-OUT-PTR USAGE POINTER.
       01 WS-IN-LEFT PIC 9(9) COMP-5.
       01 WS-OUT-LEFT PIC 9(9) COMP-5.
       01 WS-CONVERT-RESULT PIC 9(9) COMP-5.
       01 WS-CLOSE-RESULT PIC S9(9) COMP-5.
       01 WS-ERRNO-PTR USAGE POINTER.
       01 WS-ERRNO PIC S9(9) COMP-5 BASED.
       01 WS-ERRNO-VALUE PIC S9(9) COMP-5.
       01 WS-SAVED-OUTPUT PIC S9(9) COMP-5.
       01 WS-SAVED-OUT-LEFT PIC 9(9) COMP-5.
       01 WS-SAVED-OUT-PTR USAGE POINTER.
       01 WS-PRODUCED PIC S9(9) COMP-5.
       01 WS-POS PIC S9(9) COMP-5.
       01 WS-WIDTH PIC S9(9) COMP-5.
       01 WS-LAST PIC S9(9) COMP-5.
       01 WS-BYTE PIC S9(9) COMP-5.
       01 WS-BYTE-2 PIC S9(9) COMP-5.
       01 WS-BYTE-3 PIC S9(9) COMP-5.
       01 WS-BYTE-4 PIC S9(9) COMP-5.
       01 WS-VALID PIC X.
       01 WS-REPLACE PIC X.
       01 WS-FINISHED PIC X.

       LINKAGE SECTION.
       COPY TXTPARM.
       01 TP-IN PIC X(16777216) BASED.
       01 TP-OUT PIC X(16777216) BASED.

       PROCEDURE DIVISION USING TEXT-PARM.
           MOVE STATUS-INTERNAL TO TP-STATUS
           MOVE ZERO TO TP-OUTPUT-LENGTH
           MOVE FLAG-OFF TO TP-REPLACED TP-TRUNCATED
           SET WS-CONVERTER TO NULL
           IF TP-INPUT-LENGTH > LIMIT-HISTORY OR
              TP-OUTPUT-CAPACITY > LIMIT-HISTORY
               MOVE STATUS-CAPACITY TO TP-STATUS
               GOBACK
           END-IF
           IF TP-OPERATION < TEXT-NATIVE-STRICT OR
              TP-OPERATION > TEXT-UTF8-REPLACE OR
              TP-INPUT-PTR = NULL OR TP-OUTPUT-PTR = NULL OR
              TP-INPUT-LENGTH < ZERO OR
              TP-OUTPUT-CAPACITY < ZERO
               GOBACK
           END-IF
           SET ADDRESS OF TP-IN TO TP-INPUT-PTR
           SET ADDRESS OF TP-OUT TO TP-OUTPUT-PTR
           MOVE FLAG-OFF TO WS-REPLACE WS-FINISHED
           IF TP-OPERATION = TEXT-NATIVE-REPLACE OR
              TP-OPERATION = TEXT-UTF8-REPLACE
               MOVE FLAG-ON TO WS-REPLACE
           END-IF
           IF TP-OPERATION = TEXT-NATIVE-STRICT OR
              TP-OPERATION = TEXT-NATIVE-REPLACE
               CALL 'iconv_open' USING
                   BY VALUE ADDRESS OF ZOS-UTF8-NAME
                   BY VALUE ADDRESS OF ZOS-1047-NAME
                   RETURNING WS-CONVERTER
           ELSE
               CALL 'iconv_open' USING
                   BY VALUE ADDRESS OF ZOS-1047-NAME
                   BY VALUE ADDRESS OF ZOS-UTF8-NAME
                   RETURNING WS-CONVERTER
           END-IF
           IF WS-CONVERTER = WS-INVALID-CONVERTER
               MOVE STATUS-TEXT-FATAL TO TP-STATUS
               GOBACK
           END-IF
           IF TP-OPERATION = TEXT-NATIVE-STRICT OR
              TP-OPERATION = TEXT-NATIVE-REPLACE
               PERFORM CONVERT-NATIVE
           ELSE
               PERFORM CONVERT-UTF8
           END-IF
           PERFORM CLOSE-CONVERTER
           GOBACK.

       CONVERT-NATIVE.
           SET WS-IN-PTR TO TP-INPUT-PTR
           SET WS-OUT-PTR TO TP-OUTPUT-PTR
           MOVE TP-INPUT-LENGTH TO WS-IN-LEFT
           MOVE TP-OUTPUT-CAPACITY TO WS-OUT-LEFT
           PERFORM UNTIL WS-IN-LEFT = ZERO OR
                         WS-FINISHED = FLAG-ON
               CALL 'iconv' USING BY VALUE WS-CONVERTER
                   BY REFERENCE WS-IN-PTR WS-IN-LEFT
                   BY REFERENCE WS-OUT-PTR WS-OUT-LEFT
                   RETURNING WS-CONVERT-RESULT
               COMPUTE TP-OUTPUT-LENGTH =
                   TP-OUTPUT-CAPACITY - WS-OUT-LEFT
               EVALUATE TRUE
                   WHEN WS-CONVERT-RESULT = ZERO AND
                        WS-IN-LEFT = ZERO
                       MOVE STATUS-OK TO TP-STATUS
                       MOVE FLAG-ON TO WS-FINISHED
                   WHEN WS-CONVERT-RESULT = 4294967295
                       PERFORM GET-ERRNO
                       EVALUATE WS-ERRNO-VALUE
                           WHEN ZOS-E2BIG
                               MOVE FLAG-ON TO TP-TRUNCATED
                               MOVE STATUS-CAPACITY TO TP-STATUS
                               MOVE FLAG-ON TO WS-FINISHED
                           WHEN ZOS-EILSEQ
                           WHEN ZOS-EINVAL
                               PERFORM REPLACE-NATIVE-BYTE
                           WHEN OTHER
                               PERFORM FATAL-CONVERSION
                       END-EVALUATE
                   WHEN OTHER
                       PERFORM FATAL-CONVERSION
               END-EVALUATE
           END-PERFORM
           IF TP-INPUT-LENGTH = ZERO
               MOVE STATUS-OK TO TP-STATUS
           END-IF.

       REPLACE-NATIVE-BYTE.
           EVALUATE TRUE
               WHEN WS-REPLACE = FLAG-OFF
                   MOVE ZERO TO TP-OUTPUT-LENGTH
                   MOVE STATUS-TEXT-INVALID TO TP-STATUS
                   MOVE FLAG-ON TO WS-FINISHED
               WHEN WS-OUT-LEFT < 3
                   MOVE FLAG-ON TO TP-TRUNCATED WS-FINISHED
                   MOVE STATUS-CAPACITY TO TP-STATUS
               WHEN OTHER
                   MOVE X'EF' TO TP-OUT(TP-OUTPUT-LENGTH + 1:1)
                   MOVE X'BF' TO TP-OUT(TP-OUTPUT-LENGTH + 2:1)
                   MOVE X'BD' TO TP-OUT(TP-OUTPUT-LENGTH + 3:1)
                   ADD 3 TO TP-OUTPUT-LENGTH
                   SUBTRACT 3 FROM WS-OUT-LEFT
                   SET WS-OUT-PTR UP BY 3
                   SET WS-IN-PTR UP BY 1
                   SUBTRACT 1 FROM WS-IN-LEFT
                   MOVE FLAG-ON TO TP-REPLACED
           END-EVALUATE.

       CONVERT-UTF8.
           MOVE 1 TO WS-POS
           MOVE TP-OUTPUT-CAPACITY TO WS-OUT-LEFT
           SET WS-OUT-PTR TO TP-OUTPUT-PTR
           PERFORM UNTIL WS-POS > TP-INPUT-LENGTH OR
                         WS-FINISHED = FLAG-ON
               PERFORM VALIDATE-NEXT
               IF WS-VALID = FLAG-OFF
                   PERFORM REPLACE-UTF8-BYTE
               ELSE
                   SET WS-IN-PTR TO ADDRESS OF TP-IN(WS-POS:1)
                   MOVE WS-WIDTH TO WS-IN-LEFT
                   MOVE TP-OUTPUT-LENGTH TO WS-SAVED-OUTPUT
                   MOVE WS-OUT-LEFT TO WS-SAVED-OUT-LEFT
                   SET WS-SAVED-OUT-PTR TO WS-OUT-PTR
                   CALL 'iconv' USING BY VALUE WS-CONVERTER
                       BY REFERENCE WS-IN-PTR WS-IN-LEFT
                       BY REFERENCE WS-OUT-PTR WS-OUT-LEFT
                       RETURNING WS-CONVERT-RESULT
                   COMPUTE TP-OUTPUT-LENGTH =
                       TP-OUTPUT-CAPACITY - WS-OUT-LEFT
                   EVALUATE TRUE
                       WHEN WS-CONVERT-RESULT = ZERO AND
                            WS-IN-LEFT = ZERO
                           ADD WS-WIDTH TO WS-POS
                       WHEN WS-CONVERT-RESULT > ZERO AND
                            WS-CONVERT-RESULT < 4294967295
                           PERFORM ROLLBACK-NONREVERSIBLE
                           PERFORM REPLACE-UTF8-SCALAR
                       WHEN WS-CONVERT-RESULT = 4294967295
                           PERFORM GET-ERRNO
                           EVALUATE WS-ERRNO-VALUE
                               WHEN ZOS-E2BIG
                                   MOVE FLAG-ON TO TP-TRUNCATED
                                   MOVE STATUS-CAPACITY TO TP-STATUS
                                   MOVE FLAG-ON TO WS-FINISHED
                               WHEN ZOS-EILSEQ
                                   PERFORM REPLACE-UTF8-SCALAR
                               WHEN OTHER
                                   PERFORM FATAL-CONVERSION
                           END-EVALUATE
                       WHEN OTHER
                           PERFORM FATAL-CONVERSION
                   END-EVALUATE
               END-IF
           END-PERFORM
           IF WS-FINISHED = FLAG-OFF
               MOVE STATUS-OK TO TP-STATUS
           END-IF.

       ROLLBACK-NONREVERSIBLE.
           COMPUTE WS-PRODUCED =
               TP-OUTPUT-LENGTH - WS-SAVED-OUTPUT
           IF WS-PRODUCED > ZERO
               MOVE LOW-VALUES TO
                   TP-OUT(WS-SAVED-OUTPUT + 1:WS-PRODUCED)
           END-IF
           MOVE WS-SAVED-OUTPUT TO TP-OUTPUT-LENGTH
           MOVE WS-SAVED-OUT-LEFT TO WS-OUT-LEFT
           SET WS-OUT-PTR TO WS-SAVED-OUT-PTR.

       REPLACE-UTF8-BYTE.
           MOVE 1 TO WS-WIDTH
           MOVE TP-OUTPUT-LENGTH TO WS-SAVED-OUTPUT
           PERFORM REPLACE-UTF8-SCALAR.

       REPLACE-UTF8-SCALAR.
           IF WS-REPLACE = FLAG-OFF
               MOVE ZERO TO TP-OUTPUT-LENGTH
               MOVE STATUS-TEXT-INVALID TO TP-STATUS
               MOVE FLAG-ON TO WS-FINISHED
           ELSE
               MOVE WS-SAVED-OUTPUT TO TP-OUTPUT-LENGTH
               COMPUTE WS-OUT-LEFT =
                   TP-OUTPUT-CAPACITY - TP-OUTPUT-LENGTH
               SET WS-OUT-PTR TO TP-OUTPUT-PTR
               SET WS-OUT-PTR UP BY TP-OUTPUT-LENGTH
               IF WS-OUT-LEFT < 1
                   MOVE FLAG-ON TO TP-TRUNCATED WS-FINISHED
                   MOVE STATUS-CAPACITY TO TP-STATUS
               ELSE
                   MOVE X'6F' TO TP-OUT(TP-OUTPUT-LENGTH + 1:1)
                   ADD 1 TO TP-OUTPUT-LENGTH
                   SUBTRACT 1 FROM WS-OUT-LEFT
                   SET WS-OUT-PTR UP BY 1
                   ADD WS-WIDTH TO WS-POS
                   MOVE FLAG-ON TO TP-REPLACED
               END-IF
           END-IF.

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

       GET-ERRNO.
           CALL '__errno' RETURNING WS-ERRNO-PTR
           IF WS-ERRNO-PTR = NULL
               MOVE ZERO TO WS-ERRNO-VALUE
           ELSE
               SET ADDRESS OF WS-ERRNO TO WS-ERRNO-PTR
               MOVE WS-ERRNO TO WS-ERRNO-VALUE
           END-IF.

       FATAL-CONVERSION.
           MOVE ZERO TO TP-OUTPUT-LENGTH
           MOVE STATUS-TEXT-FATAL TO TP-STATUS
           MOVE FLAG-ON TO WS-FINISHED.

       CLOSE-CONVERTER.
           CALL 'iconv_close' USING BY VALUE WS-CONVERTER
               RETURNING WS-CLOSE-RESULT
           SET WS-CONVERTER TO NULL
           IF WS-CLOSE-RESULT NOT = ZERO
               MOVE ZERO TO TP-OUTPUT-LENGTH
               MOVE STATUS-TEXT-FATAL TO TP-STATUS
           END-IF.

       END PROGRAM NATUTF8.
