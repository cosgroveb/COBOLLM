      * Reviewed GNU ABI family and native POSIX declarations.
       01 GNU-ABI-FAMILY PIC X(77) VALUE
           "linux-aarch64-elf64-le-lp64-glibc2-openssl3-so3-" &
           "gnucobol3-libcob4-ai48-sa152".
       01 GNU-ABI-PROVENANCE PIC X(84) VALUE
           "spark 2026-09-04 glibc 2.39 OpenSSL 3.0.13 " &
           "/usr/include /lib/aarch64-linux-gnu".
       01 GNU-INT-WIDTH PIC S9(9) COMP-5 VALUE 4.
       01 GNU-SOCKLEN-WIDTH PIC S9(9) COMP-5 VALUE 4.
       01 GNU-POINTER-WIDTH PIC S9(9) COMP-5 VALUE 8.
       01 GNU-LONG-WIDTH PIC S9(9) COMP-5 VALUE 8.
       01 GNU-SIZE-WIDTH PIC S9(9) COMP-5 VALUE 8.
       01 GNU-SSIZE-WIDTH PIC S9(9) COMP-5 VALUE 8.
       01 GNU-ADDRINFO-SIZE PIC S9(9) COMP-5 VALUE 48.
       01 GNU-SIGACTION-SIZE PIC S9(9) COMP-5 VALUE 152.
       01 GNU-EINTR PIC S9(9) COMP-5 VALUE 4.
      * int write(int, void *, size_t) returns signed ssize_t.
      * popen(char *, char *) returns pointer; stdio counts are size_t.
       01 GNU-ERRNO-PTR             USAGE POINTER.
       01 GNU-NATIVE-RESULT         PIC S9(18) COMP-5.
       01 GNU-STREAM-PTR            USAGE POINTER.
       01 GNU-POPEN-MODE            PIC X(2) VALUE X"7200".
