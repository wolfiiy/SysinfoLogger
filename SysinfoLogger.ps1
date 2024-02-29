﻿<#
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
#>

# The parameters are defined right after the header and a comment must be added 
param($RemoteIP)

###################################################################################################################
# Variables
$Date = ""
$FilePath = "sysinfo.log"

###################################################################################################################
# Tests

###################################################################################################################
# Body

$date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"

$Title = @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                               SYSTEM INFO LOGGER                              ║
╟═══════════════════════════════════════════════════════════════════════════════╣
║ Log date: ${Date}                                                 ║
╙━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╜
"@

$Hostname = (Get-CimInstance CIM_ComputerSystem).Name
$OS = (Get-CimInstance -ClassName CIM_OperatingSystem)
$OSName = $OS.Caption
$OSVersion = $OS.Version
$OSBuild = $OS.BuildNumber

$RAMFree = [math]::Round((Get-CimInstance Cim_OperatingSystem).FreePhysicalMemory/1mb, 2)
$RAM = [math]::Round((Get-CimInstance Cim_OperatingSystem).TotalVisibleMemorySize/1mb, 2)
$CPU = (Get-CimInstance -ClassName CIM_Processor).Name
$GPU = (Get-CimInstance -ClassName CIM_VideoController).Name
$LDisks = Get-CimInstance -ClassName CIM_LogicalDisk

$LMonitors = Get-CimInstance -ClassName CIM_DesktopMonitor

$InstalledSoftware = Get-Itemproperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, 
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {!([string]:: IsNullOrWhiteSpace($_.DisplayName))} | Select DisplayName


function Write-Title() {
    clear
    Write-Host -ForegroundColor Cyan $Title
    Write-Output $Title >> $FilePath
}

function Write-All() {
    $i = 0

    Write-Output "`n┌ SYSTEM INFORMATIONS" | Tee-Object -file $FilePath -Append
    Write-Output "`| Hostname: `t$Hostname" | Tee-Object -file $FilePath -Append
    Write-Output "`| OS: `t`t$OSName" | Tee-Object -file $FilePath -Append
    Write-Output "`| Version: `t$OSVersion Build $OSBuild" | Tee-Object -file $FilePath -Append
    Write-Output "`| CPU: `t`t$CPU" | Tee-Object -file $FilePath -Append
    foreach($VGA in $GPU) {
        Write-Output "`| GPU $i`: `t`t$VGA" | Tee-Object -file  -Append$FilePath -Append
        $i++
    }
    Write-Output "└ RAM: `t`t$RAMFree / $RAM Gb" | Tee-Object -file $FilePath -Append

    Write-Output "`n┌ DISPLAYS" | Tee-Object -file $FilePath -Append
	foreach ($Monitor in $LMonitors) {
		$MonitorName = $Monitor.Name
		[string]$w = $Monitor.ScreenWidth
		[string]$h = $Monitor.ScreenHeight
		$MonitorResolution = $w + "x" + $h
		Write-Output "`| $MonitorName`: $MonitorResolution" | Tee-Object -file $FilePath -Append
	}
    Write-Output "└ $($LMonitors.DeviceID.Count) display`(s`) in total" | Tee-Object -file $FilePath -Append

    Write-Output "`n┌ STORAGE" | Tee-Object -file $FilePath -Append
    foreach($Disk in $LDisks){
        $DiskName = $Disk.DeviceID
        $DiskSize = [math]::Round($Disk.Size / 1gb, 2)
        $DiskFree = [math]::Round($Disk.FreeSpace / 1gb, 2)

        if ($DiskSize -gt 0) {
            $DiskFreePercent = [math]::Round($DiskFree / $DiskSize * 100, 2)
            Write-Output "`| $DiskName `t`t$DiskFree / $DiskSize Gb`, $DiskFreePercent% free" | Tee-Object -file $FilePath -Append
        }
    }
    Write-Output "└ Found $($LDisks.DeviceID.Count) parition`(s`)" | Tee-Object -file $FilePath -Append

    Write-Output "`n┌ SOFTWARE" | Tee-Object -file $FilePath -Append
    foreach ($Software in $InstalledSoftware) {
        Write-Output "`| $($Software.DisplayName)" | Tee-Object -file $FilePath -Append
    }
    Write-Output "└ $($InstalledSoftware.DisplayName.Count) Program`(s`) or update`(s`) installed`n`n" | Tee-Object -file $FilePath -Append
}

Write-Title
Write-All