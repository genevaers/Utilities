# gvblib
genervaers utility repo

## Description

This module can be called by external programs for disk /or tape file I/O operations on sequential files. 
It handles BSAM, and Channel I/O operation.  

## How to build Instructions

1.   Place all assember source parts in the same Partitioned Dataset within a z/OSoperation system
2.   Use these options to assemble the GVBUR20 Source 
//ASM      EXEC PGM=ASMA90,                                  
// PARM=(NODECK,OBJECT,'SYSPARM(RELEASE)','OPTABLE(ZS7)',    
// 'PC(GEN),FLAG(NOALIGN),SECTALGN(256),GOFF,LIST(133)')     
3.  Ensure the HLASM Toolkit structured macros are in the SYSLIB concatenation along with the
    the parttitioned dataset you have placed the other assembler parts in this repo.
4.    Use these parameters to bind this part
//LINK     EXEC PGM=IEWL,                                      
// PARM=(XREF,LET,LIST,MAP,AMODE(31),RMODE(ANY),REUS(RENT))    
 

## Training

Learn how to use GenevaERS with training videos and slides at [GenevaERS Training](https://genevaers.org/training-videos/)

## News and Discussion

See the most recent activity on the project at [GenevaERS Activity](https://genevaers.org/activity/)

You can connect with the community in a variety of ways...

- [GenevaERS mailing list](https://lists.openmainframeproject.org/g/genevaers-discussion)
- [#GenevaERS channel on Open Mainframe Project Slack](https://slack.openmainframeproject.org)
- After requesting access with the above link, look for the [GenevaERS channel](https://openmainframeproject.slack.com/archives/C01711931GA) 


## Contributing
Anyone can contribute to the GenevaERS project - learn more at [CONTRIBUTING.md](CONTRIBUTING.md)

## Governance
GenevaERS is a project hosted by the [Open Mainframe Project](https://openmainframeproject.org). This project has established it's own processes for managing day-to-day processes in the project at [GOVERNANCE.md](GOVERNANCE.md).


## Reporting Issues
To report a problem, you can open an [issue](https://github.com/genevaers/community/issues) in repository against a specific workflow. If the issue is sensitive in nature or a security related issue, please do not report in the issue tracker but instead email  genevaers-private@lists.openmainframeproject.org.
