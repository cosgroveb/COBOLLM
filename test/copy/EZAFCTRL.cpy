      * Test owner resets this before each fake EZASOKET lifecycle.
       01 EZA-FAKE-CONTROL EXTERNAL.
           05 EF-MODE PIC S9(9) COMP-5.
           05 EF-CALL-COUNT PIC S9(9) COMP-5.
           05 EF-TRACE-LENGTH PIC S9(9) COMP-5.
           05 EF-TRACE PIC X(64).
           05 EF-NODE-LENGTH PIC S9(9) COMP-5.
           05 EF-NODE PIC X(253).
           05 EF-SERVICE-LENGTH PIC S9(9) COMP-5.
           05 EF-SERVICE PIC X(5).
           05 EF-QUERY-VALID PIC X.
           05 EF-IOCTL-VALID PIC X.
           05 EF-QUERY-INPUT PIC X(56).
           05 EF-WRITE-COUNT PIC S9(9) COMP-5.
           05 EF-WRITTEN PIC S9(9) COMP-5.
           05 EF-WRITE-BYTES PIC X(16).
           05 EF-READ-COUNT PIC S9(9) COMP-5.
           05 EF-CONNECT-COUNT PIC S9(9) COMP-5.
           05 EF-CLOSE-COUNT PIC S9(9) COMP-5.
           05 EF-FREE-COUNT PIC S9(9) COMP-5.
           05 EF-TERM-COUNT PIC S9(9) COMP-5.
           05 EF-CLOSE-FAILURES PIC S9(9) COMP-5.
           05 EF-FREE-FAILURES PIC S9(9) COMP-5.
           05 EF-TERM-FAILURES PIC S9(9) COMP-5.
