         MACRO
&LABEL   GVBUR20P &PRE=PARM,&DSECT=Y
.*******************************************************************#VB
.*  SAFR                                                              *
.*******************************************************************#VE
.*  LICENSED MATERIALS - PROPERTY OF IBM                            #CB
.*                                                                    *
.*  "RESTRICTED MATERIALS OF IBM"                                     *
.*                                                                    *
.*  6949-17P                                                          *
.*                                                                    *
.*  (C) COPYRIGHT IBM CORP. 2008 ALL RIGHTS RESERVED.                 *
.*                                                                    *
.*  US GOVERNMENT USERS RESTRICTED RIGHTS - USE, DUPLICATION OR       *
.*  DISCLOSURE RESTRICTED BY GSA ADP SCHEDULE CONTRACT WITH           *
.*  IBM CORP.                                                         *
.*******************************************************************#CE
.** START OF SPECIFICATIONS *******************************************
.*                                                                    *
.*MACRO NAME: GVBUR20P                                                *
.*                                                                    *
.*DESCRIPTIVE NAME: Parameter list for GVBUR20 program                *
.*                                                                    *
.*                                                                    *

         LCLC  &L
&L       SETC  'UR20PARM'
         AIF   ('&LABEL' EQ '').CDSECT
&L       SETC  '&LABEL'
.CDSECT  ANOP
         SPACE 1
         AIF   ('&DSECT' EQ 'N').NDSECT1
         AIF   ('&DSECT' EQ 'n').NDSECT1
         AIF   ('&DSECT' EQ 'Y').DSECT1
         AIF   ('&DSECT' EQ 'y').DSECT1
         MNOTE 12,'***  GVBUR20P INVALID OPERAND - DSECT=&DSECT'
         AGO   .FINISH
.DSECT1  ANOP
&L       DSECT             DSS DYN EXIT ROUTINE PARM LIST
         DS    0F
         AGO   .UR20A
.NDSECT1 ANOP
&L       DS    0F          DSS DYN EXIT ROUTINE PARM LIST
.UR20A   ANOP


&PRE.FC   DS    HL02            FUNCTION CODE
&PRE.RC   DS    HL02            RETURN   CODE
&PRE.ERRC DS    HL02            ERROR    CODE
&PRE.RECL DS    HL02            RECORD   LENGTH
&PRE.RECA DS    AL04            RECORD   AREA      ADDRESS
&PRE.RBN  DS    FL04            RELATIVE BLOCK     NUMBER
&PRE.DDN  DS    CL08            FILE     DDNAME
&PRE.OPT1 DS    CL01            I/O MODE (I=IN,O=OUT,D=DIRECT,X=EXCP)
&PRE.OPT2 DS    CL01
&PRE.NBUF DS    HL02            NUMBER   OF I/O    BUFFERS
&PRE.WPTR DS    AL04            WORK     AREA      POINTER
&PRE.MEMS DS    fL04            Size of memory used by GVBUR20
*                               passed back on OPEN of a dsn


.FINISH  MEND
