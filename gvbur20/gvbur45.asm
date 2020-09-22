         TITLE 'GVBUR45 - LOAD AND SEARCH LARGE TABLES'
*
* (c) Copyright IBM Corporation 2008.  
*     Copyright Contributors to the GenevaERS Project.
* SPDX-License-Identifier: Apache-2.0
*
***********************************************************************
*                                                                           
*   Licensed under the Apache License, Version 2.0 (the "License");         
*   you may not use this file except in compliance with the License.        
*   You may obtain a copy of the License at                                 
*                                                                           
*     http://www.apache.org/licenses/LICENSE-2.0                            
*                                                                           
*   Unless required by applicable law or agreed to in writing, software     
*   distributed under the License is distributed on an "AS IS" BASIS,       
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express 
*   or implied.
*   See the License for the specific language governing permissions and     
*   limitations under the License.                                          
***********************************************************************         
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*  GVBUR45 - INITIALIZES MEMORY RESIDENT LOOK-UP TABLES USING         *
*            INFORMATION FROM TWO SEQUENTIAL FILES.                   *
*                                                                     *
*                1) THE HEADER FILE WHICH CONTAINS PROPERTIES AND     *
*                   CONTROL TOTALS FOR EACH OF THE LOOK-UP TABLES     *
*                2) THE DATA FILE WHICH CONTAINS THE ACTUAL DATA ROWS *
*                   IN EACH OF THE TABLES                             *
*                                                                     *
*        - SEARCHES TABLES FOR A MATCH ON SUPPLIED KEY                *
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
*            - INTERNAL  SUBROUTINE  RETURN ADDRESS (3RD LEVEL)       *
*            - RETURN    ADDR                                         *
*                                                                     *
*        R13 - REGISTER  SAVE  AREA  ADDRESS                          *
*                                                                     *
*        R12 - PARAMETER LIST  BASE  REGISTER                         *
*                                                                     *
*        R11 - PROGRAM   BASE  REGISTER                               *
*                                                                     *
*        R10 - INTERNAL  SUBROUTINE  RETURN ADDRESS                   *
*            - TABLE  KEY    OFFSET                                   *
*                                                                     *
*        R9  - TABLE  KEY   ADDRESS                                   *
*        R8  - TABLE  DATA   RECORD ADDRESS                           *
*                                                                     *
*        R7  - SEARCH KEY   ADDRESS                                   *
*        R6  - RECORD BUFFER PREFIX ADDRESS                           *
*                                                                     *
*        R5  - SEARCH KEY    LENGTH                                   *
*                                                                     *
*        R4  - WORK      REGISTER                                     *
*            - BINARY    SEARCH  TOP        INDEX                     *
*            - PREVIOUS  RECORD  BUFFER     ADDRESS                   *
*                                                                     *
*        R3  - WORK      REGISTER                                     *
*            - BINARY    SEARCH  BOT        INDEX                     *
*            - CURRENT   RECORD  BUFFER     LENGTH                    *
*                                                                     *
*        R2  - DCB       ADDRESS                                      *
*                                                                     *
*        R1  - PARAMETER LIST ADDRESS                                 *
*            - TEMPORARY WORK REGISTER                                *
*                                                                     *
*        R0  - TEMPORARY WORK REGISTER                                *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #LB
*                 C H A N G E   C O N T R O L   L O G                 *
*                                                                     *
* --DATE--  --SR#--  PGMR  -----COMMENTS--------                      *
*                                                                     *
* 20100921  CQ8614   QHL   ADDED EYECATCHER TO CODE                   *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * #LE
                        EJECT
WORKAREA DSECT
*
SAVEAREA DS  18F
*
HDRGETA  DS    A                  READ SUBROUTINE  ADDRESS
DATAGETA DS    A                  READ SUBROUTINE  ADDRESS
*
PREVNODE DS    A                  PREVIOUS LOOK-UP ROW ADDRESS
*
RBCHAIN  DS   0XL6                THESE  THREE  LINES
         DS    HL2                MUST  REMAIN  TOGETHER
         DS    AL4                TO MATCH THE  BUFFER PREFIX
*
DBLWORK  DS    D                  DOUBLE  WORD WORK AREA
PACKAREA DS    XL16               PACKED  DATA WORK AREA
*
PREVKEY  DS   0XL128              PREVIOUS KEY VALUE
RENTPARM DS    XL128              RE-ENTRANT   PARAMETER  LIST   AREA
*
HDRDCB   DS    (HDRDCBL)C         HEADER  FILE DCB
*
DATADCB  DS    (DATADCBL)C        DATA    FILE DCB
*
TOKNRTNC DS    A                  NAME/TOKEN   SERVICES RETURN   CODE
TOKEN    DS    XL16               NAME/TOKEN
*
INITDONE DS    C                  INITIALIZATION    DONE  FLAG
*
WORKLEN  EQU   *-WORKAREA
                        SPACE 5
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        P A R A M E T E R   L I S T   D E F I N I T I O N            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
PARMLIST DSECT
*
FUNCADDR DS    A               FUNCTION CODE ADDRESS
TABLADDR DS    A               TABLE    NAME ADDRESS
KEYADDR  DS    A               SEARCH   KEY  ADDRESS
RECADDR  DS    A               RECORD   PTR  ADDRESS
RTNCADDR DS    A               RETURN   CODE ADDRESS
WORKADDR DS    A               WORK     AREA ADDRESS
*
PARMLEN  EQU   *-PARMLIST
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        RECORD BUFFER AREA DEFINITION                                *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
RECBUFR  DSECT                 RECORD  BUFFER AREA PREFIX
*
RBLEN    DS    HL02            BUFFER  LENGTH
RBNEXT   DS    AL04            NEXT    BUFFER POINTER (0 = END-OF-LIST)
*
RBTABLID DS    CL08            TABLE   NAME
RBRECID  DS    CL04            LOGICAL RECORD     ID
RBKEYOFF DS    HL02            LOGICAL RECORD KEY OFFSET
RBKEYLEN DS    HL02            LOGICAL RECORD KEY LENGTH
RBRECLEN DS    HL02            MEMORY  RESIDENT   TABLE  ROW   LENGTH
RBSUBWRK DS   0AL04            CALLED  SUBROUTINE WORK   AREA
RBRECCNT DS    FL04            MEMORY  RESIDENT   TABLE  ROW   COUNT
RBSUBRNM DS   0CL08            CALLED  SUBROUTINE NAME
RBTBLBEG DS    AL04            MEMORY  RESIDENT   TABLE  BEGIN ADDRESS
RBTBLEND DS    AL04            MEMORY  RESIDENT   TABLE  END   ADDRESS
RBMIDDLE DS   0AL04            ADDRESS OF MIDDLE  ROW
RBSUBRAD DS    AL04            CALLED  SUBROUTINE ADDRESS
RBLSTFND DS    AL04            ADDRESS OF LAST    ENTRY  FOUND
RBRECFND DS    FL04            RECORDS      FOUND
RBRECNOT DS    FL04            RECORDS NOT  FOUND
RBEFFOFF DS    HL02            OFFSET  OF EFFECTIVE DATE
RBFLAGS  DS    XL02            PROCESSING   FLAGS
RBMEMRES EQU   X'80'           ....1000 0000  MEMORY  RESIDENT TABLE
RBEFFDAT EQU   X'40'           ....0100 0000  EFFECTIVE  DATES PRESENT
RBDSAMRD EQU   X'20'           ....0010 0000  DIRECT  READS TO DSAM
RBSUBPGM EQU   X'10'           ....0001 0000  SUBROUTINE  CALL
RBDATA   DS   0CL01            LOGICAL RECORD DATA (OPTIONAL)
*
RBPREFLN EQU   *-RECBUFR       RECORD  BUFFER AREA PREFIX LENGTH
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        LOOK-UP TABLE DATA HEADER RECORD DEFINITION                  *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
TBLHEADR DSECT                 TABLE   DATA   HEADER RECORD
*
TBTABLID DS    CL08            TABLE   NAME
TBRECID  DS    CL04            LOGICAL RECORD ID
TBRECCNT DS    FL04            RECORD  COUNT
TBRECLEN DS    HL02            RECORD  LENGTH
TBKEYOFF DS    HL02            KEY     OFFSET
TBKEYLEN DS    HL02            KEY     LENGTH
TBDSAMRD DS    CL01            BUILD   DSAM    REFERENCE FILE
TBEFFDAT DS    CL01            EFFECTIVE DATES PRESENT
TBABOVET DS    FL04            RECORD  COUNT  (MEM RES, REF>THRESHOLD)
TBBELOWT DS    FL04            RECORD  COUNT  (MEM RES, REF<THRESHOLD)
*
TBHDRLEN EQU   *-TBLHEADR      TABLE   HEADER  LENGTH
                        SPACE 5
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        LOOK-UP TABLE ENTRY DEFINITION                               *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
LKUPTBL  DSECT                 LOOK-UP TABLE  ENTRY DEFINITION
*
LKLOWENT DS    AL04            LOW  VALUE ROW ADDRESS
LKHIENT  DS    AL04            HIGH VALUE ROW ADDRESS
LKUPDATA DS   0CL01
*
LKPREFLN EQU   *-LKUPTBL       LOOK-UP TABLE  ENTRY PREFIX LENGTH
                        SPACE 5
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        S H A R E D   T A B L E   T O K E N   D E F I N I T I O N    *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
TOKENDEF DSECT                 SHARED  TABLE  TOKEN   AREA  DEFINITION
*
TKLKUPTB DS    A               FIRST   LOOKUP TABLE   CHAIN ENTRY ADDR
         DS    XL12            UNUSED
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
                        SPACE 3
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        REGISTER SAVE AREA OFFSETS:                                  *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
RSABP    EQU   4
RSAFP    EQU   8
RSA14    EQU   12
RSA15    EQU   16
RSA0     EQU   20
RSA1     EQU   24
                        SPACE 3
MSG01    EQU   01              UNDEFINED FUNCTION     CODE
MSG02    EQU   02              UNABLE TO OPEN    DATA HEADER    FILE
MSG03    EQU   03              UNABLE TO OPEN    DATA           FILE
MSG04    EQU   04              DUPLICATE TABLE   NAME IN HEADER FILE
MSG05    EQU   05              NOT FOUND - TABLE NAME MISMATCH
MSG06    EQU   06              NOT FOUND - KEY        MISMATCH
MSG07    EQU   07              NOT FOUND - BUILDING   PATH
MSG08    EQU   08              NOT FOUND - GET   NEXT
MSG09    EQU   09              INITIALIZATION ALREADY COMPLETED
MSG10    EQU   10              INITIALIZATION  "ENQ"  FAILED
MSG11    EQU   11              MISSING LOOK-UP CHAIN  ANCHOR
MSG12    EQU   12              DUPLICATE TABLE NAME - COPY
MSG13    EQU   13              NAME TOKEN CREATE FAILED
MSG14    EQU   14              WRONG RECORD   COUNT  IN HEADER
MSG15    EQU   15              TABLE KEYS NOT ASCENDING UNIQUE
*
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
* 1. SAVE  CALLING PROGRAM'S   REGISTER CONTENTS                      *
* 2. CHAIN REGISTER SAVE AREAS TOGETHER                               *
* 3. BRANCH TO THE APPROPRIATE CODE BASED ON THE FUNCTION CODE PARM   *
* 4. RESTORE CALLER'S REGISTER CONTENTS  AND RETURN  WHEN DONE        *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
         PRINT NOGEN
*
GVBUR45  RMODE ANY
GVBUR45  AMODE 31
*
GVBUR45  CSECT
         J     CODE
UR45EYE  GVBEYE GVBUR45
*
CODE     STM   R14,R12,RSA14(R13) SAVE CALLER'S   REGISTERS
*
         LR    R11,R15            SET  PROGRAM    BASE REGISTER
         USING GVBUR45,R11
*
         LR    R12,R1             LOAD PARAMETER  LIST ADDRESS
         USING PARMLIST,R12
*
         LR    R9,R13             SAVE  CALLER'S  RSA     ADDRESS
         L     R10,WORKADDR       LOAD  WORK AREA POINTER ADDRESS
         L     R13,0(,R10)        LOAD  POINTER   VALUE
         USING WORKAREA,R13
         LTR   R13,R13            ALLOCATED  ???
         BP    CHAIN              YES - BYPASS ALLOCATION
*
         LA    R0,WORKLEN+8       LOAD  WORK AREA SIZE  (+ EYEBALL)
         GETMAIN R,LV=(0)
         MVC   0(8,R1),EYEBALL
         LA    R13,8(,R1)
         ST    R13,0(,R10)        SAVE  WORK AREA ADDRESS (POINTER)
*
         LR    R0,R13             ZERO  WORK AREA
         LA    R1,WORKLEN
         SR    R14,R14
         SR    R15,R15
         MVCL  R0,R14
*
CHAIN    ST    R13,RSAFP(,R9)     SET   FORWARD  POINTER IN OLD
         ST    R9,RSABP(,R13)     SET   BACKWARD POINTER IN NEW
*
         L     R1,FUNCADDR        LOAD  ADDRESS OF FUNCTION CODE
         CLI   0(R1),C'S'         SEARCH TABLES ???
         BE    SRCHTBL            YES -  SEARCH MEMORY  RESIDENT TABLES
*
         CLI   0(R1),C'N'         GET    NEXT    ???
         BE    NEXTTBL            YES -  ADVANCE  TO NEXT ROW
*
         LA    R15,MSG01          BAD  FUNCTION CODE
         CLI   0(R1),C'I'         INITIALIZE  TABLES ???
         BNE   RETURNE            NO  - INDICATE BAD FUNCTION CODE
*
         LA    R15,MSG09          ASSUME ALREADY DONE
         CLI   INITDONE,C'Y'      INITIALIZATION ALREADY DONE ???
         BE    RETURNE
*
         B     FILLLKUP           FILL LOOK-UP   TABLES
                        SPACE 3
RETURN   SR    R15,R15            SET  RETURN CODE  TO ZERO
*
RETURNE  L     R1,RTNCADDR        LOAD RETURN CODE  ADDRESS
         STH   R15,0(,R1)         PASS RETURN CODE  TO CALLER
*
         L     R13,RSABP(,R13)    RESTORE REGISTER  R13
         L     R14,RSA14(,R13)    RESTORE REGISTER  R14
         LM    R0,R12,RSA0(R13)   RESTORE REGISTERS R0 - R12
         BR    R14                RETURN
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        T A B L E   L O O K U P                                      *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
SRCHTBL  L     R1,TABLADDR        POINT  TO  TABLE ID
         BAS   R10,LOCRB          LOCATE MATCHING  RECORD BUFFER
         USING RECBUFR,R6
*
         LTR   R6,R6              BUFFER FOUND (ALREADY ALLOCATED) ???
         BP    SRCHKEY            YES -  CONTINUE
         LA    R15,MSG05          NO  -  TABLE  NOT     FOUND
         B     RETURNE
*
SRCHKEY  L     R7,KEYADDR         LOAD  ADDRESS OF SEARCH KEY
*
         LH    R5,RBKEYLEN        LOAD  KEY  LENGTH (-1)
         LH    R10,RBKEYOFF       LOAD  KEY  OFFSET
*
         L     R4,RBMIDDLE        LOAD ADDRESS  OF MIDDLE ENTRY
         USING LKUPTBL,R4
                        SPACE 3
SRCHLOOP LR    R3,R4              SAVE    LAST  ENTRY EXAMINED
*
         LA    R9,LKUPDATA(R10)   LOAD    TABLE KEY   ADDRESS
         EX    R5,SRCHCOMP        COMPARE KEYS  ???
         BL    SRCHTOP
         BH    SRCHBOT
*
SRCHFND  LA    R14,LKUPDATA       LOAD ADDRESS  OF DATA
         ST    R14,RBLSTFND       SAVE ADDRESS  IN BUFFER  PREFIX
         L     R1,RECADDR         LOAD RECORD   PARAMETER  ADDRESS
         ST    R14,0(,R1)         PASS ADDRESS  TO CALLER
*
         L     R15,RBRECFND       INCREMENT FOUND  COUNT
         LA    R15,1(,R15)
         ST    R15,RBRECFND
*
         B     RETURN             RETURN  TO  FOUND ADDRESS
                        SPACE 3
SRCHTOP  L     R4,LKLOWENT        LOAD ADDRESS   OF LOWER  VALUE NODE
         LTR   R4,R4              FURTHER SEARCHING POSSIBLE ???
         BP    SRCHLOOP           YES - CONTINUE
         B     SRCHCHK            NO  - CHECK FOR EFFECTIVE DATE
*
SRCHBOT  L     R4,LKHIENT         LOAD ADDRESS   OF HIGHER VALUE NODE
         LTR   R4,R4              FURTHER SEARCHING POSSIBLE ???
         BP    SRCHLOOP           YES - CONTINUE
                        EJECT
SRCHCHK  TM    RBFLAGS,RBEFFDAT   EFFECTIVE DATES IN TABLE ???
         BNO   SRCHNOT            NO  -  RECORD  NOT FOUND
*
         LR    R14,R7             LOCATE EFFECTIVE DATE WITHIN KEY
         AH    R14,RBEFFOFF
         CLC   0(4,R14),ZEROES    EFFECTIVE DATE PRESENT IN KEY ???
         BE    SRCHNOT            NO  - EXACT MATCH WAS  REQUIRED
*
         LR    R1,R5              CALC KEY LENGTH EXCLUDING DATE (-1)
         S     R1,F4
*
         LR    R4,R3              RECHECK LAST ENTRY EXAMINED
         LA    R9,LKUPDATA(R10)   LOAD    TABLE  KEY ADDRESS
         EX    R5,SRCHCOMP
         BH    SRCHHIGH
                        SPACE 3
SRCHLOW  LA    R0,LKPREFLN        LOAD LENGTH OF EACH TABLE ENTRY
         AH    R0,RBRECLEN
*
         L     R14,RBTBLBEG       LOAD BEGINNING ADDRESS OF TABLE
*
         SR    R4,R0
         CR    R4,R14             CHECK FOR BEGINNING OF TABLE   ???
         BL    SRCHNOT            EXIT  IF  NO PREVIOUS  ENTRY
*
         LA    R9,LKUPDATA(R10)   LOAD  TABLE KEY ADDRESS
         EX    R1,SRCHCOMP        SAME  ROOT  KEY EXCLUDING DATE ???
         BE    SRCHEND            YES - CORRECT  ENTRY FOUND
         B     SRCHNOT            NO  - ENTRY WITH OKAY DATE NOT FOUND
                        SPACE 3
SRCHHIGH EX    R1,SRCHCOMP        SAME  ROOT KEY EXCLUDING DATE ???
         BNE   SRCHNOT            NO  - NOT  FOUND
*
SRCHEND  LA    R14,LKUPDATA+1(R10) LOAD DATA ADDRESS (FOLLOWS KEY)
         AH    R14,RBKEYLEN           (ADJUST ABOVE FOR KEYLEN -1)
*
         LR    R1,R7              LOCATE EFFECTIVE DATE WITHIN KEY
         AH    R1,RBEFFOFF
*
         CLC   0(4,R1),0(R14)     EFFECTIVE DATE EXCEEDS END  DATE ???
         BNH   SRCHFND            NO  - ENTRY FOUND
*
SRCHNOT  L     R15,RBRECNOT       INCREMENT NOT  FOUND COUNT
         LA    R15,1(,R15)
         ST    R15,RBRECNOT
*
         SR    R14,R14            SET TABLE ENTRY ADDRESS  TO HIGH VAL
         BCTR  R14,0
         ST    R14,RBLSTFND       SAVE ADDRESS
         L     R1,RECADDR         LOAD RECORD   PARAMETER  ADDRESS
         ST    R14,0(,R1)         PASS ADDRESS  TO CALLER
*
         LA    R15,MSG06          NOT  FOUND RETURN CODE
         B     RETURNE            RETURN TO NOT FOUND ADDRESS
*
SRCHCOMP CLC   0(0,R7),0(R9)      * * * * *   E X E C U T E D   * * * *
         DROP  R4
         DROP  R6
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        G E T   N E X T   T A B L E   E N T R Y                      *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
NEXTTBL  L     R1,TABLADDR        POINT  TO  TABLE ID
         BAS   R10,LOCRB          LOCATE MATCHING  RECORD BUFFER
         USING RECBUFR,R6
*
         LTR   R6,R6              BUFFER FOUND (ALREADY ALLOCATED) ???
         BP    NEXTLAST           YES -  CONTINUE
         LA    R15,MSG05          NO  -  TABLE NOT  FOUND
         B     RETURNE
*
NEXTLAST L     R4,RBLSTFND        LOAD ADDRESS  OF MIDDLE ENTRY
         LTR   R4,R4              PREVIOUS  SEARCH FOUND
         BNP   NEXTNOT
         AH    R4,RBRECLEN
         USING LKUPTBL,R4
         C     R4,RBTBLEND        LAST TABLE ENTRY ???
         BNL   NEXTNOT
*
NEXTFND  LA    R14,LKUPDATA       LOAD ADDRESS  OF DATA
         ST    R14,RBLSTFND       SAVE ADDRESS  IN BUFFER  PREFIX
         L     R1,RECADDR         LOAD RECORD   PARAMETER  ADDRESS
         ST    R14,0(,R1)         PASS ADDRESS  TO CALLER
*
         L     R15,RBRECFND       INCREMENT FOUND  COUNT
         LA    R15,1(,R15)
         ST    R15,RBRECFND
*
         B     RETURN             RETURN  TO  FOUND ADDRESS
*
NEXTNOT  L     R15,RBRECNOT       INCREMENT NOT FOUND  COUNT
         LA    R15,1(,R15)
         ST    R15,RBRECNOT
*
         SR    R14,R14            SET TABLE ENTRY ADDRESS  TO HIGH VAL
         BCTR  R14,0
         ST    R14,RBLSTFND       SAVE ADDRESS
         L     R1,RECADDR         LOAD RECORD   PARAMETER  ADDRESS
         ST    R14,0(,R1)         PASS ADDRESS  TO CALLER
*
         LA    R15,MSG08          NOT  FOUND RETURN CODE
         B     RETURNE            RETURN TO NOT FOUND ADDRESS
*
         DROP  R4
         DROP  R6
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        F I L L   M E M O R Y   R E S I D E N T   T A B L E S        *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
FILLLKUP ENQ   (PGMNAME,INITNAME,E,,STEP),RNL=NO,MF=(E,RENTPARM)
         LTR   R15,R15            SUCCESSFUL  ???
         LA    R15,MSG10          ASSUME UNSUCCESSFUL (CC NOT CHANGED)
         BNZ   RETURNE            NO  -  ASSUMPTION  CORRECT (ERROR)
*
         CALL  IEANTRT,(TOKNLVL,TOKNNAME,TOKEN,TOKNRTNC),              X
               MF=(E,RENTPARM)
         L     R15,TOKNRTNC       TOKEN SUCCESSFULLY LOCATED  ???
         LTR   R15,R15
         BNZ   TOKNNEW            NO  - LOAD AND INITIALIZE LOOKUP TBL
*
         LA    R1,TOKEN           LOAD TOKEN ADDRESS
         USING TOKENDEF,R1
*
         L     R7,TKLKUPTB        LOCATE FIRST  LOOKUP BUFFER
         LTR   R7,R7              BUFFER AVAILABLE ???
         BP    TOKNLOOP           YES -  CONTINUE
         LA    R15,MSG11          NO  -  ERROR (NOT AVAILABLE)
         B     RETURNE
         DROP  R1
*
TOKNLOOP LA    R1,RBTABLID-RECBUFR(,R7)  POINT  TO TABLE   NAME
         BAS   R10,LOCRB          LOCATE TABLE  IN CURRENT THREAD
         LTR   R6,R6              BUFFER FOUND ???
         BNP   TOKNALLO           NO  -  CONTINUE
         LA    R15,MSG12          YES -  INDICATE  DUPLICATE
         B     RETURNE
*
TOKNALLO LH    R3,RBLEN-RECBUFR(,R7)  LOAD BUFFER  LENGTH
*
         LA    R1,RBTABLID-RECBUFR(,R7)    POINT   TO  TABLE   NAME
         BAS   R10,ALLOCATE
         USING RECBUFR,R6
*
         LA    R0,L'RBCHAIN       LOAD   LENGTH OF CHAIN POINTER
         SR    R3,R0              EXCLUDE CHAIN POINTER  FROM COPY
*
         LA    R0,L'RBCHAIN(,R6)  LOAD "TO"   ADDRESS
         LR    R1,R3              LOAD "TO"   LENGTH
         LR    R15,R3             LOAD "FROM" LENGTH
         LA    R14,L'RBCHAIN(,R7)      "FROM" ADDRESS
         MVCL  R0,R14             COPY  THE   LOOKUP BUFFER
*
         L     R7,RBNEXT-RECBUFR(,R7)   LOAD  NEXT   BUFFER  ADDRESS
         LTR   R7,R7                    END-OF-CHAIN ???
         BP    TOKNLOOP                 NO  - LOOP  THROUGH  CHAIN
                        SPACE 3
         DEQ   (PGMNAME,INITNAME,,STEP),RNL=NO,MF=(E,RENTPARM)
*
         B     RETURN             RETURN
*
         DROP  R6
                        EJECT
***********************************************************************
*  PERFORM FIRSTTIME INITIALIZATION (LOAD TABLES/GET CONTROL BLOCKS)  *
***********************************************************************
TOKNNEW  MVC   HDRDCB(HDRDCBL),HDRFILE   OPEN HEADER FILE
         MVC   RENTPARM(8),OPENPARM
         OPEN  (HDRDCB,(INPUT)),MODE=31,MF=(E,RENTPARM)
         LA    R15,MSG02                 ASSUME OPEN FAILED
         TM    HDRDCB+48,X'10'           OPEN SUCCESSFUL ???
         BNO   RETURNE                   NO - INDICATE ERROR
         MVC   HDRGETA+1(3),HDRDCB+(DCBGETA-IHADCB)    SAVE SUBR ADDR
*
         MVC   DATADCB(DATADCBL),DATAFILE   OPEN  DATA FILE
         MVC   RENTPARM(8),OPENPARM
         OPEN  (DATADCB,(INPUT)),MODE=31,MF=(E,RENTPARM)
         LA    R15,MSG03                 ASSUME OPEN FAILED
         TM    DATADCB+48,X'10'          OPEN SUCCESSFUL ???
         BNO   RETURNE                   NO - INDICATE ERROR
         MVC   DATAGETA+1(3),DATADCB+(DCBGETA-IHADCB)  SAVE SUBR ADDR
*
         MVI   INITDONE,C'Y'
*
FILLHDR  LA    R1,HDRDCB          LOAD HEADER TABLE DATA FILE DCB ADDR
         L     R15,HDRGETA        READ HEADER RECORD
         BASR  R14,R15
         LR    R7,R1              LOAD RECORD ADDRESS
         USING TBLHEADR,R7
*
         L     R5,TBRECCNT        LOAD RECORD COUNT
         LTR   R5,R5              ANY  DATA   RECORDS     ???
         BNP   FILLHDR            NO - ADVANCE  TO NEXT   HEADER
*
         LA    R1,TBTABLID        POINT  TO  TABLE ID
         BAS   R10,LOCRB          LOCATE MATCHING  RECORD BUFFER
         USING RECBUFR,R6
*
         LTR   R6,R6              BUFFER FOUND (ALREADY ALLOCATED) ???
         BNP   FILLALLO           NO  -  ALLOCATE  BUFFER
         LA    R15,MSG04          YES -  INDICATE  ERROR
         B     RETURNE
*
FILLALLO LH    R3,TBRECLEN        LOAD RECORD LENGTH
         LA    R3,RBPREFLN(,R3)   ADD  PREFIX LENGTH
*
         LA    R1,TBTABLID        POINT TO  TABLE
         BAS   R10,ALLOCATE       ALLOCATE  RECORD BUFFER
         USING RECBUFR,R6
*
         OI    RBFLAGS,RBMEMRES   TURN  ON  MEMORY RESIDENT FLAG
*
         ST    R5,RBRECCNT        SAVE  THE RECORD COUNT
*
         LH    R15,TBKEYOFF       LOAD  KEY   OFFSET
         STH   R15,RBKEYOFF
         LH    R15,TBKEYLEN       LOAD  KEY   LENGTH
         BCTR  R15,0              DECREMENT   FOR  "EX"  INSTRUCTION
         STH   R15,RBKEYLEN
*
         CLI   TBEFFDAT,C'Y'      EFFECTIVE DATES PRESENT ???
         BNE   FILLGETM           NO  - BYPASS FLAG SETTING
         LH    R15,TBKEYLEN       LOAD  KEY   LENGTH
         S     R15,F4             COMPUTE EFFECTIVE DATE OFFSET
         STH   R15,RBEFFOFF
         OI    RBFLAGS,RBEFFDAT
                        EJECT
FILLGETM LH    R4,TBRECLEN        LOAD RECORD LENGTH
         STH   R4,RBRECLEN
         LA    R3,LKPREFLN(,R4)   ADD  PREFIX LENGTH
         MR    R2,R5              COMPUTE TABLE SIZE
*
         LR    R0,R3              LOAD SIZE  OF CURRENT  AREA
         GETMAIN RU,LV=(0),LOC=(ANY)
         ST    R1,RBTBLBEG        SAVE    TABLE STARTING ADDRESS
         AR    R3,R1              COMPUTE TABLE ENDING   ADDRESS
         ST    R3,RBTBLEND        SAVE    TABLE ENDING   ADDRESS
*
         LR    R2,R1              POINT TO FIRST ENTRY
         USING LKUPTBL,R2
*
         XC    PREVKEY,PREVKEY    RESET PREVIOUS KEY     VALUE
                        SPACE 3
FILLLOOP LA    R1,DATADCB         LOAD  TABLE DATA  FILE DCB ADDRESS
         L     R15,DATAGETA       READ  NEXT  RECORD
         BASR  R14,R15
         LR    R8,R1
         LA    R15,MSG14          ASSUME   MISMATCH
         CLC   TBTABLID,4+1(R8)   MATCHING TABLE ID  ???
         BNE   RETURNE            NO  - RECORD COUNT WRONG
*
FILLMOVE XC    LKLOWENT,LKLOWENT  ZERO BINARY SEARCH PATHS
         XC    LKHIENT,LKHIENT
*
         LA    R14,4+1+8(,R8)     COPY RECORD INTO TABLE (RDW + LOC +)
         LR    R15,R4
         LR    R3,R4
         LA    R2,LKUPDATA
         LR    R1,R2              SAVE RECORD ADDRESS
         MVCL  R2,R14             NOTE: R2 IS ADVANCED BY "MVCL"
*
         AH    R1,RBKEYOFF        ADVANCE TO  BEGINNING OF KEY
         LH    R14,RBKEYLEN       LOAD   KEY  LENGTH   (-1)
         LA    R15,MSG15          ASSUME KEYS OUT OF  SEQUENCE
         EX    R14,ASCENDKY       ASCENDING   KEY VALUES   ???
         BNH   RETURNE
         EX    R14,KEYSAVE
*
         BCT   R5,FILLLOOP        LOOP  UNTIL "RECCNT" RECORDS LOADED
*
         B     BLDPATH            BUILD BINARY SEARCH  PATHS
*
ASCENDKY CLC   0(0,R1),PREVKEY    * * * *  E X E C U T E D  * * * *
KEYSAVE  MVC   PREVKEY(0),0(R1)   * * * *  E X E C U T E D  * * * *
                        SPACE 3
DATAEOF  MVC   RENTPARM(8),OPENPARM
         CLOSE (HDRDCB),MODE=31,MF=(E,RENTPARM)
         CLOSE (DATADCB),MODE=31,MF=(E,RENTPARM)
*
         LA    R15,MSG14          HEADER RECORD COUNT  INCORRECT
         B     RETURNE
                        SPACE 3
FILLEOF  MVC   RENTPARM(8),OPENPARM
         CLOSE (HDRDCB),MODE=31,MF=(E,RENTPARM)
         CLOSE (DATADCB),MODE=31,MF=(E,RENTPARM)
                        SPACE 3
***********************************************************************
*  CREATE NAMED TOKEN FOR LOCATING SHARED TABLES                      *
***********************************************************************
TOKNSAV  LA    R1,TOKEN           LOAD TOKEN ADDRESS
         USING TOKENDEF,R1
*
         L     R0,RBCHAIN+(RBNEXT-RECBUFR) SAVE FIRST LOOK-UP TABLE ADR
         ST    R0,TKLKUPTB
         DROP  R1
*
         CALL  IEANTCR,(TOKNLVL,TOKNNAME,TOKEN,TOKNPERS,TOKNRTNC),     X
               MF=(E,RENTPARM)
         L     R15,TOKNRTNC       SUCCESSFUL ???
         LTR   R15,R15
         BZ    TOKNDEQ            YES - CONTINUE
         LA    R15,MSG13          NO  - INDICATE  ERROR
         B     RETURNE
*
TOKNDEQ  DEQ   (PGMNAME,INITNAME,,STEP),RNL=NO,MF=(E,RENTPARM)
*
         B     RETURN             RETURN
*
         DROP  R2
         DROP  R7
                        EJECT
BLDPATH  L     R2,RBTBLBEG        INITIALIZE FIRST TABLE ENTRY ADDRESS
         L     R7,RBRECCNT        INITIALIZE LOOP  COUNTER
*
         LH    R5,RBKEYLEN        LOAD   KEY LENGTH (-1)
*
         LA    R0,LKPREFLN        LOAD TABLE ENTRY LENGTH
         AH    R0,RBRECLEN
                        SPACE 3
BLDSRCH  L     R4,RBRECCNT        INITIALIZE TOP   OCCURRENCE NUMBER
         BCTR  R4,0               CHANGE (1:N) SCALE TO (0:N-1)
*
         SR    R3,R3              INITIALIZE BOTTOM OCCURRENCE NUMBER
*
         XC    PREVNODE,PREVNODE  INITIALIZE PREVIOUS NODE ADDRESS
*
         LA    R14,0(R3,R4)       COMPUTE MIDDLE OCCURRENCE NUMBER
         SRL   R14,1
         LR    R15,R0             COMPUTE ADDRESS OF MIDDLE ENTRY
         MR    R14,R14
         A     R15,RBTBLBEG
         ST    R15,RBMIDDLE       SAVE    ADDRESS OF MIDDLE ENTRY
                        SPACE 3
BLDLOOP  LA    R1,0(R3,R4)        COMPUTE MIDDLE OCCURRENCE NUMBER
         SRL   R1,1
*
         LR    R15,R0             COMPUTE ADDRESS OF MIDDLE ENTRY
         MR    R14,R1
         A     R15,RBTBLBEG
         USING LKUPTBL,R15
*
         L     R14,PREVNODE       SET BINARY SEARCH BRANCH  NODE
         LTR   R14,R14
         BNP   *+8
         ST    R15,0(0,R14)
*
         EX    R5,BLDKEY          COMPARE KEYS  ???
         BL    BLDTOP
         BH    BLDBOT
*
BLDMATCH AR    R2,R0              ADVANCE TO NEXT   TABLE   ENTRY
*
         BCT   R7,BLDSRCH         LOOP UNTIL ALL    ENTRIES FOUND
*
         B     FILLHDR            BRANCH AND LOAD NEXT TABLE
                        EJECT
BLDTOP   LA    R14,LKLOWENT       SAVE PREVIOUS PATH ADDRESS
         ST    R14,PREVNODE
*
         LR    R4,R1              SET TOP    = CURRENT - 1
         BCTR  R4,0
         CR    R3,R4              BOTTOM  > TOP    ???
         BNH   BLDLOOP            NO  - CONTINUE
         B     BLDNOMAT           YES - EXIT
*
BLDBOT   LA    R14,LKHIENT        SAVE PREVIOUS PATH ADDRESS
         ST    R14,PREVNODE
*
         LR    R3,R1              SET BOTTOM = CURRENT + 1
         LA    R3,1(,R3)
         CR    R3,R4              BOTTOM  > TOP    ???
         BNH   BLDLOOP            NO  - CONTINUE
*
BLDNOMAT LA    R15,MSG07          SHOULD NEVER GET NOT FOUND
         B     RETURNE            BRANCH AND  INDICATE ERROR
*
BLDKEY   CLC   LKPREFLN(0,R2),LKUPDATA * * *  E X E C U T E D   * * * *
*
         DROP  R6
         DROP  R15
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
* "ALLOCATE" - ALLOCATES MEMORY DYNAMICALLY FOR NEW LOGICAL RECORD    *
*              BUFFERS.                                               *
*                                                                     *
*  REGISTER USAGE:                                                    *
*                                                                     *
*        R10 - RETURN   ADDRESS                                       *
*        R6  - NEW      LOGICAL RECORD BUFFER ADDRESS  * * RETURNED * *
*        R4  - PREVIOUS LOGICAL RECORD BUFFER ADDRESS                 *
*        R3  - NEW      LOGICAL RECORD BUFFER LENGTH                  *
*        R1  - TABLE ID  ADDRESS                                      *
*            - AREA ADDRESS (GETMAIN)                                 *
*        R0  - AREA LENGTH  (GETMAIN)                                 *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
         USING RECBUFR,R6
*
ALLOCATE LR    R14,R1             SAVE TABLE    ID ADDRESS
*
         LR    R0,R3              LOAD AREA LENGTH
         GETMAIN R,LV=(0)
*
         LR    R6,R1              INITIALIZE CURRENT BUFFER ADDRESS
         ST    R6,RBNEXT-RECBUFR(,R4) ADD TO BUFFER  CHAIN
         STH   R3,RBLEN
*
         XC    RBNEXT,RBNEXT      INITIALIZE FORWARD CHAIN  POINTER
*
         MVC   RBTABLID,0(R14)    INITIALIZE TABLE   ID
         XC    RBRECID,RBRECID    INITIALIZE RECORD  ID
         XC    RBKEYOFF,RBKEYOFF  INITIALIZE KEY     OFFSET
         XC    RBKEYLEN,RBKEYLEN  INITIALIZE KEY     LENGTH
         XC    RBRECLEN,RBRECLEN  INITIALIZE RECORD  LENGTH
         XC    RBRECCNT,RBRECCNT  INITIALIZE RECORD  COUNT
         XC    RBTBLBEG,RBTBLBEG  INITIALIZE RECORD   TABLE BEGIN
         XC    RBTBLEND,RBTBLEND  INITIALIZE RECORD   TABLE END
         XC    RBMIDDLE,RBMIDDLE  INITIALIZE MIDDLE   ENTRY ADDRESS
         XC    RBLSTFND,RBLSTFND  INITIALIZE LAST     ENTRY FOUND
         XC    RBEFFOFF,RBEFFOFF  INITIALIZE EFFECTIVE DATE OFFSET
         XC    RBFLAGS,RBFLAGS    INITIALIZE PROCESSING FLAGS
         XC    RBRECFND,RBRECFND  INITIALIZE RECORD     FOUND COUNT
         XC    RBRECNOT,RBRECNOT  INITIALIZE RECORD NOT FOUND COUNT
*
         BR    R10                RETURN  TO CALLER
*
         DROP  R6
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
* "LOCRB" - SEARCHES THE BUFFER CHAIN FOR AN ENTRY WHICH MATCHES      *
*           THE "TABLE ID/REC ID" IN THE LOGIC TABLE ENTRY.           *
*                                                                     *
* REGISTER USAGE:                                                     *
*                                                                     *
*        R10 - RETURN   ADDRESS                                       *
*        R6  - CURRENT  LOGICAL RECORD BUFFER ADDRESS                 *
*        R4  - PREVIOUS LOGICAL RECORD BUFFER ADDRESS                 *
*        R3  - CURRENT  LOGICAL RECORD BUFFER  LENGTH                 *
*        R1  - TABLE ID  ADDRESS                                      *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
LOCRB    SR    R3,R3              INITIALIZE CURRENT  BUFFER LENGTH
         LA    R4,RBCHAIN         INITIALIZE PREVIOUS BUFFER ADDRESS
         L     R6,RBNEXT-RECBUFR(,R4)        CURRENT  BUFFER ADDRESS
         USING RECBUFR,R6
*
         B     LOCEND             CHECK  FOR END-OF-CHAIN
                        SPACE 3
LOCLOOP  LR    R4,R6              ADVANCE TO NEXT ENTRY
         L     R6,RBNEXT
LOCEND   LTR   R6,R6              END-OF-CHAIN ???
         BZR   R10                YES - EXIT SUBROUTINE
*
         CLC   RBTABLID,0(R1)     MATCHING ENTRY ???
         BNE   LOCLOOP            NO  - ADVANCE TO NEXT ENTRY ON CHAIN
                        SPACE 3
         LH    R3,RBLEN           LOAD  CURRENT BUFFER  LENGTH
*
         BR    R10                EXIT  SUBROUTINE
*
         DROP  R6
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        C O N S T A N T S                                            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
F4       DC    F'4'
*
ZEROES   DC    XL08'0000000000000000'
*
MODE31   DS   0XL04
OPENPARM DC    XL08'8000000000000000'
*
PGMNAME  DC    CL8'GVBUR45   ' PROGRAM NAME
EYEBALL  DC    CL8'GVBUR45WRK' EYEBALL LABEL
INITNAME DC    CL8'INITIAL '   MINOR   ENQ   NODE
*
TOKNLVL  DC    A(2)               NAME/TOKEN AVAILABILITY   LEVEL
TOKNPERS DC    A(0)               NAME/TOKEN PERSISTENCE
TOKNNAME DC    CL16'GVBUR45TABLETOKEN ' TOKEN NAME
                        SPACE 5
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        V A R I A B L E S                                            *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
                        EJECT
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                                     *
*        D A T A   C O N T R O L   B L O C K S                        *
*                                                                     *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
HDRFILE  DCB   DSORG=PS,DDNAME=UR45HDR,MACRF=(GL),EODAD=FILLEOF
HDRDCBL  EQU   *-HDRFILE
                        SPACE 3
DATAFILE DCB   DSORG=PS,DDNAME=UR45DATA,MACRF=(GL),EODAD=DATAEOF
DATADCBL EQU   *-DATAFILE
                        SPACE 3
         DCBD  DSORG=PS
                        SPACE 3
*
         LTORG
*
*
         END
