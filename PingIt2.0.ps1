# Get contents of computers to ping
Set-StrictMode -Version Latest

#Test Path Permissions
$Path = "E:\Scripts\MISC\PingIt"
if (Test-Path $Path){
    Set-Location -Path $Path
}else{
    Write-Error -Message "Access is denied for this user. Please sign in with correct credentials to run." -Category PermissionDenied
    Pause
    Exit
}

# Specify Script Type 
$Global:ScriptType = Read-Host "Enter script type i.e. cmd/ps "
if ($Global:ScriptType -ne "cmd" -and $Global:ScriptType -ne "ps"){
    Write-Host "Error invalid type. Closing Script"
    Pause
}else{
    # Specify location of text document
    $Global:FilePath = Read-Host "Enter data file "
    #$Global:FilePath = ".\data.txt"
    #$Global:FilePath = ".\data2.txt"
    
    # Specify location of the success log file
    $Global:LocalLog = ".\#SUCCESS.log"
    
    # Specify Script Path to run 
    $Global:ScriptPath = Read-Host "Enter Script Local Folder Path "
    #$Global:ScriptPath = "\bat_files\addADM.bat"
    #$Global:ScriptPath = "\bat_files\remADM.bat"
    #$Global:ScriptPath = "\ps_files\cpS1fix.ps1"
    if (-not (Test-Path -Path "$Path$Global:ScriptPath")){
        Write-Host "Error script path. Closing Script"
        Pause
    }else{
        # Get date
        $Global:Date = Get-Date -DisplayHint Date
        function getDate{
            $Global:Date = Get-Date -DisplayHint Date
        }
        # Get User
        $username = whoami
        [System.Collections.ArrayList]$Global:found = @()
        $Global:i = 0
        $c = 0
        #$Global:tryCount = 288 # 24hrs
        $Global:tryCount = 574 # 24hrs
        $sleep = 300 # 5 minutes
        $Global:dataCount = 0
        [System.Collections.ArrayList]$Global:ComputerList = @()
        
        # LocalLog write
        function localLogWrite{
            Param ([string]$logstring)
            Add-Content $Global:LocalLog -Value $logstring
        }
        
        function displayHeader{
            # Write Title
            Write-Host -ForegroundColor Magenta "-----------------------------------"
            Write-Host -ForegroundColor Magenta "Data Pulled from $FilePath by $username"
            Write-Host -ForegroundColor Magenta "-----------------------------------"
            Write-Host -ForegroundColor Magenta "Attempts : $Global:tryCount"
            getDate
            localLogWrite "Start : $Global:Date`n$username"
            localLogWrite "Attempts : $Global:tryCount"
        }
        displayHeader
        getDate
        localLogWrite "Starting Auto Run : $Global:Date"
        Write-Host -ForegroundColor Magenta "Starting Auto Run : $Date"
        
        function doIt{
            # Test File path exists
            if (Test-Path -Path $Global:FilePath){
                $list = Get-Content $Global:FilePath
                foreach ($value in $list){
                    $Global:ComputerList += $value
                }
                if($Global:ComputerList.Count -gt 0){
                    $Global:dataCount = $Global:ComputerList.count
                }else{
                    Write-Output("*COMPLETED ALL DATA*")
                    localLogWrite "*COMPLETED ALL DATA*"
                    exit
                }
                Write-Host -ForegroundColor Magenta "Systems remaining $Global:dataCount"
                # Loop through list
                foreach ($data in $Global:ComputerList){
                    #[console]::beep(300,250)
                    # Convert Data to strings
                    $data = $data.ToString()
                    $dataSplit = $data -split ";"
                    $system = $dataSplit[0]
                    $user = $dataSplit[1]
                    $group = $dataSplit[2]
                    # ping it
                    $pingCheck = ping $system -n 1
        
                    if ($pingCheck -like "reply*"){
                        Write-Output("$system is Online")
                        # system is online
                        localLogWrite "$system is Online"
                        try{
                            # run cmd command or bat file
                            #[console]::beep(713,266)
                            # log header
                            getDate
                            localLogWrite "Running Process : $Date`n$username;System $system;User $user"
        
                            if ($scriptType = "cmd"){
                                $process = Start-Process -Wait -PassThru -FilePath "cmd" -Verb RunAs -ArgumentList "/c $Path\$Global:ScriptPath $system $user $group"
                            }
                            if ($scriptType = "ps"){
                                $process = Start-Process -Wait -PassThru -FilePath "powershell" -Verb RunAs -ArgumentList "$Path\$Global:ScriptPath",$system,$user,$group
                            }
                            
                            # process was successful
                            $processErrCode = $process.ExitCode
                            Write-Output("  **Process Completed with ErrorCode $processErrCode")
                            localLogWrite "  **Process Completed with ErrorCode $processErrCode"
                            $Global:found.Add("$data") | Out-Null
                        }catch{
                            # fail to open cmd
                            Write-Error "  **Process FAILED" 
                            localLogWrite "  **Process FAILED"
                        }
                    }elseif ($pingCheck -like "Request timed out."){
                        Write-Output("$system request timed out")
                    }elseif ($pingCheck -like "Ping request could not find host*"){
                        Write-Output("$system is Offline")
                    }elseif ($pingCheck -like "Destination Host Unreachable*"){
                        Write-Output("$system is unreachable")
                    }else {
                        Write-Output("unkown value error : $system")
                        Write-Output("PINGCHECK : $pingCheck")
                    }
                }
                if ($Global:found.Count -ge 1){
                    Write-Output("_____")
                    #Write-Output($Global:found)
                    foreach ($d in $Global:found){
                        Write-Output("Removing : ${d}")
                        localLogWrite "Removed ${d}"
                        $c += 1
                        $out = Get-Content $Global:FilePath | Select-String -Pattern $d -notmatch 
                        Set-Content -Path $Global:FilePath -Value $out
                    }
                    Write-Output("..")
                    if ($c -ne 0){
                        Write-Output("Remove Count : ${c}")
                    }
                    Write-Output("_____")
                    localLogWrite "*---------------------------*"
                }
                $Global:tryCount = $Global:tryCount - 1
                Write-Host -ForegroundColor Magenta "Attempts remaining : ${Global:tryCount}"
                Write-Host -ForegroundColor Magenta "*---------------------------*"
                if ($Global:tryCount -gt 0){
                    if (($Global:dataCount - $c) -gt 0){
                        [System.Collections.ArrayList]$Global:found = @()
                        [System.Collections.ArrayList]$Global:ComputerList = @()
                        $c = 0
                        $data = $null
                        $dataSplit = $null
                        $system = $null
                        $user = $null
                        $pingCheck = $null
                        $Global:dataCount = 0
                        $minutes = $sleep / 60
                        Write-Host -ForegroundColor Magenta "Sleep for ${minutes} minutes. Please wait..."
                        Start-Sleep -Seconds $sleep
                        doIt
                    }else{
                        Write-Output("*COMPLETED ALL DATA*")
                        localLogWrite "*COMPLETED ALL DATA*"
                    }
                }else{
                    Write-Output("*COMPLETED ALL ATTEMPTS*")
                    localLogWrite "*COMPLETED ALL ATTEMPTS*"
                    #Pause
                    exit
                }
            }else{
                Write-Output("Cannot find system removal list at '$FilePath'`nPlease check for file in directory")
                localLogWrite "Cannot find system removal list at '$FilePath'`nPlease check for file in directory"
            }
        }
        doIt
    }
}
