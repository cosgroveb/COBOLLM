      * Every conversion requires input/output pointers and valid sizes.
      * Caller owns both buffers; NATUTF8 retains no pointer or state.
      * Callee resets status, output length, replacement, truncation.
       01  TEXT-PARM.
           05 TP-OPERATION            PIC S9(9) COMP-5.
           05 TP-STATUS               PIC S9(9) COMP-5.
           05 TP-INPUT-PTR            USAGE POINTER.
           05 TP-INPUT-LENGTH         PIC S9(9) COMP-5.
           05 TP-OUTPUT-PTR           USAGE POINTER.
           05 TP-OUTPUT-CAPACITY      PIC S9(9) COMP-5.
           05 TP-OUTPUT-LENGTH        PIC S9(9) COMP-5.
           05 TP-REPLACED             PIC X.
           05 TP-TRUNCATED            PIC X.
