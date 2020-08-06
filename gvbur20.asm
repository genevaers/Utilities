         TITLE 'GVBUR20 - SEQUENTIAL I/O MODULE'
*
* (c) Copyright IBM Corporation 2004,2017.  
*     Copyright Contributors to the GenevaERS Project.
* SPDX-License-Identifier: Apache-2.0
*
****************************************************************************
*                                                                           
*   Licensed under the Apache License, Version 2.0 (the "License");         
*   you may not use this file except in compliance with the License.        
*   You may obtain a copy of the License at                                 
*                                                                           
*     http://www.apache.org/licenses/LICENSE-2.0                            
*                                                                           
*   Unless required by applicable law or agreed to in writing, software     
*   distributed under the License is distributed on an "AS IS" BASIS,       
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and     
*   limitations under the License.                                          
****************************************************************************
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*  GVBUR20 - PERFORMS INITIALIZATION FOR READING SEQUENTIAL FILES     *
*            USING THE BSAM ACCESS METHOD                             *
*                                                                     *
*            BOTH DISK AND TAPE ARE SUPPORTED                         *
*                                                                     *
*  NOTE:     GVBUR20 RUNS IN 31-BIT ADDRESSING MODE.                  *
*                                                                     *
*  RETURN CODES:                                                      *
*                                                                     *
*            0  - SUCCESSFUL                                          *
*           NN  - ERROR MESSAGE NUMBER                                *
*                                                                     *
*                                                                     *
*  REGISTER USAGE:                                                    *
*                                                                     *
*        R15 - TEMPORARY WORK REGISTER                                *
*            - RETURN    CODE                                         *
*                                                                     *
*        R14 - TEMPORARY WORK REGISTER                                *
*            - RETURN    ADDRESS                                      *
*                                                                     *
*        R13 - REGISTER  SAVE AREA  ADDRESS   (WORK AREA BASE)        *
*                                                                     *
*        R12 - Spare                                                  *
*        R11 - PROGRAM   BASE REGISTER                                *
*                                                                     *
*        R10 - INTERNAL  SUBROUTINE  RETURN ADDRESS (1ST LEVEL)       *
*            - PARAMETER LIST ADDRESS                                 *
*            - TEMPORARY WORK REGISTER                                *
*                                                                     *
*        R9  - "UR20"    PARAMETER   AREA   ADDRESS                   *
*                                                                     *
*        R8  - "DDNAME"  WORK AREA   ADDRESS                          *
*                                                                     *
*        R7  - RESUME    EXCP WORK   AREA          ADDRESS            *
*            - BUFFER         LENGTH             ("BLKSIZE")          *
*            - EXCP WORK AREA POOL   SIZE/ENDING   ADDRESS (+1)       *
*                                                                     *
*        R6  - CURRENT RECORD ADDRESS                                 *
*            - CURRENT BLOCK  ADDRESS                                 *
*            - NUMBER  OF     BLOCKS IN ONE SET  ("BUFNO")            *
*                                                                     *
*        R5  - EXCP WORK AREA LENGTH   (ONE SET)                      *
*            - DECB           ADDRESS                                 *
*                                                                     *
*        R4  - spare                                                  *
*                                                                     *
*        R3  - EXCP WORK AREA ADDRESS  (CURRENT)                      *
*                                                                     *
*        R2  - DCB            ADDRESS  (CURRENT)                      *
*                                                                     *
*        R1  - TEMPORARY WORK REGISTER                                *
*        R0  - TEMPORARY WORK REGISTER                                *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
                        EJECT
***********************************************************************
*                                                                     *
*  FUNCTION CODES:                                                    *
*                                                                     *
*        00  - OPEN                                                   *
*        04  - CLOSE                                                  *
*        08  - READ  SEQUENTIAL                                       *
*        12  - READ  DIRECT                                           *
*        16  - WRITE RECORD                                           *
*        20  - WRITE BLOCK   (LOCATE MODE)                            *
*        24  - WRITE BLOCK   (MOVE   MODE)                            *
*                                                                     *
*  RETURN CODES:                                                      *
*                                                                     *
*        00  - SUCCESSFUL                                             *
*        04  - SUCCESSFUL (WARNING: SEE ERROR CODE)                   *
*        08  - END-OF-FILE                                            *
*        16  - PERMANENT   ERROR   (SEE ERROR CODE)                   *
*                                                                     *
*                                                                     *
*  ERROR CODES:                                                       *
*                                                                     *
*        00  - SUCCESSFUL                                             *
*        01  - BAD  WORK AREA   POINTER                               *
*        02  - UNDEFINED FUNCTION  CODE (SB:  0,4,8,12,16,20,24)      *
*        03  - UNDEFINED I/O       MODE (SB: "I","O","D","X")         *
*        04  - FILE  ALREADY     OPENED                               *
*        05  - OPEN  FOR OUTPUT  FAILED                               *
*        06  - OPEN  FOR INPUT   FAILED                               *
*        07  - FILE  NEVER       OPENED                               *
*        08  - FILE  ALREADY     CLOSED                               *
*        09  - BAD   RECORD/BLK  LENGTH                               *
*        10  - OPEN  FOR EXCP    FAILED                               *
*                                                                     *
***********************************************************************
                        EJECT

         GVBAUR35 DSECT=YES
         EJECT
         COPY  GVBMR95W
         EJECT
         COPY  GVBX95PA
         EJECT
         COPY  EXECDATA
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        "GVBUR20"  -  W O R K   A R E A   D E F I N I T I O N        *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
WORKUR20 DSECT
*
         DS    XL(saver_len)   REGISTER SAVE      AREA
*
WORKPARM DS    A               ORIGINAL PARAMETER LIST  ADDRESS
*
WORKDDNA DS    A               FIRST    DDNAME    WORK  AREA   POINTER
*
WORKDBL  DS    xl08            temp work area
*
         DS   0D
WORKRENT DS    XL08            COMMON   PARAMETER AREA
*
*
WORKEXIT DS    A
*
wktokn   DS    4f
wktoknrc ds    f
workreent ds   xl64
workflag ds    xl01
wxrck_call equ x'80'          Set this on if call from GVBXRCK
*
         ds    0d
WORKLEN  EQU   *-WORKUR20
                        EJECT
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        D D N A M E   W O R K A R E A   (P E R   F I L E)            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
DDNWORK  DSECT                 DDNAME   SPECIFIC  WORKAREA
*
DDNNEXT  DS    A               NEXT     DDNAME    WORKAREA
DDNCOMN  DS    A               COMMON   WORKAREA  ADDRESS
*
DDNNAME  DS    CL08            DDNAME
*
DDNOPT1  DS    CL01            OPTION   1  (OPEN)
DDNOPT2  DS    CL01            OPTION   2  (OPEN)
*
DDNDCBA  DS    A               DCB      ADDRESS
*
DDNGETA  DS   0A               READ     SUBROUTINE        ADDRESS
DDNPUTA  DS    A               WRITE    SUBROUTINE        ADDRESS
DDNCHKA  DS    A               CHECK    SUBROUTINE        ADDRESS
*
DDNBUFRA DS    A               BUFFER   POOL      ADDRESS
DDNBUFRL DS    F               BUFFER   POOL      LENGTH
DDNBUFL  DS    F               BLOCK    LENGTH   (ROUNDED TO DBL WORD)
*
DDNRBN   DS    F               RELATIVE BLOCK     NUMBER  CURRENT
DDNDECBL DS    F               DECB/IOB POOL      LENGTH
DDNDECBA DS    A               DECB/IOB POOL      ADDRESS
DDNDECBC DS    A               DECB/IOB ADDRESS           CURRENT
DDNBEND  DS    A               BUFFER   ENDING    ADDRESS CURRENT
DDNRECA  DS    A               RECORD   ADDRESS           CURRENT
DDNRECL  DS    F               RECORD   LENGTH            CURRENT
*
DDNDSIZE DS    F               DCB      LIST               SIZE
DDNXSIZE DS    F               EXTENT   TABLE              SIZE
*
DDNNBUF  DS    H               NUMBER   OF    BUFFERS
*
DDNEOF   DS    CL01            END-OF-FILE INDICATOR
DDNTMODE DS    CL01            TRANSFER MODE (RECORD, BLOCK)
DDNused  DS    C               Y if at least one record read/written
*
         ds     0d
DDNWORKL EQU   *-DDNWORK
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        "GVBUR20" - P A R A M E T E R   L I S T   A D D R E S S E S  *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
PARMLIST DSECT                 PARAMETER  LIST    DEFINITION
*
PARMAPTR DS    A               PARAMETER  AREA    ADDRESS
PARMRPTR DS    A               RECORD   FORMAT    ADDRESS
PARMLPTR DS    A               RECORD   LENGTH    ADDRESS
PARMBPTR DS    A               BLKSIZE            ADDRESS
                        SPACE 5
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        "GVBUR20" - P A R A M E T E R   A R E A   D E F N            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
PARMAREA  GVBUR20P PRE=PARM,DSECT=Y
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        F I L E   E X T E N T   I N F O R M A T I O N                *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        DATA EVENT CONTROL BLOCK ASSOCIATED WITH AN I/O BUFFER       *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
DECB     DSECT                  BSAM DECB
*
DECBNEXT DS    A                DECB PREFIX  (NEXT DECB ADDRESS)
*
DECBBSAM DS    cl(MDLREADL)     BSAM READ DECB
*
         ORG   DECBBSAM
DECBECB  DS    XL04             EVENT  CONTROL  BLOCK
DECBTYP1 DS    XL01             FUNCTION  TYPE
DECBTYP2 DS    XL01             FUNCTION  TYPE
DECBSIZE DS    H                BUFFER SIZE    (MAXIMUM)
DECBDCB  DS    A                DCB    ADDRESS (DUMMY FILE)
DECBBUFR DS    A                BUFFER ADDRESS
DECBIOB  DS    A                IOB    ADDRESS
*
         ORG   DECBBSAM+MDLREADL-4
DECBPREV DS    AL04             PREVIOUS BUFFER AVAILABLE
*
         ORG
DECBLEN  EQU   *-DECB
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        REGISTER EQUATES:                                            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
R0       EQU   0
R1       EQU   1
R2       EQU   2
R3       EQU   3
R4       EQU   4
R5       EQU   5
R6       EQU   6
R7       EQU   7
R8       EQU   8
R9       EQU   9
R10      EQU   10
R11      EQU   11
R12      EQU   12
R13      EQU   13
R14      EQU   14
R15      EQU   15
                        SPACE 2
ERR01    EQU   01     BAD  WORK AREA   POINTER
ERR02    EQU   02     UNDEFINED FUNCTION  CODE (SB:  0,4,8,12,16,20,24)
ERR03    EQU   03     UNDEFINED I/O       MODE (SB: "I","O","D","X")
ERR04    EQU   04     FILE  ALREADY     OPENED
ERR05    EQU   05     OPEN  FOR OUTPUT  FAILED
ERR06    EQU   06     OPEN  FOR INPUT   FAILED
ERR07    EQU   07     FILE  NEVER       OPENED
ERR08    EQU   08     FILE  ALREADY     CLOSED
ERR09    EQU   09     BAD   RECORD/BLK  LENGTH
ERR10    EQU   10     OPEN  FOR EXCP    FAILED
ERR11    EQU   11     EXCP  READ        FAILED
                        EJECT
         PRINT NOGEN
*
GVBUR20  RMODE 24
GVBUR20  AMODE 31
GVBUR20  CSECT
         J     start
         print off,nogen
         copy  asmmsp
         asmmrel ON
         ieabrcx DEFINE
         sysstate archlvl=2
         Print on
UR20EYE  GVBEYE GVBUR20
static   loctr
code     loctr
         using saver,r13
*
start    STM   R14,R12,savgrs14  SAVE  CALLING  PROGRAM'S REGISTERS
*
         LA    R11,0(,R15)        SET   PROGRAM  BASE  REGISTER
         USING (GVBUR20,code),R11
*
         LR    R10,R1             LOAD  PARAMETER LIST  ADDRESS
         USING PARMLIST,R10
*
         L     R9,PARMAPTR        LOAD  PARMAREA ADDRESS
         USING PARMAREA,R9
*
         SR    R0,R0              INITIALIZE RETURN CODE
         STH   R0,PARMRC
         STH   R0,PARMERRC        INITIALIZE ERROR  CODE
*
         LR    R2,R13             SAVE  CALLER'S RSA    ADDRESS
         L     R13,PARMWPTR       LOAD  WORKUR20 ANCHOR ADDRESS
         USING WORKUR20,R13
         using saver,workur20
*
         if clij,r13,le,0         WORK  AREA ALLOCATED Yet

           LHI R0,WORKLEN         LOAD  WORKUR20 LENGTH
           GETMAIN R,LV=(0)
           ST  R1,PARMWPTR        SAVE  WORKUR20 ADDRESS
           LR  R13,R1             SET   WORKUR20 BASE REGISTER
*
           LR  R0,R13             ZERO  WORKUR20
           LHI R1,WORKLEN
           SR  R14,R14
           SR  R15,R15
           MVCL R0,R14
*                                                                     *
*        If SNAP is required, use SNAP=Y so that MR95 allocates and   *
*        opens the file.                                              *
*        The SNAPDCB address is saved in SNAPDCBA                     *
*                                                                     *
         endif
                        SPACE 3
         ST    R10,WORKPARM       SAVE PARAMETER LIST ADDRESS
*
         ST    R2,savprev         SET  BACKWARD  POINTER
prev     using saver,r2
         ST    R13,prev.savnext   SET  FORWARD   POINTER
         drop  prev
*
         LH    R15,PARMFC         LOAD  FUNCTION CODE
         if Cij,r15,le,24         VALID RANGE ???
*
           L    R14,BRNCHTBLA     get the base (using L of a constant  +
                    so that upper part of r14 is not changed)
           b    0(r15,r14)        and go to the routine

BRNCHTBL   BRC 15,OPFUNC          00 -  OPEN
           BRC 15,CLFUNC          04 -  CLOSE
           BRC 15,RSFUNC          08 -  READ  SEQUENTIAL
           BRC 15,RBFUNC          12 -  READ  BLOCK
           BRC 15,WRFUNC          16 -  WRITE RECORD
           BRC 15,LBFUNC          20 -  WRITE BLOCK (LOCATE MODE)
           BRC 15,WBFUNC          24 -  WRITE BLOCK (MOVE   MODE)

         endif
         LHI   R14,ERR02          02 - BAD FUNCTION CODE
*
RTNERROR L     R10,WORKPARM       RELOAD  PARAMETER LIST ADDRESS
*
         STH   R14,PARMERRC       RETURN ERROR CODE
         LHI   R15,16             SET   RETURN CODE
         STH   R15,PARMRC

RETURN   LH    R15,PARMRC         LOAD    RETURN CODE
         L     R13,savprev        RESTORE REGISTER 13
         L     R14,savgrs14       RESTORE REGISTER 14
         LM    R0,R12,savgrs0     RESTORE REGISTERS 0,1, ... ,12
         BSM 0,R14                RETURN
*
         DROP  R10
                        EJECT
***********************************************************************
*                                                                     *
* FUNCTION:   OPEN THE FILE                                           *
*                                                                     *
***********************************************************************
*
OPFUNC   LA    R1,PARMDDN         WORK AREA ALREADY ALLOCATED ???
         BRAS  R10,LOCDDN
         USING DDNWORK,R8
         if cij,r8,le,0

           LA  R1,PARMDDN         NO  - ALLOCATE NEW DDNAME WORK AREA
           BRAS R10,ALLOCATE

           LA  R0,1               INDICATE FIRST BLOCK
           ST  R0,DDNRBN

           ST  R13,DDNCOMN        SAVE  COMMON  WORKUR20 ADDRESS
           MVC DDNNAME,PARMDDN    SAVE  DDNAME

         endif

         L     R6,DDNDCBA         LOAD DCB ADDRESS
         if clij,r6,ne,0          if not zero then an error
           LHI R14,ERR04          04 - FILE ALREADY  OPENED
           BRC 15,RTNERROR        RETURN
         endif
*
         MVC   DDNOPT1,PARMOPT1
         MVC   DDNOPT2,PARMOPT2
*
         llc   r12,parmopt1       get the character
         select clij,r12,eq
         when (c'I',c'D')         input or direct

OPINPUT    LA  R0,INDCBL          LOAD DCB  LENGTH
           GETMAIN R,LV=(0),LOC=BELOW
           ST  R1,DDNDCBA         SAVE DCB ADDRESS IN  WORK AREA
           LR  R6,R1              LOAD DCB BASE    REGISTER
           USING IHADCB,R6
*
           MVC ihadcb(INDCBL),INFILE  COPY  DCB
           LA  R2,INDCBE-INFILE(,R6)
           ST  R2,DCBDCBE
           USING DCBE,R2
*
           MVC DCBDDNAM,DDNNAME   COPY  DDNAME
*
           LArl R14,eod01         FILL  IN  END-OF-FILE  ADDRESS
           ST   R14,DCBEEODA
*
*   BUFNO is managed in the OPEN exit input_open_exit
*
teye       using hdreye,r15
           call ieantrt,(wtknlvl2,wktoknam,wktokn,wktoknrc),           x
               MF=(E,workreent)
           l r15,wktoknrc        successful   ???
           if ltr,r15,r15,z
             l   r15,savprev         Get prev save area
prev         using saver,r15
             l   r15,prev.savgrs12   Base reg of pgm that called us
             drop  prev

             la  r15,hdreye-gvbur20(,r15) Point to possible eyec
             if clc,teye.modname,eq,gvbxrck
               l r15,wktokn+8      Get address of -> Mr95 parms
               l r15,0(,r15)       point at MR95 parms
               using execdata,r15
               if cli,execpagf,eq,c'Y'
                 testauth ,
                 if ltr,r15,r15,z If r15 is zero the authorized
                   oi workflag,wxrck_call Signl called from GVBXRCK
                   oi dcbeflg3,dcbebfxu  Signl we fix the buffers
                 endif
               endif
               drop teye,r15
             endif
           else
             wto 'SAFR GLOBAL token not found'
             lhi r14,16
             j rtnerror
           endif
           drop r2
           MVC WORKRENT(8),OPENPARM
           OPEN ((R6),INPUT),MODE=31,MF=(E,WORKRENT) OPEN  INPUT FILE

           if  tm,dcboflgs,dcbofopn,z OPEN  failed?
*
             LHI R14,ERR06        06 - OPEN FOR INPUT FAILED
             BRC 15,RTNERROR      RETURN
           endif
*
           MVC DDNGETA+1(3),DCBGETA
           Oi  DDNGETA,x'80'
           MVC DDNCHKA+1(3),DCBCHCKA
           Oi  DDNCHKA,x'80'
*
           LH  R0,DCBLRECL        PASS BACK     LRECL FROM  DCB
           STH R0,PARMRECL
*
           LH  R2,DCBBLKSI        LOAD PHYSICAL BLOCKSIZE
           LA  R2,7(,R2)          ROUND TO NEXT DOUBLEWORD
           nill r2,x'fff8'
           ST  R2,DDNBUFL         SAVE ROUNDED  BLOCK  LENGTH
*
           llc R7,dcbncp          Get buffer number (set in exit)
           if ltr,r7,r7,z         If exit did not set NCP (DUMMY?)
             lhi r7,2             then set default of 2
           endif
           STH R7,PARMNBUF        PASS BACK NO. BUFFERS
           STH R7,DDNNBUF         SAVE  NO. BUFFERS
*
*          The following code must be serialised to keep acurate
*          statistics of the i/o buffer storage use, as
*          multiple threads/TCBs could be operating.
*          The current total and high water mark are kept in the
*          THRDMAIN area.
*
           ENQ (GENEVA,ENQSTAT,E,,STEP),RNL=NO
           if LTR,R15,R15,nz
             WTO 'GVBUR20 - Buffer stats "ENQ" FAILED'
*            DC H'0'
           endif
*
           LR  R14,R2             COMPUTE   BUFFER POOL SIZE
           LR  R15,R7             COMPUTE   BUFFER POOL SIZE
           MR  R14,R14
           LR  R3,R15             SAVE  TOTAL SIZE
           ST  R3,DDNBUFRL
           LR  R0,R3              GET    BUFFERS
           GETMAIN RU,LV=(0),LOC=(ANY),BNDRY=PAGE
           ST  R1,DDNBUFRA        SAVE ADDR OF FIRST   BUFFER
*
           LA  R0,DECBLEN         GET  DECB LENGTH
           LR  R1,R7              GET NO. BUFFERS
           MR  R0,R0
           LR  R3,R1
           ST  R3,DDNDECBL        SIZE OF DECB POOL
*
           LR  R0,R1
           GETMAIN R,LV=(0)
           ST  R1,DDNDECBA        SAVE DECB    POOL   ADDRESS
           ST  R1,DDNDECBC        POINT  TO    FIRST  DECB
           LR  R5,R1              LOAD CURRENT DECB   ADDRESS
           USING DECB,R5
           AR  R3,R5              SAVE END  OF DECB'S ADDRESS (+1)
*          ly  r2,SNAPDCBA
*          SNAP DCB=(r2),PDATA=REGS,ID=002
*
*   Increase buffer total stats
*
           l   r14,wktokn+12         Get the main thread area
d1         using thrdarea,r14
           ly  r1,d1.read_buffer_tot Get current total of buffers
           ay  r1,ddnbufrl           Add size of buffers from above
           ay  r1,ddndecbl           Add size of decbs from above
           sty r1,d1.read_buffer_tot
*
*   Increase buffer high water mark stats
*
           if cy,r1,gt,d1.read_buffer_hwm If current total > HWM
             sty r1,d1.read_buffer_hwm  save new HWM
           endif
           drop d1
*
           DEQ (GENEVA,ENQSTAT,,STEP),RNL=NO
*
           if tm,workflag,wxrck_call,o possible page fix

             modeset mode=SUP
             l r1,ddnbufra        Get addr of buffers
             l r2,ddnbufrl        Get total length of buffers
             ahi r2,-1             and point
             ar r2,r1               at last byte
             PGSER R,FIX,A=(1),EA=(2),ECB=0
             modeset mode=PROB
             WTO 'Page fix event file GVBUR20'

           endif
*
           L   R2,ddnbufra        LOAD CURRENT BUFFER  ADDRESS
*
*   R5 -> start of DECBs , R3 -> end of DECBs, R2 -> start of buffers
*
           do  inf
             LA R14,DECBLEN(,R5)  LOAD ADDRESS OF NEXT DECB
             if Clrj,R14,ge,R3    ADDRESS  BEYOND LAST DECB ???
               L R14,DDNDECBA     YES - POINT  TO FIRST
             endif
*
             ST R14,DECBNEXT      CHAIN DECB   PREFIXES TOGETHER
*
             MVC decbbsam(MDLREADL),MDLREAD COPY  MODEL    DECB
             MVC DECBSIZE,DCBBLKSI SAVE BLOCK  SIZE     IN DECB
             ST R6,DECBDCB        SAVE  DCB    ADDRESS  IN DECB
             ST R2,DECBBUFR       SET   BUFFER ADDRESS  IN DECB
*
             LA R1,DECBECB        POINT TO  DECB (FOLLOWING PREFIX)
             XC decbecb,decbecb   CLEAR ECB
             L R15,DDNGETA        LOAD  READ     SUBROUTINE ADDRESS
*
             basr r14,r15         Read the physical block
*
             doexit (CLC,DECBNEXT,eq,DDNDECBA)  LAST DECB STARTED   ???
             L R5,DECBNEXT        LOAD  NEXT DECB  ADDRESS
             A R2,DDNBUFL         LOAD  NEXT BLOCK ADDRESS
           enddo                   - LOOP THROUGH ALL DECB'S
                          EJECT
           L   R5,DDNDECBA        CHECK FOR COMPLETION OF FIRST READ
           LA  R1,DECBECB         LOAD DECB ADDRESS
           L   R15,DDNCHKA        WAIT FOR READ TO COMPLETE
*
           basr r14,r15           issue Check
*
           L   R4,DECBBUFR        LOAD  BUFFER   ADDRESS   FROM   DECB
*
           if TM,DCBRECFM,dcbrecf,o FIXED/UNDEFINED LENGTH   ???
*
             MVI PARMOPT2,C'F'    RETURN RECFM
             LH R0,DCBLRECL       LOAD   RECORD  LENGTH
             ST R0,DDNRECL        SAVE   RECORD  LENGTH
             LH R15,DCBBLKSI      COMPUTE BLOCK  LENGTH
             L R14,DECBIOB        LOAD IOB ADDRESS
             SH R15,14(,R14)      SUBTRACT RESIDUAL COUNT (CSW)
             LA R14,0(R4,R15)     ADD     BLOCK  LENGTH TO BASE
             ST R14,DDNBEND
*
             SR R4,R0             BACKUP TO VIRTUAL STARTING POINT
             ST R4,DDNRECA        SAVE   FIRST   RECORD  ADDRESS
*
           else
*
             MVI PARMOPT2,C'V'    RETURN RECFM
             LH R15,0(,R4)        LOAD    BLOCK LENGTH  FROM "BDW"
             LA R14,0(R4,R15)     COMPUTE END-OF-BLOCK  ADDRESS
             ST R14,DDNBEND
             LH R15,4(,R4)        LOAD   RECORD LENGTH  FROM "RDW"
             ST R15,DDNRECL       SAVE  CURRENT RECORD LENGTH
             LA R4,4(,R4)         SKIP   "BDW"
*
             SR R4,R15            BACKUP TO VIRTUAL STARTING POINT
             ST R4,DDNRECA        SAVE   FIRST  RECORD  ADDRESS
*
           endif
           l   r14,ddnbufrl       Get buffer length if any
           a   r14,ddndecbl       add decb buffers if any
           st  r14,parmmems       return memory used to calling pgm

         when (c'O')              output

***********************************************************************
*                                                                     *
* FUNCTION:   OPEN FOR OUTPUT                                         *
*                                                                     *
***********************************************************************
OPOUTPUT   LA  R0,OUTDCBL         LOAD DCB  LENGTH
           GETMAIN R,LV=(0),LOC=BELOW
           ST  R1,DDNDCBA         SAVE DCB ADDRESS IN  WORK AREA
           LR  R6,R1              LOAD DCB BASE    REGISTER
           USING IHADCB,R6
*
           MVC ihadcb(OUTDCBL),OUTFILE   COPY DCB
           LA  R2,OUTDCBE-OUTFILE(,R6)
           ST  R2,DCBDCBE
*
           MVC DCBDDNAM,DDNNAME   COPY DDNAME
*
           L   R10,WORKPARM       LOAD  PARAMETER LIST ADDRESS
           USING PARMLIST,R10
*
           if TM,PARMAPTR,X'80',z PARMAREA NOT THE LAST POINTER ???
             L R14,PARMRPTR       NO  - LOAD RECORD FORMAT ADDRESS
             select ,

             when CLC,vba,eq,0(r14) VARIABLE BLOCKED  WITH ASA  CC ???
               MVI DCBRECFM,dcbrecv+dcbrecbr+dcbrecca
             when CLC,vbs,eq,0(r14) VARIABLE BLOCKED  STANDARD ???
               MVI DCBRECFM,dcbrecv+dcbrecbr+dcbrecsb
             when CLC,vb,eq,0(r14) VARIABLE  BLOCKED  ???
               MVI DCBRECFM,dcbrecv+dcbrecbr
             when CLC,fba,eq,0(r14) FIXED BLOCKED WITH ASA CC  ???
               MVI DCBRECFM,dcbrecf+dcbrecbr+dcbrecca
             when CLC,fbs,eq,0(r14) FIXED BLOCKED STANDARD ???
               MVI DCBRECFM,dcbrecf+dcbrecbr+dcbrecsb
             when CLC,fb,eq,0(r14) FIXED BLOCKED ???
               MVI DCBRECFM,dcbrecf+dcbrecbr

             endsel
             if TM,PARMRPTR,X'80',z REC  FMT not THE  LAST POINTER ???
               L R14,PARMLPTR     NO  - LOAD RECORD LENGTH ADDRESS
               MVC DCBLRECL,0(R14) NO - COPY RECORD LENGTH
               if TM,PARMLPTR,X'80',Z  REC  LEN noit THE  LAST POINTER ???
                 L R14,PARMBPTR   NO  - LOAD BLOCKSIZE     ADDRESS
                 MVC DCBBLKSI,0(R14) NO - COPY BLOCKSIZE
               endif
             endif
           endif
           DROP R10
*
           MVC WORKRENT(8),OPENPARM
           OPEN ((R6),OUTPUT),MODE=31,MF=(E,WORKRENT)  OPEN OUTPUT FILE
           if  tm,dcboflgs,dcbofopn,z OPEN  failed?

             LHI R14,ERR05        05 - OPEN FOR OUTPUT FAILED
             BRC 15,RTNERROR      RETURN

           endif

           MVC DDNPUTA+1(3),DCBPUTA
           Oi  DDNPUTA,x'80'
*          LA  R15,DDNWORKL-1(,R8)
*          ly  r2,SNAPDCBA
*          SNAP DCB=(r2),PDATA=REGS,ID=003,STORAGE=((R8),(R15))
           MVC DDNCHKA+1(3),DCBCHCKA
           Oi  DDNCHKA,x'80'
*
           MVC DDNOPT1,PARMOPT1
           MVC DDNOPT2,PARMOPT2
*
           LH  R2,DCBLRECL        LOAD   RECORD LENGTH
           STH R2,PARMRECL        PASS     BACK LRECL FROM  DCB
           if TM,DCBRECFM,dcbrecv,o  VARIABLE LENGTH ???
             LA R2,4(,R2)
           endif
           if CH,R2,gt,DCBBLKSI   BAD  DCB INFO (BLKSIZE < LRECL) ???

             CLOSE ((R6)),MODE=31,MF=(E,WORKRENT) CLOSE FILE
             LA R0,OUTDCBL        RELEASE  DCB
             L R1,DDNDCBA
             FREEMAIN R,LV=(0),A=(1)
             XC DDNDCBA,DDNDCBA
             LHI R14,ERR09        09 - Bad length
             BRC 15,RTNERROR      RETURN
           endif

           LH  R2,DCBBLKSI        LOAD PHYSICAL BLOCKSIZE
           LA  R2,7(,R2)          ROUND TO NEXT DOUBLEWORD
           nill r2,x'fff8'
           ST  R2,DDNBUFL         SAVE ROUNDED  BLOCK  LENGTH
*
           llc R15,dcbncp         Get buffer number (set in exit)
           if ltr,r15,r15,z       If exit did not set NCP (DUMMY?)
             lhi r15,2            then set default of 2
           endif
           sth r15,PARMNBUF
*
*          CLI DDNOPT2,C'S'       SHARE BUFFER  POOL OPTION ???
*          BRNE OPOTNBUF          NO  - BYPASS  CHECK
*          LHI R15,POOLNBUF       YES - USE     MAXIMUM
*
OPOTNBUF   STH R15,DDNNBUF        SAVE  NO. BUFFERS
*
           LR  R14,R2             COMPUTE   BUFFER POOL SIZE
           MR  R14,R14
           LR  R3,R15             SAVE  TOTAL SIZE
           ST  R3,DDNBUFRL
*
*          CLI DDNOPT2,C'S'       SHARE  BUFFER  POOL OPTION ???
*          BRNE OPOTBUFN          NO  -  BYPASS  POOL CHECK
*
*          OC  WORKPOOL,WORKPOOL  POOL  ALREADY  ALLOCATED   ???
*          BRNZ OPOTPOOL          YES - CHECK IF AVAILABLE
*          L   R0,F320K           LOAD  POOL  SIZE
*          GETMAIN RU,LV=(0),LOC=(ANY),BNDRY=PAGE
*          ST  R1,WORKPOOL        SAVE  POOL  ADDRESS
*POTPOOL   OC  WORKOWNR,WORKOWNR  POOL  ALREADY ASSIGNED ???
*          BRNZ OPOTBUFN          YES - MUST GET A NEW AREA
*          ST  R7,WORKOWNR        NO  - OWNER IS THIS  WORKAREA
*          L   R1,WORKPOOL        LOAD   BUFFERS ADDRESS
*          BRC 15,OPOTSAVB        BYPASS REGULAR GETMAIN
*
*POTBUFN   ds  0h
           LR  R0,R3              GET    BUFFERS
           GETMAIN RU,LV=(0),LOC=(ANY),BNDRY=PAGE
OPOTSAVB   ST  R1,DDNBUFRA        SAVE ADDR OF FIRST   BUFFER
           LR  R2,R1              LOAD CURRENT BUFFER  ADDRESS
*
           LA  R0,MDLWRTL+4       GET  DECB    POOL
           LH  R1,DDNNBUF
           MR  R0,R0
           LR  R3,R1
           ST  R3,DDNDECBL
*
           LR  R0,R1
           GETMAIN R,LV=(0)
           ST  R1,DDNDECBA        SAVE DECB    POOL   ADDRESS
           ST  R1,DDNDECBC        POINT  TO    FIRST  DECB
           LR  R5,R1              LOAD CURRENT DECB   ADDRESS
           USING DECB,R5
           AR  R3,R5              SAVE END  OF DECB'S ADDRESS (+1)
*          ly  r2,SNAPDCBA
*          SNAP DCB=(r2),PDATA=REGS,ID=003
*
           LR  R14,R2             SAVE  FIRST  RECORD ADDRESS
           LR  R0,R2
           if TM,DCBRECFM,dcbrecf,z  Not FIXED/UNDEFINED ???
             LA R0,4(,R14)        SKIP  BDW
           endif
           ST  R0,DDNRECA
           AH  R14,DCBBLKSI
           ST  R14,DDNBEND
*
           LH  R0,DDNNBUF         INITIALIZE LOOP COUNTER
           do  from=(r0)
             LA R14,MDLWRTL+4(,R5) LOAD ADDRESS OF NEXT DECB
             LA R14,l'decbnext+l'decbbsam(,R5) LOAD ADDR OF NEXT DECB

             if crj,R14,ge,R3     ADDRESS  BEYOND LAST BUFFER ???
               L R14,DDNDECBA     YES - POINT  TO FIRST
             endif
*
             ST R14,DECBNEXT      CHAIN DECB'S TOGETHER
             LAY R1,MDLWRT        COPY   MODEL   DECB
             MVC decbbsam(mdlwrtl),0(R1) COPY MODEL   DECB
             MVC DECBSIZE,DCBBLKSI SAVE BLOCK  SIZE    IN DECB
             ST R6,DECBDCB        SAVE  DCB    ADDRESS IN DECB
             ST R2,DECBBUFR       SAVE  BUFFER ADDRESS IN DECB
             MVI DECBECB,X'7F'    INDICATE I/O COMPLETE (BUFFER FREE)
*
             L R5,DECBNEXT        ADVANCE  TO NEXT DECB
             A R2,DDNBUFL         ADVANCE  TO NEXT BUFFER
           enddo
*
           if TM,DCBRECFM,dcbrecf,o   FIXED/UNDEFINED LENGTH   ???
             MVI PARMOPT2,C'F'    fixed
           else
             MVI PARMOPT2,C'V'    variable
           endif
           DROP R5
           DROP R6

         othrwise

           lhi r14,err03          03 - undefined I/O mode
           j     rtnerror

         endsel
         j    return
                        EJECT
***********************************************************************
*                                                                     *
* FUNCTION:   CLOSE THE FILE                                          *
*                                                                     *
***********************************************************************
*
CLFUNC   LA    R1,PARMDDN         WORK AREA ALREADY ALLOCATED ???
         BRAS  R10,LOCDDN
         USING DDNWORK,R8
         do ,
           doexit  cij,r8,le,0
*
*          LA  R15,DDNWORKL-1(,R8)
*          ly  r2,SNAPDCBA
*          SNAP DCB=(r2),ID=010,STORAGE=((R8),(R15))
           L   R6,DDNDCBA         LOAD  DCB  ADDRESS
           USING IHADCB,R6
*
           doexit  cij,r6,le,0    get out if not opened

           if  tm,dcboflgs,dcbofopn,z CLOSED ?
             MVC PARMRC,H004      WARNING
             MVC PARMERRC,H008    08 - FILE ALREADY CLOSED
           else
             if CLI,DDNOPT1,eq,C'O' OUTPUT FILE    ???

               L R5,DDNDECBC      LOAD  CURRENT  DECB PREFIX ADDRESS
               USING DECB,R5
               LR R4,R5           SAVE  STARTING DECB PREFIX ADDRESS

               do ,
                 doexit CLI,DDNTMODE,eq,C'M' MOVE  BLOCK  MODE  ???
                 if CLI,DDNTMODE,eq,c'B' LOCATE BLOCK MODE  ???

                   LH R0,PARMRECL LOAD   BLOCK LENGTH
                   SR R14,R14     ASSUME FIXED (SET MINIMUM = 0)
                   if TM,DCBRECFM,dcbrecf,NO FIXED/UNDEFINED ???
                     LA R14,8     NO  -  SET   MINIMUM  = 8
                   endif
                   doexit crj,R0,le,R14 NULL  BLOCK  ???

                 else

                   L R0,DDNRECA   LOAD  BUFFER   POSITION
                   L R14,DECBBUFR LOAD  BUFFER   ADDR FROM   DECB
                   SR R0,R14      COMPUTE BLOCK  LENGTH
                   doexit (TM,DCBRECFM,dcbrecf,o),and,   FIXED/UNDEF?  +
               cij,R0,le,0       NULL   BLOCK    ???

                   STH R0,0(,R14) BUILD   BLOCK DESCRIPTOR WORD (BDW)
                   XC 2(2,R14),2(R14)
                   doexit cij,R0,le,8  No DATA  IN BLOCK  ???
                 endif

                 if TM,DCBRECFM,dcbrecbr,o BLOCKED RECORDS ???
                   STH R0,DECBSIZE PLACE LENGTH IN DECB
                   STH R0,DCBBLKSI PLACE LENGTH IN DCB
                 endif

                 XC DECBECB,DECBECB CLEAR ECB
                 LA R1,DECBECB    POINT TO DECB (FOLLOWING PREFIX)
                 L R15,DDNPUTA    LOAD  WRITE  ROUTINE ADDRESS
                 basr r14,r15       and write it

               enddo
               do until=(crj,r5,eq,r4)
                 L R5,DECBNEXT    LOAD NEXT DECB PREFIX ADDRESS
                 ST R5,DDNDECBC   SAVE  ADDRESS OF NEXT DECB PREFIX
*
                 LA R1,DECBECB  POINT TO ECB
                 L R15,DDNCHKA  WAIT FOR I/O  TO COMPLETE
                 basr r14,r15   and do the check now
               enddo

             endif
             MVC WORKRENT(8),OPENPARM
             CLOSE ((R6)),MODE=31,MF=(E,WORKRENT) CLOSE FILE

             MVI DDNEOF,C'N'      CLEAR END-OF-FILE INDICATOR
*
             if tm,workflag,wxrck_call,o possible page fix
               modeset mode=SUP
               l r1,ddnbufra      address of buffers
               l r2,ddnbufrl      Get total length of buffers
               ahi r2,-1           and point
               ar r2,r1             at last byte
               PGSER R,FREE,A=(1),EA=(2) unfix pages
               modeset mode=PROB
             endif
*
*   Serialise to adjust buffer total
*
             ENQ (GENEVA,ENQSTAT,E,,STEP),RNL=NO
             if LTR,R15,R15,nz
               WTO 'GVBUR20 - Buffer stats "ENQ" FAILED'
*            this just means that the stats will not be correct
             endif
*
             xr r2,r2
             L R0,DDNBUFRL        LOAD  BUFFER  LENGTH
             if Lt,R1,DDNBUFRA,P  LOAD  BUFFER  ADDRESS

               lr r2,r0
               FREEMAIN RU,LV=(0),A=(1)

             endif
*
             L R0,DDNDECBL        RELEASE  DECB/IOB  POOL
             if Lt,R1,DDNDECBA,p

               ar r2,r0
               FREEMAIN R,LV=(0),A=(1)

             endif
*
             if ltr,r2,r2,p
d1             using thrdarea,r14
               l r14,wktokn+12       Get the main thread area
               ly r1,d1.read_buffer_tot Get total size of buffers used
               sr r1,r2              subtract freemained value
               sty r1,d1.read_buffer_tot
               drop d1
             endif
*
             DEQ (GENEVA,ENQSTAT,,STEP),RNL=NO
*
             XC DDNBUFRL,DDNBUFRL
             XC DDNBUFRA,DDNBUFRA
             XC DDNDECBA,DDNDECBA
             XC DDNDECBC,DDNDECBC
             XC DDNDECBL,DDNDECBL
*
             LA R0,INDCBL         ASSUME INPUT FILE
*
             if CLI,DDNOPT1,eq,C'O' OUTPUT FILE ???
               LA R0,OUTDCBL      YES - CHANGE TO OUTPUT
             endif
*
             L R1,DDNDCBA         RELEASE  DCB
             FREEMAIN R,LV=(0),A=(1)
             XC DDNDCBA,DDNDCBA

             DROP R5
             DROP R6
           endif
           BRC 15,RETURN          RETURN
         enddo

         MVC   PARMRC,H012        SERIOUS   ERROR
         MVC   PARMERRC,H007      07 - FILE NEVER   OPENED
*
         BRC   15,RETURN          RETURN

                        EJECT
***********************************************************************
*                                                                     *
* FUNCTION:   READ THE NEXT BSAM RECORD                               *
*                                                                     *
***********************************************************************
*
RSFUNC   L     R8,WORKDDNA        LOAD ADDRESS OF FIRST DDNAME WORKAREA
         USING DDNWORK,R8

         do inf
           if cij,r8,le,0         END-OF-CHAIN ???
             MVC PARMRC,H012      SERIOUS   ERROR
             MVC PARMERRC,H007    07 - FILE NEVER   OPENED
             BRC 15,RETURN        RETURN
           endif

           doexit CLC,DDNNAME,eq,PARMDDN  CORRECT WORK AREA ???

           L   R8,DDNNEXT         ADVANCE TO NEXT WORK AREA
         enddo

         L     R6,DDNDCBA         LOAD CURRENT  DCB ADDRESS
         USING IHADCB,R6

         L     R4,DDNRECA         LOAD PREVIOUS RECORD   ADDRESS
         A     R4,DDNRECL         ADVANCE  TO NEXT RECORD
         IF C,R4,lt,DDNBEND       More data in buffer ???

           ST  R4,DDNRECA         SAVE NEXT RECORD'S ADDRESS
           if TM,DCBRECFM,dcbrecf,no   FIXED/UNDEFINED LENGTH ???

             LH R15,0(,R4)        LOAD   RECORD LENGTH  FROM "RDW"
             ahi R15,-4
             ST R15,DDNRECL       SAVE  CURRENT RECORD LENGTH
             LA R4,4(,R4)         SKIP   "RDW"
             ST R4,DDNRECA        SAVE   FIRST  RECORD  ADDRESS
           endif

         else
*
           if CLI,DDNEOF,eq,C'Y'  END-OF-FILE   ???
EOD01        MVI DDNEOF,C'Y'      INDICATE END-OF-FILE
*
             XC DDNRECA,DDNRECA
             XC DDNRECL,DDNRECL
             XC DDNBEND,DDNBEND
*
             MVC PARMRC,H008
             BRC 15,RETURN
           else
             L R5,DDNDECBC        LOAD CURRENT DECB PREFIX ADDRESS
             USING DECB,R5
             if LT,R1,DECBPREV,P    PRECEDING  BUFFER AVAILABLE  ???
               XC DECBPREV,DECBPREV CLEAR AVAILABLE INDICATION
               MVC 10(2,R1),DCBBLKSI RESET BLOCK SIZE IN DECB
               LA R1,4(,R1)       LOAD  DECB  ADDRESS
               XC 0(4,R1),0(R1)   ZERO  THE   ECB
               L R15,DDNGETA      CALL AND SWITCH TO 31-BIT MODE
               basr R14,r15       issue the read
             endif
             LR R14,R5            SAVE     CURRENT DECB  PREFIX ADDR
             L R5,DECBNEXT        ADVANCE  TO NEXT DECB  PREFIX
             ST R14,DECBPREV      INDICATE PRECEDING  AVAILABLE
             ST R5,DDNDECBC
*
             LA R1,DECBECB      LOAD DECB ADDRESS
             L R15,DDNCHKA      WAIT FOR READ TO COMPLETE
             basr r14,r15       issue the check
                            EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*         S E T U P A D D R E S S E S F O R   N E W   B U F F E R     *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
             L R4,DECBBUFR        LOAD  BUFFER   ADDRESS   FROM   DECB
             if TM,DCBRECFM,dcbrecf,o FIXED/UNDEFINED LENGTH ???

               ST R4,DDNRECA      SAVE   FIRST   RECORD  ADDRESS

               LH R15,DCBLRECL    SAVE   RECORD  LENGTH  (ASSUME FIXED)
               ST R15,DDNRECL

               LH R15,DCBBLKSI    COMPUTE BLOCK  LENGTH
               L R14,DECBIOB      LOAD IOB ADDRESS
               SH R15,14(,R14)    SUBTRACT RESIDUAL COUNT (CSW)
               LA R14,0(R4,R15)   ADD     BLOCK  LENGTH TO BASE
               ST R14,DDNBEND

             else

               LH R15,0(,R4)      LOAD    BLOCK LENGTH  FROM "BDW"
               LA R14,0(R4,R15)   COMPUTE END-OF-BLOCK  ADDRESS
               ST R14,DDNBEND
*
               LH R15,4(,R4)      LOAD   RECORD LENGTH  FROM "RDW"
               ahi R15,-4
               ST R15,DDNRECL     SAVE  CURRENT RECORD LENGTH
               LA R4,4+4(,R4)     SKIP   "BDW" + "RDW"
               ST R4,DDNRECA      SAVE   FIRST  RECORD  ADDRESS

             endif
           endif
         endif
         ST    R4,PARMRECA         RETURN POINTER
         L     R15,DDNRECL         COPY   LENGTH
         STH R15,PARMRECL
*
         mvi DDNused,c'Y'          mark as used
*
         BRC   15,RETURN           RETURN

***********************************************************************
*                                                                     *
* FUNCTION :   WRITE THE NEXT BSAM RECORD                             *
*                                                                     *
***********************************************************************
*
WRFUNC   L     R8,WORKDDNA        LOAD ADDRESS OF FIRST DDNAME WORKAREA
         USING DDNWORK,R8

         do inf
           if cij,r8,le,0         END-OF-CHAIN ???
             MVC PARMRC,H012      SERIOUS   ERROR
             MVC PARMERRC,H007    07 - FILE NEVER   OPENED
             BRC 15,RETURN        RETURN
           endif

           doexit CLC,DDNNAME,eq,PARMDDN  CORRECT WORK AREA ???

           L   R8,DDNNEXT         ADVANCE TO NEXT WORK AREA
         enddo

         L     R6,DDNDCBA         LOAD CURRENT  DCB  ADDRESS
         USING IHADCB,R6

         L     R4,PARMRECA        LOAD  RECORD  AREA ADDR
*
         do inf
           L   R0,DDNRECA         LOAD  TARGET  ADDRESS FOR NEW RECORD
           LH  R15,PARMRECL       LOAD  RECORD  LENGTH
           if TM,DCBRECFM,dcbrecf,NO    FIXED/UNDEFINED  ???
             LA R15,4(,R15)       NO  - ADD RDW LENGTH
           endif
           LR  R14,R0             COMPUTE TRIAL END-OF-BUFFER  ADDRESS
           AR  R14,R15
           doexit C,R14,le,DDNBEND  Get out if it fits

           if  ch,R15,gt,DCBLRECL RECORD   TOO  LARGE ???
             LHI R14,ERR09        09 - Bad length
             BRC 15,RTNERROR      RETURN
           endif

           L   R5,DDNDECBC        LOAD  CURRENT DECB PREFIX ADDRESS
           L   R14,DECBBUFR       LOAD   BUFFER ADDR FROM   DECB
           if TM,DCBRECFM,dcbrecf,no    FIXED/UNDEFINED  ???
             SR R0,R14            COMPUTE BLOCK LENGTH
             STH R0,0(,R14)       BUILD   BLOCK DESCRIPTOR WORD (BDW)
           else
             LH R0,DCBBLKSI       LOAD   RECORD  LENGTH
           endif
           STH R0,DECBSIZE        PLACE  LENGTH IN DECB
           XC  DECBECB,DECBECB    CLEAR  ECB
           LA  R1,DECBECB         POINT TO DECB (FOLLOWING PREFIX)
           L   R15,DDNPUTA        LOAD  WRITE  ROUTINE ADDRESS
           basr R14,r15           and go to the routine

           L   R5,DECBNEXT        LOAD  ADDRESS OF NEXT DECB PREFIX
           ST  R5,DDNDECBC        SAVE  ADDRESS OF NEXT DECB PREFIX

           LA R1,DECBECB        POINT TO ECB
           L R15,DDNCHKA        WAIT FOR I/O  TO COMPLETE
           basr R14,r15         and go to the routine

           asi DDNRBN,1           INCREMENT RELATIVE BLOCK NUMBER
*
           L   R1,DECBBUFR        LOAD  BUFFER ADDRESS FROM DECB
           LR  R14,R1             SAVE  FIRST  RECORD  ADDRESS
           AH  R1,DCBBLKSI
           ST  R1,DDNBEND
           if TM,DCBRECFM,dcbrecf,no    FIXED/UNDEFINED  ???
             LA R14,4(,R14)       SKIP  BDW
           endif
           ST  R14,DDNRECA        INITIALIZE CURRENT BUFFER POSITION

         enddo

         ST    R14,DDNRECA        UPDATE ADDRESS  FOR NEXT RECORD
*
         if TM,DCBRECFM,dcbrecf,no      FIXED/UNDEFINED  ???
           LR  R1,R0              BUILD RDW
           STH R15,0(,R1)
           XC  2(2,R1),2(R1)
           LA  R0,4(,R1)
           LH  R15,PARMRECL
         endif
*
         LR    R14,R4             MOVE   THIS OUTPUT  RECORD TO BUFFER
         LR    R1,R15
         LR    R10,R0             SAVE BUFFER ADDRESS FOR SNAP
         do until=(MVCLe,R0,R14,X'b0',no)  Move until completed
         enddo
*
*        LA    R15,DDNWORKL-1(,R8)
*        ly    r2,SNAPDCBA
*        SNAP  DCB=(r2),ID=221,STORAGE=((R8),(R15))
*        LH    R15,PARMRECL
*        AR    R15,R10
*        BCTR  R15,0
*        SNAP  DCB=(r2),ID=222,STORAGE=((R10),(R15))
*
         mvi   DDNused,c'Y'        mark as used
*
         MVC   PARMRBN,DDNRBN     PASS RELATIVE BLOCK NUMBER TO CALLER
         BRC   15,RETURN          RETURN
*
                        EJECT
***********************************************************************
*                                                                     *
* FUNCTION :   WRITE THE NEXT BSAM BLOCK (LOCATE MODE)                *
*                                                                     *
***********************************************************************
*
LBFUNC   L     R8,WORKDDNA        LOAD ADDRESS OF FIRST DDNAME WORKAREA
         USING DDNWORK,R8

         do inf
           if cij,r8,le,0         END-OF-CHAIN ???
             MVC PARMRC,H012      SERIOUS   ERROR
             MVC PARMERRC,H007    07 - FILE NEVER   OPENED
             BRC 15,RETURN        RETURN
           endif

           doexit CLC,DDNNAME,eq,PARMDDN  CORRECT WORK AREA ???

           L   R8,DDNNEXT         ADVANCE TO NEXT WORK AREA
         enddo

         L     R6,DDNDCBA         LOAD CURRENT  DCB  ADDRESS
         USING IHADCB,R6
*
         L     R5,DDNDECBC        LOAD  CURRENT DECB PREFIX ADDRESS
*
         if cli,DDNused,eq,c'Y'   Already written to?

           LH  R0,PARMRECL        LOAD  BLOCK  LENGTH
           if cij,r0,gt,0         something to write?

             STH R0,DECBSIZE      PLACE LENGTH IN DECB
*
             XC DECBECB,DECBECB   CLEAR ECB
             LA R1,DECBECB        POINT TO DECB (FOLLOWING PREFIX)
             L R15,DDNPUTA        LOAD  WRITE  ROUTINE ADDRESS
             basr R14,r15         and go to the routine
*
             L R5,DECBNEXT        LOAD  ADDRESS OF NEXT DECB PREFIX
             ST R5,DDNDECBC       SAVE  ADDRESS OF NEXT DECB PREFIX

             LA R1,DECBECB      POINT TO ECB
             L R15,DDNCHKA      WAIT FOR I/O  TO COMPLETE
             basr R14,r15       and go to the routine

             asi DDNRBN,1        INCREMENT RELATIVE BLOCK NUMBER
           endif
         endif

         MVI   DDNTMODE,C'B'      INDICATE LOCATE BLOCK MODE
         L     R1,DECBBUFR        LOAD  BUFFER  ADDRESS FROM DECB
         LR    R14,R1             SAVE  FIRST   RECORD  ADDRESS
         AH    R1,DCBBLKSI
         ST    R1,DDNBEND
*
         ST    R14,PARMRECA       PASS  BLOCK ADDRESS TO CALLER
         LH    R15,DCBBLKSI       COMPUTE END-OF-BLOCK  ADDRESS
         STH   R15,PARMRECL
         AR    R14,R15
         ST    R14,DDNRECA        SET   PREVIOUS BLOCK  ENDING  ADDRESS
*
         mvi   DDNused,c'Y'        mark as used
*
         MVC   PARMRBN,DDNRBN     PASS RELATIVE BLOCK NUMBER TO  CALLER
         BRC   15,RETURN
                        EJECT
***********************************************************************
*                                                                     *
* FUNCTION :   WRITE THE NEXT BSAM BLOCK (MOVE   MODE)                *
*                                                                     *
***********************************************************************
*
WBFUNC   L     R8,WORKDDNA        LOAD ADDRESS OF FIRST DDNAME WORKAREA
         USING DDNWORK,R8

         do inf
           if cij,r8,le,0         END-OF-CHAIN ???
             MVC PARMRC,H012      SERIOUS   ERROR
             MVC PARMERRC,H007    07 - FILE NEVER   OPENED
             BRC 15,RETURN        RETURN
           endif

           doexit CLC,DDNNAME,eq,PARMDDN  CORRECT WORK AREA ???

           L   R8,DDNNEXT         ADVANCE TO NEXT WORK AREA
         enddo

         L     R6,DDNDCBA         LOAD CURRENT  DCB  ADDRESS
         USING IHADCB,R6

         L     R5,DDNDECBC        LOAD  CURRENT DECB PREFIX ADDRESS

         LH    R1,PARMRECL        LOAD  BLOCK  LENGTH

         if LTR,R1,R1,np,or,      NULL  BLOCK  ???                     +
               CH,R1,gt,DCBBLKSI        TOO   LONG   ???
           LHI R14,ERR09          09 - Bad length
           BRC 15,RTNERROR        RETURN
         endif

         STH   R1,DECBSIZE        PLACE LENGTH IN DECB
*
         L     R0,DECBBUFR        LOAD  BUFFER ADDRESS
         L     R14,PARMRECA       LOAD  BLOCK  ADDRESS
         LR    R15,R1             LOAD  BLOCK  LENGTH
         MVCL  R0,R14             COPY  BLOCK
*
*        L     R10,DECBBUFR
*        LH    R15,DECBSIZE
*        AR    R15,R10
*        BCTR  R15,0
*        ly    r2,SNAPDCBA
*        SNAP  DCB=(r2),ID=222,STORAGE=((R10),(R15))
*
         XC    DECBECB,DECBECB    CLEAR ECB
         LA    R1,DECBECB         POINT TO DECB (FOLLOWING PREFIX)
         L     R15,DDNPUTA        LOAD  WRITE  ROUTINE ADDRESS
         basr  R14,r15            and go to the routine
*
         L     R5,DECBNEXT        LOAD  ADDRESS OF NEXT DECB PREFIX
         ST    R5,DDNDECBC        SAVE  ADDRESS OF NEXT DECB PREFIX
*
         LA  R1,DECBECB         POINT TO ECB
         L   R15,DDNCHKA        WAIT FOR I/O  TO COMPLETE
         basr R14,r15           and go to the routine

         asi   DDNRBN,1           INCREMENT RELATIVE BLOCK NUMBER

         MVI   DDNTMODE,C'M'      INDICATE  BLOCK  MOVE  MODE

         mvi   DDNused,c'Y'        mark as used

         MVC   PARMRBN,DDNRBN     PASS RELATIVE BLOCK NUMBER TO  CALLER
         BRC   15,RETURN
                        EJECT
***********************************************************************
*                                                                     *
* FUNCTION:   READ THE NEXT BSAM BLOCK (LOCATE MODE)                  *
*                                                                     *
***********************************************************************
*
RBFUNC   L     R8,WORKDDNA        LOAD ADDRESS OF FIRST DDNAME WORKAREA
         USING DDNWORK,R8

         do inf
           if cij,r8,le,0         END-OF-CHAIN ???
             MVC PARMRC,H012      SERIOUS   ERROR
             MVC PARMERRC,H007    07 - FILE NEVER   OPENED
             BRC 15,RETURN        RETURN
           endif

           doexit CLC,DDNNAME,eq,PARMDDN  CORRECT WORK AREA ???

           L   R8,DDNNEXT         ADVANCE TO NEXT WORK AREA
         enddo

         L     R6,DDNDCBA         LOAD CURRENT  DCB ADDRESS
         USING IHADCB,R6

         CLI   DDNEOF,C'Y'        END-OF-FILE   ???
         BRE   EOD01              YES -  TELL   CALLER
*
         L     R5,DDNDECBC        LOAD CURRENT  DECB PREFIX ADDRESS
         USING DECB,R5
*
         L     R4,DDNRECA         LOAD PREVIOUS RECORD ADDRESS
         A     R4,DDNRECL         ADVANCE    TO NEXT   RECORD
         if C,R4,ge,DDNBEND       LAST  RECORD  IN     BUFFER  ???

           L   R1,DECBPREV        PRECEDING  BUFFER AVAILABLE  ???
           if cij,r1,gt,0         PRECEDING  BUFFER AVAILABLE  ???

             XC DECBPREV,DECBPREV CLEAR AVAILABLE   INDICATION
             MVC 10(2,R1),DCBBLKSI RESET BLOCK SIZE IN DECB
             LA R1,4(,R1)         LOAD  DECB  ADDRESS
             XC 0(4,R1),0(R1)     ZERO  THE   ECB
             L R15,DDNGETA        CALL  AND  SWITCH TO 31-BIT MODE
             basr R14,r15         and go to the routine

           endif

           LR  R14,R5             SAVE     CURRENT DECB  PREFIX ADDR
           L   R5,DECBNEXT        ADVANCE  TO NEXT DECB  PREFIX
           ST  R14,DECBPREV       INDICATE PRECEDING  AVAILABLE
           ST  R5,DDNDECBC
*
           LA R1,DECBECB        LOAD DECB ADDRESS
           L R15,DDNCHKA        WAIT FOR I/O  TO COMPLETE
           basr R14,r15         and go to the routine
         endif
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*     S E T U P   A D D R E S S E S   F O R   N E W   B L O C K       *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
         MVI   DDNTMODE,C'B'      INDICATE  BLOCK READ     MODE
*
         L     R4,DECBBUFR        LOAD  BUFFER    ADDRESS  FROM   DECB
         if TM,DCBRECFM,dcbrecf,o   FIXED/UNDEFINED LENGTH   ???
           ST  R4,DDNRECA         SAVE     FIRST   BLOCK   ADDRESS
           LH  R15,DCBBLKSI       COMPUTE  BLOCK   LENGTH
           L   R14,DECBIOB        LOAD IOB ADDRESS
           SH  R15,14(,R14)       SUBTRACT RESIDUAL COUNT (CSW)
           ST  R15,DDNRECL        SAVE     BLOCK   LENGTH
           LA  R14,0(R4,R15)      ADD      BLOCK   LENGTH  TO BASE
           ST  R14,DDNBEND
         else
           LH  R15,0(,R4)         LOAD    BLOCK LENGTH  FROM "BDW"
           LA  R14,0(R4,R15)      COMPUTE END-OF-BLOCK  ADDRESS
           ST  R14,DDNBEND
           ST  R15,DDNRECL        SAVE   CURRENT BLOCK  LENGTH
           ST  R4,DDNRECA         SAVE   BLOCK ADDRESS
         endif
         ST    R4,PARMRECA        RETURN POINTER
         L     R15,DDNRECL        COPY   LENGTH
         STH   R15,PARMRECL
*
         mvi   DDNused,c'Y'        mark as used
*
         BRC   15,RETURN          RETURN
*
         DROP  R5
         DROP  R6
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*  "ALLOCATE" - ALLOCATES MEMORY DYNAMICALLY FOR NEW DDNAME           *
*               WORK AREAS.                                           *
*                                                                     *
*  REGISTER USAGE:                                                    *
*                                                                     *
*        R10 - RETURN ADDRESS                                         *
*        R8  - CURRENT  "DDN" WORK AREA ADDRESS                       *
*        R2  - PREVIOUS "DDN" WORK AREA ADDRESS                       *
*        R1  - DDNAME    ADDRESS                                      *
*        R0  - AREA LENGTH                                            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
         USING DDNWORK,R8
*
ALLOCATE LHI   R0,DDNWORKL        LOAD  AREA LENGTH
         GETMAIN RU,LV=(0),LOC=(ANY)
*
         LR    R8,R1              INITIALIZE CURRENT DDN ADDRESS
         ST    R8,0(,R2)          ADD TO DDN CHAIN
*
         XC    DDNWORK(DDNWORKL),DDNWORK     ZERO WORK AREA
         MVI   DDNused,c'N'       set this to N
*
         BR    R10                RETURN  TO CALLER
*
         DROP  R8
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
* "LOCDDN" - SEARCHES THE "DDN" CHAIN FOR AN ENTRY WHICH MATCHES      *
*            THE "DDNAME" IN THE PARAMETER AREA.                      *
*                                                                     *
* REGISTER USAGE:                                                     *
*                                                                     *
*        R10 - RETURN ADDRESS                                         *
*        R8  - CURRENT  "DDN"  WORK AREA ADDRESS                      *
*        R2  - PREVIOUS "DDN"  WORK AREA ADDRESS                      *
*        R1  - DDNAME          ADDRESS                                *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
LOCDDN   LA    R2,WORKDDNA          INITIALIZE PREVIOUS WORK AREA ADDR
         L     R8,WORKDDNA          INITIALIZE CURRENT  WORK AREA ADDR
*
         BRC   15,LOCEND            CHECK  FOR END-OF-CHAIN
                        SPACE 3
         USING DDNWORK,R8
*
LOCLOOP  LR    R2,R8
         L     R8,DDNNEXT
LOCEND   LTR   R8,R8              END-OF-CHAIN ???
         BZR   R10                YES - EXIT SUBROUTINE
*
         CLC   DDNNAME,0(R1)      MATCHING ENTRY ???
         BRNE  LOCLOOP            NO  - ADVANCE TO NEXT ENTRY ON CHAIN
*
         BR    R10                YES - EXIT SUBROUTINE
*
         DROP  R8
         DROP  R9
**********************************************************************
*                                                                    *
*        This is the DCB OPEN exit - given control during OPEN       *
*        processing                                                  *
*        See DFSMS Using Data Sets - Chapter 31 for details          *
*                                                                    *
*        Registers at entry                                          *
*           0                                                        *
*           1      - low order 3 bytes --> DCB                       *
*           2-13   - Contents unchanged from execution of OPEN       *
*          14      - Return address                                  *
*          15      - Exit entry address                              *
*                                                                    *
*        Notes - No need to preserve 2-13                            *
*              - Must NOT use the savearea addressed by R13          *
*              - always entered in 24 bit amode                      *
*        No return codes required                                    *
*                                                                    *
**********************************************************************
Input_open_exit ds 0h
         push  using
         la    r1,0(,r1)          clean r1 address
         using ihadcb,r1            and address the DCB
         sam31                    flip to 31 bit amode
*
* check number of read buffers and set MULTACC if appropriate
*
         do ,
* If BUFNO not set in the JCL use PARMNBUF (UR20 parameter list)
* If PARMNBUF is 0 then use the MLTSDN option to calculate
* the DCBNCP value.
* If BUFNO is set in the JCL, remember the value and set BUFNO to 0.
* The buffers will be allocated later according to the value in
* DCBNCP, and because we allocate them later and not at OPEN time
* the buffers can be above the line.
*
           llc R15,DCBBUFNO       load bufno from DCB (in JCL)
           if ltr,R15,R15,np      "BUFNO" not in JCL ?
             USING PARMarea,R9    UR20 parameter area
             lh  r15,PARMnbuf     use value from caller
             drop r9
           endif
*
           if ltr,r15,r15,np      Any value passed in parms?
             l r10,wktokn+8        Get address of -> Mr95 parms
             l r10,0(,r10)         point at MR95 parms
             using execdata,r10
             PACK WORKDBL,EXECmsdn get the value for MULTSDN
             CVB R9,WORKDBL
             DROP R10
* Set MULTACC to half MULTSDN (use half of the buffers in each CP)
             L R2,DCBDCBE     LOAD  DCBE   ADDRESS
             USING DCBE,R2
             AHI R9,1             ROUND MULTSDN to MULTIPLE OF 2
             SRL R9,1
             STC R9,DCBEMACC      MULTACC =  1/2 multsdn
             SLL R9,1
             stc r9,dcbemsdn       set the sdn value
             DROP R2
             mvi dcbncp,x'00'     set NCP to zero and on return
           else
*
             if CHI,r15,lt,2      check for minimum ???
               LHI R15,2          NO  - USE    MINIMUM
             else
               if  CHI,R15,gt,5   CHECK THRESHOLD  FOR "MULTACC"
                 L R2,DCBDCBE     LOAD  DCBE   ADDRESS
                 USING DCBE,R2
                 AHI R15,1        ROUND TO MULTIPLE OF  2
                 SRL R15,1
                 STC R15,DCBEMACC MULTACC  =  1/2 BUFNO
                 SLL R15,1
                 if CHI,r15,gt,255      NCP can not be greater than 255
                   lhi r15,254
                   mvi dcbemacc,x'7F'
                 endif
                 DROP R2
               endif
             endif
             MVI DCBbufno,x'00'     let us allocate buffers later
             STC R15,DCBNCP         SET  "DCBNCP" OPTION
           endif
*
         enddo
         drop  r1
*
         sam24                    set amode back before return
         BR    R14
         pop   using
**********************************************************************
*                                                                    *
*        This is the DCB OPEN exit - given control during OPEN       *
*        processing                                                  *
*        See DFSMS Using Data Sets - Chapter 31 for details          *
*                                                                    *
*        Registers at entry                                          *
*           0                                                        *
*           1      - low order 3 bytes --> DCB                       *
*           2-13   - Contents unchanged from execution of OPEN       *
*          14      - Return address                                  *
*          15      - Exit entry address                              *
*                                                                    *
*        Notes - No need to preserve 2-13                            *
*              - Must NOT use the savearea addressed by R13          *
*              - always entered in 24 bit amode                      *
*        No return codes required                                    *
*                                                                    *
**********************************************************************
Output_open_exit ds 0h
         push  using
         la    r1,0(,r1)          clean r1 address
         using ihadcb,r1            and address the DCB
         sam31                    flip to 31 bit amode
*
* check number of write buffers and set MULTACC if appropriate
*
         do ,
* If BUFNO not set in the JCL use PARMNBUF (UR20 parameter list)
* If PARMNBUF is 0 then use the MULTSDN option to calculate
* the DCBNCP value.
* If BUFNO is set in the JCL, remember the value and set BUFNO to 0.
* The buffers will be allocated later according to the value in
* DCBNCP, and because we allocate them later and not at OPEN time
* the buffers can be above the line.
*
           llc R15,DCBBUFNO       load bufno from DCB (in JCL)
           if ltr,R15,R15,np      "BUFNO" not in JCL ?
             USING PARMarea,R9    UR20 parameter area
             lh  r15,PARMnbuf     use value from caller
             drop r9
           endif
*
           if ltr,r15,r15,np      Any value passed in parms?
             l r10,wktokn+8        Get address of -> Mr95 parms
             l r10,0(,r10)         point at MR95 parms
             using execdata,r10
             PACK WORKDBL,EXECmsdn get the value for MULTSDN
             CVB R9,WORKDBL
             DROP R10
* Set MULTACC to half MULTSDN (use half of the buffers in each CP)
             L R2,DCBDCBE     LOAD  DCBE   ADDRESS
             USING DCBE,R2
             AHI R9,1             ROUND MULTSDN to MULTIPLE OF 2
             SRL R9,1
             STC R9,DCBEMACC      MULTACC =  1/2 multsdn
             SLL R9,1
             stc r9,dcbemsdn       set the sdn value
             DROP R2
             mvi dcbncp,x'00'     set NCP to zero and on return
           else
*
             if CHI,r15,lt,2      check for minimum ???
               LHI R15,2          NO  - USE    MINIMUM
             else
               if  CHI,R15,gt,5   CHECK THRESHOLD  FOR "MULTACC"
                 L R2,DCBDCBE     LOAD  DCBE   ADDRESS
                 USING DCBE,R2
                 AHI R15,1        ROUND TO MULTIPLE OF  2
                 SRL R15,1
                 STC R15,DCBEMACC MULTACC  =  1/2 NCP
                 SLL R15,1
                 if CHI,r15,gt,255      NCP can not be greater than 255
                   lhi r15,254          set to even number
                   mvi dcbemacc,x'7F'   half of NCP
                 endif
                 DROP R2
               endif
             endif
             MVI DCBbufno,x'00'     let us allocate buffers later
             STC R15,DCBNCP         SET  "DCBNCP" OPTION
           endif
*
         enddo
         drop  r1
*
         sam24                    set amode back before return
         BR    R14
         pop   using
*
         DROP  R13
static   loctr  ,
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        C O N S T A N T S                                            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
         DS   0A
BRNCHTBLA dc a(brnchtbl)
*
mode31   equ   X'8000'
OPENPARM DC    XL8'8000000000000000'
*
H004     DC    H'004'
H007     DC    H'007'
H008     DC    H'008'
H012     DC    H'012'
*
P000     DC    PL1'0'
P001     DC    PL1'1'
*
gvbxrck  dc    cl8'GVBXRCK'
GENEVA   DC    CL8'GENEVA  '      MAJOR  ENQ NODE
PGMNAME  DC    CL8'GVBUR20 '      MINOR  ENQ NODE
ENQSTAT  DC    CL8'BUFSTATS'      MINOR  ENQ  NODE
*
FB       DC    C'FB'
FBA      DC    C'FBA'
FBS      DC    C'FBS'
VB       DC    C'VB'
VBA      DC    C'VBA'
VBS      DC    C'VBS'
*
wtKNLVL2 DC    A(2)               NAME/TOKEN  AVAILABILITY  LEVEL
wktoknam ds    0cl16
         DC    CL8'GENEVA'                  TOKEN  NAME
         DC    CL8'GLOBAL'
*
TRACEMSG DC    CL01' '            CARRIAGE CONTROL
         DC    CL31'READ COMPRESSED DATA FILE:  CC='
TRACECC  DC    CL04' '
         DC    CL05', HH='
TRACEHH  DC    CL02' '
         DC    CL04', R='
TRACER   DC    CL02' '
         DC    CL12', BLKS READ='
TRACEBLK DC    CL04' '
         DC    CL10', READING='
TRACECNT DC    CL04' '
         DC    CL54' '
                        SPACE 5
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        D A T A   C O N T R O L   B L O C K S                        *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
INFILE   DCB   DSORG=PS,DDNAME=INFILE,MACRF=(R),DCBE=INDCBE,           +
               EXLST=input_exit_list
INDCBE   DCBE  RMODE31=BUFF,BLOCKTOKENSIZE=LARGE
INDCBL   EQU   *-INFILE
input_exit_list dc 0f'0',al1(exllaste+exldcbex),AL3(input_open_exit)
                        SPACE 3
OUTFILE  DCB   DSORG=PS,DDNAME=OUTFILE,MACRF=(W),DCBE=OUTDCBE,         +
               EXLST=output_exit_list
output_exit_list dc 0f'0',al1(exllaste+exldcbex),AL3(output_open_exit)
OUTDCBE  DCBE  RMODE31=BUFF,BLOCKTOKENSIZE=LARGE
OUTDCBL  EQU   *-OUTFILE
                        SPACE 3
MDLREAD  READ  READECB,SF,INFILE,0,0,MF=L
MDLREADP DC    AL4(0)
MDLREADL EQU   *-MDLREAD
                        SPACE 3
MDLWRT   WRITE WRITECB,SF,OUTFILE,0,0,MF=L
MDLWRTL  EQU   *-MDLWRT
                        SPACE 5
         LTORG
*
         PRINT NOGEN
         ihasaver
         DCBD  DSORG=PS
                        SPACE 3
         IHADCBE
                        SPACE 3
         IHAEXLST ,     DCB exit list mapping
                        SPACE 3
         PRINT GEN
*
         END
