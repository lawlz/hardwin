<#
    .Synopsis
        this will get all services status and backup that up
        There is a set option as well in this.  
        Also there is a diff option too, to see what the harden csv settings you choose.
    .DESCRIPTION
        TODO:  Make this easily extensible
                
    Dependencies:
        
    
    Resources:
        Two main resources this was combined from:
            https://github.com/Disassembler0/Win10-Initial-Setup-Script
            https://github.com/ssh3ll/Windows-10-Hardening

        I pulled from other sources as well.

    Cobbler: JimmyJames

        .EXAMPLE
            get-hardened.ps1 
#>

param(
 [Parameter(Mandatory=$false,HelpMessage='Please Enter path for harden_n config:')][string]$presetLocation,
 [Parameter(Mandatory=$false,HelpMessage="Enter a path to store the logs if you wanna")][string]$log,
 [Parameter(Mandatory=$false,HelpMessage="This is necessary if you don't wish to backup")][switch]$noBackup
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

# make sure the preset file is there
if (-not $presetLocation) {
    $presetLocation = Get-FileName
}
$presetLocation

# These next few lines are from ssh3ll/Windows-10-Hardening repo

# Make sure the script is run with Administrator privileges
# if (-Not ($IsAdmin))
# {
# 	Write-Warning("The script must be executed with Administrator privileges")
# 	return
# }

if (-not $noBackup){
    # Let the user choose the registry backup destination directory
    $regBckpDir = Get-Filename
    if (!$regBckpDir) {
        Write-Warning("You must select a directory to save the .reg files")
        return
    }
    else {
        # backup existing reg files
        Write-Host("Backing up registry hives..")
        $reg = {'hklm','hkcu','hkcr'}
        if (test-path -Path $regBckpDir\*.reg) {  
            for ($i = 0; $i -lt $reg.length; $i++) {
                move-item $regBckpDir\$reg[$i].reg $regBckpDir\$reg[$i].reg.bak$(Get-Date) 
                # Perform a backup of the interested Registry Hives
                reg export HKLM $regBckpDir\$reg[$i].reg | Out-Null
                Write-Host("$reg[$i] saved successfully")        
            }
            Write-Host("Done.")
        }
    }

}
# # add or remove settings
# Function AddOrRemoveSetting($settings) {
#     $selectedSettings = @()
#     foreach ($setting in $settings) {
#         If ($setting -like "^[!,#]") {
#             # If the name starts with exclamation mark (!), exclude the setting$setting from selection
#             $setting = Where-Object { $_ -ne $setting.Substring(1) }
#         } ElseIf ($setting -ne "") {
#             # Otherwise add the setting$setting
#             $selectedSettings += $setting
#         }
#     }
#     return $selectedSettings
# }

# get the preset file settings
[regex]$getNoSet = "^#.*"
$presets = @()
$allPresets = get-content $presetLocation 
$allpresets
foreach ($preset in $allPresets) {
    Write-Host $preset
    if($preset -notmatch $getNoSet) {
        $presets += ($preset.Split("#")[0].Trim())
        
    }
}

# Import required modules
Import-Module ".\Utils.psm1"
# seperate each command in config
foreach ($config in $presets) {
    # only run if $config has a non empty string
    if ($config) {
        write-host "running $config"
        Invoke-Expression $config
        
    }

}
