      * WRITE requires descriptor 1 or 2 and a nonnull buffer if used.
      * Descriptor is OUTPUT-STDOUT or OUTPUT-STDERR.
      * Caller owns buffer; OUTPUT retains and replaces no pointer.
      * Callee resets status and written count for every call.
       01  OUTPUT-PARM.
           05 OP-STATUS               PIC S9(9) COMP-5.
           05 OP-FILE-DESCRIPTOR      PIC S9(9) COMP-5.
           05 OP-BUFFER-PTR           USAGE POINTER.
           05 OP-BUFFER-LENGTH        PIC S9(9) COMP-5.
           05 OP-WRITTEN              PIC S9(9) COMP-5.
