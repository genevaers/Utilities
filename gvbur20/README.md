# gvbur20
the genevaers io sub routine.
genervaers utility repo

## Description

This module can be called by external programs for disk /or tape file I/O operations on sequential files.
It handles BSAM, and Channel I/O operation.  

## How to build Instructions

1.   Place all assember source parts in the same Partitioned Dataset within a z/OS operating system
2.   Use these options to assemble the GVBUR20 Source
//ASM      EXEC PGM=ASMA90,                                  
// PARM=(NODECK,OBJECT,'SYSPARM(RELEASE)','OPTABLE(ZS7)',    
// 'PC(GEN),FLAG(NOALIGN),SECTALGN(256),GOFF,LIST(133)')     
3.  Ensure the HLASM Toolkit structured macros are in the SYSLIB concatenation along with the
    the parttitioned dataset you have placed the other assembler parts in this repo.
4.    Use these parameters to bind this part
//LINK     EXEC PGM=IEWL,                                      
// PARM=(XREF,LET,LIST,MAP,AMODE(31),RMODE(ANY),REUS(RENT))      

## Function and Return CODES

  FUNCTION CODES:                                              

        00  - OPEN                                             
        04  - CLOSE                                            
        08  - READ  SEQUENTIAL                                 
        12  - READ  DIRECT                                     
        16  - WRITE RECORD                                     
        20  - WRITE BLOCK   (LOCATE MODE)                      
        24  - WRITE BLOCK   (MOVE   MODE)                      

  RETURN CODES:                                                

        00  - SUCCESSFUL                                       
        04  - SUCCESSFUL (WARNING: SEE ERROR CODE)             
        08  - END-OF-FILE                                      
        16  - PERMANENT   ERROR   (SEE ERROR CODE)             
                                                          

  ERROR CODES:                                                 

        00  - SUCCESSFUL                                       
        01  - BAD  WORK AREA   POINTER                         
        02  - UNDEFINED FUNCTION  CODE (SB:  0,4,8,12,16,20,24)
        03  - UNDEFINED I/O       MODE (SB: "I","O","D","X")   
        04  - FILE  ALREADY     OPENED                         
        05  - OPEN  FOR OUTPUT  FAILED                         
        06  - OPEN  FOR INPUT   FAILED                         
        07  - FILE  NEVER       OPENED                         
        08  - FILE  ALREADY     CLOSED                         
        09  - BAD   RECORD/BLK  LENGTH                         
        10  - OPEN  FOR EXCP    FAILED                         

***************************************************************
