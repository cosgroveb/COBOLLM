      * OPEN requires both host pointers; buffer pointer must be null.
      * READ/WRITE require buffer; host pointers must be null.
      * CLOSE requires null pointers and is idempotent after failure.
      * Caller owns storage; NETIO retains handles only while active.
      * Callee preserves inputs and resets status/count/EOF results.
       01  NET-PARM.
           05 NP-OPERATION            PIC S9(9) COMP-5.
           05 NP-STATUS               PIC S9(9) COMP-5.
           05 NP-SCHEME               PIC S9(9) COMP-5.
           05 NP-CONNECT-HOST-PTR     USAGE POINTER.
           05 NP-CONNECT-HOST-LENGTH  PIC S9(9) COMP-5.
           05 NP-VERIFY-HOST-PTR      USAGE POINTER.
           05 NP-VERIFY-HOST-LENGTH   PIC S9(9) COMP-5.
           05 NP-PORT                 PIC S9(9) COMP-5.
           05 NP-BUFFER-PTR           USAGE POINTER.
           05 NP-BUFFER-CAPACITY      PIC S9(9) COMP-5.
           05 NP-REQUEST-LENGTH       PIC S9(9) COMP-5.
           05 NP-TRANSFERRED          PIC S9(9) COMP-5.
           05 NP-EOF                  PIC X.
