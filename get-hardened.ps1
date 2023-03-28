<#
    .Synopsis
        This tool is used to harden a Windows operating system.  Initially intended for a Windows Home application.
        TODO: There is a set option as well in this.  
        TODO: Also there is a diff option too, to see what the harden csv settings you choose.
    .DESCRIPTION
        TODO:  Make this easily extensible
                
    Dependencies:
        
    
    Resources:
        Main resources this was combined from:
            https://github.com/0x6d69636b/windows_hardening
            https://github.com/Disassembler0/Win10-Initial-Setup-Script
            https://github.com/ssh3ll/Windows-10-Hardening

        I pulled from other sources as well and should be noted within.

    Cobbler: JimmyJames

        .EXAMPLE
            get-hardened.ps1 -preset default.preset
            
        This command will not run the backup process. 

        .EXAMPLE
            get-hardened.ps1 -preset default.preset -Backup
            
        This command will run the hardening with the default preset and do a backup.

#>

param(
    [Parameter(Mandatory = $false, HelpMessage = 'Please Enter path for harden_n config:')][string]$presetLocation,
    [Parameter(Mandatory = $false, HelpMessage = "Enter a path to store the logs if you wanna")][string]$log,
    [Parameter(Mandatory = $false, HelpMessage = "This is necessary if you wish to do a backup")][switch]$backup
)


#http://stackoverflow.com/questions/22509719/how-to-enable-autocompletion-while-entering-paths
Function Get-FileName {   
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = (get-location).path
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

Function open-directory {   
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $openFolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $openFolderDialog.ShowDialog() 
    return $openFolderDialog.SelectedPath
}


function IsAdmin() {  
    # Build the object first then query it below.
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        return $True
    }
    else {
        return $False
    }
}

# make sure the preset file is there
if (-not $presetLocation) {
    write-host "Please select the file to pull your presets from"
    $presetLocation = Get-FileName
}

# Make sure the script is run with Administrator privileges
if (-not (IsAdmin)) {
    Write-Warning("The script must be executed with Administrator privileges")
    return
}

if ($Backup) {
    # Let the user choose the registry backup destination directory
    write-host "Where would you like to backup the files?"
    $regBckpDir = open-directory
    if (!$regBckpDir) {
        Write-Warning("You must select a directory to save the .reg files")
        return
    }
    else {
        # backup existing reg files
        Write-Host("Backing up registry hives..")
        $reg = { 'hklm', 'hkcu', 'hkcr' }
        if (test-path -Path $regBckpDir\*.reg) {  
            for ($i = 0; $i -lt $reg.length; $i++) {
                move-item $regBckpDir\$reg[$i].reg $regBckpDir\$reg[$i].reg.bak$(Get-Date -format FileDateTime) 
                # Perform a backup of the interested Registry Hives
                reg export HKLM $regBckpDir\$reg[$i].reg | Out-Null
                Write-Host("$reg[$i] saved successfully")        
            }
            Write-Host("Done.")
        }
    }

}

# get the preset file settings
# regex to find every line that does not start with '#'
[regex]$getNoSet = "^#.*"
$presets = @()
# Get the content of the preset file and add to var
$allPresets = get-content $presetLocation 
# Loop through to find the valid setting line
foreach ($preset in $allPresets) {
    if ($preset -notmatch $getNoSet) {
        $presets += ($preset.Split("#")[0].Trim())
        
    }
}

# Import required modules
Import-Module ".\hardeningUtils.psm1"
# seperate each command in config
foreach ($config in $presets) {
    # only run if $config has a non empty string
    if ($config) {
        Invoke-Expression $config
    }
}



#TODOs
#  Services not disabling:  server, workstation, iphelper, RPCs, TCP/IP NetBIOS helper
#  App not uninstalling:  Tiktok, prime vid, Disney and some PS thing
#  Run a check routine maybe?  Like a self nmap or something?GET-=
#

