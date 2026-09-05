      * EXECUTE requires command/output pointers and valid sizes.
      * Caller owns both buffers; SHELL retains no pointer or handle.
      * Callee resets status, output length, outcome, and truncation.
       01  SHELL-PARM.
           05 SP-STATUS               PIC S9(9) COMP-5.
           05 SP-COMMAND-PTR          USAGE POINTER.
           05 SP-COMMAND-LENGTH       PIC S9(9) COMP-5.
           05 SP-OUTPUT-PTR           USAGE POINTER.
           05 SP-OUTPUT-CAPACITY      PIC S9(9) COMP-5.
           05 SP-OUTPUT-LENGTH        PIC S9(9) COMP-5.
           05 SP-RESULT-KIND          PIC S9(9) COMP-5.
           05 SP-EXIT-CODE            PIC S9(9) COMP-5.
           05 SP-SIGNAL               PIC S9(9) COMP-5.
           05 SP-TRUNCATED            PIC X.
