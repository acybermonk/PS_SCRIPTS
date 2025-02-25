<#
::================================================
::Tool to add list of systems to AD Group
::Dec 2024
::================================================
#>

Set-StrictMode -Version Latest

# Import modules
Import-Module ActiveDirectory

#Test Path Permissions
$Path = "E:\Scripts\AD\AddGroup\"
if (Test-Path $Path){
    Set-Location -Path $Path
}else{
    Write-Error -Message "Access is denied for this user. Please sign in with correct credentials to run." -Category PermissionDenied
    Pause
    Exit
}

# Specify location of text document
$Global:FilePath = ".\computers.txt"
$Global:LocalLog = ".\#SUCCESS.log"
# Get date
$Date = Get-Date -DisplayHint Date
# Get User
$user = whoami
# Add Groups in array
$AddGroups = @("AD_GROUP_NAME")

# Count variables
$SuccessCount = 0
$FailCount = 0

# LocalLog write
function localLogWrite{
    Param ([string]$logstring)
    Add-Content $Global:LocalLog -Value $logstring
}

function displayHeader{
    # Write Title
    Write-Host -ForegroundColor Magenta "-----------------------------------"
    Write-Host -ForegroundColor Magenta "Data Pulled from $FilePath by $user"
    Write-Host -ForegroundColor Magenta "-----------------------------------"
    # log header
    localLogWrite "---------------"
    localLogWrite "$Date`n$user`n"
    localLogWrite "---------------"
}

function displayFooter{
    #Write Footer
    Write-Host -ForegroundColor Magenta "-----------------------------------"
    Write-Host -ForegroundColor Magenta "Completed List"
    Write-Host -ForegroundColor Magenta "-----------------------------------`n"
    Write-Host -ForegroundColor Magenta "Successful:  $SuccessCount"
    Write-Host -ForegroundColor Magenta "Fail:  $FailCount"
    localLogWrite "---------------"
    localLogWrite "Completed List"
    localLogWrite "---------------`n"
    localLogWrite "Successful:  $SuccessCount"
    localLogWrite "Fail:  $FailCount"
}

# Test File path exists
if (Test-Path -Path $Global:FilePath){
    $Global:ComputerList = Get-Content $Global:FilePath
    displayHeader

    # Loop through list
    foreach ($system in $Global:ComputerList){
        # Convert Data to strings

        #Write-Host "Computer target"
        foreach($groupTarget in $AddGroups){
            Write-Host "Attempting to add $groupTarget to $system"
            try{
                $groupDist = Get-ADGroup -Identity $groupTarget -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
                $computerDist = Get-ADComputer -Identity $system -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
                Add-ADGroupMember -Identity $groupDist -Members $computerDist -Confirm:$false
                Write-Host -ForegroundColor Green "Successfully added $system to $groupTarget"
                localLogWrite "$system added to $groupTarget"
                Get-Content $Global:FilePath | Select-String -Pattern $system -notmatch | Out-File $Global:FilePath
                localLogWrite "$system removed from $Global:FilePath" 
                $SuccessCount += 1
            }catch{
                Write-Error -Message "  ** ERROR: 02 ** Unable to add $system to $groupTarget" -Category InvalidArgument
                localLogWrite "$system unable to be added to $groupTarget"
                $FailCount += 1
            }
        }
    }
    displayFooter
    localLogWrite "--------------------"
    localLogWrite "--------------------`n"
}else{
    Write-Host "Cannot find system add list at '$FilePath'`nPlease check for file in directory"
    localLogWrite "Cannot find system add list at '$FilePath'`nPlease check for file in directory"
}
