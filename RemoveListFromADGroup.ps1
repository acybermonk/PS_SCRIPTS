<#
::================================================
::Tool to remove systems from CrashplanRollout Group
::Dec 2024
::================================================
#>

Set-StrictMode -Version Latest

# Import modules
Import-Module ActiveDirectory

#Test Path Permissions
$Path = "E:\Scripts\AD\RemoveGroup\"
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
# Removal Groups in array
$RemovalGroups = @("REMOVE_AD_GROUP")

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
    localLogWrite "$Date`n$user`n"
}

# Test File path exists
if (Test-Path -Path $Global:FilePath){
    $Global:ComputerList = Get-Content $Global:FilePath
    displayHeader

    # Loop through list
    foreach ($system in $Global:ComputerList){
        # Convert Data to strings

        #Write-Host "Computer target"
        foreach($groupTarget in $RemovalGroups){
            Write-Host "Attempting to remove $groupTarget from $system"
            try{
                $groupDist = Get-ADGroup -Identity $groupTarget -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
                $computerDist = Get-ADComputer -Identity $system -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
                Remove-ADGroupMember -Identity $groupDist -Members $computerDist -Confirm:$false
                Write-Host -ForegroundColor Green "Successfully removed $system from $groupTarget"
                localLogWrite "$system removed from $groupTarget"
                Get-Content $Global:FilePath | Select-String -Pattern $system -notmatch | Out-File $Global:FilePath
                localLogWrite "$system removed from $Global:FilePath" 
            }catch{
                Write-Error -Message "  ** ERROR: 02 ** Unable to remove $system from $groupTarget" -Category InvalidArgument
                localLogWrite "$system unable to be removed from $groupTarget"
            }
        }
    }
    localLogWrite "----------`n"
}else{
    Write-Host "Cannot find system removal list at '$FilePath'`nPlease check for file in directory"
    localLogWrite "Cannot find system removal list at '$FilePath'`nPlease check for file in directory"
}
