# Windows 10/11 Auto Patch installer
# Created by Daniel Krysty; Updated December 2024

# User and system ENV vars saved 
$Global:SystemName = $env:COMPUTERNAME
$Global:User = $env:USERNAME

# Gather system data
$Global:InstallPath = "APP_REPO_FOLDER_PATH"
$Global:TempPath = "C:\TempFolder"
$Global:LocalLog = "C:\ProgramData\MyLogs\$Global:SystemName`_$Global:User`_AutoPatch.log"
$Global:PatchFolder = "2025-02"
$Global:ProcessName = "Windows Updates : Auto Patch Installer (Win-10/Win-11)"
$GetComputerInfo = ""
$GetManufacturer = ""
$GetOS = ""
$GetWinVersion = ""
$Global:Reboot = $false

# Sleep variables #from TJs script to disable idle settings while script is running
$function=@' 
[DllImport("kernel32.dll", CharSet = CharSet.Auto,SetLastError = true)]
    public static extern void SetThreadExecutionState(uint esFlags);
'@
$method = Add-Type -MemberDefinition $function -name System -namespace Win32 -passThru 
#Specify the flags to use them later
$Global:ES_CONTINUOUS = [uint32]'0x80000000'
$Global:ES_AWAYMODE_REQUIRED = [uint32]'0x00000040'
$Global:ES_DISPLAY_REQUIRED = [uint32]'0x00000002'
$Global:ES_SYSTEM_REQUIRED = [uint32]'0x00000001'

Write-Host -ForegroundColor Magenta $Global:ProcessName

# LocalLog write
function localLogWrite{
    Param ([string]$logstring)
    Add-Content $Global:LocalLog -Value $logstring
}

# Activate the sleep/idle state
function activateSleep{
    Write-Host -ForegroundColor Yellow "** Setting PC to original sleep state **"
    try{
        #Restoring saving mechanisms
        $method::SetThreadExecutionState($Global:ES_CONTINUOUS)
        Write-Host -ForegroundColor Green "  Sleep activation successful"
        localLogWrite "Sleep : Activation successful"
    }catch{
        Write-Error -Message "  ERROR: Sleep activation failed" -Category InvalidArgument
        Write-Host -ForegroundColor Red "  Sleep activation failed"
        localLogWrite "Sleep : Activation failed"
    }
}

function deactivateSleep{
    Write-Host -ForegroundColor Red "** Setting PC to stay awake ** DO NOT CLOSE WINDOW **"
    try{
        #Configuring the system to ignore any energy saving technologies
        $method::SetThreadExecutionState($Global:ES_SYSTEM_REQUIRED -bor $Global:ES_DISPLAY_REQUIRED -bor $Global:ES_CONTINUOUS)
        Write-Host -ForegroundColor Green "  Sleep deactivation successful"
        localLogWrite "Sleep : Deactivation successful"
    }catch{
        Write-Error -Message "  ERROR: Sleep deactivation failed" -Category InvalidArgument
        Write-Host -ForegroundColor Red "   Sleep deactivation failed"
        localLogWrite "Sleep : Deactivation failed"
    }
}

# Check if TempFolder exists
function checkTemp{
    # Check TempFolder exists and clear old data; make new TempFolder
    Write-Host '** Check TempFolder **' -ForegroundColor Yellow
    if (Test-Path $Global:TempPath){
        Write-Host '  TempFolder exists.' -ForegroundColor DarkGray
        localLogWrite "TempFolder : Does exist"
        try{
            Remove-Item -Path $Global:TempPath -Recurse -Force
            Write-Host '  Old TempFolder data removed' -ForegroundColor Green
            localLogWrite "TempFolder : Removed"
        }catch{
            Write-Error -Message "  ERROR: Cannot remove file" -Category InvalidArgument
            localLogWrite "TempFolder : Failed to be removed"
        }
        Write-Host '  Creating/Overwriting TempFolder' -ForegroundColor Green
        $tempFolder = New-Item -Path "C:\" -Name "TempFolder" -ItemType "Directory" -Force 
        Write-Host -ForegroundColor Yellow '** Verifying TempFolder and Install directory connections **'
        if (Test-Path $Global:TempPath){
            Write-Host '  TempFolder path is good' -ForegroundColor Green
            localLogWrite "TempFolderPath : Good"
            if (Test-Path $Global:InstallPath){
                Write-Host '  Install path is good' -ForegroundColor Green
                localLogWrite "Install path : Good"
            }else{
                Write-Host '  Install path is failed' -ForegroundColor Green
                localLogWrite "Install path : Failed"
                exit
            }
        }else{
            Write-Host '  TempFolder path is failed' -ForegroundColor Green
            localLogWrite "TempFolder path : Faled"
            exit
        }
    }else{
        Write-Host '  TempFolder does not exist' -ForegroundColor Green
        localLogWrite "TempFolder : Does not exist"
        # Create a new TempFolder directory
        Write-Host '  Creating TempFolder' -ForegroundColor Green
        localLogWrite "TempFolder : Creating"
        $tempFolder = New-Item -Path "C:\" -Name "TempFolder" -ItemType "Directory"
        Write-Host -ForegroundColor Yellow '** Verifying TempFolder and Install directory connections **'
        if (Test-Path $Global:TempPath){
            Write-Host '  TempFolder path is good' -ForegroundColor Green
            localLogWrite "TempFolder path : Good"
            if (Test-Path $Global:InstallPath){
                Write-Host '  Install path is good' -ForegroundColor Green
                localLogWrite "Install path : Good"
            }else{
                Write-Host '  Install path is failed' -ForegroundColor Green
                localLogWrite "Install path : Failed"
                exit
            }
        }else{
            Write-Host '  TempFolder path is failed' -ForegroundColor Green
            localLogWrite "TempFolder path : Faled"
            exit
        }
    }
}

# Remove TempFolder
function removeFolder{
    Write-Host '** Removing Temp Folder **' -ForegroundColor Yellow
    if (Test-Path $Global:TempPath){
        Remove-Item -Path $Global:TempPath -Recurse -Force
        localLogWrite "TempFolder : Removing"
    }
    if (Test-Path $Global:TempPath){
        Write-Host '  Temp Folder has not been removed. Please remove manually' -ForegroundColor Red
        localLogWrite "TempFolder : Not removed"
    }else{
        Write-Host '  Temp Folder has been removed' -ForegroundColor Green
        localLogWrite "TempFolder : Removed"
    }
}

# Check Temp Folder
checkTemp

# Gather Data : shown in log
Write-Host -ForegroundColor Yellow '** Gathering Data **'
localLogWrite "--DATA PULL--"
$GetComputerInfo = Get-ComputerInfo
# Get Manufacturer
$GetManufacturer = Get-ComputerInfo | Select-Object -expand CsManufacturer
Write-Host -ForegroundColor Green "  Manufacturer : $GetManufacturer"
localLogWrite "MANUFACTURER"
localLogWrite "*********"
localLogWrite $GetManufacturer
localLogWrite "---------"
# Get System OS
$GetOS = Get-ComputerInfo | Select-Object -expand OsName
Write-Host -ForegroundColor Green "  OS : $GetOS"
localLogWrite "OS"
localLogWrite "*********"
localLogWrite $GetOS
localLogWrite "---------"
# Get OS VERSION 22H2 or 23H2
$GetWinVersion = [System.Environment]::OSVersion.Version.Build
Write-Host -ForegroundColor Green "  WinVer : $GetWinVersion"
localLogWrite "WINDOWS VERSION"
localLogWrite "*********"
localLogWrite $GetWinVersion
localLogWrite "---------"


# Windows Update
Write-Host "** Windows Update - $Global:PatchFolder **" -ForegroundColor Yellow
Write-Host "** Please make sure your PC is plugged in before you continue **" -ForegroundColor Yellow
Pause
# Check OS Version
if ($GetOS -match "10"){ #### WINDOWS 10
    if($GetWinVersion -eq 19045){ #### 19045 = 22H2
        deactivateSleep
        Write-Host "  You are using $GetOS 22H2; Getting correct Windows 10 Patches for 22H2" -ForegroundColor Gray
        
        # Create Patches Directory
        $patches10 = New-Item -Path "$Global:TempPath" -Name "Patches" -ItemType "Directory"

        # Copy Patches Directory
        Copy-Item "$Global:InstallPath\Patches\Windows10\w10-22h2" -Destination "$Global:TempPath\Patches" -Force -Recurse

        # Get KBs from Directory
        $PatchPath = "$Global:TempPath\Patches\w10-22h2\$Global:PatchFolder"
        $PatchContents = Get-ChildItem -Path $PatchPath -Recurse
        Write-Host "  Installing all from '\w10-22h2\$Global:PatchFolder'" -ForegroundColor Gray

        # Install Windows 10 updates
        foreach ($patch in $PatchContents){
            # Loop through folder of patches
            $kb = (Get-Item "$PatchPath\$patch").BaseName

            # Install Patch
            # check Hot-Fix
            if (-not(Get-Hotfix -id $kb -ErrorAction SilentlyContinue)){
                $Global:ProcessName = "Window Update $kb"
                Write-Host "  $kb is not installed" -ForegroundColor Gray
                Write-Host "  Installing Patch : $kb" -ForegroundColor Green
                try{
                    Start-Process -FilePath "wusa.exe" -ArgumentList "$PatchPath\$patch /quiet /norestart" -Wait
                    Write-Host "  $kb install complete; Restart required" -ForegroundColor DarkGray
                    localLogWrite "$Global:ProcessName - $kb : Successful"
                    $Global:Reboot = $true
                }catch{
                    Write-Error -Message "  ERROR: $kb install failed  " -Category InvalidArgument
                    localLogWrite "$Global:ProcessName - $kb : Failed"
                }
            }else{
                Write-Host "  $kb is already installed; Skipping installation"
                localLogWrite "$Global:ProcessName - $kb : Skipped"
            }
        }
        activateSleep
    }else{
        Write-Host "$GetWinVersion is not a valid WindowsVersion"
        locallogwrite "WinUPDATE WinVersion : Build Number Failed"
    }            
}elseif($GetOS -match "11"){ #### WINDOWS 11
    if($GetWinVersion -eq 22631){ #### 22631 = 23H2
        deactivateSleep
        Write-Host "  You are using $GetOS 23H2; Getting correct Windows 11 Patches for 23H2" -ForegroundColor Gray
        
        # Create Patches Directory
        $patches11 = New-Item -Path "$Global:TempPath" -Name "Patches" -ItemType "Directory"

        # Copy Patches Directory
        Copy-Item "$Global:InstallPath\Patches\Windows11\w11-23h2" -Destination "$Global:TempPath\Patches" -Force -Recurse

        # Get KBs from Directory
        $PatchPath = "$Global:TempPath\Patches\w11-23h2\$Global:PatchFolder"
        $PatchContents = Get-ChildItem -Path $PatchPath -Recurse
        Write-Host "  Installing all from '\w11-23h2\$Global:PatchFolder'" -ForegroundColor Gray

        # Install Windows 11 updates
        foreach ($patch in $PatchContents){
            # Loop through folder of patches
            $kb = (Get-Item "$PatchPath\$patch").BaseName

            # Install Patch
            # check Hot-Fix
            if (-not(Get-Hotfix -id $kb -ErrorAction SilentlyContinue)){
                $Global:ProcessName = "Window Update $kb"
                Write-Host "  $kb is not installed" -ForegroundColor Gray
                Write-Host "  Installing Patch : $kb" -ForegroundColor Green
                try{
                    Start-Process -FilePath "wusa.exe" -ArgumentList "$PatchPath\$patch /quiet /norestart" -Wait
                    Write-Host "  $kb install complete; Restart required" -ForegroundColor DarkGray
                    localLogWrite "$Global:ProcessName - $kb : Successful"
                    $Global:Reboot = $true
                }catch{
                    Write-Error -Message "  ERROR: $kb install failed  " -Category InvalidArgument
                    localLogWrite "$Global:ProcessName - $kb : Failed"
                }
            }else{
                Write-Host "  $kb is already installed; Skipping installation"
                localLogWrite "$Global:ProcessName - $kb : Skipped"

            }
        }
        activateSleep
    }elseif($GetWinVersion -eq 22621){ #### 22621 = 22H2
        deactivateSleep
        Write-Host "  You are using $GetOS 22H2; Getting correct Windows 11 Patches for 22H2" -ForegroundColor Gray
        
        # Create Patches Directory
        $patches11 = New-Item -Path "$Global:TempPath" -Name "Patches" -ItemType "Directory"

        # Copy Patches Directory
        Copy-Item "$Global:InstallPath\Patches\Windows11\w11-22h2" -Destination "$Global:TempPath\Patches" -Force -Recurse

        # Get KBs from Directory
        $PatchPath = "$Global:TempPath\Patches\w11-22h2\$Global:PatchFolder"
        $PatchContents = Get-ChildItem -Path $PatchPath -Recurse
        Write-Host "  Installing all from '\w11-22h2\$Global:PatchFolder'" -ForegroundColor Gray

        # Install Windows 11 updates
        foreach ($patch in $PatchContents){
            # Loop through folder of patches
            $kb = (Get-Item "$PatchPath\$patch").BaseName

            # Install Patch
            # check Hot-Fix
            if (-not(Get-Hotfix -id $kb -ErrorAction SilentlyContinue)){
                $Global:ProcessName = "Window Update $kb"
                Write-Host "  $kb is not installed" -ForegroundColor Gray
                Write-Host "  Installing Patch : $kb" -ForegroundColor Green
                try{
                    Start-Process -FilePath "wusa.exe" -ArgumentList "$PatchPath\$patch /quiet /norestart" -Wait
                    Write-Host "  $kb install complete; Restart required" -ForegroundColor DarkGray
                    localLogWrite "$Global:ProcessName - $kb : Successful"
                    $Global:Reboot = $true
                }catch{
                    Write-Error -Message "  ERROR: $kb install failed  " -Category InvalidArgument
                    localLogWrite "$Global:ProcessName - $kb : Failed"
                }
            }else{
                Write-Host "  $kb is already installed; Skipping installation"
                localLogWrite "$Global:ProcessName - $kb : Skipped"
            }
        }
        activateSleep
    }elseif($GetWinVersion -eq 26100){ #### 26100 = 24H2
        Write-Host "  You are using $GetOS 24H2; Getting correct Windows 11 Patches for 24H2" -ForegroundColor Gray
        # Create Patches Directory
        $patches11 = New-Item -Path "$Global:TempPath" -Name "Patches" -ItemType "Directory"

        # Copy Patches Directory
        Copy-Item "$Global:InstallPath\Patches\Windows11\w11-24h2" -Destination "$Global:TempPath\Patches" -Force -Recurse

        # Get KBs from Directory
        $PatchPath = "$Global:TempPath\Patches\w11-24h2\$Global:PatchFolder"
        $PatchContents = Get-ChildItem -Path $PatchPath -Recurse
        Write-Host "  Installing all from '\w11-24h2\$Global:PatchFolder'" -ForegroundColor Gray

        # Install Windows 11 updates
        foreach ($patch in $PatchContents){
            # Loop through folder of patches
            $kb = (Get-Item "$PatchPath\$patch").BaseName

            # Install Patch
            # check Hot-Fix
            if (-not(Get-Hotfix -id $kb -ErrorAction SilentlyContinue)){
                $Global:ProcessName = "Window Update $kb"
                Write-Host "  $kb is not installed" -ForegroundColor Gray
                Write-Host "  Installing Patch : $kb" -ForegroundColor Green
                try{
                    Start-Process -FilePath "wusa.exe" -ArgumentList "$PatchPath\$patch /quiet /norestart" -Wait
                    Write-Host "  $kb install complete; Restart required" -ForegroundColor DarkGray
                    localLogWrite "$Global:ProcessName - $kb : Successful"
                }catch{
                    Write-Error -Message "  ERROR: $kb install failed  " -Category InvalidArgument
                    localLogWrite "$Global:ProcessName - $kb : Failed"
                }

            }else{
                Write-Host "  $kb is already installed; Skipping installation"
                localLogWrite "$Global:ProcessName - $kb : Skipped"
            }
        }
    }else{
        Write-Host "$GetWinVersion is not a valid WindowsVersion"
        locallogwrite "WinUPDATE WinVersion : Build Number Failed"
    }

}else{
    Write-Host "  Unknown OS : $GetOS" -ForegroundColor Red
    localLogWrite "Unknown OS : $GetOS : OS Updates Skipped"
}

# Remove folder
removeFolder
if ($Global:Reboot){
    localLogWrite "Reboot Required Pending"
    Write-Host -ForegroundColor Red "** System Needs to Reboot. Do you want to reboot now? (y/n)"
    $continue = Read-Host "Continue? "
    $continue = $continue.ToUpper()
    if ($continue -eq "Y" -or $continue -eq "YES"){
        Write-Host -ForegroundColor Magenta "  Restart Pending. Will restart on close."
        localLogWrite "Reboot Initiated. Waiting 5 seconds."
        Start-Sleep -Seconds 5 
        Restart-Computer -Force
    }elseif ($continue -eq "N" -or $continue -eq "NO"){
        Write-Host -ForegroundColor Magenta "  No Restart Pending. Please restart system manually."
        localLogWrite "Reboot Declined."
    }else{
        Write-Host -ForegroundColor Magenta "  No selection made. Please restart system manually."
        localLogWrite "Reboot Declined. Bad input."
    }      
}else{
    Write-Host -ForegroundColor Magenta "  No Restart required."
    localLogWrite "Reboot not required."
    Pause
}
localLogWrite "-------------------------------------------------"
