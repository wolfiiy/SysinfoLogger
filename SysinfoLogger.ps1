<#
.NOTES
    *****************************************************************************
    ETML
    Script name: Sysinfo Logger
    Author: Valentin PIGNAT, Sebastien TILLE
    Date: January 24th, 2024
    *****************************************************************************

.SYNOPSIS
    Logging system data

.DESCRIPTION
    This script gets and logs system information. Data collected:
    - Hostname
    - OS version
    - Disk usage
    - Memory usage
    - Software installed
    - TODO

.PARAMETER RemoteIP
    IP address of a remote computer.

.OUTPUTS
    The script logs the gathered data inside of the sysinfo.log file.
	
.EXAMPLE
	TODO
	
.LINK
    TODO
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
# Variables
$header = "LOG DATE: "
$date= Get-Date

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