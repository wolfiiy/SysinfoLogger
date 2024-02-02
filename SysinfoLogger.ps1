<#
.NOTES
    *****************************************************************************
    ETML
    Script name: Sysinfo Logger
    Author: Valentin PIGNAT, Sebastien TILLE
    Date: January 24th, 2024
    *****************************************************************************

    IDEAS
    - Custom save location
    - IPs from files test
    - Check for package managers

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
$Header = "LOG DATE: "
$Date = ""
$FilePath = "sysinfo.log"

###################################################################################################################
# Tests

# Display help if at least one parameter is missing and exit, "safe guard clauses" allowed to optimize scripts running and reading
<#if(!$Param1 -or !$Param2 -or !$Param3)
{
    Get-Help $MyInvocation.Mycommand.Path
	exit
}#>

###################################################################################################################
# Body

$date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"

$Title = @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                               SYSTEM INFO LOGGER                              ║
╟═══════════════════════════════════════════════════════════════════════════════╣
║ Log date: ${Date}                                                 ║
╙━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╜
"@

$Hostname = (Get-CimInstance CIM_ComputerSystem).Name

$OS = (Get-CimInstance -ClassName CIM_OperatingSystem)
$OSName = $OS.Caption
$OSVersion = $OS.Version
$OSBuild = $OS.BuildNumber

$CPU = (Get-CimInstance -ClassName CIM_Processor).Name
$GPU = (Get-CimInstance -ClassName CIM_VideoController).Name
$LDisks = Get-CimInstance -ClassName CIM_LogicalDisk

$LMonitors = Get-CimInstance -ClassName CIM_DesktopMonitor

$InstalledSoftware = Get-Itemproperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, 
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {!([string]:: IsNullOrWhiteSpace($_.DisplayName))} | Select DisplayName


function Write-Title() {
    clear
    Write-Host -ForegroundColor Cyan $Title
}


function Write-Data() {
    Write-Host Hostname: `t$Hostname
    Write-Host OS: `t`t$OSName
    Write-Host Version: `t$OSVersion Build $OSBuild
    
    Write-Host CPU `t`t$CPU
    
    $i = 0
    Write-Host `n
    foreach($VGA in $GPU) {
        Write-Host GPU $i`: `t`t$VGA
        $i++
    }
	foreach ($Monitor in $LMonitors) {
		$MonitorName = $Monitor.Name
		[string]$w = $Monitor.ScreenWidth
		[string]$h = $Monitor.ScreenHeight
		$MonitorResolution = $w + "x" + $h
		Write-Host $MonitorName`: $MonitorResolution
	}

    foreach($Disk in $LDisks){
        $DiskName = $Disk.DeviceID
        $DiskSize = [math]::Round($Disk.Size / 1gb)
        $DiskFree = [math]::Round($Disk.FreeSpace / 1gb)

        if ($DiskSize -gt 0) {
            $DiskFreePercent = [math]::Round($DiskFree / $DiskSize * 100, 2)
            Write-Host $DiskName `t`t$DiskFree / $DiskSize Gb`, $DiskFreePercent% free
        }
    }

    Write-Host `nInstalled software:
    $InstalledSoftware.DisplayName
}

# Appends the gathered data to the logging file.
function Write-To-File() {
    Write-Output "`n********** LOG DATE $date **********" >> $FilePath
    Write-Output "Hostname: `t$Hostname" >> $FilePath
    Write-Output "OS: `t`t$OSName" >> $FilePath
    Write-Output "Version: `t$OSVersion Build $OSBuild" >> $FilePath
    Write-Output "CPU `t`t$CPU" >> $FilePath
    # TODO store in variable
    $i = 0
    foreach($VGA in $GPU) {
        Write-Output "GPU $i`: `t`t$VGA" >> $FilePath
        $i++
    }
    foreach($Disk in $LDisks){
        $DiskName = $Disk.DeviceID
        $DiskSize = [math]::Round($Disk.Size / 1gb)
        $DiskFree = [math]::Round($Disk.FreeSpace / 1gb)

        if ($DiskSize -gt 0) {
            $DiskFreePercent = [math]::Round($DiskFree / $DiskSize * 100, 2)
            Write-Output "$DiskName `t`t$DiskFree / $DiskSize Gb`, $DiskFreePercent% free" >> $FilePath
        }
    }
}

Write-Title
Write-Data
Write-To-File