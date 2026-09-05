      * PREFLIGHT requires URL; key/body/response pointers are null.
      * POST requires URL/key/body/response pointers and their sizes.
      * Caller owns all storage; HTTP11 retains and replaces no pointer.
      * Callee resets status, response length, code, and plaintext flag.
       01  HTTP-PARM.
           05 HP-OPERATION            PIC S9(9) COMP-5.
           05 HP-STATUS               PIC S9(9) COMP-5.
           05 HP-URL-PTR              USAGE POINTER.
           05 HP-URL-LENGTH           PIC S9(9) COMP-5.
           05 HP-KEY-PTR              USAGE POINTER.
           05 HP-KEY-LENGTH           PIC S9(9) COMP-5.
           05 HP-BODY-PTR             USAGE POINTER.
           05 HP-BODY-LENGTH          PIC S9(9) COMP-5.
           05 HP-RESPONSE-PTR         USAGE POINTER.
           05 HP-RESPONSE-CAPACITY    PIC S9(9) COMP-5.
           05 HP-RESPONSE-LENGTH      PIC S9(9) COMP-5.
           05 HP-HTTP-STATUS          PIC S9(9) COMP-5.
           05 HP-PLAINTEXT            PIC X.
