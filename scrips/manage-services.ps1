<#
    .Synopsis
        this will get all services status and backup that up
        There is a set option as well in this.  
        Also there is a diff option too, to see what the harden csv settings you choose.
    .DESCRIPTION
        TODO:  Make this easily extensible
                
    Dependencies:
        
    
    Resources:


    AUTHOR: JimmyJames

        .EXAMPLE
            manage-services.ps1
#>

Param(
    [Parameter(Mandatory=$false,HelpMessage='Please enter a valid backup location path')]$backupLocation,
    [Parameter(Mandatory=$false,HelpMessage='Please enter a valid working folder path')]$workingFolder,
    [Parameter(Mandatory=$false,HelpMessage='Please enter a path to your proposed service csv settings')]$setFile,
    [Parameter(Mandatory=$false,HelpMessage='Please enter a path to your proposed diff file settings')]$diffFile,
    [Parameter(Mandatory=$false,HelpMessage='Please enter a path to your proposed backup name tag for file')]$backupName,
    [parameter(Valuefrompipeline=$true)][switch]$set = $false,
    [parameter(Valuefrompipeline=$true)][switch]$force = $false,
    [parameter(Valuefrompipeline=$true)][switch]$diff = $false,
    [parameter(Valuefrompipeline=$true)][switch]$backup = $false
)

Function Get-FileName {   
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $env:USERPROFILE
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}

#check for working folder
Function create-working {

}


Function compare-service {
    Param(
        [Parameter(Mandatory=$false,HelpMessage='Please enter the new service config')]$differentService,
        [Parameter(Mandatory=$true,HelpMessage='Get me the old config')]$runService
    )

    $testTrue = @()
    # we have to go through both lists of services, old and new
    foreach ($srvNewStatus in $differentService){
        foreach ($srvOldStatus in $runService){
            if($serNewStatus.name -eq $srvOldStatus.name) {
                write-host "Checking $srvNewStatus"
                $comparez = compare-object -referenceObject $srvOldStatus.status -DifferenceObject $srvNewStatus.status
                if($comparez){
                    write-host "setting " + $srvNewStatus.name + " to " + $srvNewStatus.startup
                    $testTrue += set-service -name $srvNewStatus.name -StartupType $srvNewStatus.startup 
                }

            }
        }
    }
    return $testTrue


}

#todo, make these into functions
#function obtain-service{}
$services = get-service 
#this is a way to create a custom object quickly.  Kinda odd how it works..
$serviceStatus = foreach ($serve in $services) {
    [PSCustomObject]@{Name=$serve.name;
                    status=$serve.status;
                    description=$serve.DisplayName;
                    startup=$serve.StartType}
}
#TODO create a function
if (!($workingFolder)){
    $workingFolder = (get-location).path
    mkdir -path $workingFolder -force
}


#get backup location if not set and then backup current service config
if ($backup) {
    if (!($backupFolder)){
        $backupFolder = "$workingFolder\backups"
        mkdir -path $backupFolder -force
    }
    #backup the file
    $serviceStatus | export-csv -path "$backupFolder\services$(get-date -uformat %Y%m%d).csv" -NoTypeInformation
}
if($diff){
    if(!($diffFile)) {
        $diffFile = Get-FileName
        $newSetting = ConvertFrom-Csv -InputObject (get-content $diffFile)
    }
    $difference = compare-object $serviceStatus $newSetting
    write-host "The difference is here:" 
    $difference
}

# if you are going to set the services
if($set) {
    #check for admin on set?
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if ($isAdmin){
        if(!($setFile)){
            write-host "Please choose the file to use in order to apply settings"
            $setFile = Get-FileName 
        }
        $updates = ConvertFrom-Csv -InputObject (get-content $setfile)
        $compared = compare-service -runService $serviceStatus -differentService $updates
        if($compared) {
            # since there are differences, going to backup the running config
            if (!($backupFolder)){
                $backupFolder = "$workingFolder\backups"
                mkdir -path $backupFolder -force
            }
            #backup the file
            $serviceStatus | export-csv -path "$backupFolder\$(get-date -uformat %m%d)servicesBackup.csv" -NoTypeInformation
            # now set the services
            foreach ($service in $updates){
                write-host "now setting " + $service.name
            }
        }
        else {
            write-host "The running configuration is the same as the set location No further action"
        }

    }
    else {
        write-host "$($env:USERNAME) is not an admin..."
    }
}


