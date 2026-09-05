      * All operations require input. FIND also requires name.
      * ESCAPE/DECODE require output; span-only operations require null.
      * Caller owns storage; JSONSCAN retains and replaces no pointer.
      * Callee resets status, output/cursors/spans/depth, and flags.
       01  JSON-PARM.
           05 JP-OPERATION            PIC S9(9) COMP-5.
           05 JP-STATUS               PIC S9(9) COMP-5.
           05 JP-INPUT-PTR            USAGE POINTER.
           05 JP-INPUT-LENGTH         PIC S9(9) COMP-5.
           05 JP-CURSOR               PIC S9(9) COMP-5.
           05 JP-NAME-PTR             USAGE POINTER.
           05 JP-NAME-LENGTH          PIC S9(9) COMP-5.
           05 JP-OUTPUT-PTR           USAGE POINTER.
           05 JP-OUTPUT-CAPACITY      PIC S9(9) COMP-5.
           05 JP-OUTPUT-LENGTH        PIC S9(9) COMP-5.
           05 JP-NEXT-CURSOR          PIC S9(9) COMP-5.
           05 JP-SPAN-START           PIC S9(9) COMP-5.
           05 JP-SPAN-LENGTH          PIC S9(9) COMP-5.
           05 JP-DEPTH                PIC S9(9) COMP-5.
           05 JP-FOUND                PIC X.
           05 JP-END                  PIC X.
