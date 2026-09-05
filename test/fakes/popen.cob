       IDENTIFICATION DIVISION.
       PROGRAM-ID. "popen".

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY LIMITS.
       COPY POPFCTRL.
       01 FP-RESULT               PIC S9(18) COMP-5 VALUE ZERO.

       LINKAGE SECTION.
       01 FP-COMMAND              PIC X(65546).
       01 FP-MODE                 PIC X(2).

       PROCEDURE DIVISION USING
           BY REFERENCE FP-COMMAND
           BY REFERENCE FP-MODE.
           ADD 1 TO FP-CALL-COUNT
           MOVE FLAG-OFF TO FP-STAGING-VALID
           EVALUATE FP-EXPECTED-LENGTH
               WHEN ZERO
                   IF FP-MODE = X"7200" AND
                      FP-COMMAND(1:10) =
                          X"6578656320323E26310A" AND
                      FP-COMMAND(11:1) = X"00"
                       MOVE FLAG-ON TO FP-STAGING-VALID
                   END-IF
               WHEN 65534
                   IF FP-MODE = X"7200" AND
                      FP-COMMAND(1:10) =
                          X"6578656320323E26310A" AND
                      FP-COMMAND(11:65534) = ALL X"41" AND
                      FP-COMMAND(65545:1) = X"00"
                       MOVE FLAG-ON TO FP-STAGING-VALID
                   END-IF
               WHEN 65535
                   IF FP-MODE = X"7200" AND
                      FP-COMMAND(1:10) =
                          X"6578656320323E26310A" AND
                      FP-COMMAND(11:65535) = ALL X"41" AND
                      FP-COMMAND(65546:1) = X"00"
                       MOVE FLAG-ON TO FP-STAGING-VALID
                   END-IF
               WHEN OTHER CONTINUE
           END-EVALUATE
           GOBACK RETURNING FP-RESULT.

       END PROGRAM "popen".
