#--------------------------------------------------------------------------------------------------
# ** PRODUCTION SCRIPT **
# check functionality on test server then move to prod

# Script to create tickets in bulk for list of userss being Deployed new systems

# Will need to have working credentials for connecting to the ITSM (Cherwell); Valid Service Group account is needed to authenticate

# REQUIREMENTS
# Will need a txt file locally with the Field IDs of the technicians to be assigned
# Will need a txt file locally with the user names that the tickets will be associated for

#--------------------------------------------------------------------------------------------------


# Log File ad function for logging
$logFile = .\CreateBulkTicket.log"

function Log-Message($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = $timestamp + " - " + $message
    Add-Content -Path $logFile -Value $logLine
    #Write-Host $logLine
}

# Set server login variables
$test_serverName = "test_server.domain.com"
$prod_serverName = "prod_server.domain.com"

# Select server
$server = $prod_serverName

# Set API Key variables
$test_apiKey = "API-KEY-ID-HERE" # Test API Key
$prod_apiKey = "API-KEY-ID-HERE" # Prod API Key

# Select API Key
$apiKey = $prod_apiKey

Write-Warning "*** Running in Prod ***"

$baseUri = "https://$server/CherwellAPI"
$tokenResponse = $null

# Get an access token
$tokenUri = "$baseUri/token"
$authMode = "Windows"

# Get password from user terminal
#$password = Read-Host "**Password Required** "
$Cred = Get-Credential -Message "Enter ITSM Service Credentials (PROD)"

If ($Cred -eq $null -or $Cred -eq "" -or $Cred -eq " "){
    Write-Host "Invalid or Missing Credentials"
    exit 
}
# Ticket requested by list from file
$usersPath = ".\usernames.txt"
$technicanPath = ".\technicians.txt"

<#

# Requires to enter file path (Copy as path)
$usersPath = Read-Host "Enter full file PATH for USERNAMES"
$usersPath = $usersPath.Trim('"')
$usersPath = $usersPath.Trim("'")

# Requires to enter file path (Copy as path)
$technicanPath = Read-Host "Enter full file PATH for Technicians"
$technicanPath = $technicanPath.Trim('"')
$technicanPath = $technicanPath.Trim("'")


#>

if (-not (Test-Path $usersPath)){
    Write-Error "ERR: USERNAMES File Path INVALID"
}else{
    # Get user list from file
    $userList = Get-Content -Path $usersPath -Force

    if (-not (Test-Path $technicanPath)){
        Write-Error "ERR: TECHNICIANS File Path INVALID"
    }else{
        $techList = Get-Content -Path $technicanPath -Force
        
        # Token body
        $tokenRequestBody =
        @{
            Accept = "application/json";
            grant_type = "password";
            client_id = $apiKey;
            Credential = $Cred;
            username = $Cred.UserName
            password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Cred.Password));
        }

        #write out URL
        #Log-Message "`nURL:"
        #Log-Message "------"
        #Log-Message "${tokenUri}?auth_mode=${authMode}&api_key=${apiKey}`n"

        # Get Token
        $tokenResponse = Invoke-RestMethod -Method POST -Uri "${tokenUri}?auth_mode=${authMode}&api_key=${apiKey}" -Body $tokenRequestBody

        # Check if tokenresponse was successfull
        if ($tokenResponse -ne $null -or $tokenResponse -eq ""){
            Write-Host "Token Response was successfull`nGenerating Tickets. Please wait.`n" -ForegroundColor Green
            #Write-Host $tokenResponse.access_token
        }else{
            Write-Host "Token Response failed`n" -ForegroundColor Red
            Exit
        }

        # Create the Ticket template
        # Temp ticket

        $headers = @{
            Authorization = "Bearer $($tokenResponse.access_token)"
            Accept = "application/json"
        }

        $boSummary = Invoke-RestMethod -Method Get -Uri "${baseUri}/api/V1/getbusinessobjectsummary/busobname/Incident" -Headers $headers
        $busObId = $boSummary.busObId
        Log-Message "Business Object ID : $busObId"

        $userCount = $null
        $techCount = $null
        [int]$techIndex = 0
        [int]$count = 0

        if ($userList -ne $null){
            $userCount = $userList.Count
        }else{
            Write-Error -Message "   ***ERR User acount list empty in file"
            if ($techList -eq $null){
                Write-Error -Message "   ***ERR Tech acount list empty in file"
            }
            exit         
        }
        if ($techList -ne $null){
            $techCount = $techList.Count
        }else{
            Write-Error -Message "   ***ERR Tech acount list empty in file"
            exit
        }

        [int]$techSplit = [math]::floor($userCount/$techCount)
        [int]$rem = ($userCount - ($techCount*$techSplit)) + $techSplit

        Write-Host "User Count = " $userCount
        #Write-Host "UserList : " $userList
        Write-Host "Tech Count = " $techCount
        #Write-Host "TechList : " $techList
        Write-Host "Split = " $techSplit
        Write-Host "Remaining for to last tech = " $rem

        [System.Collections.ArrayList]$assigned = @()

        <##>

        foreach ($user in $userList){
            if (-not ($user -eq $null -or $user -eq "" -or $user -eq " ")){
                # if last tech on list they get added  the remainder of list
                if ($techIndex -eq ($techCount - 1)){
                    $tech = $techList[$techIndex]
                    $count = $count + 1
                    Write-Host "Assigning Ticket to LAST" $tech -ForegroundColor Yellow
                }else{
                    $tech = $techList[$techIndex]
                    Write-Host "Assigning Ticket to" $tech -ForegroundColor Yellow
                    $count = $count + 1
                    if ($count -eq $techsplit){
                        $techIndex = $techIndex + 1
                        $count = 0
                    }
                }
                try{
                    $payload = @{
                    busObId = $busObId
                        fields = @(
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Submitted ITSSID"; value = "SUBMITTED_ID"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Customer ID"; value = "VALUE_ID_HERE"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Owned By ID"; value = "$tech"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Owned By Team ID"; value = "VALUE_ID_HERE"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Service"; value = "SERVICE_TYPE"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Category"; value =  "CATEGORY_TYPE"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Subcategory"; value = "SUBCATEGORY_TYPE"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Description"; value = "DESCRIPTION_HERE"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Priority"; value = "3"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "Short Description"; value = "(AutoTicket)SHORT_DESCRIPTION_HERE"; dirty = 'true' },
                            @{ fieldID = "FIELD_ID_HERE"; displayName = "BypassSFRequiredFields"; value = "true"; dirty = 'true' }
                        )
                    }

                    $payload_json = Write-Output ($payload) | ConvertTo-Json
                    #Write-Host $payload_json
        
                    #write out URL
                    #Log-Message "`nURL: (For Business object)"
                    #Log-Message "------"
                    #Log-Message "${baseUri}/api/V1/savebusinessobject"

                    $response = Invoke-RestMethod -Method Post -Uri "${baseUri}/api/V1/savebusinessobject" -Headers $headers -Body ($payload | ConvertTo-Json -Depth 10) -ContentType "application/json"
                    $logMessage = "Ticket created : " + $response.busObPublicId + " for user $user"
                    Log-Message $logMessage
                    Write-Host "Ticket created : " $response.busObPublicId " for user " $user
                    $assigned.Add("$user") | Out-Null

                    $response = $null

                }catch{
                    Write-Error -Message  "    **ERR** Unable to create ticket; USER-$user; TECHID-$tech"
                    Log-Message "    **ERR** Unable to create ticket; USER-$user; TECHID-$tech"

                }
            }
            #Add delay
            Start-Sleep -Seconds 10
        }
        if ($assigned.Count -ge 1){
            foreach ($user in $assigned){
                #remove succsessful to text file
                $newFileText = Get-Content $usersPath | Select-String -Pattern $user -notmatch
                Set-Content -Path $usersPath -Value $newFileText
                Log-Message "  * Removing Successful $user"
            }
        }
        #>
    }
}
