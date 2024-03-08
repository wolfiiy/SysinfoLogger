<#
.NOTES
    *****************************************************************************
    ETML
    Script name: Sysinfo Logger
    Author: Valentin PIGNAT, Sebastien TILLE
    Date: February 29th, 2024
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

.PARAMETER Remote
    IP address of a remote computer.

.OUTPUTS
    The script logs the gathered data inside of the sysinfo.log file.
	
.EXAMPLE
	TODO
#>
# The parameters are defined right after the header and a comment must be added 

param(
    [string[]]$Remote=@(),
    [string]$Path,
    $Password
)

###################################################################################################################
# Variables
$Date = ""
$FilePath = "sysinfo.log"

###################################################################################################################
# Path is valid
if ($Path.Length -gt 0) {
    if (!(Test-Path -Path $Path)) {
        throw [System.ArgumentException]::new("Save path is invalid! Please use an existing directory.")
    }
 
    $FilePath = $Path + "\sysinfo.log"
}


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

    #Title
    Write-Output $Title | Tee-Object -file $FilePath -Append

    # Computer and OS
    Write-Output "`n┌ SYSTEM INFORMATIONS" | Tee-Object -file $FilePath -Append
    Write-Output "`| Hostname: `t$($SysInfo['Hostname'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| OS: `t`t$($SysInfo['OSName'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| Version: `t$($SysInfo['OSVersion']) Build $($SysInfo['OSBuild'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| CPU: `t`t$($SysInfo['CPU'])" | Tee-Object -file $FilePath -Append
    foreach($VGA in $($SysInfo['GPU'])) {
        Write-Output "`| GPU $i`: `t`t$VGA" | Tee-Object -file  $FilePath -Append
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
        $DiskUsed = $DiskSize - $DiskFree

        $EmptyDisk = 0
        if ($DiskSize -gt 0) {
            $DiskUsedPercent = [math]::Round($DiskUsed / $DiskSize * 100, 2)
            Write-Output "`| $DiskName `t`t$DiskUsed / $DiskSize Gb`, $DiskUsedPercent% used" | Tee-Object -file $FilePath -Append
        }
        else {
            $EmptyDisk++
        }
    }
    Write-Output "└ Found $($($SysInfo['LDisks']).DeviceID.Count - $EmptyDisk) partition`(s`)" | Tee-Object -file $FilePath -Append

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
            $HostName = [System.Net.Dns]::GetHostByAddress($PC).HostName
            
            if ($Password -ne $null){
                $Password = ConvertTo-SecureString $Password -AsPlainText -Force
                $cred = new-object -typename System.Management.Automation.PSCredential ($HostName,$Password)
                New-PSSession -ComputerName $HostName -Credential $cred -erroraction 'silentlycontinue'
            }
            else{
                New-PSSession -ComputerName $HostName -Credential Get-Credential -erroraction 'silentlycontinue'
            }
            
            Get-SystemInformation -ComputerName $HostName -IsLocal $false
            # Remove-PSSession
        } catch {
            Write-Error "Logging for $HostName failed." 
            Write-Host $_.ScriptStackTrace
        }
    }
} else {
    # Log this computer
    Get-SystemInformation -ComputerName $env:COMPUTERNAME -IsLocal $true
}