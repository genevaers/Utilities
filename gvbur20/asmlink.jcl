//ASMLINK  JOB (ACCT),'ASSEMBLE AND LINK  ',              
//            NOTIFY=&SYSUID.,                             
//            CLASS=A,                                     
//            MSGLEVEL=(1,1),                              
//            MSGCLASS=X  
//*                                                        
//*  ASSEMBLE MODULE                                       
//*     
//*
//* (c) Copyright IBM Corporation 2004,2017.  
//*     Copyright Contributors to the GenevaERS Project.
//* SPDX-License-Identifier: Apache-2.0
//*
//***********************************************************************
//*                                                                           
//*   Licensed under the Apache License, Version 2.0 (the "License");         
//*   you may not use this file except in compliance with the License.        
//*   You may obtain a copy of the License at                                 
//*                                                                           
//*     http://www.apache.org/licenses/LICENSE-2.0                            
//*                                                                           
//*   Unless required by applicable law or agreed to in writing, software     
//*   distributed under the License is distributed on an "AS IS" BASIS,       
//*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express 
//*   or implied.
//*   See the License for the specific language governing permissions and     
//*   limitations under the License.                                          
//***********************************************************************
//ASM      EXEC PGM=ASMA90,                                
// PARM=(NODECK,OBJECT,'SYSPARM(RELEASE)','OPTABLE(ZS7)',  
// 'PC(GEN),FLAG(NOALIGN),SECTALGN(256),GOFF,LIST(133)')   
//*                                                        
//SYSIN    DD *                                            
*PROCESS   LIBMAC                                          
//         DD DSN=&SYSUID..GVBLIB.BUILD(GVBUR45),DISP=SHR      
//*                                                     
//SYSLIB   DD DISP=SHR,DSN=&SYSUID..GVBLIB.BUILD               
//         DD DISP=SHR,DSN=ASM.SASMMAC2                 
//         DD DISP=SHR,DSN=SYS1.MACLIB                  
//         DD DISP=SHR,DSN=SYS1.MODGEN                  
//         DD DISP=SHR,DSN=CEE.SCEEMAC                  
//*                                                     
//SYSLIN   DD DSN=&&OBJECT,                             
//            DISP=(NEW,PASS),                          
//            UNIT=SYSDA,                               
//            SPACE=(TRK,(25,10),RLSE),                 
//            RECFM=FB,LRECL=80,BLKSIZE=2960            
//*                                                     
//SYSUT1   DD DSN=&&SYSUT1,                             
//            UNIT=SYSDA,                               
//            SPACE=(1024,(300,300),,,ROUND),           
//            BUFNO=1                                   
//*                                                     
//SYSPRINT DD SYSOUT=* 
//*                                                      
//LINK    EXEC PGM=IEWL,                                   
// PARM=(XREF,LET,LIST,MAP,AMODE(31),RMODE(24),REUS(RENT))  
//SYSLIN   DD DISP=SHR,DSN=&&OBJECT    
//*
//SYSLIB   DD DISP=SHR,DSN=SYS1.CSSLIB                   
//*                                                         
//SYSUT1   DD DSN=&&SYSUT1,                                 
//            UNIT=SYSDA,                                   
//            SPACE=(1024,(120,120),,,ROUND),               
//            BUFNO=1                                       
//*                                                         
//SYSLMOD  DD DSN=&SYSUID..GVBLIB.LOAD(GVBUR45),                  
//            DISP=SHR                                      
//*                                                         
//SYSPRINT DD SYSOUT=*                                      
//*                                                    
//ASM      EXEC PGM=ASMA90,                                
// PARM=(NODECK,OBJECT,'SYSPARM(RELEASE)','OPTABLE(ZS7)',  
// 'PC(GEN),FLAG(NOALIGN),SECTALGN(256),GOFF,LIST(133)')   
//*                                                        
//SYSIN    DD *                                            
*PROCESS   LIBMAC                                          
//         DD DSN=&SYSUID..GVBLIB.BUILD(GVBUR20),DISP=SHR      
//*                                                     
//SYSLIB   DD DISP=SHR,DSN=&SYSUID..GVBLIB.BUILD               
//         DD DISP=SHR,DSN=ASM.SASMMAC2                 
//         DD DISP=SHR,DSN=SYS1.MACLIB                  
//         DD DISP=SHR,DSN=SYS1.MODGEN                  
//         DD DISP=SHR,DSN=CEE.SCEEMAC                  
//*                                                     
//SYSLIN   DD DSN=&&OBJECT,                             
//            DISP=(NEW,PASS),                          
//            UNIT=SYSDA,                               
//            SPACE=(TRK,(25,10),RLSE),                 
//            RECFM=FB,LRECL=80,BLKSIZE=2960            
//*                                                     
//SYSUT1   DD DSN=&&SYSUT1,                             
//            UNIT=SYSDA,                               
//            SPACE=(1024,(300,300),,,ROUND),           
//            BUFNO=1                                   
//*                                                     
//SYSPRINT DD SYSOUT=* 
//*                                                      
//LINK    EXEC PGM=IEWL,                                   
// PARM=(XREF,LET,LIST,MAP,AMODE(31),RMODE(24),REUS(RENT))  
//SYSLIN   DD DISP=SHR,DSN=&&OBJECT                         
//*
//SYSLIB   DD DISP=SHR,DSN=SYS1.CSSLIB                   
//*                                                         
//SYSUT1   DD DSN=&&SYSUT1,                                 
//            UNIT=SYSDA,                                   
//            SPACE=(1024,(120,120),,,ROUND),               
//            BUFNO=1                                       
//*                                                         
//SYSLMOD  DD DSN=&SYSUID..GVBLIB.LOAD(GVBUR20),                  
//            DISP=SHR                                      
//*                                                         
//SYSPRINT DD SYSOUT=*                                      
//*
