<#
.NOTES
    *****************************************************************************
    ETML
    Script name: Sysinfo Logger
    Author: Valentin PIGNAT, Sebastien TILLE
    Date: February 29th, 2024
    *****************************************************************************

    IDEAS
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

.PARAMETER Remote
    IP addresses of remote computers. Separate using a comma.

.PARAMETER Path
    Existing folder in which to save the log file. Do *not* include the file name.

.OUTPUTS
    The script logs the gathered data inside of the sysinfo.log file.
	
.EXAMPLE
	TODO
#>

###################################################################################################################
# Parameters
param(
    [string[]]$Remote=@(), 
    [string]$Path
)

###################################################################################################################
# Variables
$Date = ""
$FilePath = "sysinfo.log"

###################################################################################################################
# Checks

# Path is valid
if ($Path.Length -gt 0) {
    if (!(Test-Path -Path $Path)) {
        throw [System.ArgumentException]::new("Save path is invalid! Please use an existing directory.")
    }

    $FilePath = $Path + "\sysinfo.log"
}

###################################################################################################################
# Body

# Header
$Date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
$Title = @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                               SYSTEM INFO LOGGER                              ║
╟═══════════════════════════════════════════════════════════════════════════════╣
║ Log date: ${Date}                                                 ║
╙━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╜
"@

# Data logger
function Get-SystemInformation {
    param([string]$ComputerName, [bool]$IsLocal)

    $Data = {
        # Computer and OS
        $Hostname = (Get-CimInstance CIM_ComputerSystem).Name
        $IPAddress = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4'}).IPAddress
        $OS = (Get-CimInstance -ClassName CIM_OperatingSystem)
        $OSName = $OS.Caption
        $OSVersion = $OS.Version
        $OSBuild = $OS.BuildNumber

        # Hardware and displays
        $RAMFree = [math]::Round((Get-CimInstance Cim_OperatingSystem).FreePhysicalMemory/1mb, 2)
        $RAM = [math]::Round((Get-CimInstance Cim_OperatingSystem).TotalVisibleMemorySize/1mb, 2)
        $CPU = (Get-CimInstance -ClassName CIM_Processor).Name
        $GPU = (Get-CimInstance -ClassName CIM_VideoController).Name
        $LDisks = Get-CimInstance -ClassName CIM_LogicalDisk
        $LMonitors = Get-CimInstance -ClassName CIM_DesktopMonitor

        # Software
        $InstalledSoftware = Get-Itemproperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, 
        HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object {!([string]:: IsNullOrWhiteSpace($_.DisplayName))} | Select DisplayName

        # Hashtable containing all system information
        $info = @{
            "Hostname" = $Hostname
            "OSName" = $OSName
            "OSVersion" = $OSVersion
            "OSBuild" = $OSBuild
            "RAMFree" = $RAMFree
            "RAM" = $RAM
            "CPU" = $CPU
            "GPU" = $GPU
            "LDisks" = $LDisks
            "LMonitors" = $LMonitors
            "InstalledSoftware" = $InstalledSoftware
            "IPAddress" = $IPAddress
        }

        return $info
    }

    if ($IsLocal) {
        $SysInfo = & $Data
    } else {
        # Sending command to remote computers
        $SysInfo = Invoke-Command -ComputerName $ComputerName -ScriptBlock $Data
    }
    
    # Counter
    $i = 0

    # Computer and OS
    Write-Output $Title | Tee-Object -file $FilePath -Append
    Write-Output "`n┌ SYSTEM INFORMATIONS" | Tee-Object -file $FilePath -Append
    Write-Output "`| Hostname: `t$($SysInfo['Hostname'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| OS: `t`t$($SysInfo['OSName'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| Version: `t$($SysInfo['OSVersion']) Build $($SysInfo['OSBuild'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| CPU: `t`t$($SysInfo['CPU'])" | Tee-Object -file $FilePath -Append
    foreach($VGA in $($SysInfo['GPU'])) {
        Write-Output "`| GPU $i`: `t`t$VGA" | Tee-Object -file  -Append$FilePath -Append
        $i++
    }
    Write-Output "└ RAM: `t`t$($SysInfo['RAMFree']) / $($SysInfo['RAM']) Gb" | Tee-Object -file $FilePath -Append

    # Displays
    Write-Output "`n┌ DISPLAYS" | Tee-Object -file $FilePath -Append
	foreach ($Monitor in $($SysInfo['LMonitors'])) {
		$MonitorName = $Monitor.Name
		[string]$w = $Monitor.ScreenWidth
		[string]$h = $Monitor.ScreenHeight
		$MonitorResolution = $w + "x" + $h
		Write-Output "`| $MonitorName`: $MonitorResolution" | Tee-Object -file $FilePath -Append
	}
    Write-Output "└ $($($SysInfo['LMonitors']).DeviceID.Count) display`(s`) in total" | Tee-Object -file $FilePath -Append

    # Storage
    Write-Output "`n┌ STORAGE" | Tee-Object -file $FilePath -Append
    foreach($Disk in $($SysInfo['LDisks'])){
        $DiskName = $Disk.DeviceID
        $DiskSize = [math]::Round($Disk.Size / 1gb, 2)
        $DiskFree = [math]::Round($Disk.FreeSpace / 1gb, 2)

        if ($DiskSize -gt 0) {
            $DiskFreePercent = [math]::Round($DiskFree / $DiskSize * 100, 2)
            Write-Output "`| $DiskName `t`t$DiskFree / $DiskSize Gb`, $DiskFreePercent% free" | Tee-Object -file $FilePath -Append
        }
    }
    Write-Output "└ Found $($($SysInfo['LDisks']).DeviceID.Count) parition`(s`)" | Tee-Object -file $FilePath -Append

    # Software
    Write-Output "`n┌ SOFTWARE" | Tee-Object -file $FilePath -Append
    foreach ($Software in $($SysInfo['InstalledSoftware'])) {
        Write-Output "`| $($Software.DisplayName)" | Tee-Object -file $FilePath -Append
    }
    Write-Output "└ $($($SysInfo['InstalledSoftware']).DisplayName.Count) Program`(s`) or update`(s`) installed`n`n" | Tee-Object -file $FilePath -Append
}

if ($Remote -gt 0) {
    # Log remote computers
    foreach ($PC in $Remote) {
        try {
            New-PSSession -ComputerName $PC -Credential Get-Credential
            Get-SystemInformation -ComputerName $PC -IsLocal $false
            # Remove-PSSession
        } catch {
            Write-Error "Logging for $PC failed." 
            Write-Host $_.ScriptStackTrace
        }
    }
} else {
    # Log this computer
    Get-SystemInformation -ComputerName $env:COMPUTERNAME -IsLocal $true
}