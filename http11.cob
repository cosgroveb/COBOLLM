       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTTP11.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       OBJECT-COMPUTER. COBOLLM-HOST
           PROGRAM COLLATING SEQUENCE IS ASCII-WIRE.
       SPECIAL-NAMES.
           ALPHABET ASCII-WIRE IS STANDARD-1.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY NETPARM.

       01  WS-REQUEST-HEADER       PIC X(12288).
       01  WS-REQUEST-LENGTH       PIC S9(9) COMP-5.
       01  WS-RESPONSE-HEADER      PIC X(65536).
       01  WS-HEADER-LENGTH        PIC S9(9) COMP-5.
       01  WS-NET-BUFFER           PIC X(65536).
       01  WS-NET-LENGTH           PIC S9(9) COMP-5.
       01  WS-NET-POS              PIC S9(9) COMP-5.
       01  WS-NET-EOF              PIC X.
       01  WS-WIRE-BYTE            PIC S9(9) COMP-5.
       01  WS-WIRE-HAVE            PIC X.
       01  WS-WIRE-STATUS          PIC S9(9) COMP-5.

       01  WS-HOST                 PIC X(253).
       01  WS-HOST-LENGTH          PIC S9(9) COMP-5.
       01  WS-TARGET               PIC X(2059).
       01  WS-TARGET-LENGTH        PIC S9(9) COMP-5.
       01  WS-PORT                 PIC S9(9) COMP-5.
       01  WS-PORT-EXPLICIT        PIC X.
       01  WS-SCHEME               PIC S9(9) COMP-5.
       01  WS-AUTH-START           PIC S9(9) COMP-5.
       01  WS-AUTH-END             PIC S9(9) COMP-5.
       01  WS-PATH-START           PIC S9(9) COMP-5.
       01  WS-COLON                PIC S9(9) COMP-5.
       01  WS-LABEL-START          PIC S9(9) COMP-5.
       01  WS-LABEL-LENGTH         PIC S9(9) COMP-5.
       01  WS-IP-CANDIDATE         PIC X.
       01  WS-IP-SEGMENTS          PIC S9(9) COMP-5.
       01  WS-IP-VALUE             PIC S9(9) COMP-5.
       01  WS-VALID                PIC X.

       01  WS-OPEN                 PIC X.
       01  WS-PENDING-STATUS       PIC S9(9) COMP-5.
       01  WS-POS                  PIC S9(9) COMP-5.
       01  WS-END                  PIC S9(9) COMP-5.
       01  WS-LINE-START           PIC S9(9) COMP-5.
       01  WS-LINE-END             PIC S9(9) COMP-5.
       01  WS-COLON-POS            PIC S9(9) COMP-5.
       01  WS-VALUE-START          PIC S9(9) COMP-5.
       01  WS-VALUE-END            PIC S9(9) COMP-5.
       01  WS-BYTE                 PIC S9(9) COMP-5.
       01  WS-BYTE-2               PIC S9(9) COMP-5.
       01  WS-BYTE-CHAR            PIC X.
       01  WS-DIGIT                PIC S9(9) COMP-5.
       01  WS-NUMBER               PIC S9(9) COMP-5.
       01  WS-CURRENT-LENGTH       PIC S9(9) COMP-5.
       01  WS-FIELD-LENGTH         PIC S9(9) COMP-5.
       01  WS-CONTENT-LENGTH       PIC S9(9) COMP-5.
       01  WS-CHUNK-SIZE           PIC S9(9) COMP-5.
       01  WS-CHUNK-COUNT          PIC S9(9) COMP-5.
       01  WS-HAVE-LENGTH          PIC X.
       01  WS-HAVE-TRANSFER        PIC X.
       01  WS-HAVE-CONTENT-CODING  PIC X.
       01  WS-NAME-MATCH           PIC X.
       01  WS-NAME-PTR             USAGE POINTER.
       01  WS-NAME-LENGTH          PIC S9(9) COMP-5.
       01  WS-APPEND-PTR           USAGE POINTER.
       01  WS-APPEND-LENGTH        PIC S9(9) COMP-5.
       01  WS-SEND-PTR             USAGE POINTER.
       01  WS-SEND-LENGTH          PIC S9(9) COMP-5.
       01  WS-SEND-OFFSET          PIC S9(9) COMP-5.
       01  WS-ESCAPED              PIC X.
       01  WS-TEMP-CHAR            PIC X.
       01  WS-EXT-STATE            PIC X.
           88 EXT-BEFORE-NAME      VALUE X'01'.
           88 EXT-NAME             VALUE X'02'.
           88 EXT-AFTER-NAME       VALUE X'03'.
           88 EXT-BEFORE-VALUE     VALUE X'04'.
           88 EXT-TOKEN-VALUE      VALUE X'05'.
           88 EXT-QUOTED-VALUE     VALUE X'06'.
           88 EXT-AFTER-VALUE      VALUE X'07'.

       01  C-ASCII-DIGITS          PIC X(10) VALUE
           X"30313233343536373839".
       01  C-POST                  PIC X(5) VALUE X"504F535420".
       01  C-VERSION               PIC X(11) VALUE
           X"20485454502F312E310D0A".
       01  C-HOST                  PIC X(6) VALUE X"486F73743A20".
       01  C-AUTH                  PIC X(22) VALUE
           X"417574686F72697A6174696F6E3A2042656172657220".
       01  C-TYPE.
           05 FILLER PIC X(25) VALUE
              X"436F6E74656E742D547970653A206170706C69636174696F6E".
           05 FILLER PIC X(7) VALUE X"2F6A736F6E0D0A".
       01  C-ACCEPT.
           05 FILLER PIC X(24) VALUE
              X"4163636570743A206170706C69636174696F6E2F6A736F6E".
           05 FILLER PIC X(2) VALUE X"0D0A".
       01  C-ENCODING.
           05 FILLER PIC X(24) VALUE
              X"4163636570742D456E636F64696E673A206964656E746974".
           05 FILLER PIC X(3) VALUE X"790D0A".
       01  C-LENGTH                PIC X(16) VALUE
           X"436F6E74656E742D4C656E6774683A20".
       01  C-CLOSE                 PIC X(21) VALUE
           X"436F6E6E656374696F6E3A20636C6F73650D0A0D0A".
       01  C-RESPONSES             PIC X(10) VALUE
           X"2F726573706F6E736573".
       01  C-NAME-LENGTH           PIC X(14) VALUE
           X"636F6E74656E742D6C656E677468".
       01  C-NAME-TRANSFER         PIC X(17) VALUE
           X"7472616E736665722D656E636F64696E67".
       01  C-NAME-CONTENT          PIC X(16) VALUE
           X"636F6E74656E742D656E636F64696E67".
       01  C-VALUE-CHUNKED         PIC X(7) VALUE
           X"6368756E6B6564".
       01  C-VALUE-IDENTITY        PIC X(8) VALUE
           X"6964656E74697479".
       01  C-DECIMAL               PIC X(10).
       01  C-DECIMAL-LENGTH        PIC S9(9) COMP-5.

       LINKAGE SECTION.
       COPY HTTPPARM.
       01  HP-URL                  PIC X(2048).
       01  HP-KEY                  PIC X(8192).
       01  HP-BODY                 PIC X(16777216).
       01  HP-RESPONSE             PIC X(8388608).
       01  WS-APPEND-DATA          PIC X(16777216).
       01  WS-SEND-DATA            PIC X(16777216).
       01  WS-NAME-DATA            PIC X(32).

       PROCEDURE DIVISION USING HTTP-PARM.
           MOVE STATUS-INTERNAL TO HP-STATUS
           MOVE ZERO TO HP-RESPONSE-LENGTH HP-HTTP-STATUS
           MOVE FLAG-OFF TO HP-PLAINTEXT
           IF HP-OPERATION NOT = HTTP-PREFLIGHT AND
              HP-OPERATION NOT = HTTP-POST
               GOBACK
           END-IF
           IF HP-URL-LENGTH > LIMIT-URL
               MOVE STATUS-CAPACITY TO HP-STATUS
               GOBACK
           END-IF
           IF HP-URL-PTR = NULL OR HP-URL-LENGTH < 1
               MOVE STATUS-CONFIG-URL TO HP-STATUS
               GOBACK
           END-IF
           IF HP-OPERATION = HTTP-PREFLIGHT
               IF HP-KEY-PTR NOT = NULL OR HP-KEY-LENGTH NOT = 0 OR
                  HP-BODY-PTR NOT = NULL OR HP-BODY-LENGTH NOT = 0 OR
                  HP-RESPONSE-PTR NOT = NULL OR
                  HP-RESPONSE-CAPACITY NOT = 0
                   GOBACK
               END-IF
           ELSE
               IF HP-KEY-PTR = NULL OR HP-KEY-LENGTH < 0 OR
                  HP-KEY-LENGTH > LIMIT-KEY OR
                  HP-BODY-PTR = NULL OR HP-BODY-LENGTH < 0 OR
                  HP-BODY-LENGTH > LIMIT-REQUEST OR
                  HP-RESPONSE-PTR = NULL OR
                  HP-RESPONSE-CAPACITY < 0 OR
                  HP-RESPONSE-CAPACITY > LIMIT-RESPONSE
                   GOBACK
               END-IF
           END-IF
           SET ADDRESS OF HP-URL TO HP-URL-PTR
           PERFORM PARSE-URL
           IF HP-STATUS NOT = STATUS-OK
               GOBACK
           END-IF
           IF WS-SCHEME = NET-PLAINTEXT
               MOVE FLAG-ON TO HP-PLAINTEXT
           END-IF
           IF HP-OPERATION = HTTP-PREFLIGHT
               GOBACK
           END-IF
           SET ADDRESS OF HP-KEY TO HP-KEY-PTR
           SET ADDRESS OF HP-BODY TO HP-BODY-PTR
           SET ADDRESS OF HP-RESPONSE TO HP-RESPONSE-PTR
           PERFORM BUILD-REQUEST
           IF HP-STATUS NOT = STATUS-OK
               PERFORM ERASE-REQUEST
               GOBACK
           END-IF
           PERFORM EXCHANGE
           PERFORM ERASE-REQUEST
           GOBACK.

       PARSE-URL.
           MOVE STATUS-CONFIG-URL TO HP-STATUS
           MOVE SPACES TO WS-HOST WS-TARGET
           MOVE ZERO TO WS-HOST-LENGTH WS-TARGET-LENGTH WS-COLON
           MOVE ZERO TO WS-PORT WS-SCHEME
           MOVE FLAG-OFF TO WS-PORT-EXPLICIT
           MOVE FLAG-ON TO WS-VALID
           IF HP-URL-LENGTH >= 7 AND
              HP-URL(1:7) = X"687474703A2F2F"
               MOVE NET-PLAINTEXT TO WS-SCHEME
               MOVE 80 TO WS-PORT
               MOVE 8 TO WS-AUTH-START
           ELSE
               IF HP-URL-LENGTH >= 8 AND
                  HP-URL(1:8) = X"68747470733A2F2F"
                   MOVE NET-TLS TO WS-SCHEME
                   MOVE 443 TO WS-PORT
                   MOVE 9 TO WS-AUTH-START
               ELSE
                   EXIT PARAGRAPH
               END-IF
           END-IF
           MOVE HP-URL-LENGTH TO WS-AUTH-END
           MOVE ZERO TO WS-PATH-START
           PERFORM VARYING WS-POS FROM WS-AUTH-START BY 1
               UNTIL WS-POS > HP-URL-LENGTH
               MOVE HP-URL(WS-POS:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE = 47
                   MOVE WS-POS TO WS-PATH-START
                   COMPUTE WS-AUTH-END = WS-POS - 1
                   EXIT PERFORM
               END-IF
               IF WS-BYTE = 64 OR WS-BYTE = 63 OR WS-BYTE = 35 OR
                  WS-BYTE = 92 OR WS-BYTE <= 32 OR WS-BYTE > 126
                   MOVE FLAG-OFF TO WS-VALID
                   EXIT PERFORM
               END-IF
           END-PERFORM
           IF WS-VALID = FLAG-OFF
               EXIT PARAGRAPH
           END-IF
           IF WS-AUTH-END < WS-AUTH-START
               EXIT PARAGRAPH
           END-IF
           PERFORM VARYING WS-POS FROM WS-AUTH-START BY 1
               UNTIL WS-POS > WS-AUTH-END
               MOVE HP-URL(WS-POS:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE = 58
                   IF WS-COLON NOT = ZERO
                       MOVE FLAG-OFF TO WS-VALID
                       EXIT PERFORM
                   END-IF
                   MOVE WS-POS TO WS-COLON
               END-IF
           END-PERFORM
           IF WS-VALID = FLAG-OFF
               EXIT PARAGRAPH
           END-IF
           IF WS-COLON = WS-AUTH-START OR WS-COLON = WS-AUTH-END
               EXIT PARAGRAPH
           END-IF
           IF WS-COLON = ZERO
               COMPUTE WS-HOST-LENGTH =
                   WS-AUTH-END - WS-AUTH-START + 1
           ELSE
               COMPUTE WS-HOST-LENGTH = WS-COLON - WS-AUTH-START
               MOVE FLAG-ON TO WS-PORT-EXPLICIT
               MOVE ZERO TO WS-PORT
               COMPUTE WS-POS = WS-COLON + 1
               PERFORM VARYING WS-POS FROM WS-POS BY 1
                   UNTIL WS-POS > WS-AUTH-END
                   MOVE HP-URL(WS-POS:1) TO WS-BYTE-CHAR
                   COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
                   IF WS-BYTE < 48 OR WS-BYTE > 57
                       MOVE FLAG-OFF TO WS-VALID
                       EXIT PERFORM
                   END-IF
                   COMPUTE WS-DIGIT = WS-BYTE - 48
                   IF WS-PORT > 6553 OR
                      (WS-PORT = 6553 AND WS-DIGIT > 5)
                       MOVE FLAG-OFF TO WS-VALID
                       EXIT PERFORM
                   END-IF
                   MULTIPLY 10 BY WS-PORT
                   ADD WS-DIGIT TO WS-PORT
               END-PERFORM
               IF WS-VALID = FLAG-OFF
                   EXIT PARAGRAPH
               END-IF
               IF WS-PORT < 1
                   EXIT PARAGRAPH
               END-IF
           END-IF
           IF WS-HOST-LENGTH < 1 OR
              WS-HOST-LENGTH > LIMIT-HOST
               EXIT PARAGRAPH
           END-IF
           MOVE HP-URL(WS-AUTH-START:WS-HOST-LENGTH) TO
               WS-HOST(1:WS-HOST-LENGTH)
           MOVE 1 TO WS-LABEL-START
           PERFORM VARYING WS-POS FROM 1 BY 1
               UNTIL WS-POS > WS-HOST-LENGTH
               MOVE WS-HOST(WS-POS:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF NOT ((WS-BYTE >= 65 AND WS-BYTE <= 90) OR
                  (WS-BYTE >= 97 AND WS-BYTE <= 122) OR
                  (WS-BYTE >= 48 AND WS-BYTE <= 57)) AND
                  WS-BYTE NOT = 45 AND WS-BYTE NOT = 46
                   MOVE FLAG-OFF TO WS-VALID
                   EXIT PERFORM
               END-IF
               IF WS-BYTE = 46
                   COMPUTE WS-LABEL-LENGTH = WS-POS - WS-LABEL-START
                   IF WS-LABEL-LENGTH < 1 OR WS-LABEL-LENGTH > 63
                       MOVE FLAG-OFF TO WS-VALID
                       EXIT PERFORM
                   END-IF
                   PERFORM CHECK-LABEL-ENDS
                   IF WS-NAME-MATCH = FLAG-OFF
                       MOVE FLAG-OFF TO WS-VALID
                       EXIT PERFORM
                   END-IF
                   COMPUTE WS-LABEL-START = WS-POS + 1
               END-IF
           END-PERFORM
           IF WS-VALID = FLAG-OFF
               EXIT PARAGRAPH
           END-IF
           COMPUTE WS-LABEL-LENGTH =
               WS-HOST-LENGTH - WS-LABEL-START + 1
           IF WS-LABEL-LENGTH < 1 OR WS-LABEL-LENGTH > 63
               EXIT PARAGRAPH
           END-IF
           PERFORM CHECK-LABEL-ENDS
           IF WS-NAME-MATCH = FLAG-OFF
               EXIT PARAGRAPH
           END-IF
           PERFORM DETECT-IPV4
           IF WS-IP-CANDIDATE = FLAG-ON
               EXIT PARAGRAPH
           END-IF
           IF WS-PATH-START NOT = ZERO
               COMPUTE WS-TARGET-LENGTH =
                   HP-URL-LENGTH - WS-PATH-START + 1
               PERFORM VARYING WS-POS FROM WS-PATH-START BY 1
                   UNTIL WS-POS > HP-URL-LENGTH
                   MOVE HP-URL(WS-POS:1) TO WS-BYTE-CHAR
                   COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
                   IF WS-BYTE <= 32 OR WS-BYTE > 126 OR
                      WS-BYTE = 92 OR WS-BYTE = 63 OR WS-BYTE = 35
                       MOVE FLAG-OFF TO WS-VALID
                       EXIT PERFORM
                   END-IF
                   IF WS-BYTE = 37
                       COMPUTE WS-END = WS-POS + 2
                       IF WS-END > HP-URL-LENGTH
                           MOVE FLAG-OFF TO WS-VALID
                           EXIT PERFORM
                       END-IF
                       MOVE HP-URL(WS-POS + 1:1) TO WS-BYTE-CHAR
                       COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
                       PERFORM CHECK-HEX
                       IF WS-NAME-MATCH = FLAG-OFF
                           MOVE FLAG-OFF TO WS-VALID
                           EXIT PERFORM
                       END-IF
                       MOVE HP-URL(WS-POS + 2:1) TO WS-BYTE-CHAR
                       COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
                       PERFORM CHECK-HEX
                       IF WS-NAME-MATCH = FLAG-OFF
                           MOVE FLAG-OFF TO WS-VALID
                           EXIT PERFORM
                       END-IF
                   END-IF
               END-PERFORM
               IF WS-VALID = FLAG-OFF
                   EXIT PARAGRAPH
               END-IF
               MOVE HP-URL(WS-PATH-START:WS-TARGET-LENGTH) TO
                   WS-TARGET(1:WS-TARGET-LENGTH)
               PERFORM UNTIL WS-TARGET-LENGTH = ZERO OR
                   WS-TARGET(WS-TARGET-LENGTH:1) NOT = X"2F"
                   SUBTRACT 1 FROM WS-TARGET-LENGTH
               END-PERFORM
           END-IF
           IF WS-TARGET-LENGTH >
              LIMIT-URL-TARGET - LENGTH OF C-RESPONSES
               MOVE STATUS-CAPACITY TO HP-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE C-RESPONSES TO
               WS-TARGET(WS-TARGET-LENGTH + 1:
                         LENGTH OF C-RESPONSES)
           ADD LENGTH OF C-RESPONSES TO WS-TARGET-LENGTH
           MOVE STATUS-OK TO HP-STATUS.

       DETECT-IPV4.
           MOVE FLAG-ON TO WS-IP-CANDIDATE
           MOVE 1 TO WS-IP-SEGMENTS
           MOVE 1 TO WS-LABEL-START
           PERFORM UNTIL WS-LABEL-START > WS-HOST-LENGTH OR
               WS-IP-CANDIDATE = FLAG-OFF
               MOVE WS-LABEL-START TO WS-END
               PERFORM UNTIL WS-END > WS-HOST-LENGTH OR
                   WS-HOST(WS-END:1) = X'2E'
                   ADD 1 TO WS-END
               END-PERFORM
               COMPUTE WS-LABEL-LENGTH = WS-END - WS-LABEL-START
               PERFORM CHECK-IP-COMPONENT
               IF WS-END <= WS-HOST-LENGTH
                   ADD 1 TO WS-IP-SEGMENTS
                   IF WS-IP-SEGMENTS > 4
                       MOVE FLAG-OFF TO WS-IP-CANDIDATE
                   END-IF
                   COMPUTE WS-LABEL-START = WS-END + 1
               ELSE
                   COMPUTE WS-LABEL-START = WS-HOST-LENGTH + 1
               END-IF
           END-PERFORM.

       CHECK-IP-COMPONENT.
           MOVE WS-LABEL-START TO WS-POS
           MOVE ZERO TO WS-IP-VALUE
           IF WS-LABEL-LENGTH > 2 AND
              WS-HOST(WS-LABEL-START:1) = X'30' AND
              (WS-HOST(WS-LABEL-START + 1:1) = X'78' OR
               WS-HOST(WS-LABEL-START + 1:1) = X'58')
               COMPUTE WS-POS = WS-LABEL-START + 2
               MOVE 16 TO WS-IP-VALUE
           END-IF
           PERFORM VARYING WS-POS FROM WS-POS BY 1
               UNTIL WS-POS >= WS-END OR
                     WS-IP-CANDIDATE = FLAG-OFF
               MOVE WS-HOST(WS-POS:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-IP-VALUE = 16
                   IF NOT ((WS-BYTE >= 48 AND WS-BYTE <= 57) OR
                      (WS-BYTE >= 65 AND WS-BYTE <= 70) OR
                      (WS-BYTE >= 97 AND WS-BYTE <= 102))
                       MOVE FLAG-OFF TO WS-IP-CANDIDATE
                   END-IF
               ELSE
                   IF WS-BYTE < 48 OR WS-BYTE > 57
                       MOVE FLAG-OFF TO WS-IP-CANDIDATE
                   END-IF
               END-IF
           END-PERFORM.

       CHECK-LABEL-ENDS.
           MOVE FLAG-OFF TO WS-NAME-MATCH
           MOVE WS-HOST(WS-LABEL-START:1) TO WS-BYTE-CHAR
           COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
           IF NOT ((WS-BYTE >= 65 AND WS-BYTE <= 90) OR
              (WS-BYTE >= 97 AND WS-BYTE <= 122) OR
              (WS-BYTE >= 48 AND WS-BYTE <= 57))
               EXIT PARAGRAPH
           END-IF
           MOVE WS-HOST(WS-LABEL-START + WS-LABEL-LENGTH - 1:1)
               TO WS-BYTE-CHAR
           COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
           IF NOT ((WS-BYTE >= 65 AND WS-BYTE <= 90) OR
              (WS-BYTE >= 97 AND WS-BYTE <= 122) OR
              (WS-BYTE >= 48 AND WS-BYTE <= 57))
               EXIT PARAGRAPH
           END-IF
           MOVE FLAG-ON TO WS-NAME-MATCH.

       CHECK-HEX.
           MOVE FLAG-OFF TO WS-NAME-MATCH
           IF (WS-BYTE >= 48 AND WS-BYTE <= 57) OR
              (WS-BYTE >= 65 AND WS-BYTE <= 70) OR
              (WS-BYTE >= 97 AND WS-BYTE <= 102)
               MOVE FLAG-ON TO WS-NAME-MATCH
           END-IF.

       BUILD-REQUEST.
           MOVE STATUS-CAPACITY TO HP-STATUS
           MOVE LOW-VALUES TO WS-REQUEST-HEADER
           MOVE ZERO TO WS-REQUEST-LENGTH
           SET WS-APPEND-PTR TO ADDRESS OF C-POST
           MOVE 5 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO ADDRESS OF WS-TARGET
           MOVE WS-TARGET-LENGTH TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO ADDRESS OF C-VERSION
           MOVE 11 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO ADDRESS OF C-HOST
           MOVE 6 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO ADDRESS OF WS-HOST
           MOVE WS-HOST-LENGTH TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           IF WS-PORT-EXPLICIT = FLAG-ON
               PERFORM APPEND-COLON-PORT
           END-IF
           PERFORM APPEND-CRLF
           SET WS-APPEND-PTR TO ADDRESS OF C-AUTH
           MOVE 22 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO HP-KEY-PTR
           MOVE HP-KEY-LENGTH TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           PERFORM APPEND-CRLF
           SET WS-APPEND-PTR TO ADDRESS OF C-TYPE
           MOVE 32 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO ADDRESS OF C-ACCEPT
           MOVE 26 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO ADDRESS OF C-ENCODING
           MOVE 27 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           SET WS-APPEND-PTR TO ADDRESS OF C-LENGTH
           MOVE 16 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           MOVE HP-BODY-LENGTH TO WS-NUMBER
           PERFORM FORMAT-DECIMAL
           SET WS-APPEND-PTR TO ADDRESS OF C-DECIMAL
           MOVE C-DECIMAL-LENGTH TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           PERFORM APPEND-CRLF
           SET WS-APPEND-PTR TO ADDRESS OF C-CLOSE
           MOVE 21 TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST
           IF WS-REQUEST-LENGTH <= LIMIT-REQUEST-HEADER
               MOVE STATUS-OK TO HP-STATUS
           END-IF.

       APPEND-COLON-PORT.
           MOVE WS-PORT TO WS-NUMBER
           PERFORM FORMAT-DECIMAL
           MOVE X"3A" TO WS-REQUEST-HEADER(WS-REQUEST-LENGTH + 1:1)
           ADD 1 TO WS-REQUEST-LENGTH
           SET WS-APPEND-PTR TO ADDRESS OF C-DECIMAL
           MOVE C-DECIMAL-LENGTH TO WS-APPEND-LENGTH
           PERFORM APPEND-REQUEST.

       APPEND-CRLF.
           MOVE X"0D0A" TO
               WS-REQUEST-HEADER(WS-REQUEST-LENGTH + 1:2)
           ADD 2 TO WS-REQUEST-LENGTH.

       APPEND-REQUEST.
           IF WS-APPEND-LENGTH < 0 OR WS-REQUEST-LENGTH >
              LIMIT-REQUEST-HEADER - WS-APPEND-LENGTH
               COMPUTE WS-REQUEST-LENGTH = LIMIT-REQUEST-HEADER + 1
               EXIT PARAGRAPH
           END-IF
           IF WS-APPEND-LENGTH = ZERO
               EXIT PARAGRAPH
           END-IF
           SET ADDRESS OF WS-APPEND-DATA TO WS-APPEND-PTR
           MOVE WS-APPEND-DATA(1:WS-APPEND-LENGTH) TO
               WS-REQUEST-HEADER(WS-REQUEST-LENGTH + 1:
               WS-APPEND-LENGTH)
           ADD WS-APPEND-LENGTH TO WS-REQUEST-LENGTH.

       FORMAT-DECIMAL.
           MOVE LOW-VALUES TO C-DECIMAL
           MOVE ZERO TO C-DECIMAL-LENGTH
           IF WS-NUMBER = ZERO
               MOVE X"30" TO C-DECIMAL(1:1)
               MOVE 1 TO C-DECIMAL-LENGTH
               EXIT PARAGRAPH
           END-IF
           PERFORM UNTIL WS-NUMBER = ZERO
               COMPUTE WS-DIGIT = FUNCTION MOD(WS-NUMBER, 10)
               ADD 1 TO C-DECIMAL-LENGTH
               MOVE C-ASCII-DIGITS(WS-DIGIT + 1:1) TO
                   C-DECIMAL(C-DECIMAL-LENGTH:1)
               DIVIDE 10 INTO WS-NUMBER
           END-PERFORM
           MOVE 1 TO WS-POS
           MOVE C-DECIMAL-LENGTH TO WS-END
           PERFORM UNTIL WS-POS >= WS-END
               MOVE C-DECIMAL(WS-POS:1) TO WS-TEMP-CHAR
               MOVE C-DECIMAL(WS-END:1) TO C-DECIMAL(WS-POS:1)
               MOVE WS-TEMP-CHAR TO C-DECIMAL(WS-END:1)
               ADD 1 TO WS-POS
               SUBTRACT 1 FROM WS-END
           END-PERFORM.

       EXCHANGE.
           MOVE FLAG-OFF TO WS-OPEN
           MOVE STATUS-OK TO WS-PENDING-STATUS
           MOVE ZERO TO WS-NET-LENGTH WS-NET-POS
           MOVE FLAG-OFF TO WS-NET-EOF
           INITIALIZE NET-PARM
           MOVE NET-OPEN TO NP-OPERATION
           MOVE WS-SCHEME TO NP-SCHEME
           SET NP-CONNECT-HOST-PTR TO ADDRESS OF WS-HOST
           MOVE WS-HOST-LENGTH TO NP-CONNECT-HOST-LENGTH
           SET NP-VERIFY-HOST-PTR TO ADDRESS OF WS-HOST
           MOVE WS-HOST-LENGTH TO NP-VERIFY-HOST-LENGTH
           MOVE WS-PORT TO NP-PORT
           CALL "NETIO" USING NET-PARM
           IF NP-STATUS NOT = STATUS-OK
               MOVE STATUS-NETWORK TO HP-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE FLAG-ON TO WS-OPEN
           SET WS-SEND-PTR TO ADDRESS OF WS-REQUEST-HEADER
           MOVE WS-REQUEST-LENGTH TO WS-SEND-LENGTH
           PERFORM SEND-ALL
           IF WS-PENDING-STATUS = STATUS-OK AND
              HP-BODY-LENGTH > ZERO
               SET WS-SEND-PTR TO HP-BODY-PTR
               MOVE HP-BODY-LENGTH TO WS-SEND-LENGTH
               PERFORM SEND-ALL
           END-IF
           IF WS-PENDING-STATUS = STATUS-OK
               PERFORM READ-RESPONSE
           END-IF
           IF WS-PENDING-STATUS = STATUS-OK
               IF HP-HTTP-STATUS < 200 OR HP-HTTP-STATUS > 299
                   MOVE STATUS-HTTP-CODE TO WS-PENDING-STATUS
               END-IF
           END-IF
           PERFORM CLOSE-CONNECTION
           IF WS-PENDING-STATUS NOT = STATUS-OK
               IF HP-RESPONSE-LENGTH > ZERO
                   MOVE LOW-VALUES TO
                       HP-RESPONSE(1:HP-RESPONSE-LENGTH)
               END-IF
               MOVE ZERO TO HP-RESPONSE-LENGTH
           END-IF
           MOVE WS-PENDING-STATUS TO HP-STATUS
           MOVE LOW-VALUES TO WS-RESPONSE-HEADER WS-NET-BUFFER.

       SEND-ALL.
           MOVE ZERO TO WS-SEND-OFFSET
           SET ADDRESS OF WS-SEND-DATA TO WS-SEND-PTR
           PERFORM UNTIL WS-SEND-OFFSET = WS-SEND-LENGTH OR
               WS-PENDING-STATUS NOT = STATUS-OK
               INITIALIZE NET-PARM
               MOVE NET-WRITE TO NP-OPERATION
               SET NP-BUFFER-PTR TO ADDRESS OF
                   WS-SEND-DATA(WS-SEND-OFFSET + 1:1)
               COMPUTE NP-BUFFER-CAPACITY =
                   WS-SEND-LENGTH - WS-SEND-OFFSET
               IF NP-BUFFER-CAPACITY > LIMIT-NET-CHUNK
                   MOVE LIMIT-NET-CHUNK TO NP-BUFFER-CAPACITY
               END-IF
               MOVE NP-BUFFER-CAPACITY TO NP-REQUEST-LENGTH
               CALL "NETIO" USING NET-PARM
               IF NP-STATUS NOT = STATUS-OK OR
                  NP-TRANSFERRED <= ZERO OR
                  NP-TRANSFERRED > NP-REQUEST-LENGTH
                   MOVE STATUS-NETWORK TO WS-PENDING-STATUS
               ELSE
                   ADD NP-TRANSFERRED TO WS-SEND-OFFSET
               END-IF
           END-PERFORM.

       READ-RESPONSE.
           MOVE ZERO TO HP-RESPONSE-LENGTH WS-HEADER-LENGTH
           MOVE FLAG-OFF TO WS-HAVE-LENGTH WS-HAVE-TRANSFER
           MOVE FLAG-OFF TO WS-HAVE-CONTENT-CODING
           PERFORM UNTIL WS-PENDING-STATUS NOT = STATUS-OK
               PERFORM GET-WIRE-BYTE
               IF WS-WIRE-STATUS NOT = STATUS-OK
                   MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               IF WS-WIRE-HAVE = FLAG-OFF
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               IF WS-HEADER-LENGTH >= LIMIT-HTTP-HEADER
                   MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-HEADER-LENGTH
               MOVE FUNCTION CHAR(WS-WIRE-BYTE + 1) TO
                   WS-RESPONSE-HEADER(WS-HEADER-LENGTH:1)
               IF WS-HEADER-LENGTH >= 4 AND
                  WS-RESPONSE-HEADER(WS-HEADER-LENGTH - 3:4) =
                  X"0D0A0D0A"
                   EXIT PERFORM
               END-IF
           END-PERFORM
           IF WS-PENDING-STATUS NOT = STATUS-OK
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-HEADERS
           IF WS-PENDING-STATUS NOT = STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-HAVE-TRANSFER = FLAG-ON AND
              WS-HAVE-LENGTH = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           IF WS-HAVE-TRANSFER = FLAG-ON
               PERFORM READ-CHUNKED
           ELSE
               IF WS-HAVE-LENGTH = FLAG-ON
                   PERFORM READ-FIXED
               ELSE
                   PERFORM READ-TO-CLOSE
               END-IF
           END-IF.

       GET-WIRE-BYTE.
           MOVE STATUS-OK TO WS-WIRE-STATUS
           MOVE FLAG-OFF TO WS-WIRE-HAVE
           IF WS-NET-POS < WS-NET-LENGTH
               ADD 1 TO WS-NET-POS
               MOVE WS-NET-BUFFER(WS-NET-POS:1) TO WS-BYTE-CHAR
               COMPUTE WS-WIRE-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               MOVE FLAG-ON TO WS-WIRE-HAVE
               EXIT PARAGRAPH
           END-IF
           IF WS-NET-EOF = FLAG-ON
               EXIT PARAGRAPH
           END-IF
           INITIALIZE NET-PARM
           MOVE NET-READ TO NP-OPERATION
           SET NP-BUFFER-PTR TO ADDRESS OF WS-NET-BUFFER
           MOVE LIMIT-NET-CHUNK TO NP-BUFFER-CAPACITY
           CALL "NETIO" USING NET-PARM
           IF NP-STATUS NOT = STATUS-OK OR
              NP-TRANSFERRED < ZERO OR
              NP-TRANSFERRED > LIMIT-NET-CHUNK OR
              (NP-EOF NOT = FLAG-OFF AND NP-EOF NOT = FLAG-ON)
               MOVE STATUS-NETWORK TO WS-WIRE-STATUS
               EXIT PARAGRAPH
           END-IF
           IF NP-TRANSFERRED = ZERO AND NP-EOF = FLAG-OFF
               MOVE STATUS-NETWORK TO WS-WIRE-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE NP-TRANSFERRED TO WS-NET-LENGTH
           MOVE ZERO TO WS-NET-POS
           MOVE NP-EOF TO WS-NET-EOF
           IF WS-NET-LENGTH > ZERO
               ADD 1 TO WS-NET-POS
               MOVE WS-NET-BUFFER(1:1) TO WS-BYTE-CHAR
               COMPUTE WS-WIRE-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               MOVE FLAG-ON TO WS-WIRE-HAVE
           END-IF.

       PARSE-HEADERS.
           IF WS-HEADER-LENGTH < 17 OR
              WS-RESPONSE-HEADER(1:9) NOT =
              X"485454502F312E3120"
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           PERFORM VARYING WS-POS FROM 10 BY 1 UNTIL WS-POS > 12
               MOVE WS-RESPONSE-HEADER(WS-POS:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE < 48 OR WS-BYTE > 57
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PARAGRAPH
               END-IF
           END-PERFORM
           MOVE WS-RESPONSE-HEADER(10:1) TO WS-BYTE-CHAR
           COMPUTE WS-DIGIT = FUNCTION ORD(WS-BYTE-CHAR) - 1
           SUBTRACT 48 FROM WS-DIGIT
           MOVE WS-DIGIT TO HP-HTTP-STATUS
           MULTIPLY 10 BY HP-HTTP-STATUS
           MOVE WS-RESPONSE-HEADER(11:1) TO WS-BYTE-CHAR
           COMPUTE WS-DIGIT = FUNCTION ORD(WS-BYTE-CHAR) - 1
           SUBTRACT 48 FROM WS-DIGIT
           ADD WS-DIGIT TO HP-HTTP-STATUS
           MULTIPLY 10 BY HP-HTTP-STATUS
           MOVE WS-RESPONSE-HEADER(12:1) TO WS-BYTE-CHAR
           COMPUTE WS-DIGIT = FUNCTION ORD(WS-BYTE-CHAR) - 1
           SUBTRACT 48 FROM WS-DIGIT
           ADD WS-DIGIT TO HP-HTTP-STATUS
           IF HP-HTTP-STATUS < 100 OR HP-HTTP-STATUS > 999 OR
              WS-RESPONSE-HEADER(13:1) NOT = X"20"
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE 13 TO WS-POS
           PERFORM FIND-CRLF
           IF WS-LINE-END = ZERO
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           PERFORM VARYING WS-END FROM 14 BY 1
               UNTIL WS-END > WS-LINE-END
               MOVE WS-RESPONSE-HEADER(WS-END:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE NOT = 9 AND
                  (WS-BYTE < 32 OR WS-BYTE = 127)
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PARAGRAPH
               END-IF
           END-PERFORM
           COMPUTE WS-POS = WS-LINE-END + 3
           PERFORM UNTIL WS-POS > WS-HEADER-LENGTH - 2 OR
               WS-PENDING-STATUS NOT = STATUS-OK
               IF WS-RESPONSE-HEADER(WS-POS:2) = X"0D0A"
                   EXIT PERFORM
               END-IF
               MOVE WS-POS TO WS-LINE-START
               PERFORM FIND-CRLF
               IF WS-LINE-END = ZERO
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               PERFORM PARSE-HEADER-LINE
               COMPUTE WS-POS = WS-LINE-END + 3
           END-PERFORM.

       FIND-CRLF.
           MOVE ZERO TO WS-LINE-END
           PERFORM VARYING WS-END FROM WS-POS BY 1
               UNTIL WS-END >= WS-HEADER-LENGTH
               IF WS-RESPONSE-HEADER(WS-END:2) = X"0D0A"
                   COMPUTE WS-LINE-END = WS-END - 1
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       PARSE-HEADER-LINE.
           MOVE ZERO TO WS-COLON-POS
           PERFORM VARYING WS-END FROM WS-LINE-START BY 1
               UNTIL WS-END > WS-LINE-END
               MOVE WS-RESPONSE-HEADER(WS-END:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE = 58
                   MOVE WS-END TO WS-COLON-POS
                   EXIT PERFORM
               END-IF
               PERFORM CHECK-TOKEN
               IF WS-NAME-MATCH = FLAG-OFF
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PARAGRAPH
               END-IF
           END-PERFORM
           IF WS-COLON-POS <= WS-LINE-START
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           COMPUTE WS-VALUE-START = WS-COLON-POS + 1
           MOVE WS-LINE-END TO WS-VALUE-END
           PERFORM TRIM-OWS
           PERFORM VARYING WS-END FROM WS-VALUE-START BY 1
               UNTIL WS-END > WS-VALUE-END
               MOVE WS-RESPONSE-HEADER(WS-END:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE NOT = 9 AND
                  (WS-BYTE < 32 OR WS-BYTE = 127)
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PARAGRAPH
               END-IF
           END-PERFORM
           SET WS-NAME-PTR TO ADDRESS OF C-NAME-LENGTH
           MOVE 14 TO WS-NAME-LENGTH
           PERFORM MATCH-HEADER-NAME
           IF WS-NAME-MATCH = FLAG-ON
               PERFORM PARSE-CONTENT-LENGTH
               EXIT PARAGRAPH
           END-IF
           SET WS-NAME-PTR TO ADDRESS OF C-NAME-TRANSFER
           MOVE 17 TO WS-NAME-LENGTH
           PERFORM MATCH-HEADER-NAME
           IF WS-NAME-MATCH = FLAG-ON
               PERFORM PARSE-TRANSFER
               EXIT PARAGRAPH
           END-IF
           SET WS-NAME-PTR TO ADDRESS OF C-NAME-CONTENT
           MOVE 16 TO WS-NAME-LENGTH
           PERFORM MATCH-HEADER-NAME
           IF WS-NAME-MATCH = FLAG-ON
               PERFORM PARSE-CONTENT-CODING
           END-IF.

       CHECK-TOKEN.
           MOVE FLAG-OFF TO WS-NAME-MATCH
           IF (WS-BYTE >= 48 AND WS-BYTE <= 57) OR
              (WS-BYTE >= 65 AND WS-BYTE <= 90) OR
              (WS-BYTE >= 97 AND WS-BYTE <= 122) OR
              WS-BYTE = 33 OR WS-BYTE = 35 OR WS-BYTE = 36 OR
              WS-BYTE = 37 OR WS-BYTE = 38 OR WS-BYTE = 39 OR
              WS-BYTE = 42 OR WS-BYTE = 43 OR WS-BYTE = 45 OR
              WS-BYTE = 46 OR WS-BYTE = 94 OR WS-BYTE = 95 OR
              WS-BYTE = 96 OR WS-BYTE = 124 OR WS-BYTE = 126
               MOVE FLAG-ON TO WS-NAME-MATCH
           END-IF.

       TRIM-OWS.
           PERFORM UNTIL WS-VALUE-START > WS-VALUE-END
               MOVE WS-RESPONSE-HEADER(WS-VALUE-START:1)
                   TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE NOT = 32 AND WS-BYTE NOT = 9
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-VALUE-START
           END-PERFORM
           PERFORM UNTIL WS-VALUE-END < WS-VALUE-START
               MOVE WS-RESPONSE-HEADER(WS-VALUE-END:1)
                   TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE NOT = 32 AND WS-BYTE NOT = 9
                   EXIT PERFORM
               END-IF
               SUBTRACT 1 FROM WS-VALUE-END
           END-PERFORM.

       MATCH-HEADER-NAME.
           MOVE FLAG-OFF TO WS-NAME-MATCH
           COMPUTE WS-CURRENT-LENGTH =
               WS-COLON-POS - WS-LINE-START
           IF WS-CURRENT-LENGTH NOT = WS-NAME-LENGTH
               EXIT PARAGRAPH
           END-IF
           SET ADDRESS OF WS-NAME-DATA TO WS-NAME-PTR
           MOVE FLAG-ON TO WS-NAME-MATCH
           PERFORM VARYING WS-END FROM 1 BY 1
               UNTIL WS-END > WS-NAME-LENGTH
               MOVE WS-RESPONSE-HEADER(
                   WS-LINE-START + WS-END - 1:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE >= 65 AND WS-BYTE <= 90
                   ADD 32 TO WS-BYTE
               END-IF
               MOVE WS-NAME-DATA(WS-END:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE-2 = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE NOT = WS-BYTE-2
                   MOVE FLAG-OFF TO WS-NAME-MATCH
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       PARSE-CONTENT-LENGTH.
           IF WS-VALUE-START > WS-VALUE-END
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE WS-VALUE-START TO WS-POS
           MOVE ZERO TO WS-CURRENT-LENGTH
           MOVE ZERO TO WS-FIELD-LENGTH
           PERFORM UNTIL WS-POS > WS-VALUE-END
               MOVE ZERO TO WS-NUMBER
               MOVE FLAG-OFF TO WS-NAME-MATCH
               PERFORM UNTIL WS-POS > WS-VALUE-END
                   MOVE WS-RESPONSE-HEADER(WS-POS:1)
                       TO WS-BYTE-CHAR
                   COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
                   IF WS-BYTE < 48 OR WS-BYTE > 57
                       EXIT PERFORM
                   END-IF
                   MOVE FLAG-ON TO WS-NAME-MATCH
                   COMPUTE WS-DIGIT = WS-BYTE - 48
                   IF WS-NUMBER >
                      (LIMIT-RESPONSE - WS-DIGIT) / 10
                       MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
                       EXIT PARAGRAPH
                   END-IF
                   MULTIPLY 10 BY WS-NUMBER
                   ADD WS-DIGIT TO WS-NUMBER
                   ADD 1 TO WS-POS
               END-PERFORM
               IF WS-NAME-MATCH = FLAG-OFF
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PARAGRAPH
               END-IF
               IF WS-CURRENT-LENGTH = ZERO
                   MOVE WS-NUMBER TO WS-FIELD-LENGTH
               ELSE
                   IF WS-NUMBER NOT = WS-FIELD-LENGTH
                       MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       EXIT PARAGRAPH
                   END-IF
               END-IF
               ADD 1 TO WS-CURRENT-LENGTH
               PERFORM UNTIL WS-POS > WS-VALUE-END
                   MOVE WS-RESPONSE-HEADER(WS-POS:1)
                       TO WS-BYTE-CHAR
                   COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
                   IF WS-BYTE NOT = 32 AND WS-BYTE NOT = 9
                       EXIT PERFORM
                   END-IF
                   ADD 1 TO WS-POS
               END-PERFORM
               IF WS-POS <= WS-VALUE-END
                   IF WS-RESPONSE-HEADER(WS-POS:1) NOT = X"2C"
                       MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       EXIT PARAGRAPH
                   END-IF
                   ADD 1 TO WS-POS
                   PERFORM UNTIL WS-POS > WS-VALUE-END
                       MOVE WS-RESPONSE-HEADER(WS-POS:1)
                           TO WS-BYTE-CHAR
                       COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
                       IF WS-BYTE NOT = 32 AND WS-BYTE NOT = 9
                           EXIT PERFORM
                       END-IF
                       ADD 1 TO WS-POS
                   END-PERFORM
                   IF WS-POS > WS-VALUE-END
                       MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       EXIT PARAGRAPH
                   END-IF
               END-IF
           END-PERFORM
           IF WS-HAVE-LENGTH = FLAG-ON AND
              WS-CONTENT-LENGTH NOT = WS-FIELD-LENGTH
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE WS-FIELD-LENGTH TO WS-CONTENT-LENGTH
           MOVE FLAG-ON TO WS-HAVE-LENGTH.

       PARSE-TRANSFER.
           IF WS-HAVE-TRANSFER = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE 7 TO WS-NAME-LENGTH
           SET WS-NAME-PTR TO ADDRESS OF C-VALUE-CHUNKED
           PERFORM MATCH-HEADER-VALUE
           IF WS-NAME-MATCH = FLAG-OFF
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE FLAG-ON TO WS-HAVE-TRANSFER.

       PARSE-CONTENT-CODING.
           IF WS-HAVE-CONTENT-CODING = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE 8 TO WS-NAME-LENGTH
           SET WS-NAME-PTR TO ADDRESS OF C-VALUE-IDENTITY
           PERFORM MATCH-HEADER-VALUE
           IF WS-NAME-MATCH = FLAG-OFF
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           MOVE FLAG-ON TO WS-HAVE-CONTENT-CODING.

       MATCH-HEADER-VALUE.
           MOVE FLAG-OFF TO WS-NAME-MATCH
           COMPUTE WS-CURRENT-LENGTH =
               WS-VALUE-END - WS-VALUE-START + 1
           IF WS-CURRENT-LENGTH NOT = WS-NAME-LENGTH
               EXIT PARAGRAPH
           END-IF
           SET ADDRESS OF WS-NAME-DATA TO WS-NAME-PTR
           MOVE FLAG-ON TO WS-NAME-MATCH
           PERFORM VARYING WS-END FROM 1 BY 1
               UNTIL WS-END > WS-NAME-LENGTH
               MOVE WS-RESPONSE-HEADER(
                   WS-VALUE-START + WS-END - 1:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE >= 65 AND WS-BYTE <= 90
                   ADD 32 TO WS-BYTE
               END-IF
               MOVE WS-NAME-DATA(WS-END:1) TO WS-BYTE-CHAR
               COMPUTE WS-BYTE-2 = FUNCTION ORD(WS-BYTE-CHAR) - 1
               IF WS-BYTE NOT = WS-BYTE-2
                   MOVE FLAG-OFF TO WS-NAME-MATCH
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       READ-FIXED.
           IF WS-CONTENT-LENGTH > HP-RESPONSE-CAPACITY
               MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           PERFORM WS-CONTENT-LENGTH TIMES
               PERFORM GET-WIRE-BYTE
               IF WS-WIRE-STATUS NOT = STATUS-OK
                   MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               IF WS-WIRE-HAVE = FLAG-OFF
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               PERFORM STORE-RESPONSE-BYTE
           END-PERFORM
           IF WS-PENDING-STATUS NOT = STATUS-OK
               EXIT PARAGRAPH
           END-IF
           PERFORM REQUIRE-END-OF-WIRE.

       READ-TO-CLOSE.
           PERFORM UNTIL WS-PENDING-STATUS NOT = STATUS-OK
               PERFORM GET-WIRE-BYTE
               IF WS-WIRE-STATUS NOT = STATUS-OK
                   MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               IF WS-WIRE-HAVE = FLAG-OFF
                   EXIT PERFORM
               END-IF
               PERFORM STORE-RESPONSE-BYTE
           END-PERFORM.

       STORE-RESPONSE-BYTE.
           IF HP-RESPONSE-LENGTH >= HP-RESPONSE-CAPACITY
               MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO HP-RESPONSE-LENGTH
           MOVE FUNCTION CHAR(WS-WIRE-BYTE + 1) TO
               HP-RESPONSE(HP-RESPONSE-LENGTH:1).

       READ-CHUNKED.
           PERFORM UNTIL WS-PENDING-STATUS NOT = STATUS-OK
               PERFORM READ-CHUNK-SIZE
               IF WS-PENDING-STATUS NOT = STATUS-OK
                   EXIT PERFORM
               END-IF
               IF WS-CHUNK-SIZE = ZERO
                   PERFORM READ-TRAILERS
                   IF WS-PENDING-STATUS = STATUS-OK
                       PERFORM REQUIRE-END-OF-WIRE
                   END-IF
                   EXIT PERFORM
               END-IF
               IF HP-RESPONSE-LENGTH >
                  HP-RESPONSE-CAPACITY - WS-CHUNK-SIZE
                   MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               PERFORM WS-CHUNK-SIZE TIMES
                   PERFORM GET-WIRE-BYTE
                   IF WS-WIRE-STATUS NOT = STATUS-OK
                       MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
                       EXIT PERFORM
                   END-IF
                   IF WS-WIRE-HAVE = FLAG-OFF
                       MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       EXIT PERFORM
                   END-IF
                   PERFORM STORE-RESPONSE-BYTE
               END-PERFORM
               IF WS-PENDING-STATUS = STATUS-OK
                   PERFORM REQUIRE-CRLF
               END-IF
           END-PERFORM.

       READ-CHUNK-SIZE.
           MOVE ZERO TO WS-CHUNK-SIZE WS-CHUNK-COUNT
           MOVE FLAG-OFF TO WS-ESCAPED
           PERFORM UNTIL WS-PENDING-STATUS NOT = STATUS-OK
               PERFORM GET-WIRE-BYTE
               IF WS-WIRE-STATUS NOT = STATUS-OK
                   MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               IF WS-WIRE-HAVE = FLAG-OFF
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               IF WS-CHUNK-COUNT = ZERO
                   PERFORM HEX-DIGIT-VALUE
                   IF WS-DIGIT < ZERO
                       MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       EXIT PERFORM
                   END-IF
                   MOVE 1 TO WS-CHUNK-COUNT
               ELSE
                   PERFORM HEX-DIGIT-VALUE
                   IF WS-DIGIT < ZERO
                       EXIT PERFORM
                   END-IF
               END-IF
               IF WS-CHUNK-SIZE >
                  (LIMIT-RESPONSE - WS-DIGIT) / 16
                   MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               MULTIPLY 16 BY WS-CHUNK-SIZE
               ADD WS-DIGIT TO WS-CHUNK-SIZE
           END-PERFORM
           IF WS-PENDING-STATUS NOT = STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-WIRE-BYTE = 59
               PERFORM READ-CHUNK-EXTENSION
           ELSE
               IF WS-WIRE-BYTE NOT = 13
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PARAGRAPH
               END-IF
               PERFORM REQUIRE-LF
           END-IF.

       HEX-DIGIT-VALUE.
           MOVE -1 TO WS-DIGIT
           IF WS-WIRE-BYTE >= 48 AND WS-WIRE-BYTE <= 57
               COMPUTE WS-DIGIT = WS-WIRE-BYTE - 48
           ELSE
               IF WS-WIRE-BYTE >= 65 AND WS-WIRE-BYTE <= 70
                   COMPUTE WS-DIGIT = WS-WIRE-BYTE - 55
               ELSE
                   IF WS-WIRE-BYTE >= 97 AND WS-WIRE-BYTE <= 102
                       COMPUTE WS-DIGIT = WS-WIRE-BYTE - 87
                   END-IF
               END-IF
           END-IF.

       READ-CHUNK-EXTENSION.
           SET EXT-BEFORE-NAME TO TRUE
           MOVE 1 TO WS-CURRENT-LENGTH
           MOVE FLAG-OFF TO WS-ESCAPED
           PERFORM UNTIL WS-PENDING-STATUS NOT = STATUS-OK
               PERFORM GET-WIRE-BYTE
               IF WS-WIRE-STATUS NOT = STATUS-OK
                   MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               IF WS-WIRE-HAVE = FLAG-OFF
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-CURRENT-LENGTH
               IF WS-CURRENT-LENGTH > LIMIT-HTTP-HEADER
                   MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
                   EXIT PERFORM
               END-IF
               MOVE WS-WIRE-BYTE TO WS-BYTE
               IF EXT-BEFORE-NAME
                   IF WS-BYTE = 32 OR WS-BYTE = 9
                       CONTINUE
                   ELSE
                       PERFORM CHECK-TOKEN
                       IF WS-NAME-MATCH = FLAG-ON
                           SET EXT-NAME TO TRUE
                       ELSE
                           MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       END-IF
                   END-IF
               ELSE
               IF EXT-NAME
                   PERFORM CHECK-TOKEN
                   IF WS-NAME-MATCH = FLAG-ON
                       CONTINUE
                   ELSE
                       IF WS-BYTE = 32 OR WS-BYTE = 9
                           SET EXT-AFTER-NAME TO TRUE
                       ELSE
                           IF WS-BYTE = 61
                               SET EXT-BEFORE-VALUE TO TRUE
                           ELSE
                               IF WS-BYTE = 59
                                   SET EXT-BEFORE-NAME TO TRUE
                               ELSE
                                   IF WS-BYTE = 13
                                       PERFORM REQUIRE-LF
                                       EXIT PERFORM
                                   ELSE
                                       MOVE STATUS-HTTP TO
                                           WS-PENDING-STATUS
                                   END-IF
                               END-IF
                           END-IF
                       END-IF
                   END-IF
               ELSE
               IF EXT-AFTER-NAME
                   IF WS-BYTE = 32 OR WS-BYTE = 9
                       CONTINUE
                   ELSE
                       IF WS-BYTE = 61
                           SET EXT-BEFORE-VALUE TO TRUE
                       ELSE
                           IF WS-BYTE = 59
                               SET EXT-BEFORE-NAME TO TRUE
                           ELSE
                               IF WS-BYTE = 13
                                   PERFORM REQUIRE-LF
                                   EXIT PERFORM
                               ELSE
                                   MOVE STATUS-HTTP TO
                                       WS-PENDING-STATUS
                               END-IF
                           END-IF
                       END-IF
                   END-IF
               ELSE
               IF EXT-BEFORE-VALUE
                   IF WS-BYTE = 32 OR WS-BYTE = 9
                       CONTINUE
                   ELSE
                       IF WS-BYTE = 34
                           SET EXT-QUOTED-VALUE TO TRUE
                       ELSE
                           PERFORM CHECK-TOKEN
                           IF WS-NAME-MATCH = FLAG-ON
                               SET EXT-TOKEN-VALUE TO TRUE
                           ELSE
                               MOVE STATUS-HTTP TO WS-PENDING-STATUS
                           END-IF
                       END-IF
                   END-IF
               ELSE
               IF EXT-TOKEN-VALUE
                   PERFORM CHECK-TOKEN
                   IF WS-NAME-MATCH = FLAG-ON
                       CONTINUE
                   ELSE
                       IF WS-BYTE = 32 OR WS-BYTE = 9
                           SET EXT-AFTER-VALUE TO TRUE
                       ELSE
                           IF WS-BYTE = 59
                               SET EXT-BEFORE-NAME TO TRUE
                           ELSE
                               IF WS-BYTE = 13
                                   PERFORM REQUIRE-LF
                                   EXIT PERFORM
                               ELSE
                                   MOVE STATUS-HTTP TO
                                       WS-PENDING-STATUS
                               END-IF
                           END-IF
                       END-IF
                   END-IF
               ELSE
               IF EXT-QUOTED-VALUE
                   IF WS-ESCAPED = FLAG-ON
                       IF WS-BYTE NOT = 9 AND
                          (WS-BYTE < 32 OR WS-BYTE = 127)
                           MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       END-IF
                       MOVE FLAG-OFF TO WS-ESCAPED
                   ELSE
                       IF WS-BYTE = 92
                           MOVE FLAG-ON TO WS-ESCAPED
                       ELSE
                           IF WS-BYTE = 34
                               SET EXT-AFTER-VALUE TO TRUE
                           ELSE
                               IF WS-BYTE NOT = 9 AND
                                  (WS-BYTE < 32 OR WS-BYTE = 127)
                                   MOVE STATUS-HTTP TO
                                       WS-PENDING-STATUS
                               END-IF
                           END-IF
                       END-IF
                   END-IF
               ELSE
               IF EXT-AFTER-VALUE
                   IF WS-BYTE = 32 OR WS-BYTE = 9
                       CONTINUE
                   ELSE
                       IF WS-BYTE = 59
                           SET EXT-BEFORE-NAME TO TRUE
                       ELSE
                           IF WS-BYTE = 13
                               PERFORM REQUIRE-LF
                               EXIT PERFORM
                           ELSE
                               MOVE STATUS-HTTP TO WS-PENDING-STATUS
                           END-IF
                       END-IF
                   END-IF
               ELSE
                   MOVE STATUS-HTTP TO WS-PENDING-STATUS
               END-IF END-IF END-IF END-IF END-IF END-IF END-IF
           END-PERFORM
           IF EXT-BEFORE-NAME OR EXT-BEFORE-VALUE OR
              EXT-QUOTED-VALUE OR WS-ESCAPED = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
           END-IF.

       REQUIRE-CRLF.
           PERFORM GET-WIRE-BYTE
           IF WS-WIRE-STATUS NOT = STATUS-OK
               MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           IF WS-WIRE-HAVE = FLAG-OFF OR WS-WIRE-BYTE NOT = 13
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           PERFORM REQUIRE-LF.

       REQUIRE-LF.
           PERFORM GET-WIRE-BYTE
           IF WS-WIRE-STATUS NOT = STATUS-OK
               MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           IF WS-WIRE-HAVE = FLAG-OFF OR WS-WIRE-BYTE NOT = 10
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
           END-IF.

       READ-TRAILERS.
           PERFORM UNTIL WS-PENDING-STATUS NOT = STATUS-OK
               MOVE WS-HEADER-LENGTH TO WS-LINE-START
               ADD 1 TO WS-LINE-START
               PERFORM UNTIL WS-PENDING-STATUS NOT = STATUS-OK
                   PERFORM GET-WIRE-BYTE
                   IF WS-WIRE-STATUS NOT = STATUS-OK
                       MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
                       EXIT PERFORM
                   END-IF
                   IF WS-WIRE-HAVE = FLAG-OFF
                       MOVE STATUS-HTTP TO WS-PENDING-STATUS
                       EXIT PERFORM
                   END-IF
                   IF WS-HEADER-LENGTH >= LIMIT-HTTP-HEADER
                       MOVE STATUS-CAPACITY TO WS-PENDING-STATUS
                       EXIT PERFORM
                   END-IF
                   ADD 1 TO WS-HEADER-LENGTH
                   MOVE FUNCTION CHAR(WS-WIRE-BYTE + 1) TO
                       WS-RESPONSE-HEADER(WS-HEADER-LENGTH:1)
                   IF WS-HEADER-LENGTH >= 2 AND
                      WS-RESPONSE-HEADER(WS-HEADER-LENGTH - 1:2) =
                      X"0D0A"
                       EXIT PERFORM
                   END-IF
               END-PERFORM
               IF WS-PENDING-STATUS NOT = STATUS-OK
                   EXIT PERFORM
               END-IF
               COMPUTE WS-LINE-END = WS-HEADER-LENGTH - 2
               IF WS-LINE-END < WS-LINE-START
                   EXIT PERFORM
               END-IF
               PERFORM VALIDATE-TRAILER-LINE
           END-PERFORM.

       VALIDATE-TRAILER-LINE.
           PERFORM PARSE-HEADER-LINE
           IF WS-PENDING-STATUS NOT = STATUS-OK
               EXIT PARAGRAPH
           END-IF
           SET WS-NAME-PTR TO ADDRESS OF C-NAME-LENGTH
           MOVE 14 TO WS-NAME-LENGTH
           PERFORM MATCH-HEADER-NAME
           IF WS-NAME-MATCH = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           SET WS-NAME-PTR TO ADDRESS OF C-NAME-TRANSFER
           MOVE 17 TO WS-NAME-LENGTH
           PERFORM MATCH-HEADER-NAME
           IF WS-NAME-MATCH = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           SET WS-NAME-PTR TO ADDRESS OF C-NAME-CONTENT
           MOVE 16 TO WS-NAME-LENGTH
           PERFORM MATCH-HEADER-NAME
           IF WS-NAME-MATCH = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
           END-IF.

       REQUIRE-END-OF-WIRE.
           PERFORM GET-WIRE-BYTE
           IF WS-WIRE-STATUS NOT = STATUS-OK
               MOVE WS-WIRE-STATUS TO WS-PENDING-STATUS
               EXIT PARAGRAPH
           END-IF
           IF WS-WIRE-HAVE = FLAG-ON
               MOVE STATUS-HTTP TO WS-PENDING-STATUS
           END-IF.

       CLOSE-CONNECTION.
           IF WS-OPEN = FLAG-OFF
               EXIT PARAGRAPH
           END-IF
           INITIALIZE NET-PARM
           MOVE NET-CLOSE TO NP-OPERATION
           CALL "NETIO" USING NET-PARM
           MOVE FLAG-OFF TO WS-OPEN
           IF NP-STATUS NOT = STATUS-OK AND
              WS-PENDING-STATUS = STATUS-OK
               MOVE STATUS-NETWORK TO WS-PENDING-STATUS
           END-IF.

       ERASE-REQUEST.
           MOVE LOW-VALUES TO WS-REQUEST-HEADER
           MOVE ZERO TO WS-REQUEST-LENGTH.

       END PROGRAM HTTP11.
