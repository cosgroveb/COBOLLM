       IDENTIFICATION DIVISION.
       PROGRAM-ID. NETIO.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY POSIXNAT.
       COPY NETNAT.
       01 WS-ACTIVE               PIC X VALUE X'00'.
       01 WS-SIGNAL-SAVED         PIC X VALUE X'00'.
       01 WS-TLS-ACTIVE           PIC X VALUE X'00'.
       01 WS-FATAL-TLS            PIC X VALUE X'00'.
       01 WS-SOCKET               PIC S9(9) COMP-5 VALUE -1.
       01 WS-HOST-CSTR            PIC X(254).
       01 WS-SERVICE-CSTR         PIC X(6).
       01 WS-PORT-DISPLAY         PIC ZZZZ9.
       01 WS-PORT-START           PIC S9(9) COMP-5.
       01 WS-PORT-LENGTH          PIC S9(9) COMP-5.
       01 WS-AI-RESULT            USAGE POINTER.
       01 WS-AI-CURRENT           USAGE POINTER.
       01 WS-NULL                 USAGE POINTER.
       01 WS-SSL-METHOD           USAGE POINTER.
       01 WS-SSL-CTX              USAGE POINTER.
       01 WS-SSL                  USAGE POINTER.
       01 WS-RESULT               PIC S9(18) COMP-5.
       01 WS-NATIVE-SIZE          PIC 9(18) COMP-5.
       01 WS-INT-RESULT           PIC S9(9) COMP-5.
       01 WS-SSL-ERROR            PIC S9(9) COMP-5.
       01 WS-SAVED-ERRNO          PIC S9(9) COMP-5.
       01 WS-ERRNO                PIC S9(9) COMP-5 BASED.
       01 WS-SSL-LONG             PIC S9(18) COMP-5.
       01 WS-SSL-VERIFY-MODE      PIC S9(9) COMP-5.
       01 WS-SNI-NAME-TYPE       PIC S9(18) COMP-5.
       01 WS-RETRY                PIC X.
       01 WS-PARAMETERS-VALID     PIC X.

       LINKAGE SECTION.
       COPY NETPARM.
       01 NP-HOST                 PIC X(253) BASED.
       01 NP-VERIFY-HOST          PIC X(253) BASED.

       PROCEDURE DIVISION USING NET-PARM.
           MOVE STATUS-INTERNAL TO NP-STATUS
           MOVE ZERO TO NP-TRANSFERRED
           MOVE FLAG-OFF TO NP-EOF
           PERFORM VALIDATE-PARAMETERS
           IF WS-PARAMETERS-VALID NOT = FLAG-ON GOBACK END-IF
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
                      (NP-SCHEME NOT = NET-PLAINTEXT AND
                       NP-SCHEME NOT = NET-TLS)
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
           IF WS-SIGNAL-SAVED = FLAG-ON
               PERFORM RESTORE-SIGNAL
               IF WS-SIGNAL-SAVED = FLAG-ON
                   MOVE STATUS-NETWORK TO NP-STATUS
                   EXIT PARAGRAPH
               END-IF
           END-IF
           SET WS-NULL TO NULL
           SET WS-AI-RESULT TO NULL
           SET WS-SSL-METHOD TO NULL
           SET WS-SSL-CTX TO NULL
           SET WS-SSL TO NULL
           MOVE FLAG-OFF TO WS-TLS-ACTIVE WS-FATAL-TLS
           MOVE -1 TO WS-SOCKET
           MOVE GNU-SSL-VERIFY-PEER TO WS-SSL-VERIFY-MODE
           MOVE GNU-SNI-HOST-NAME TO WS-SNI-NAME-TYPE
           MOVE LOW-VALUES TO WS-HOST-CSTR WS-SERVICE-CSTR
                              GNU-SAVED-SIGACTION-RECORD
           SET ADDRESS OF NP-HOST TO NP-CONNECT-HOST-PTR
           MOVE NP-HOST(1:NP-CONNECT-HOST-LENGTH) TO WS-HOST-CSTR
           MOVE X"00" TO
               WS-HOST-CSTR(NP-CONNECT-HOST-LENGTH + 1:1)
           MOVE NP-PORT TO WS-PORT-DISPLAY
           MOVE 1 TO WS-PORT-START
           PERFORM UNTIL WS-PORT-START > 5 OR
                         WS-PORT-DISPLAY(WS-PORT-START:1) NOT = SPACE
               ADD 1 TO WS-PORT-START
           END-PERFORM
           COMPUTE WS-PORT-LENGTH = 6 - WS-PORT-START
           MOVE WS-PORT-DISPLAY(WS-PORT-START:WS-PORT-LENGTH) TO
               WS-SERVICE-CSTR(1:WS-PORT-LENGTH)
           MOVE X"00" TO WS-SERVICE-CSTR(WS-PORT-LENGTH + 1:1)
           CALL STATIC "sigaction" USING
               BY VALUE SIZE IS 4 GNU-SIGPIPE
               BY VALUE WS-NULL
               BY REFERENCE GNU-SAVED-SIGACTION-RECORD
               RETURNING WS-INT-RESULT
           IF WS-INT-RESULT NOT = ZERO
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           MOVE FLAG-ON TO WS-SIGNAL-SAVED
           MOVE LOW-VALUES TO GNU-SIGACTION-RECORD
           CALL STATIC "sigemptyset" USING
               BY REFERENCE GNU-SA-MASK
               RETURNING WS-INT-RESULT
           IF WS-INT-RESULT NOT = ZERO
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           MOVE GNU-SIG-IGN TO GNU-SA-HANDLER
           CALL STATIC "sigaction" USING
               BY VALUE SIZE IS 4 GNU-SIGPIPE
               BY REFERENCE GNU-SIGACTION-RECORD
               BY VALUE WS-NULL
               RETURNING WS-INT-RESULT
           IF WS-INT-RESULT NOT = ZERO
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           MOVE LOW-VALUES TO GNU-ADDRINFO
           MOVE GNU-AF-UNSPEC TO GNU-AI-FAMILY
           MOVE GNU-SOCK-STREAM TO GNU-AI-SOCKTYPE
           MOVE GNU-IPPROTO-TCP TO GNU-AI-PROTOCOL
           CALL STATIC "getaddrinfo" USING
               BY REFERENCE WS-HOST-CSTR
               BY REFERENCE WS-SERVICE-CSTR
               BY REFERENCE GNU-ADDRINFO
               BY REFERENCE WS-AI-RESULT
               RETURNING WS-INT-RESULT
           IF WS-INT-RESULT NOT = ZERO OR WS-AI-RESULT = NULL
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           SET WS-AI-CURRENT TO WS-AI-RESULT
           PERFORM UNTIL WS-AI-CURRENT = NULL OR WS-SOCKET >= ZERO
               SET ADDRESS OF GNU-ADDRINFO-VIEW TO WS-AI-CURRENT
               CALL STATIC "socket" USING
                   BY VALUE SIZE IS 4 GNU-V-AI-FAMILY
                   BY VALUE SIZE IS 4 GNU-V-AI-SOCKTYPE
                   BY VALUE SIZE IS 4 GNU-V-AI-PROTOCOL
                   RETURNING WS-SOCKET
               IF WS-SOCKET >= ZERO
                   CALL STATIC "connect" USING
                       BY VALUE SIZE IS 4 WS-SOCKET
                       BY VALUE GNU-V-AI-ADDR
                       BY VALUE SIZE IS 4 GNU-V-AI-ADDRLEN
                       RETURNING WS-INT-RESULT
                   IF WS-INT-RESULT NOT = ZERO
                       PERFORM SAVE-ERRNO
                       CALL STATIC "close" USING
                           BY VALUE SIZE IS 4 WS-SOCKET
                           RETURNING WS-INT-RESULT
                       MOVE -1 TO WS-SOCKET
                       IF WS-SAVED-ERRNO NOT = GNU-EINTR
                           SET WS-AI-CURRENT TO GNU-V-AI-NEXT
                       END-IF
                   END-IF
               ELSE
                   SET WS-AI-CURRENT TO GNU-V-AI-NEXT
               END-IF
           END-PERFORM
           CALL STATIC "freeaddrinfo" USING BY VALUE WS-AI-RESULT
           SET WS-AI-RESULT TO NULL
           IF WS-SOCKET < ZERO
               PERFORM OPEN-FAIL
               EXIT PARAGRAPH
           END-IF
           IF NP-SCHEME = NET-TLS
               PERFORM START-TLS
               IF WS-TLS-ACTIVE NOT = FLAG-ON
                   PERFORM OPEN-FAIL
                   EXIT PARAGRAPH
               END-IF
           END-IF
           MOVE FLAG-ON TO WS-ACTIVE
           MOVE LOW-VALUES TO WS-HOST-CSTR WS-SERVICE-CSTR
           MOVE STATUS-OK TO NP-STATUS.

       START-TLS.
           MOVE FLAG-OFF TO WS-TLS-ACTIVE WS-FATAL-TLS
           CALL STATIC "TLS_client_method" RETURNING WS-SSL-METHOD
           IF WS-SSL-METHOD = NULL EXIT PARAGRAPH END-IF
           CALL STATIC "SSL_CTX_new" USING
               BY VALUE WS-SSL-METHOD RETURNING WS-SSL-CTX
           IF WS-SSL-CTX = NULL EXIT PARAGRAPH END-IF
           CALL STATIC "SSL_CTX_set_default_verify_paths" USING
               BY VALUE WS-SSL-CTX RETURNING WS-INT-RESULT
           IF WS-INT-RESULT NOT = 1 EXIT PARAGRAPH END-IF
           CALL STATIC "SSL_CTX_set_verify" USING
               BY VALUE WS-SSL-CTX
               BY VALUE SIZE IS 4 WS-SSL-VERIFY-MODE
               BY VALUE WS-NULL
           CALL STATIC "SSL_new" USING
               BY VALUE WS-SSL-CTX RETURNING WS-SSL
           IF WS-SSL = NULL EXIT PARAGRAPH END-IF
           CALL STATIC "SSL_set_fd" USING
               BY VALUE WS-SSL
               BY VALUE SIZE IS 4 WS-SOCKET
               RETURNING WS-INT-RESULT
           IF WS-INT-RESULT NOT = 1 EXIT PARAGRAPH END-IF
           MOVE LOW-VALUES TO WS-HOST-CSTR
           SET ADDRESS OF NP-VERIFY-HOST TO NP-VERIFY-HOST-PTR
           MOVE NP-VERIFY-HOST(1:NP-VERIFY-HOST-LENGTH) TO
               WS-HOST-CSTR
           MOVE X"00" TO
               WS-HOST-CSTR(NP-VERIFY-HOST-LENGTH + 1:1)
           SET WS-AI-CURRENT TO ADDRESS OF WS-HOST-CSTR
           CALL STATIC "SSL_ctrl" USING
               BY VALUE WS-SSL
               BY VALUE SIZE IS 4 GNU-SSL-CTRL-SNI
               BY VALUE WS-SNI-NAME-TYPE
               BY VALUE WS-AI-CURRENT
               RETURNING WS-SSL-LONG
           IF WS-SSL-LONG NOT = 1 EXIT PARAGRAPH END-IF
           CALL STATIC "SSL_set1_host" USING
               BY VALUE WS-SSL
               BY VALUE WS-AI-CURRENT
               RETURNING WS-INT-RESULT
           IF WS-INT-RESULT NOT = 1 EXIT PARAGRAPH END-IF
           PERFORM TLS-CONNECT
           PERFORM UNTIL WS-INT-RESULT NOT = -2
               PERFORM TLS-CONNECT
           END-PERFORM
           IF WS-INT-RESULT = 1
               MOVE FLAG-ON TO WS-TLS-ACTIVE
           END-IF.

       TLS-CONNECT.
           CALL STATIC "ERR_clear_error"
           CALL STATIC "SSL_connect" USING BY VALUE WS-SSL
               RETURNING WS-INT-RESULT
           IF WS-INT-RESULT = 1 EXIT PARAGRAPH END-IF
           PERFORM SAVE-ERRNO
           CALL STATIC "SSL_get_error" USING
               BY VALUE WS-SSL
               BY VALUE SIZE IS 4 WS-INT-RESULT
               RETURNING WS-SSL-ERROR
           IF WS-SSL-ERROR = GNU-SSL-ERROR-WANT-READ OR
              WS-SSL-ERROR = GNU-SSL-ERROR-WANT-WRITE
               MOVE -2 TO WS-INT-RESULT
           ELSE
               MOVE -1 TO WS-INT-RESULT
               MOVE FLAG-ON TO WS-FATAL-TLS
           END-IF.

       WRITE-CONNECTION.
           IF WS-ACTIVE NOT = FLAG-ON
               EXIT PARAGRAPH
           END-IF
           IF NP-REQUEST-LENGTH = ZERO
               MOVE STATUS-OK TO NP-STATUS
               EXIT PARAGRAPH
           END-IF
           IF WS-TLS-ACTIVE = FLAG-ON
               PERFORM TLS-WRITE
           ELSE
               PERFORM PLAIN-WRITE
           END-IF.

       PLAIN-WRITE.
           MOVE FLAG-ON TO WS-RETRY
           MOVE NP-REQUEST-LENGTH TO WS-NATIVE-SIZE
           PERFORM UNTIL WS-RETRY = FLAG-OFF
               MOVE FLAG-OFF TO WS-RETRY
               CALL STATIC "write" USING
                   BY VALUE SIZE IS 4 WS-SOCKET
                   BY VALUE NP-BUFFER-PTR
                   BY VALUE WS-NATIVE-SIZE
                   RETURNING WS-RESULT
               EVALUATE TRUE
                   WHEN WS-RESULT > ZERO AND
                        WS-RESULT <= NP-REQUEST-LENGTH
                       MOVE WS-RESULT TO NP-TRANSFERRED
                       MOVE STATUS-OK TO NP-STATUS
                   WHEN WS-RESULT < ZERO
                       PERFORM SAVE-ERRNO
                       IF WS-SAVED-ERRNO = GNU-EINTR
                           MOVE FLAG-ON TO WS-RETRY
                       ELSE
                           MOVE STATUS-NETWORK TO NP-STATUS
                           PERFORM FAIL-ACTIVE
                       END-IF
                   WHEN OTHER
                       MOVE STATUS-NETWORK TO NP-STATUS
                       PERFORM FAIL-ACTIVE
               END-EVALUATE
           END-PERFORM.

       TLS-WRITE.
           MOVE FLAG-ON TO WS-RETRY
           MOVE NP-BUFFER-CAPACITY TO WS-NATIVE-SIZE
           PERFORM UNTIL WS-RETRY = FLAG-OFF
               MOVE FLAG-OFF TO WS-RETRY
               CALL STATIC "ERR_clear_error"
               CALL STATIC "SSL_write" USING
                   BY VALUE WS-SSL
                   BY VALUE NP-BUFFER-PTR
                   BY VALUE SIZE IS 4 NP-REQUEST-LENGTH
                   RETURNING WS-INT-RESULT
               IF WS-INT-RESULT > ZERO AND
                  WS-INT-RESULT <= NP-REQUEST-LENGTH
                   MOVE WS-INT-RESULT TO NP-TRANSFERRED
                   MOVE STATUS-OK TO NP-STATUS
               ELSE
                   PERFORM SAVE-ERRNO
                   CALL STATIC "SSL_get_error" USING
                       BY VALUE WS-SSL
                       BY VALUE SIZE IS 4 WS-INT-RESULT
                       RETURNING WS-SSL-ERROR
                   IF WS-SSL-ERROR = GNU-SSL-ERROR-WANT-READ OR
                      WS-SSL-ERROR = GNU-SSL-ERROR-WANT-WRITE
                       MOVE FLAG-ON TO WS-RETRY
                   ELSE
                       MOVE FLAG-ON TO WS-FATAL-TLS
                       MOVE STATUS-NETWORK TO NP-STATUS
                       PERFORM FAIL-ACTIVE
                   END-IF
               END-IF
           END-PERFORM.

       READ-CONNECTION.
           IF WS-ACTIVE NOT = FLAG-ON
               EXIT PARAGRAPH
           END-IF
           IF WS-TLS-ACTIVE = FLAG-ON
               PERFORM TLS-READ
           ELSE
               PERFORM PLAIN-READ
           END-IF.

       PLAIN-READ.
           MOVE FLAG-ON TO WS-RETRY
           MOVE NP-BUFFER-CAPACITY TO WS-NATIVE-SIZE
           PERFORM UNTIL WS-RETRY = FLAG-OFF
               MOVE FLAG-OFF TO WS-RETRY
               CALL STATIC "read" USING
                   BY VALUE SIZE IS 4 WS-SOCKET
                   BY VALUE NP-BUFFER-PTR
                   BY VALUE WS-NATIVE-SIZE
                   RETURNING WS-RESULT
               EVALUATE TRUE
                   WHEN WS-RESULT > ZERO AND
                        WS-RESULT <= NP-BUFFER-CAPACITY
                       MOVE WS-RESULT TO NP-TRANSFERRED
                       MOVE STATUS-OK TO NP-STATUS
                   WHEN WS-RESULT = ZERO
                       MOVE FLAG-ON TO NP-EOF
                       MOVE STATUS-OK TO NP-STATUS
                   WHEN OTHER
                       PERFORM SAVE-ERRNO
                       IF WS-SAVED-ERRNO = GNU-EINTR
                           MOVE FLAG-ON TO WS-RETRY
                       ELSE
                           MOVE STATUS-NETWORK TO NP-STATUS
                           PERFORM FAIL-ACTIVE
                       END-IF
               END-EVALUATE
           END-PERFORM.

       TLS-READ.
           MOVE FLAG-ON TO WS-RETRY
           PERFORM UNTIL WS-RETRY = FLAG-OFF
               MOVE FLAG-OFF TO WS-RETRY
               CALL STATIC "ERR_clear_error"
               CALL STATIC "SSL_read" USING
                   BY VALUE WS-SSL
                   BY VALUE NP-BUFFER-PTR
                   BY VALUE SIZE IS 4 NP-BUFFER-CAPACITY
                   RETURNING WS-INT-RESULT
               IF WS-INT-RESULT > ZERO AND
                  WS-INT-RESULT <= NP-BUFFER-CAPACITY
                   MOVE WS-INT-RESULT TO NP-TRANSFERRED
                   MOVE STATUS-OK TO NP-STATUS
               ELSE
                   PERFORM SAVE-ERRNO
                   CALL STATIC "SSL_get_error" USING
                       BY VALUE WS-SSL
                       BY VALUE SIZE IS 4 WS-INT-RESULT
                       RETURNING WS-SSL-ERROR
                   EVALUATE TRUE
                       WHEN WS-SSL-ERROR = GNU-SSL-ERROR-WANT-READ OR
                            WS-SSL-ERROR = GNU-SSL-ERROR-WANT-WRITE
                           MOVE FLAG-ON TO WS-RETRY
                       WHEN WS-SSL-ERROR =
                            GNU-SSL-ERROR-ZERO-RETURN
                           MOVE FLAG-ON TO NP-EOF
                           MOVE STATUS-OK TO NP-STATUS
                       WHEN OTHER
                           MOVE FLAG-ON TO WS-FATAL-TLS
                           MOVE STATUS-NETWORK TO NP-STATUS
                           PERFORM FAIL-ACTIVE
                   END-EVALUATE
               END-IF
           END-PERFORM.

       FAIL-ACTIVE.
           MOVE FLAG-ON TO WS-FATAL-TLS
           PERFORM RELEASE-RESOURCES
           PERFORM RESTORE-SIGNAL
           MOVE FLAG-OFF TO WS-ACTIVE.

       CLOSE-CONNECTION.
           IF WS-ACTIVE = FLAG-ON
               PERFORM RELEASE-RESOURCES
               PERFORM RESTORE-SIGNAL
               MOVE FLAG-OFF TO WS-ACTIVE
           END-IF
           IF WS-SIGNAL-SAVED = FLAG-ON
               MOVE STATUS-NETWORK TO NP-STATUS
           ELSE
               MOVE STATUS-OK TO NP-STATUS
           END-IF.

       OPEN-FAIL.
           IF WS-AI-RESULT NOT = NULL
               CALL STATIC "freeaddrinfo" USING
                   BY VALUE WS-AI-RESULT
               SET WS-AI-RESULT TO NULL
           END-IF
           PERFORM RELEASE-RESOURCES
           PERFORM RESTORE-SIGNAL
           MOVE LOW-VALUES TO WS-HOST-CSTR WS-SERVICE-CSTR
           MOVE STATUS-NETWORK TO NP-STATUS.

       RELEASE-RESOURCES.
           IF WS-SSL NOT = NULL
               IF WS-TLS-ACTIVE = FLAG-ON AND
                  WS-FATAL-TLS = FLAG-OFF
                   PERFORM SHUTDOWN-TLS
               END-IF
               CALL STATIC "SSL_free" USING BY VALUE WS-SSL
               SET WS-SSL TO NULL
           END-IF
           IF WS-SSL-CTX NOT = NULL
               CALL STATIC "SSL_CTX_free" USING BY VALUE WS-SSL-CTX
               SET WS-SSL-CTX TO NULL
           END-IF
           IF WS-SOCKET >= ZERO
               CALL STATIC "close" USING
                   BY VALUE SIZE IS 4 WS-SOCKET
                   RETURNING WS-INT-RESULT
               MOVE -1 TO WS-SOCKET
           END-IF
           MOVE FLAG-OFF TO WS-TLS-ACTIVE WS-FATAL-TLS.

       SHUTDOWN-TLS.
           MOVE FLAG-ON TO WS-RETRY
           PERFORM UNTIL WS-RETRY = FLAG-OFF
               MOVE FLAG-OFF TO WS-RETRY
               CALL STATIC "ERR_clear_error"
               CALL STATIC "SSL_shutdown" USING BY VALUE WS-SSL
                   RETURNING WS-INT-RESULT
               IF WS-INT-RESULT < ZERO
                   PERFORM SAVE-ERRNO
                   CALL STATIC "SSL_get_error" USING
                       BY VALUE WS-SSL
                       BY VALUE SIZE IS 4 WS-INT-RESULT
                       RETURNING WS-SSL-ERROR
                   IF WS-SSL-ERROR = GNU-SSL-ERROR-WANT-READ OR
                      WS-SSL-ERROR = GNU-SSL-ERROR-WANT-WRITE
                       MOVE FLAG-ON TO WS-RETRY
                   ELSE
                       MOVE FLAG-ON TO WS-FATAL-TLS
                   END-IF
               END-IF
           END-PERFORM.

       RESTORE-SIGNAL.
           IF WS-SIGNAL-SAVED = FLAG-ON
               CALL STATIC "sigaction" USING
                   BY VALUE SIZE IS 4 GNU-SIGPIPE
                   BY REFERENCE GNU-SAVED-SIGACTION-RECORD
                   BY VALUE WS-NULL
                   RETURNING WS-INT-RESULT
               IF WS-INT-RESULT = ZERO
                   MOVE FLAG-OFF TO WS-SIGNAL-SAVED
               END-IF
           END-IF.

       SAVE-ERRNO.
           CALL STATIC "__errno_location" RETURNING GNU-ERRNO-PTR
           IF GNU-ERRNO-PTR = NULL
               MOVE ZERO TO WS-SAVED-ERRNO
           ELSE
               SET ADDRESS OF WS-ERRNO TO GNU-ERRNO-PTR
               MOVE WS-ERRNO TO WS-SAVED-ERRNO
           END-IF.

       END PROGRAM NETIO.
