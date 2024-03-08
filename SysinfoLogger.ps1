<#
.NOTES
    *****************************************************************************
    ETML
    Script name: Sysinfo Logger
    Author: Valentin PIGNAT, Sebastien TILLE
    Date: February 29th, 2024
    Url: https://github.com/wolfiiy/SysinfoLogger
    *****************************************************************************

.SYNOPSIS
    System information logging

.DESCRIPTION
    This script allows for easy system information logging. It can be used on the
    local computer or other Windows computer on the same network. The collected 
    data is written to a sysinfo.log file.

    Collected information (in order):
    - Hostname
    - OS, version and build number
    - IP
    - Package managers
    - CPU, GPU
    - Connected displays
    - Memory usage
    - Disk usage
    - Installed software

.PARAMETER Remote
    IP addresses of remote computers. Separate using a comma.

.PARAMETER Path
    Existing folder in which to save the log file. Do *not* include the file name.

.OUTPUTS
    The script logs the gathered data inside of the sysinfo.log file.
	
.EXAMPLE
	.\SysinfoLogger.ps1
    Result:
    ╔═══════════════════════════════════════════════════════════════════════════════╗
    ║                               SYSTEM INFO LOGGER                              ║
    ╟═══════════════════════════════════════════════════════════════════════════════╣
    ║ Log date: 2024.03.01 15:11:12                                                 ║
    ╙━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╜

    ┌ OPERATING SYSTEM
    | Hostname:     VM-ICT122
    | IP:           10.0.2.15
    | OS:           Microsoft Windows 11 Professionnel
    | Version:      10.0.22631 Build 22631
    | Packages:     winget.exe choco.exe
    └ Uptime:       01:22:49.5000000

    ┌ HARDWARE
    | CPU:          Intel(R) Core(TM) i7-8700 CPU @ 3.20GHz
    | GPU 0:        VirtualBox Graphics Adapter (WDDM)
    └ RAM:          4.63 / 7.99 Gb

    ┌ DISPLAYS
    | Moniteur non Plug-and-Play générique: x
    └ 1 display(s) in total

    ┌ STORAGE
    | C:            21.82 / 49.12 Gb, 44.42% used
    | D:            0.06 / 0.06 Gb, 100% used
    └ Found 2 partition(s)

    ┌ SOFTWARE
    | Microsoft Edge
    | Microsoft Edge Update
    | Microsoft Edge WebView2 Runtime
    | CIM Explorer
    | Git
    | Oracle VM VirtualBox Guest Additions 6.1.38
    | Microsoft Visual Studio Code
    └ 7 Program(s) or update(s) installed
#>

###################################################################################################################
# Parameters
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
        $Date = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
        $Hostname = (Get-CimInstance CIM_ComputerSystem).Name
        $IPAddress = (Get-NetIPAddress | Where-Object {$_.AddressFamily -eq 'IPv4' -and $_.InterfaceAlias -notmatch "loopback"}).IPAddress
        $OS = (Get-CimInstance -ClassName CIM_OperatingSystem)
        $OSName = $OS.Caption
        $OSVersion = $OS.Version
        $OSBuild = $OS.BuildNumber
        $Uptime = New-TimeSpan -Start $OS.LastBootUpTime -End $Date
        $PkgWinget = (Get-Command winget -ErrorAction SilentlyContinue).Name
        $PkgChoco = (Get-Command choco -ErrorAction SilentlyContinue).Name
        $PkgScoop = (Get-Command scoop -ErrorAction SilentlyContinue).Name
        $PkgManagers = "$PkgWinget $PkgChoco $PkgScoop"

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
            "Uptime" = $Uptime
            "PkgManagers" = $PkgManagers
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
    Write-Output "`n┌ OPERATING SYSTEM" | Tee-Object -file $FilePath -Append
    Write-Output "`| Hostname: `t$($SysInfo['Hostname'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| IP: `t`t$($SysInfo['IPAddress'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| OS: `t`t$($SysInfo['OSName'])" | Tee-Object -file $FilePath -Append
    Write-Output "`| Version: `t$($SysInfo['OSVersion']) Build $($SysInfo['OSBuild'])" | Tee-Object -file $FilePath -Append

    $InstalledPacman = $($SysInfo['PkgManagers'])
    if ($InstalledPacman.Length -gt 0) {
        Write-Output "`| Packages: `t$InstalledPacman" | Tee-Object -file $FilePath -Append
    }
    Write-Output "`└ Uptime: `t$($SysInfo['Uptime'])" | Tee-Object -file $FilePath -Append
    
    # Hardware
    Write-Output "`n┌ HARDWARE" | Tee-Object -file $FilePath -Append
    Write-Output "`| CPU: `t`t$($SysInfo['CPU'])" | Tee-Object -file $FilePath -Append
    foreach($VGA in $($SysInfo['GPU'])) {
        Write-Output "`| GPU $i`: `t$VGA" | Tee-Object -file $FilePath -Append
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
        $DiskUsed = [math]::Round($DiskSize - $DiskFree, 2)

        $EmptyDisk = 0
        if ($DiskSize -gt 0) {
            $DiskUsedPercent = [math]::Round($DiskUsed / $DiskSize * 100, 2)
            Write-Output "`| $DiskName `t`t$DiskUsed / $DiskSize Gb`, $DiskUsedPercent% used" | Tee-Object -file $FilePath -Append
        } else {
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
            
            if ($Password -ne $null) {
                $Password = ConvertTo-SecureString $Password -AsPlainText -Force
                $cred = new-object -typename System.Management.Automation.PSCredential ($HostName,$Password)
                New-PSSession -ComputerName $HostName -Credential $cred -erroraction 'silentlycontinue'
            } else {
                New-PSSession -ComputerName $HostName -Credential Get-Credential -erroraction 'silentlycontinue'
            }
            
            Get-SystemInformation -ComputerName $HostName -IsLocal $false
        } catch {
            Write-Error "Logging for $HostName failed." 
            Write-Host $_.ScriptStackTrace
        }
    }
} else {
    # Log this computer
    Get-SystemInformation -ComputerName $env:COMPUTERNAME -IsLocal $true
}
