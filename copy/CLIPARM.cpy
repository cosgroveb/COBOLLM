      * Launcher owns and initializes this block for one invocation.
      * Launcher sets platform/count/task; COBOLLM sets CLI-EXIT-CODE.
      * CLI-STATUS reports only launcher normalization failure.
       01  CLI-PARM.
           05 CLI-STATUS              PIC S9(9) COMP-5.
           05 CLI-PLATFORM            PIC S9(9) COMP-5.
           05 CLI-ARG-COUNT           PIC S9(9) COMP-5.
           05 CLI-TASK-LENGTH         PIC S9(9) COMP-5.
           05 CLI-TASK                PIC X(65535).
           05 CLI-EXIT-CODE           PIC S9(9) COMP-5.
