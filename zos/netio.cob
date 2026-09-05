       IDENTIFICATION DIVISION.
       PROGRAM-ID. NETIO.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY NETNAT.
       COPY TXTPARM.
       01 WS-ACTIVE PIC X VALUE X'00'.
       01 WS-API-ACTIVE PIC X VALUE X'00'.
       01 WS-SIGNAL-SAVED PIC X VALUE X'00'.
       01 WS-SIGNAL-INSTALLED PIC X VALUE X'00'.
       01 WS-NULL USAGE POINTER.
       01 WS-NATIVE-RESULT PIC S9(8) BINARY.
       01 WS-PORT-DISPLAY PIC ZZZZ9.
       01 WS-PORT-START PIC S9(9) COMP-5.
       01 WS-PORT-LENGTH PIC S9(9) COMP-5.
       01 WS-SUCCESS PIC X VALUE X'00'.
       01 WS-RETRY PIC X VALUE X'00'.
       01 WS-ADVANCE PIC X VALUE X'00'.
       01 WS-PARAMETERS-VALID PIC X VALUE X'00'.
       01 WS-CLEANUP-FAILED PIC X VALUE X'00'.
       01 WS-CONNECT-ERRNO PIC 9(8) BINARY.
       01 WS-TTLS-IOCTL-DATA.
           COPY EZBZTLSB.

       LINKAGE SECTION.
       COPY NETPARM.
       01 LK-CONNECT-HOST PIC X(253) BASED.
       01 LK-VERIFY-HOST PIC X(253) BASED.
       01 LK-BUFFER PIC X(65536) BASED.

       PROCEDURE DIVISION USING NET-PARM.
           MOVE STATUS-INTERNAL TO NP-STATUS
           MOVE ZERO TO NP-TRANSFERRED
           MOVE FLAG-OFF TO NP-EOF
           PERFORM VALIDATE-PARAMETERS
           IF WS-PARAMETERS-VALID NOT = FLAG-ON GOBACK END-IF
           MOVE FLAG-OFF TO WS-CLEANUP-FAILED
           EVALUATE NP-OPERATION
               WHEN NET-OPEN PERFORM OPEN-CONNECTION
               WHEN NET-WRITE PERFORM WRITE-CONNECTION
               WHEN NET-READ PERFORM READ-CONNECTION
               WHEN NET-CLOSE PERFORM CLOSE-CONNECTION
               WHEN OTHER CONTINUE
           END-EVALUATE
           GOBACK.

       VALIDATE-PARAMETERS.
           MOVE FLAG-OFF TO WS-PARAMETERS-VALID
           EVALUATE NP-OPERATION
               WHEN NET-OPEN
                   IF NP-CONNECT-HOST-LENGTH > LIMIT-HOST OR
                      NP-VERIFY-HOST-LENGTH > LIMIT-HOST
                       MOVE STATUS-CAPACITY TO NP-STATUS
                       EXIT PARAGRAPH
                   END-IF
                   IF NP-CONNECT-HOST-PTR = NULL OR
                      NP-VERIFY-HOST-PTR = NULL OR
                      NP-CONNECT-HOST-LENGTH < 1 OR
                      NP-VERIFY-HOST-LENGTH < 1 OR
                      NP-BUFFER-PTR NOT = NULL OR
                      NP-BUFFER-CAPACITY NOT = ZERO OR
                      NP-REQUEST-LENGTH NOT = ZERO OR
                      NP-PORT < 1 OR NP-PORT > LIMIT-PORT OR
                      NP-SCHEME NOT = NET-TLS
                       EXIT PARAGRAPH
                   END-IF
                   IF NP-CONNECT-HOST-LENGTH NOT =
                      NP-VERIFY-HOST-LENGTH
                       EXIT PARAGRAPH
                   END-IF
                   SET ADDRESS OF LK-CONNECT-HOST TO
                       NP-CONNECT-HOST-PTR
                   SET ADDRESS OF LK-VERIFY-HOST TO
                       NP-VERIFY-HOST-PTR
                   IF LK-CONNECT-HOST(
                       1:NP-CONNECT-HOST-LENGTH) NOT =
                      LK-VERIFY-HOST(1:NP-VERIFY-HOST-LENGTH)
                       EXIT PARAGRAPH
                   END-IF
               WHEN NET-WRITE
                   IF NP-CONNECT-HOST-PTR NOT = NULL OR
                      NP-CONNECT-HOST-LENGTH NOT = ZERO OR
                      NP-VERIFY-HOST-PTR NOT = NULL OR
                      NP-VERIFY-HOST-LENGTH NOT = ZERO OR
                      NP-BUFFER-PTR = NULL OR
                      NP-BUFFER-CAPACITY < ZERO OR
                      NP-BUFFER-CAPACITY > LIMIT-NET-CHUNK OR
                      NP-REQUEST-LENGTH < ZERO OR
                      NP-REQUEST-LENGTH > NP-BUFFER-CAPACITY
                       EXIT PARAGRAPH
                   END-IF
               WHEN NET-READ
                   IF NP-CONNECT-HOST-PTR NOT = NULL OR
                      NP-CONNECT-HOST-LENGTH NOT = ZERO OR
                      NP-VERIFY-HOST-PTR NOT = NULL OR
                      NP-VERIFY-HOST-LENGTH NOT = ZERO OR
                      NP-BUFFER-PTR = NULL OR
                      NP-BUFFER-CAPACITY < 1 OR
                      NP-BUFFER-CAPACITY > LIMIT-NET-CHUNK OR
                      NP-REQUEST-LENGTH NOT = ZERO
                       EXIT PARAGRAPH
                   END-IF
               WHEN NET-CLOSE
                   IF NP-CONNECT-HOST-PTR NOT = NULL OR
                      NP-CONNECT-HOST-LENGTH NOT = ZERO OR
                      NP-VERIFY-HOST-PTR NOT = NULL OR
                      NP-VERIFY-HOST-LENGTH NOT = ZERO OR
                      NP-BUFFER-PTR NOT = NULL OR
                      NP-BUFFER-CAPACITY NOT = ZERO OR
                      NP-REQUEST-LENGTH NOT = ZERO
                       EXIT PARAGRAPH
                   END-IF
               WHEN OTHER
                   EXIT PARAGRAPH
           END-EVALUATE
           MOVE FLAG-ON TO WS-PARAMETERS-VALID.

       OPEN-CONNECTION.
           IF WS-ACTIVE = FLAG-ON
               EXIT PARAGRAPH
           END-IF
           IF WS-API-ACTIVE = FLAG-ON OR
              ZN-SOCKET-DESCRIPTOR >= ZERO OR
              ZN-RESULTS-PTR NOT = NULL
               PERFORM RELEASE-SESSION
               IF WS-CLEANUP-FAILED = FLAG-ON OR
                  WS-API-ACTIVE = FLAG-ON OR
                  ZN-SOCKET-DESCRIPTOR >= ZERO OR
                  ZN-RESULTS-PTR NOT = NULL
                   MOVE STATUS-NETWORK TO NP-STATUS
                   EXIT PARAGRAPH
               END-IF
           END-IF
           IF WS-SIGNAL-SAVED = FLAG-ON
               PERFORM RESTORE-SIGPIPE
               IF WS-SIGNAL-SAVED = FLAG-ON
                   MOVE STATUS-NETWORK TO NP-STATUS
                   EXIT PARAGRAPH
               END-IF
           END-IF
           MOVE FLAG-OFF TO WS-ACTIVE WS-API-ACTIVE
                            WS-SUCCESS
           SET WS-NULL ZN-RESULTS-PTR ZN-CURRENT-RESULT
               ZN-NAME-PTR ZN-NEXT-PTR TO NULL
           MOVE -1 TO ZN-SOCKET-DESCRIPTOR
           MOVE LOW-VALUES TO ZN-NODE ZN-SERVICE ZN-HINTS
                              ZN-NEW-ACTION ZN-SAVED-ACTION
           MOVE ZN-SOCKTYPE TO ZN-HINTS-SOCKTYPE
           MOVE ZN-PROTOCOL TO ZN-HINTS-PROTOCOL
           INITIALIZE TEXT-PARM
           MOVE TEXT-UTF8-STRICT TO TP-OPERATION
           SET TP-INPUT-PTR TO NP-CONNECT-HOST-PTR
           MOVE NP-CONNECT-HOST-LENGTH TO TP-INPUT-LENGTH
           SET TP-OUTPUT-PTR TO ADDRESS OF ZN-NODE
           MOVE LIMIT-HOST TO TP-OUTPUT-CAPACITY
           CALL 'NATUTF8' USING TEXT-PARM
           IF TP-STATUS NOT = STATUS-OK OR
              TP-OUTPUT-LENGTH NOT = NP-CONNECT-HOST-LENGTH
               PERFORM ERASE-OPEN-STAGING
               EXIT PARAGRAPH
           END-IF
           MOVE TP-OUTPUT-LENGTH TO ZN-NODELEN
           MOVE NP-PORT TO WS-PORT-DISPLAY
           MOVE 1 TO WS-PORT-START
           PERFORM UNTIL WS-PORT-START > 5 OR
               WS-PORT-DISPLAY(WS-PORT-START:1) NOT = SPACE
               ADD 1 TO WS-PORT-START
           END-PERFORM
           COMPUTE WS-PORT-LENGTH = 6 - WS-PORT-START
           MOVE WS-PORT-DISPLAY(WS-PORT-START:WS-PORT-LENGTH)
               TO ZN-SERVICE(1:WS-PORT-LENGTH)
           MOVE WS-PORT-LENGTH TO ZN-SERVLEN
           PERFORM INSTALL-SIGPIPE
           IF WS-SIGNAL-INSTALLED NOT = FLAG-ON
               MOVE STATUS-NETWORK TO NP-STATUS
               PERFORM ERASE-OPEN-STAGING
               EXIT PARAGRAPH
           END-IF
           CALL 'EZASOKET' USING ZN-INITAPI ZN-MAXSOC ZN-IDENT
               ZN-SUBTASK ZN-MAXSNO ZN-ERRNO ZN-RETCODE
           IF ZN-RETCODE NOT = ZERO
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           MOVE FLAG-ON TO WS-API-ACTIVE
           SET ZN-HINTS-PTR TO ADDRESS OF ZN-HINTS
           CALL 'EZASOKET' USING ZN-GETADDRINFO
               ZN-NODE ZN-NODELEN ZN-SERVICE ZN-SERVLEN
               ZN-HINTS-PTR ZN-RESULTS-PTR ZN-CANONLEN
               ZN-ERRNO ZN-RETCODE
           IF ZN-RETCODE NOT = ZERO OR ZN-RESULTS-PTR = NULL
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           SET ZN-CURRENT-RESULT TO ZN-RESULTS-PTR
           PERFORM UNTIL ZN-CURRENT-RESULT = NULL OR
                         WS-SUCCESS = FLAG-ON OR
                         WS-CLEANUP-FAILED = FLAG-ON
               MOVE FLAG-ON TO WS-ADVANCE
               MOVE ZERO TO ZN-NAME-LEN
               MOVE SPACES TO ZN-CANONICAL-NAME
               SET ZN-NAME-PTR ZN-NEXT-PTR TO NULL
               CALL 'EZACIC09' USING ZN-CURRENT-RESULT
                   ZN-NAME-LEN ZN-CANONICAL-NAME
                   ZN-NAME-PTR ZN-NEXT-PTR ZN-RETCODE
               IF ZN-RETCODE = ZERO AND ZN-NAME-PTR NOT = NULL
                   SET ADDRESS OF ZN-SOCKET-ADDRESS TO ZN-NAME-PTR
                   MOVE ZN-SA-FAMILY TO ZN-AF
                   CALL 'EZASOKET' USING ZN-SOCKET ZN-AF
                       ZN-SOCKTYPE ZN-PROTOCOL ZN-ERRNO ZN-RETCODE
                   IF ZN-RETCODE >= ZERO
                       MOVE ZN-RETCODE TO ZN-SOCKET-DESCRIPTOR
                       CALL 'EZASOKET' USING ZN-CONNECT
                           ZN-SOCKET-DESCRIPTOR ZN-SOCKET-ADDRESS
                           ZN-ERRNO ZN-RETCODE
                       IF ZN-RETCODE = ZERO
                           MOVE FLAG-ON TO WS-SUCCESS
                       ELSE
                           MOVE ZN-ERRNO TO WS-CONNECT-ERRNO
                           PERFORM CLOSE-SOCKET
                           IF WS-CLEANUP-FAILED = FLAG-ON
                               MOVE FLAG-OFF TO WS-ADVANCE
                           ELSE
                               IF WS-CONNECT-ERRNO = ZN-EINTR
                                   MOVE FLAG-OFF TO WS-ADVANCE
                               END-IF
                           END-IF
                       END-IF
                   END-IF
               END-IF
               IF WS-ADVANCE = FLAG-ON
                   SET ZN-CURRENT-RESULT TO ZN-NEXT-PTR
               END-IF
           END-PERFORM
           PERFORM FREE-RESULTS
           IF WS-SUCCESS NOT = FLAG-ON OR
              WS-CLEANUP-FAILED = FLAG-ON
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           PERFORM QUERY-TLS
           IF WS-SUCCESS NOT = FLAG-ON
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           MOVE FLAG-ON TO WS-ACTIVE
           MOVE STATUS-OK TO NP-STATUS
           PERFORM ERASE-OPEN-STAGING.

       INSTALL-SIGPIPE.
           MOVE FLAG-OFF TO WS-SIGNAL-INSTALLED
           CALL 'sigaction' USING BY VALUE ZN-SIGPIPE
               BY VALUE WS-NULL BY REFERENCE ZN-SAVED-ACTION
               RETURNING WS-NATIVE-RESULT
           IF WS-NATIVE-RESULT NOT = ZERO EXIT PARAGRAPH END-IF
           MOVE FLAG-ON TO WS-SIGNAL-SAVED
           MOVE LOW-VALUES TO ZN-NEW-ACTION
           CALL 'sigemptyset' USING BY REFERENCE ZN-NEW-MASK
               RETURNING WS-NATIVE-RESULT
           IF WS-NATIVE-RESULT NOT = ZERO
               PERFORM RESTORE-SIGPIPE
               EXIT PARAGRAPH
           END-IF
           SET ZN-NEW-HANDLER TO ZN-SIG-IGN
           CALL 'sigaction' USING BY VALUE ZN-SIGPIPE
               BY REFERENCE ZN-NEW-ACTION BY VALUE WS-NULL
               RETURNING WS-NATIVE-RESULT
           IF WS-NATIVE-RESULT NOT = ZERO
               PERFORM RESTORE-SIGPIPE
           ELSE
               MOVE FLAG-ON TO WS-SIGNAL-INSTALLED
           END-IF.

       QUERY-TLS.
           MOVE FLAG-OFF TO WS-SUCCESS
           MOVE LOW-VALUES TO WS-TTLS-IOCTL-DATA
           SET TTLSI-BUFFERPTR TO NULL
           MOVE TTLS-VERSION1 TO TTLSI-VER
           MOVE TTLS-QUERY-ONLY TO TTLSI-REQ-TYPE
           CALL 'EZASOKET' USING ZN-IOCTL ZN-SOCKET-DESCRIPTOR
               SIOCTTLSCTL WS-TTLS-IOCTL-DATA
               WS-TTLS-IOCTL-DATA ZN-ERRNO ZN-RETCODE
           IF ZN-RETCODE = ZERO AND
              TTLSI-STAT-POLICY = TTLS-POL-ENABLED AND
              TTLSI-STAT-CONN = TTLS-CONN-SECURE AND
              TTLSI-SEC-TYPE = TTLS-SEC-CLIENT
               EVALUATE TRUE
                   WHEN TTLSI-SSL-PROT = TTLS-PROT-TLSV1-3 AND
                        TTLSI-NEG-CIPHER4 = "1301"
                       MOVE FLAG-ON TO WS-SUCCESS
                   WHEN TTLSI-SSL-PROT = TTLS-PROT-TLSV1-2 AND
                        TTLSI-NEG-CIPHER4 = "C02F"
                       MOVE FLAG-ON TO WS-SUCCESS
               END-EVALUATE
           END-IF.

       WRITE-CONNECTION.
           IF WS-ACTIVE NOT = FLAG-ON OR NP-BUFFER-PTR = NULL OR
              NP-REQUEST-LENGTH < ZERO OR
              NP-REQUEST-LENGTH > NP-BUFFER-CAPACITY
               EXIT PARAGRAPH
           END-IF
           IF NP-REQUEST-LENGTH = ZERO
               MOVE STATUS-OK TO NP-STATUS
               EXIT PARAGRAPH
           END-IF
           SET ADDRESS OF LK-BUFFER TO NP-BUFFER-PTR
           MOVE NP-REQUEST-LENGTH TO ZN-NBYTE
           MOVE FLAG-ON TO WS-RETRY
           PERFORM UNTIL WS-RETRY = FLAG-OFF
               MOVE FLAG-OFF TO WS-RETRY
               CALL 'EZASOKET' USING ZN-WRITE
                   ZN-SOCKET-DESCRIPTOR ZN-NBYTE LK-BUFFER
                   ZN-ERRNO ZN-RETCODE
               IF ZN-RETCODE < ZERO AND ZN-ERRNO = ZN-EINTR
                   MOVE FLAG-ON TO WS-RETRY
               END-IF
           END-PERFORM
           IF ZN-RETCODE > ZERO AND
              ZN-RETCODE <= NP-REQUEST-LENGTH
               MOVE ZN-RETCODE TO NP-TRANSFERRED
               MOVE STATUS-OK TO NP-STATUS
           ELSE
               PERFORM ACTIVE-FAIL
           END-IF.

       READ-CONNECTION.
           IF WS-ACTIVE NOT = FLAG-ON OR NP-BUFFER-PTR = NULL OR
              NP-BUFFER-CAPACITY < 1 OR
              NP-BUFFER-CAPACITY > LIMIT-NET-CHUNK
               EXIT PARAGRAPH
           END-IF
           SET ADDRESS OF LK-BUFFER TO NP-BUFFER-PTR
           MOVE NP-BUFFER-CAPACITY TO ZN-NBYTE
           MOVE FLAG-ON TO WS-RETRY
           PERFORM UNTIL WS-RETRY = FLAG-OFF
               MOVE FLAG-OFF TO WS-RETRY
               CALL 'EZASOKET' USING ZN-READ
                   ZN-SOCKET-DESCRIPTOR ZN-NBYTE LK-BUFFER
                   ZN-ERRNO ZN-RETCODE
               IF ZN-RETCODE < ZERO AND ZN-ERRNO = ZN-EINTR
                   MOVE FLAG-ON TO WS-RETRY
               END-IF
           END-PERFORM
           EVALUATE TRUE
               WHEN ZN-RETCODE > ZERO AND
                    ZN-RETCODE <= NP-BUFFER-CAPACITY
                   MOVE ZN-RETCODE TO NP-TRANSFERRED
                   MOVE STATUS-OK TO NP-STATUS
               WHEN ZN-RETCODE = ZERO
                   MOVE FLAG-ON TO NP-EOF
                   MOVE STATUS-OK TO NP-STATUS
               WHEN OTHER
                   PERFORM ACTIVE-FAIL
           END-EVALUATE.

       ACTIVE-FAIL.
           MOVE STATUS-NETWORK TO NP-STATUS
           PERFORM RELEASE-SESSION
           MOVE FLAG-OFF TO WS-ACTIVE.

       CLOSE-CONNECTION.
           PERFORM RELEASE-SESSION
           IF WS-CLEANUP-FAILED = FLAG-ON OR
              WS-SIGNAL-SAVED = FLAG-ON OR
              WS-API-ACTIVE = FLAG-ON OR
              ZN-SOCKET-DESCRIPTOR >= ZERO OR
              ZN-RESULTS-PTR NOT = NULL
               MOVE STATUS-NETWORK TO NP-STATUS
           ELSE
               MOVE STATUS-OK TO NP-STATUS
           END-IF
           MOVE FLAG-OFF TO WS-ACTIVE.

       OPEN-FAIL.
           PERFORM RELEASE-SESSION
           PERFORM ERASE-OPEN-STAGING
           MOVE STATUS-NETWORK TO NP-STATUS.

       RELEASE-SESSION.
           PERFORM CLOSE-SOCKET
           PERFORM FREE-RESULTS
           IF WS-API-ACTIVE = FLAG-ON
               CALL 'EZASOKET' USING ZN-TERMAPI
                   ZN-ERRNO ZN-RETCODE
               IF ZN-RETCODE = ZERO
                   MOVE FLAG-OFF TO WS-API-ACTIVE
                   MOVE -1 TO ZN-SOCKET-DESCRIPTOR
               ELSE
                   MOVE FLAG-ON TO WS-CLEANUP-FAILED
               END-IF
           END-IF
           PERFORM RESTORE-SIGPIPE
           IF WS-SIGNAL-SAVED = FLAG-ON
               MOVE FLAG-ON TO WS-CLEANUP-FAILED
           END-IF.

       CLOSE-SOCKET.
           IF ZN-SOCKET-DESCRIPTOR >= ZERO
               CALL 'EZASOKET' USING ZN-CLOSE
                   ZN-SOCKET-DESCRIPTOR ZN-ERRNO ZN-RETCODE
               IF ZN-RETCODE = ZERO
                   MOVE -1 TO ZN-SOCKET-DESCRIPTOR
               ELSE
                   MOVE FLAG-ON TO WS-CLEANUP-FAILED
               END-IF
           END-IF.

       FREE-RESULTS.
           IF ZN-RESULTS-PTR NOT = NULL
               CALL 'EZASOKET' USING ZN-FREEADDRINFO
                   ZN-RESULTS-PTR ZN-ERRNO ZN-RETCODE
               IF ZN-RETCODE = ZERO
                   SET ZN-RESULTS-PTR ZN-CURRENT-RESULT TO NULL
               ELSE
                   MOVE FLAG-ON TO WS-CLEANUP-FAILED
               END-IF
           END-IF.

       RESTORE-SIGPIPE.
           IF WS-SIGNAL-SAVED = FLAG-ON
               CALL 'sigaction' USING BY VALUE ZN-SIGPIPE
                   BY REFERENCE ZN-SAVED-ACTION BY VALUE WS-NULL
                   RETURNING WS-NATIVE-RESULT
               IF WS-NATIVE-RESULT = ZERO
                   MOVE FLAG-OFF TO WS-SIGNAL-SAVED
                                    WS-SIGNAL-INSTALLED
               END-IF
           END-IF.

       ERASE-OPEN-STAGING.
           MOVE LOW-VALUES TO ZN-NODE ZN-SERVICE ZN-HINTS
           MOVE ZERO TO ZN-NODELEN ZN-SERVLEN
           SET ZN-HINTS-PTR TO NULL.

       END PROGRAM NETIO.
