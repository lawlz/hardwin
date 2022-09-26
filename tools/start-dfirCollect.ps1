<#
.SYNOPSIS
   Get information about a Windows 10 system to perform ....  hardening...  no DFIR...  analysis.
.DESCRIPTION
   On systems with a restricted script execution policy, run: PowerShell.exe -ExecutionPolicy UnRestricted -File .\dfircollect.ps1

   This script needs at lesat PowerShell 2.0 (Windows 10)
.PARAMETER EvidenceId
   A string identifying the evidence. The output directory and zip file will have this name. Default: "evidence"
.PARAMETER ExportRegistry
   Export HKEY_LOCAL_MACHINE and HKEY_CURRENT_USER from the registry.
.PARAMETER ExportMFT
   Export the MFT of all partitions. RawCopy.exe must be present alongside this script.
.PARAMETER CollectLogs
   Collect logs.
.PARAMETER Complete
   Get all evidence from all sections.
.EXAMPLE
   ./dfircollect.ps1 -EvidenceId 12345
.EXAMPLE
   ./dfircollect.ps1 -EvidenceId 12345 -Complete
.NOTES
    Under the GPL license.
        THANK YOU!!!!!  -- jj
   (c) 2019, Juan Vera (juanvvc@gmail.com)
#>

# Configuration parameters from the command line
param(
    [string]$EvidenceId="evidence",
    [switch]$ExportRegistry,
    [switch]$ExportMFT,
    [switch]$CollectLogs,
    [switch]$Complete,
    [string]$RawCopyPath="$PSScriptRoot\RawCopy\RawCopy.exe",
    [string]$FlsPath="$PSScriptRoot\sleuthkit\bin\fls.exe",
    [string]$IcatPath="$PSScriptRoot\sleuthkit\bin\icat.exe"
)

Write-Host $RawCopyPath

# Internal configuration

# If complete, activate these sections
if ( $Complete ) {
    $ExportRegistry = $true
    $ExportMFT = $true
    $CollectLogs = $true
}

$OutputDirectory = $EvidenceId
$TotalSections = 7

Function Prepare-Section {
    <#
    .DESCRIPTION
    Prepare the environment to run a section
    .PARAMETER Index
    A string identifying the index of the section. For example: "01", "15"...
    .PARAMETER Name
    The description of the section.
    .PARAMETER Run
    Whether the section will be run.
    .PARAMETER Log
    A message to log run.
    .NOTES
    Returns the $Run parameter. Use in an If expression to run the commands of the section or not.

    $SectionPreffix will be set to the preffix to add to output files. If it is a directory, it will be created.
    #>
    param(
        [string]$Index='',
        [string]$Name='',
        [switch]$Run=$true,
        [string]$Log=''
    )
    $SectionName = "$Index-$Name"
    Set-Variable -Name "SectionPreffix" -Value "$Index-" -Scope Global
    # mkdir $SectionPreffix | Out-Null
    If ( $Log -eq '' ) {
        If ( $Run ) {
            Write-Host "($Index/$TotalSections) Running: $SectionName..."
        } Else {
            Write-Host "($Index/$TotalSections) Skipping: $SectionName." -ForegroundColor yellow
        }
    } Else {
        If ( $Run ) {
            Write-Host "($Index/$TotalSections) ${Log}: $SectionName..."
        } Else {
            Write-Host "($Index/$TotalSections) ${Log}: $SectionName." -ForegroundColor yellow
        }
    }
    Return $Run
}


####################### Start the process

$now = Get-Date
Write-Host "Starting the collection process. Output directory: $OutputDirectory. Date: $now" -ForegroundColor Green

# backup the previous files
# Remove-Item $OutputDirectory -Recurse -ErrorAction Ignore
# Remove-Item $OutputZipFile -ErrorAction Ignore
# Remove-Item $OutputHashFile -ErrorAction Ignore
if (!($backupFolder)){
    $backupFolder = "$OutputDirectory\backups"
    mkdir -path $backupFolder -force
}

# check to see if we need to create the output directory and change directory to it
if (!(test-path $OutputDirectory)){
    mkdir $OutputDirectory | Out-Null
}

Set-Location $OutputDirectory
# Metadata: date and current user
Write-Output $now | Out-File METADATA
whoami /ALL >> METADATA


####################### Machine and Operating system information

If ( Prepare-Section -Index "01" -Name "Machine and Operating system information" ) {
    # Basic system information
    Get-CimInstance Win32_OperatingSystem | Export-Clixml ${SectionPreffix}OperatingSystem.xml
    # Environment vars
    Get-ChildItem env: | Export-Clixml ${SectionPreffix}EnvironmentVars.xml
}

####################### Network

If ( Prepare-Section -Index "02" -Name "Network configuration and connectivity information" ) {
    # Traditional commands
    cmd /c "netstat -nabo > ${SectionPreffix}netstat.txt"
    # netstat, parsing the output to include process information
    $netstat = netstat -nao
    $NetstatProcessed = New-Object System.Collections.Generic.List[System.Object]
    Foreach ( $conn in $netstat[4..$netstat.count] ) {
        $data = $conn -replace '^\s+','' -split '\s+'
        $element = @{
            "Proto" = $data[0]
            "Local IP" = $data[1]
            "Remote IP" = $data[2]
            "Status" = $data[3]
            "Process PID" = $data[4]
            "Process Name" = ((Get-process | Where-Object {$_.ID -eq $data[4]})).Name
            "Process Path" = ((Get-process | Where-Object {$_.ID -eq $data[4]})).Path
            "Process StartTime" = ((Get-process | Where-Object {$_.ID -eq $data[4]})).StartTime
            "Process DLLs" = ((Get-process| Where-Object {$_.ID -eq $data[4]})).Modules |Select-Object @{Name='Modules';Expression={$_.filename -join'; '} }
        }
        $NetstatProcessed.Add((New-Object -TypeName PSObject -Property $element))
    }
    $NetstatProcessed | Export-Clixml ${SectionPreffix}ProcessedNetStat.xml
}


####################### Services, process and applications

If ( Prepare-Section -Index "03" -Name "Startup applications" ) {
    # Services run when the system starts
    Get-CimInstance win32_service -Filter "startmode = 'auto'" | Export-Clixml ${SectionPreffix}StartupServices.xml
    # Applications run when the system starts
    Get-CimInstance Win32_StartupCommand | Export-Clixml ${SectionPreffix}StartupCommands.xml
    Get-Process | Export-Clixml ${SectionPreffix}Process.xml
    Get-Service | Export-Clixml ${SectionPreffix}Service.xml
}

####################### Scheduled jobs

If ( Prepare-Section -Index "4" -Name "Scheduled jobs" ) {
    Get-ScheduledTask | Export-Clixml  ${SectionPreffix}ScheduledTask.xml
    Get-ScheduledJob | Export-Clixml  ${SectionPreffix}ScheduledJob.xml
    # Traditional commands
    cmd /c "schtasks /query > ${SectionPreffix}schtasks.txt"
    cmd /c "at > ${SectionPreffix}at.txt"
}

####################### Active network connections and related process

If ( Prepare-Section -Index "5" -Name "Active network connections and related process" ) {
    # active networks
    Get-NetConnectionProfile | Export-Clixml  ${SectionPreffix}NetConnectionProfile.xml
    # TCP connections (established, listening)
    Get-NetTCPConnection | Export-Clixml  ${SectionPreffix}NetTCPConnection.xml
    # UDP listeres
    Get-NetUDPEndpoint | Export-Clixml  ${SectionPreffix}NetUDPEndpoint.xml
}

####################### Hotfix

If ( Prepare-Section -Index "6" -Name "Hotfix" ) {
    Get-HotFix | Export-Clixml ${SectionPreffix}Hotfix.xml
}

####################### Installed applications

If ( Prepare-Section -Index "7" -Name "Installed applications" ) {
    # Installed applications according to wmic
    # This list doesn't include "applets" in the starting menu, nor windows utilities such as the clock
    get-ciminstance -class win32_product | Export-Clixml ${SectionPreffix}InstalledApplications.xml
    # WARNING: you will find in the Internet references to this command.
    # Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Format-Table –AutoSize > C:\Users\Lori\Documents\InstalledPrograms\InstalledProgramsPS.txt
    # In our experience, many installed applications are not listed using that command
}


####################### Convert files and create zip

If ( Prepare-Section -Index $TotalSections -Name "Converting files" ) {
     #Converts all XML files into CSV, for easy greps and rvt2, and human readable lists
    Get-ChildItem -path -File *xml -Recurse | ForEach-Object {
        Import-Clixml $_ | Export-Csv -NoTypeInformation ($_.FullName + ".csv")
        # Import-Clixml $_ | Format-List * | Out-File ($_.FullName + ".txt")
    }
}

# potentially remove
# Create ZIP and calculate its hash value
# Set-Location ..
# Compress-Archive -Path $OutputDirectory -DestinationPath $OutputZipFile
# Get-FileHash -Algorithm SHA256 $OutputZipFile | Export-Clixml $OutputHashFile

# $now = Get-Date
# $hash = Import-Clixml $OutputHashFile
# Write-Host "The collection process ended. Output file and hash: $hash. Date: $now" -ForegroundColor Green
