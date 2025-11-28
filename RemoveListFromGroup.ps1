<#
::================================================
::Tool to remove systems from Group
::Dec 2024
::================================================
#>

Set-StrictMode -Version Latest

# Import modules
Import-Module ActiveDirectory
# Check for Active Directory Module
Write-Host "--Starting script--"
$ModuleList = Get-Module -Name ActiveDirectory
if ($ModuleList -eq $null){
    Write-Host "ActiveDirectory Module : Not Present. Importing Module."
    Import-Module ActiveDirectory -Scope Global -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $ModuleList = Get-Module -Name ActiveDirectory
    if ($ModuleList -eq $null){
        Write-Host "ActiveDirectory Module : Not Present. Installing Module."
        Install-Module -Name ActiveDirectory -Scope AllUsers -Confirm:$false -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        Write-Warning "Close and Reopen"
        Pause
        Exit
    }else{
        Write-Host "ActiveDirectory Module : Present" -ForegroundColor Green
    }
}else{
    Write-Host "ActiveDirectory Module Present" -ForegroundColor Green
}
