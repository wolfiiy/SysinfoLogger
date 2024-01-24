<#
.NOTES
    *****************************************************************************
    ETML
    Script's name:	CanevasV3-EN.ps1
    Author:	
    Date:	dd.mm.yyyy
 	*****************************************************************************
    Modifications
 	Date  : -
 	Author: -
 	Reasons: -
 	*****************************************************************************
.SYNOPSIS
	Light information about the script, could be the title
 	
.DESCRIPTION
    Explanations about the script with details, what it does, what kind of tests and some possible results
  	
.PARAMETER Param1
    Description of the first parameter with limits and requirements
	
.PARAMETER Param2
    Description of the second parameter with limits and requirements
 	
.PARAMETER Param3
    Description of the third parameter with limits and requirements

.OUTPUTS
	What the script do, like output files or system modifications
	
.EXAMPLE
	.\CanevasV3.ps1 -Param1 Toto -Param2 Titi -Param3 Tutu
	What you write to run the script with the parameters
	Result : for exemple a file, a modification, a error message
	
.EXAMPLE
	.\CanevasV3.ps1
	Result : Display help when no parameter are present
	
.LINK
    When other scripts are used in this script
#>

<# The number of parameters must be the same as described in the header
   It's possible to have no parameter but arguments
   One parameter can be typed : [string]$Param1
   One parameter can be initialized : $Param2="Toto"
   One parameter can be required : [Parameter(Mandatory=$True][string]$Param3
#>
# The parameters are defined right after the header and a comment must be added 
param($Param1, $Param2, $Param3)

###################################################################################################################
# Area for the variables and functions with exemples
# Comments for variables
$date= Get-Date
$count= 0
$path= "c:\temp"

###################################################################################################################
# Area for the tests, for exemple admin rignts, existing path or the presence of parameters

# Display help if at least one parameter is missing and exit, "safe guard clauses" allowed to optimize scripts running and reading
if(!$Param1 -or !$Param2 -or !$Param3)
{
    Get-Help $MyInvocation.Mycommand.Path
	exit
}

###################################################################################################################
# Body's script

# What does the script, in this case display a message
Write-Host "coucou"
    



