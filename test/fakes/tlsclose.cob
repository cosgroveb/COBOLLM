       IDENTIFICATION DIVISION.
       PROGRAM-ID. "SSL_shutdown".

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY FTCTRL.
       01  FT-RESULT                PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01  FT-SSL                   USAGE POINTER.

       PROCEDURE DIVISION USING BY VALUE FT-SSL.
           IF FT-SSL = NULL OR FT-PENDING = FLAG-ON
               MOVE FLAG-OFF TO FT-VALID
           END-IF
           ADD 1 TO FT-SHUTDOWN-COUNT
           EVALUATE FT-SHUTDOWN-COUNT
               WHEN 1
               WHEN 2
               WHEN 4
                   MOVE FLAG-ON TO FT-PENDING
                   MOVE -1 TO FT-RESULT
               WHEN 3
                   MOVE FLAG-OFF TO FT-PENDING
                   MOVE 0 TO FT-RESULT
               WHEN OTHER
                   MOVE FLAG-OFF TO FT-PENDING FT-VALID
                   MOVE 1 TO FT-RESULT
           END-EVALUATE
           GOBACK RETURNING FT-RESULT.

       END PROGRAM "SSL_shutdown".

       IDENTIFICATION DIVISION.
       PROGRAM-ID. "SSL_get_error".

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY NETNAT.
       COPY FTCTRL.
       01  FT-RESULT                PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01  FT-SSL                   USAGE POINTER.
       01  FT-SSL-RESULT            PIC S9(9) COMP-5.

       PROCEDURE DIVISION USING
           BY VALUE FT-SSL
           BY VALUE FT-SSL-RESULT.
           IF FT-PENDING = FLAG-ON
               IF FT-SSL = NULL OR FT-SSL-RESULT NOT = -1
                   MOVE FLAG-OFF TO FT-VALID
               END-IF
               ADD 1 TO FT-GET-ERROR-COUNT
               EVALUATE FT-SHUTDOWN-COUNT
                   WHEN 1
                       MOVE GNU-SSL-ERROR-WANT-READ TO FT-RESULT
                   WHEN 2
                       MOVE GNU-SSL-ERROR-WANT-WRITE TO FT-RESULT
                   WHEN 4
                       MOVE 1 TO FT-RESULT
                   WHEN OTHER
                       MOVE FLAG-OFF TO FT-VALID
                       MOVE 1 TO FT-RESULT
               END-EVALUATE
               MOVE FLAG-OFF TO FT-PENDING
           ELSE
               MOVE 1 TO FT-RESULT
           END-IF
           GOBACK RETURNING FT-RESULT.

       END PROGRAM "SSL_get_error".
