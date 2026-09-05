      * Reviewed GNU ABI family and native network declarations.
       01 GNU-NET-ABI-FAMILY PIC X(77) VALUE
           "linux-aarch64-elf64-le-lp64-glibc2-openssl3-so3-" &
           "gnucobol3-libcob4-ai48-sa152".
       01 GNU-NET-ABI-PROVENANCE PIC X(84) VALUE
           "spark 2026-09-04 glibc 2.39 OpenSSL 3.0.13 " &
           "/usr/include /lib/aarch64-linux-gnu".
       78 GNU-NET-INT-WIDTH         VALUE 4.
       78 GNU-NET-SOCKLEN-WIDTH     VALUE 4.
       78 GNU-NET-POINTER-WIDTH     VALUE 8.
       78 GNU-NET-LONG-WIDTH        VALUE 8.
       78 GNU-NET-SIZE-WIDTH        VALUE 8.
       78 GNU-NET-SSIZE-WIDTH       VALUE 8.
       78 GNU-NET-ADDRINFO-SIZE     VALUE 48.
       78 GNU-NET-SIGACTION-SIZE    VALUE 152.
       78 GNU-AF-UNSPEC             VALUE 0.
       78 GNU-SOCK-STREAM           VALUE 1.
       78 GNU-IPPROTO-TCP           VALUE 6.
       78 GNU-SIGPIPE               VALUE 13.
       78 GNU-SIG-IGN               VALUE 1.
       78 GNU-SSL-VERIFY-PEER       VALUE 1.
       78 GNU-SSL-CTRL-SNI          VALUE 55.
       78 GNU-SNI-HOST-NAME         VALUE 0.
       78 GNU-SSL-ERROR-WANT-READ   VALUE 2.
       78 GNU-SSL-ERROR-WANT-WRITE  VALUE 3.
       78 GNU-SSL-ERROR-ZERO-RETURN VALUE 6.
       01 GNU-ADDRINFO.
           05 GNU-AI-FLAGS          PIC S9(9) COMP-5.
           05 GNU-AI-FAMILY         PIC S9(9) COMP-5.
           05 GNU-AI-SOCKTYPE       PIC S9(9) COMP-5.
           05 GNU-AI-PROTOCOL       PIC S9(9) COMP-5.
           05 GNU-AI-ADDRLEN        PIC 9(9) COMP-5.
           05 GNU-AI-PADDING        PIC X(4).
           05 GNU-AI-ADDR           USAGE POINTER.
           05 GNU-AI-CANONNAME      USAGE POINTER.
           05 GNU-AI-NEXT           USAGE POINTER.
       01 GNU-ADDRINFO-VIEW BASED.
           05 GNU-V-AI-FLAGS        PIC S9(9) COMP-5.
           05 GNU-V-AI-FAMILY       PIC S9(9) COMP-5.
           05 GNU-V-AI-SOCKTYPE     PIC S9(9) COMP-5.
           05 GNU-V-AI-PROTOCOL     PIC S9(9) COMP-5.
           05 GNU-V-AI-ADDRLEN      PIC 9(9) COMP-5.
           05 GNU-V-AI-PADDING      PIC X(4).
           05 GNU-V-AI-ADDR         USAGE POINTER.
           05 GNU-V-AI-CANONNAME    USAGE POINTER.
           05 GNU-V-AI-NEXT         USAGE POINTER.
       01 GNU-SIGACTION-RECORD.
           05 GNU-SA-HANDLER        PIC 9(18) COMP-5.
           05 GNU-SA-MASK           PIC X(128).
           05 GNU-SA-FLAGS          PIC S9(9) COMP-5.
           05 GNU-SA-PADDING        PIC X(4).
           05 GNU-SA-RESTORER       USAGE POINTER.
       01 GNU-SAVED-SIGACTION-RECORD.
           05 GNU-SAVED-SA-HANDLER  PIC 9(18) COMP-5.
           05 GNU-SAVED-SA-MASK     PIC X(128).
           05 GNU-SAVED-SA-FLAGS    PIC S9(9) COMP-5.
           05 GNU-SAVED-SA-PADDING  PIC X(4).
           05 GNU-SAVED-SA-RESTORER USAGE POINTER.
