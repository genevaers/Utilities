#!/bin/bash   
#
# (c) Copyright IBM Corporation 2020.  
#     Copyright Contributors to the GenevaERS Project.
# SPDX-License-Identifier: Apache-2.0
#
# ***************************************************************************
#                                                                           
#   Licensed under the Apache License, Version 2.0 (the "License");         
#   you may not use this file except in compliance with the License.        
#   You may obtain a copy of the License at                                 
#                                                                           
#     http://www.apache.org/licenses/LICENSE-2.0                            
#                                                                           
#   Unless required by applicable law or agreed to in writing, software     
#   distributed under the License is distributed on an "AS IS" BASIS,       
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and     
#   limitations under the License.                                          
# ****************************************************************************
#                                                              
#   script to move part to a new load library                  
#                                                              
echo " Move part to a new load library "                       
echo " High Level Qualifier is " $1  " /n"                     
#                                                              
if (( $? )); then                                              
 echo "Usage : testing.sh <High Level Qualifier> \n e.g. GEBT" 
 echo "        This high level qualifier not supplied "        
 set -e                                                        
 exit 1                                                        
fi                                                             
#   .   remove any prior instance                              
tsocmd "ALLOC DSN('$1.GENEMOD') OLD DELETE"                    
if (( $? )); then                                              
            echo "---------------------"                       
            echo "file has been not  deleted"                  
            echo "---------------------"      
                 
else                                                                                                                       
            echo "expected error with delete of $1.GENEMOD"                                                                
fi                                                                                                                         
#                                                                                                                          
#   .   alloc new file                                                                                                     
tsocmd "ALLOC DSN('$1.GENEMOD') NEW CATALOG TRACKS UNIT(SYSDA) SPACE(10,10) LRECL(80) RECFM(F) DSORG(PO) BLKSIZE(0) DSNTYPE(LIBRARY)"
if (( $? )); then                                                                                                          
            echo "---------------------"                                                                                   
            echo "file has not been  created"                                                                              
            echo "---------------------"                                                                                   
            exit 1                                                                                                         
else                                                                                                                       
            echo "File has been created $1.GENEMOD"                                                                        
fi                                                                                                                         
#                                                                                                                          
#   .   copy part to new load library  
cd gvbur20                                        
cp -F nl README.md "//'$1.GENEMOD(README)'"       
cp -F nl dl96area.copy "//'$1.GENEMOD(DL96AREA)'" 
cp -F nl execdata.copy "//'$1.GENEMOD(EXECDATA)'" 
cp -F nl gvbaur35.copy "//'$1.GENEMOD(GVBAUR35)'" 
cp -F nl gvbeye.macro  "//'$1.GENEMOD(GVBEYE)'"   
cp -F nl gvbmr95w.copy "//'$1.GENEMOD(GVBMR95W)'" 
cp -F nl gvbur20.asm   "//'$1.GENEMOD(GVBUR20)'"  
cp -F nl gvbur20p.macro "//'$1.GENEMOD(GVBUR20P)'" 
cp -F nl gvbx95pa.copy "//'$1.GENEMOD(GVBX95PA)'" 
if (( $? )); then                                                                                                          
            echo "---------------------"                                                                                   
            echo "file has not been moved to GENEMOD"                                                                      
            echo "---------------------"                                                                                   
            exit 1                       
fi     
exit 0               
