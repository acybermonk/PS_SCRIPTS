# Input Parameters*
    param(
        [parameter(Mandatory)]
        [string]$systemName,[string]$user,[string]$group
    )

    $login = Get-Credential -Message "Please sign for access."  -UserName $null | Out-Null
    #$user = $login.UserName

    $listPath = ""

    #$nameList = Get-Content -Path $listPath -Force

    $itsm_jasonFile = $null

    $itsm_jasonFile = ""

    $GET_REQUEST = ""

    Write-Host "** Attempting to make a ticket **" -ForegroundColor Yellow
    # Test if user can GET
    if ($GET_REQUEST){
        # Can GET; Now test POST
        
        # POST
        $POST_REQUEST
        if ($POST_REQUEST){

        }
    }else{
        # Failed to GET
        Write-Error " *ERR: cannot establish GET connection"
    }

    Write-Host "    $user Makeing a ticket: Deploy laptop for user $user" -ForegroundColor Green

Start-Sleep -Seconds 3
