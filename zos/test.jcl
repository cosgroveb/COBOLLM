//TSTHELLO JOB
//* Replace HLQ and adjust the JOB card for the target system.
//         SET HLQ=BCOSGROVE
//TEST     EXEC IGYWCLG,GOPGM=TSTHELLO,
//             PARM.COBOL='FLAGSTD(H),NOSEQ'
//COBOL.SYSIN DD DISP=SHR,
//             DSN=&HLQ..COBOLLM.COBOL(TSTHELLO)
//         DD DISP=SHR,
//             DSN=&HLQ..COBOLLM.COBOL(GREETER)
//COBOL.SYSLIB DD DISP=SHR,
//             DSN=&HLQ..COBOLLM.COPY
//GO.SYSOUT DD SYSOUT=*
//
