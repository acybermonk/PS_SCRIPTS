# Input Parameters*
    param(
        [parameter(Mandatory)]
        [string]$systemName,[string]$user,[string]$group
    )

Write-Host "Attepting connect to $systemName" -ForegroundColor Magenta

Invoke-Command -ComputerName $systemName -ScriptBlock {
    # Use passed variables in Invoke-Command request
    $systemName = $Using:systemName
    $user = $Using:user
    $group = $Using:group

    hostname
    Write-Host "Connection Successful"
    Write-Host "---------------------"
    Write-Host "Args =" 
    Write-Host "   - System: $systemName"
    Write-Host "   - User  : $user"
    Write-Host "   - Group : $group"
}
Start-Sleep -Seconds 3
