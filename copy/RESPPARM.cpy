      * START requires config/key/task/action pointers; shell is null.
      * CONTINUE requires config/key/action and shell output when used.
      * DESTROY requires every pointer null and every size zero.
      * Caller owns storage; RESPAPI retains history, never pointers.
      * Callee resets action length/category/code, not shell inputs.
       01  RESP-PARM.
           05 RP-OPERATION            PIC S9(9) COMP-5.
           05 RP-STATUS               PIC S9(9) COMP-5.
           05 RP-MODEL-PTR            USAGE POINTER.
           05 RP-MODEL-LENGTH         PIC S9(9) COMP-5.
           05 RP-URL-PTR              USAGE POINTER.
           05 RP-URL-LENGTH           PIC S9(9) COMP-5.
           05 RP-KEY-PTR              USAGE POINTER.
           05 RP-KEY-LENGTH           PIC S9(9) COMP-5.
           05 RP-TASK-PTR             USAGE POINTER.
           05 RP-TASK-LENGTH          PIC S9(9) COMP-5.
           05 RP-SHELL-STATUS         PIC S9(9) COMP-5.
           05 RP-SHELL-EXIT           PIC S9(9) COMP-5.
           05 RP-SHELL-SIGNAL         PIC S9(9) COMP-5.
           05 RP-SHELL-TRUNCATED      PIC X.
           05 RP-SHELL-ENCODING-LOSS  PIC X.
           05 RP-SHELL-OUTPUT-PTR     USAGE POINTER.
           05 RP-SHELL-OUTPUT-LENGTH  PIC S9(9) COMP-5.
           05 RP-ACTION               PIC S9(9) COMP-5.
           05 RP-ACTION-PTR           USAGE POINTER.
           05 RP-ACTION-CAPACITY      PIC S9(9) COMP-5.
           05 RP-ACTION-LENGTH        PIC S9(9) COMP-5.
           05 RP-ERROR-CATEGORY       PIC S9(9) COMP-5.
           05 RP-HTTP-STATUS          PIC S9(9) COMP-5.
