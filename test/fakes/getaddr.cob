       IDENTIFICATION DIVISION.
       PROGRAM-ID. "getaddrinfo".

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY FGCTRL.
       01  FG-PORT-ENV              PIC 9(5).
       01  FG-PORT                  PIC S9(9) COMP-5.
       01  FG-HIGH                  PIC S9(9) COMP-5.
       01  FG-LOW                   PIC S9(9) COMP-5.
       01  FG-I                     PIC S9(9) COMP-5.
       01  FG-RETURN                PIC S9(9) COMP-5.
       01  FG-AI-ONE.
           05 FG-A1-FLAGS           PIC S9(9) COMP-5 VALUE ZERO.
           05 FG-A1-FAMILY          PIC S9(9) COMP-5 VALUE 2.
           05 FG-A1-SOCKTYPE        PIC S9(9) COMP-5 VALUE 1.
           05 FG-A1-PROTOCOL        PIC S9(9) COMP-5 VALUE 6.
           05 FG-A1-ADDRLEN         PIC 9(9) COMP-5 VALUE 16.
           05 FG-A1-PADDING         PIC X(4) VALUE LOW-VALUES.
           05 FG-A1-ADDR            USAGE POINTER.
           05 FG-A1-CANONNAME       USAGE POINTER.
           05 FG-A1-NEXT            USAGE POINTER.
       01  FG-AI-TWO.
           05 FG-A2-FLAGS           PIC S9(9) COMP-5 VALUE ZERO.
           05 FG-A2-FAMILY          PIC S9(9) COMP-5 VALUE 2.
           05 FG-A2-SOCKTYPE        PIC S9(9) COMP-5 VALUE 1.
           05 FG-A2-PROTOCOL        PIC S9(9) COMP-5 VALUE 6.
           05 FG-A2-ADDRLEN         PIC 9(9) COMP-5 VALUE 16.
           05 FG-A2-PADDING         PIC X(4) VALUE LOW-VALUES.
           05 FG-A2-ADDR            USAGE POINTER.
           05 FG-A2-CANONNAME       USAGE POINTER.
           05 FG-A2-NEXT            USAGE POINTER.
       01  FG-SOCKADDR-ONE          PIC X(16).
       01  FG-SOCKADDR-TWO          PIC X(16).

       LINKAGE SECTION.
       01  FG-NODE-ARG              PIC X(254).
       01  FG-SERVICE-ARG           PIC X(6).
       01  FG-HINTS.
           05 FG-H-FLAGS            PIC S9(9) COMP-5.
           05 FG-H-FAMILY           PIC S9(9) COMP-5.
           05 FG-H-SOCKTYPE         PIC S9(9) COMP-5.
           05 FG-H-PROTOCOL         PIC S9(9) COMP-5.
           05 FILLER                PIC X(32).
       01  FG-RESULT-PTR            USAGE POINTER.

       PROCEDURE DIVISION USING
           BY REFERENCE FG-NODE-ARG
           BY REFERENCE FG-SERVICE-ARG
           BY REFERENCE FG-HINTS
           BY REFERENCE FG-RESULT-PTR.
           MOVE 1 TO FG-RETURN
           ADD 1 TO FG-CALL-COUNT
           MOVE FLAG-ON TO FG-VALID
           MOVE LOW-VALUES TO FG-NODE FG-SERVICE
           MOVE ZERO TO FG-NODE-LENGTH FG-SERVICE-LENGTH
           PERFORM VARYING FG-I FROM 1 BY 1 UNTIL FG-I > 254 OR
               FG-NODE-ARG(FG-I:1) = X"00"
               MOVE FG-NODE-ARG(FG-I:1) TO FG-NODE(FG-I:1)
               MOVE FG-I TO FG-NODE-LENGTH
           END-PERFORM
           IF FG-I > 254 MOVE FLAG-OFF TO FG-VALID END-IF
           PERFORM VARYING FG-I FROM 1 BY 1 UNTIL FG-I > 6 OR
               FG-SERVICE-ARG(FG-I:1) = X"00"
               MOVE FG-SERVICE-ARG(FG-I:1) TO FG-SERVICE(FG-I:1)
               MOVE FG-I TO FG-SERVICE-LENGTH
           END-PERFORM
           IF FG-I > 6 MOVE FLAG-OFF TO FG-VALID END-IF
           IF FG-H-FLAGS NOT = ZERO OR FG-H-FAMILY NOT = ZERO OR
              FG-H-SOCKTYPE NOT = 1 OR FG-H-PROTOCOL NOT = 6
               MOVE FLAG-OFF TO FG-VALID
           END-IF
           ACCEPT FG-PORT-ENV FROM ENVIRONMENT
               "COBOLLM_TEST_RESOLVE_PORT"
           MOVE FG-PORT-ENV TO FG-PORT
           COMPUTE FG-HIGH = FG-PORT / 256
           COMPUTE FG-LOW = FUNCTION MOD(FG-PORT 256)
           MOVE LOW-VALUES TO FG-SOCKADDR-ONE FG-SOCKADDR-TWO
           MOVE X"0200" TO FG-SOCKADDR-ONE(1:2)
                              FG-SOCKADDR-TWO(1:2)
           MOVE FUNCTION CHAR(FG-HIGH + 1) TO
               FG-SOCKADDR-ONE(3:1) FG-SOCKADDR-TWO(3:1)
           MOVE FUNCTION CHAR(FG-LOW + 1) TO
               FG-SOCKADDR-ONE(4:1) FG-SOCKADDR-TWO(4:1)
           MOVE X"7F000002" TO FG-SOCKADDR-ONE(5:4)
           MOVE X"7F000001" TO FG-SOCKADDR-TWO(5:4)
           SET FG-A1-ADDR TO ADDRESS OF FG-SOCKADDR-ONE
           SET FG-A2-ADDR TO ADDRESS OF FG-SOCKADDR-TWO
           SET FG-A1-CANONNAME FG-A2-CANONNAME TO NULL
           SET FG-A1-NEXT TO ADDRESS OF FG-AI-TWO
           SET FG-A2-NEXT TO NULL
           SET FG-RESULT-PTR TO ADDRESS OF FG-AI-ONE
           MOVE ZERO TO FG-RETURN
           GOBACK RETURNING FG-RETURN.

       END PROGRAM "getaddrinfo".

       IDENTIFICATION DIVISION.
       PROGRAM-ID. "freeaddrinfo".

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY FGCTRL.

       LINKAGE SECTION.
       01  FG-IGNORED               USAGE POINTER.

       PROCEDURE DIVISION USING BY VALUE FG-IGNORED.
           ADD 1 TO FG-FREE-COUNT
           GOBACK.

       END PROGRAM "freeaddrinfo".
