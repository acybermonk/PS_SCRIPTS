####################################################
#                 _                         _      #
#     ___ ___ _ _| |_ ___ ___ _____ ___ ___| |__   #
#    | .'|  _| | | . | -_|  _|     | . |   | '_|   #
#    |__,|___|_  |___|___|_| |_|_|_|___|_|_|_,_|   #
#            |___|                                 #
#                      Created by : Daniel Krysty  #
####################################################

# PRODUCTION SCRIPT
# #----------------------------------------------------------------#
<#
.SYNOPSIS
    - This is an Update / Install Package created to pull in the latest HP Image Assistant and update system.
    - Can be packaged into an executable / signed and added to an automated scheduled task for fleet
.DESCRIPTION
    This Package is to install the latest version of HPIA.
    - Stops all HP Image Assistant instances on the device (all users)
    - Validates image and Icon files are accessible locally
    - Validates current HPIA version on system 
    - Updates to newest from HP website for HPIA and installs
    - Runs HPIA and checks for all updates
    - Reads JSON file output from HPIA for applied updates
    - Checks for Pending Restart
    - Insalls / Uses Burnt Toast 8.5 to send nofication
    - Option reboot option if needed with slight delay
.VERSION
    - 2.0
.AUTHOR
    - Daniel Krysty
#>

#----------------------------------------------------------------#
#     Silent HPIA Online Installer (Direct from HP)
#     Created : 2026
#----------------------------------------------------------------#

#================================================================#
# Logging Details
#================================================================#

# Log Header Details
$logFileDate = Get-Date -Format "MM-dd-yy_HH-mm"
$logHeader = @"
Auto HPIA Update Package - created by acybermonk
-----------------------------------------------------------`n
    ** Initiated by : $env:USERNAME
    ** Initiated on : $logFileDate
-----------------------------------------------------------`n
"@

# Log File
    $logFile = "hpia-auto_$($logFileDate).log"
    $logBasePath = "C:\Logs\Auto\HPIA"
    if (-not (Test-Path -Path "$($logBasePath)\$($logFile)")){
        New-Item -Path $logBasePath -Name $logFile -ItemType File -Confirm:$false -Force | Out-Null
    }

# Add Log Header
    Add-Content -Path "$($logBasePath)\$($logFile)" -Value $logHeader

#================================================================#
# Functions
#================================================================#

#----------------------------------------------------------------#
# Logging Message Function

## Validated
#----------------------------------------------------------------#
    function Log-Message($message) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logLine = "LOG-ENTRY[" + $timestamp + "] " + $message
        Add-Content -Path "$($logBasePath)\$($logFile)" -Value $logLine
    }

#----------------------------------------------------------------#
# Loging Error Function

## Validated
#----------------------------------------------------------------#

function Log-Error($errVariable) {
    Log-Message "ERROR:: Action(s) failed to complete"
    Log-Message "Captured Error(s) :"
    foreach ($err in $errVariable){
        Log-Message " -$($err.Exception.Message)"
    }
}

#----------------------------------------------------------------#
# Logging Title Function

## Validated
#----------------------------------------------------------------#
    function Log-Title($message) {
        $logLine = $message
        Add-Content -Path "C:\Logs\Auto\HPIA\$($logFile)" -Value $logLine
    }

#----------------------------------------------------------------#
# Validate Image / Icon Download from HP base site / server repo

# Icon is created for shortcut from the HP Image downloaded
# Server location is a backup if unable to download
## Validated
#----------------------------------------------------------------#


    function ValidateImage {
        if (-not (Test-Path -Path "$($env:APPDATA)\HP\$($image)")){
            HPDownloadImage
            if (-not (Test-Path -Path "$($env:APPDATA)\HP\$($icon)")){
                ServerDownloadIcon
            }else{
                $Global:appIconFile = "$($env:APPDATA)\HP\$($icon)"
            }
        }else{
            $Global:appImageFile = "$($env:APPDATA)\HP\$($image)"
            if (-not (Test-Path -Path "$($env:APPDATA)\HP\$($icon)")){
                ServerDownloadIcon
            }else{
                $Global:appIconFile = "$($env:APPDATA)\HP\$($icon)"
            }
        }
    }

    function HPDownloadImage {
        $errHPDownloadImage = $null
        $Global:appImageFile = "."
        $Global:response = Invoke-WebRequest -Uri $URLBase_Site -UseBasicParsing -ErrorAction SilentlyContinue -ErrorVariable +InvokeRequestErr
        if (-not ($InvokeRequestErr)){
            $html = $response.Content
            $pattern = '(?<=src=["''])(https?:\/\/[^"'']+\.(?:jpg|jpeg|png|gif|webp))'
            $matches = [regex]::Matches($html, $pattern, 'IgnoreCase')
            $imageUrls = $matches | ForEach-Object { $_.Value } | Sort-Object -Unique
            if ($imageUrls.count -lt 2){
                $errImage1 = $null
                $fileName = Split-Path $imageUrls -Leaf
                Log-Message "Downloading: $($fileName) to $($env:APPDATA)\HP"
                Invoke-WebRequest -Uri $imageUrls -OutFile "$($env:APPDATA)\HP\$($image)" -ErrorVariable +errImage1
                if (-not ($errImage1)){
                    if (Test-Path -Path "$($env:APPDATA)\HP\$($image)"){
                        $Global:appImageFile = "$($env:APPDATA)\HP\$($image)"
                        Log-Message " -Downloaded image successfully"

                    }
                }else{
                    Log-Error $errImage1
                    ServerDownloadImage
                }
            }elseif ($imageUrls -ge 2){
                $errImage2 = $null
                foreach ($url in $imageUrls){
                    $fileName = Split-Path $imageUrls -Leaf
                    Log-Message "Downloading: $($fileName) to $($env:APPDATA)\HP"
                    Invoke-WebRequest -Uri $imageUrls -OutFile "$($env:APPDATA)\HP\$($image)" -ErrorVariable +errImage2
                    if (-not ($errImage2)){
                        if (Test-Path -Path "$($env:APPDATA)\HP\$($Image)"){
                            $Global:appImageFile = "$($env:APPDATA)\HP\$($image)"
                            Log-Message " -Downloaded ico successfully"
                        }
                    }else{
                        Log-Error $errImage2
                        ServerDownloadImage
                    }
                    break
                }
            }else{
                Log-Message "No images located on page based on HTML REGEX"
                ServerDownloadImage
            }
        }else{
            Log-Error $InvokeRequestErr
            ServerDownloadImage
        }
    }

    function CreateIcon {
       param(
           [Parameter(Mandatory=$true)]
           $bitmapPath,
           $iconPath = "$env:temp\newicon.ico"
       )
       Add-Type -AssemblyName System.Drawing
       if (Test-Path $bitmapPath) {
           $b = [System.Drawing.Bitmap]::FromFile($bitmapPath)
           $icon = [System.Drawing.Icon]::FromHandle($b.GetHicon())
           $file = New-Object System.IO.FileStream($iconPath, 'OpenOrCreate')
           $icon.Save($file)
           $file.Close()
           $icon.Dispose()
           $Global:appIconFile = $iconPath
       } else {
           Log-Message "$BitmapPath does not exist"
       }
    }

    function ServerDownloadImage {
        Log-Message "Attempting to download the image file from server repository"
        if (-not (Test-Path -Path "$($env:APPDATA)\HP\$($image)")){
            Log-Message " -Image not present and attempting to copy from repository"
            if (Test-Path -Path $imageRepoPath){
                $errCopyImage = $null
                $serverImagePath = Join-Path -Path $imageRepoPath -ChildPath $image
                $localImagePath = Join-Path -Path "$($env:APPDATA)\HP" -ChildPath $image
                if (-not (Test-Path -Path $localImagePath)){
                    $hp = new-item -Path "$($env:APPDATA)" -ItemType Directory -Name "HP" -Confirm:$false -Force
                }
                Copy-Item -Path $serverImagePath -Destination $localImagePath -ErrorAction SilentlyContinue -ErrorVariable +errCopyImage
                if (-not ($errCopyImage)){
                    if (Test-Path -Path "$($env:APPDATA)\HP\$($image)"){
                        Log-Message " -Image copied successfully"
                        $Global:appImageFile = "$($env:APPDATA)\HP\$($image)"
                    }
                }else{
                    Log-Error $errCopyImage
                }
            }
        }else{
            Log-Message " -Image present locally`n($($env:APPDATA)\HP\$($image))"
            $Global:appImageFile = "$($env:APPDATA)\HP\$($image)"
        }
    }

    function ServerDownloadIcon {
        Log-Message "Attempting to download the icon file from server repository"
        if (-not (Test-Path -Path "$($env:APPDATA)\HP\$($icon)")){
            Log-Message " -Icon not present and attempting to copy from repository"
            if (Test-Path -Path $iconRepoPath){
                $errCopyIcon = $null
                $serverIconPath = Join-Path -Path $iconRepoPath -ChildPath $icon
                $localIconPath = Join-Path -Path "$($env:APPDATA)\HP" -ChildPath $icon
                if (-not (Test-Path -Path $localIconPath)){
                    $hp = new-item -Path "$($env:APPDATA)" -ItemType Directory -Name "HP" -Confirm:$false -Force
                }
                Copy-Item -Path $serverIconPath -Destination $localIconPath -ErrorAction SilentlyContinue -ErrorVariable +errCopyImage
                if (-not ($errCopyIcon)){
                    if (Test-Path -Path "$($env:APPDATA)\HP\$($icon)"){
                        Log-Message " -Icon copied successfully"
                        $Global:appIconFile = "$($env:APPDATA)\HP\$($icon)"
                    }
                }else{
                    Log-Error $errCopyIcon
                }
            }
        }else{
            Log-Message " -Icon present locally`n($($env:APPDATA)\HP\$($icon))"
            $Global:appIconFile = "$($env:APPDATA)\HP\$($icon)"
        }
    }

#----------------------------------------------------------------#
# Stop all running HPIA processes / instances 

## Validated
#----------------------------------------------------------------#
    function StopHPIA{
        $ServiceErr = $null
        $process = $null
        $ProcessStop = "HPImageAssistant"
        Log-Message "Attempting to Stop Current Processes of $($ProcessStop)"
        $process = Get-Process -Name "$($ProcessStop)*"
        if ($process){
            Get-Process -Name "$($ProcessStop)*" | Stop-Process -Force -ErrorAction SilentlyContinue -ErrorVariable +ServiceErr
            Start-Sleep -Seconds 5
            $processList = Get-Process -Name $ProcessStop
            if (-not ($processList)){
                Log-Error $processList
            }else{
                Log-Message " -Services Stopped Successfully. Proceeding."
            }
        }else{
            Log-Message " -No Processes to be stopped. Proceeding."
        }
    }

#----------------------------------------------------------------#
# Check new HPIA version from HP and get download links

## Validated
#----------------------------------------------------------------#
    function CheckCurrentHPIAVersion {
        $InvokeRequestErr = $null
        Log-Message "Checking HPIA from HP site (base URL site)`n -($($URLBase_Site))"
        $Global:response = Invoke-WebRequest -Uri $URLBase_Site -UseBasicParsing -ErrorAction SilentlyContinue -ErrorVariable +InvokeRequestErr
        if (-not ($InvokeRequestErr)){
            $links = $response.Links
            Log-Message "Checking for correct download link."
            foreach ($link in $links){
                $versionfound = $link.onclick
                $href = $link.href
                if ($href -match $URLBase_Downlaod){
                    $Global:URL_Download = $href
                    $hrefSplit = $href -split "/"
                    $hrefSplit = $hrefSplit[$($hrefSplit.length - 1)]
                    $hrefSplit = $hrefSplit -split "-"
                    $hrefSplit = $hrefSplit[$($hrefSplit.length - 1)]
                    $Global:versionNumb = $hrefSplit -replace ".exe",""
                    $match = [regex]::Match($versionfound, "sp[0-9][0-9][0-9][0-9][0-9][0-9]")
                    if ($match.Success){
                        $Global:version_Download = $match.Value
                    }
                    Log-Message " -Found download link for v:$($version_Download) successfully"
                    Log-Message " -Download link: $($Global:URL_Download)"
                    break
                }
            }
        }else{
            Log-Error $InvokeRequestErr
        }
    }

#----------------------------------------------------------------#
# Validate current HPIA version from HP vs current local version

# - if found run local install
# - if not found do nothing
## Validated
#----------------------------------------------------------------#
    function ValidateHPIAVersion {
        $RunHPIALocalErr = $null
        Log-Message "Validating HPIA Version on current device"
        if (Test-Path -Path "C:\SWSetup\$($version_Download)\HPImageAssistant.exe"){
            Log-Message " -Found $($version_Download) already installed on device based on directory (C:\SWSetup\$($version_Download))"
            Log-Message "Attemting to run $($version_Download) version HPIA softpaqs"
            Log-Message " -Log Folder = $($hpiaLogDir)"
            Log-Message " -Report Folder = $($hpiaReportDir)"
            Start-Process -FilePath "C:\SWSetup\$($version_Download)\HPImageAssistant.exe" -ErrorVariable +RunHPIALocalErr -Wait -ArgumentList "/Silent /Operation:Analyze /Selection:All /Action:Install /Debug /LogFolder:$($hpiaLogDir) /ProxyURL:$($proxyURL) /ProxyPort:$($proxyPort) /ReportFolder:$($hpiaReportDir) /Format:JSON /SoftpaqDownloadFolder:C:\HPIA\download_${DateShort} /AutoCleanup"
            if (-not ($RunHPIALocalErr)){
                Log-Message " -HPIA Proccess Completed"
                ReadJSONReport
                ToastMessageNotify
                Exit
            }else{
                Log-Error $RunHPIALocalErr
                ToastMessageNotify
                Exit
            }
        }else{
            Log-Message "$($version_Download) version not found on device based on directory`n -(C:\SWSetup\$($version_Download))"
        }
    }

#----------------------------------------------------------------#
# Remove old Shortcuts Create Shortcut 

## Removed
#----------------------------------------------------------------#
    function CreateShortcut {
        Log-Message "Checking for old shortcurts on system`n($($env:USERPROFILE)\Desktop)"
        $currentShortcut = Get-ChildItem -Path "$($env:USERPROFILE)\Desktop" -Filter "*HPImageAssistant*.lnk" -ErrorAction SilentlyContinue
        if ($currentShortcut){
            Log-Message " -Found one or more shorcuts at location with the name 'HPImageAssistant'"
            foreach ($shortcut in $currentShortcut){
                Log-Message " -Removing shortcut : $($shortcut.FullName)"
                Remove-Item -Path "$($shortcut.FullName)" -Confirm:$false -Force
            }
            $currentShortcut = Get-ChildItem -Path "$($env:USERPROFILE)\Desktop" -Filter "*HPImageAssistant*.lnk" -ErrorAction SilentlyContinue
            if (-not ($currentShortcut)){
                Log-Message " -All shortcuts have been removed successfully"
                Log-Message "Creating new shortcut at location`n($($env:USERPROFILE)\Desktop)"
                $targetFile = "C:\SWSetup\$($version_Download)\HPImageAssistant.exe"
                $shortcutPath = "$($env:USERPROFILE)\Desktop\HPImageAssistant - Shortcut.lnk"
                $WScriptObj = New-Object -ComObject "WScript.Shell"
                $shortcut = $WscriptObj.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = $targetFile
                $shortcut.IconLocation = $Global:appIconFile
                $shortcut.Save()
                if (Test-Path -Path "$($env:USERPROFILE)\Desktop\HPImageAssistant - Shortcut.lnk"){
                    Log-Message " -Shortcut created successfully"
                }else{
                    Log-Message " -Shortcut failed to be created"
                }
            }else{
                Log-Message " -Unable to remove shortcuts"
            }
        }else{
            Log-Message "Creating new shortcut at location`n($($env:USERPROFILE)\Desktop)"
            $targetFile = "C:\SWSetup\$($version_Download)\HPImageAssistant.exe"
            $shortcutPath = "$($env:USERPROFILE)\Desktop\HPImageAssistant - Shortcut.lnk"
            $WScriptObj = New-Object -ComObject "WScript.Shell"
            $shortcut = $WscriptObj.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $targetFile
            $shortcut.IconLocation = $Global:appIconFile
            $shortcut.Save()
            if (Test-Path -Path "$($env:USERPROFILE)\Desktop\HPImageAssistant - Shortcut.lnk"){
                Log-Message " -Shortcut created successfully"
            }else{
                Log-Message " -Shortcut failed to be created"
            }
        }
    }

#----------------------------------------------------------------#
# Download from HPIA website

## Validated
#----------------------------------------------------------------#
    function DownloadFromHP {
        $InvokeDownloadErr = $null
        if ($URL_Download){
            Log-Message "Attempting to Download HPIA"
            Log-Message " -Creating a temp dowload directory`n -($($rootTempPath)\$($appDirectoryName))"
            $tempDirCreate = New-Item -ItemType Directory -Name $appDirectoryName -Path $rootTempPath -Confirm:$false -Force
            Log-Message " -Downloading HPIA from $($URL_Download)"
            $download = Invoke-WebRequest -Uri $URL_Download -OutFile "$($rootTempPath)\$($appDirectoryName)\hpia.exe" -ErrorAction SilentlyContinue -ErrorVariable +InvokeDownloadErr
            if (-not ($InvokeDownloadErr)){
                if (Test-Path -Path "$($rootTempPath)\$($appDirectoryName)\hpia.exe"){
                    $installHPIAErr = $null
                    Log-Message " -Download Successful"
                    Log-Message "Installing HPIA from path`n -($($rootTempPath)\$($appDirectoryName)\hpia.exe)"
                    $installHPIA = Start-Process -FilePath "$($rootTempPath)\$($appDirectoryName)\hpia.exe" -ErrorAction SilentlyContinue -ErrorVariable +InstallHPIAErr -ArgumentList "/s /e /f `"C:\SWSetup\$($version_Download)`"" -PassThru -Wait
                    if (-not ($installHPIAErr)){
                        if (Test-Path -Path "C:\SWSetup\$($version_Download)\HPImageAssistant.exe"){
                            $RunHPIADownload = $null
                            Log-Message " -Install Successful"
                            Log-Message "Attemting to run $($version_Download) version HPIA softpaqs."
                            Log-Message " -Log Folder = $($hpiaLogDir)"
                            Log-Message " -Report Folder = $($hpiaReportDir)"
                            Start-Process -FilePath "C:\SWSetup\$($version_Download)\HPImageAssistant.exe" -ErrorVariable +RunHPIADownload -Wait -ArgumentList "/Silent /Operation:Analyze /Selection:All /Action:Install /Debug /LogFolder:$($hpiaLogDir) /ProxyURL:$($proxyURL) /ProxyPort:$($proxyPort) /ReportFolder:$($hpiaReportDir) /Format:JSON /SoftpaqDownloadFolder:C:\HPIA\download_${DateShort} /AutoCleanup"
                            if (-not ($RunHPIADownload)){
                                Log-Message " -HPIA proccess installing softpaq completed"
                                #CreateIcon -bitmapPath $Global:appImageFile -iconPath $Global:appIconFile
                                #CreateShortcut
                            }else{
                                Log-Error $RunHPIADownload
                            }
                        }else{
                            Log-Message " -Installed version not found"
                        }
                    }else{
                        Log-Error $installHPIAErr
                    }
                }else{
                    Log-Message " -Download Unsuccessful. Contact your Administrator for troubleshooting."
                }
            }else{
                Log-Error $InvokeDownloadErr
            }
        }else{
            Log-Message " -Unable to download HPIA from $($URLBase_Site). Contact your Administrator for troubleshooting."
        }
    }

#----------------------------------------------------------------#
# Remove temp download directory

## Validated
#----------------------------------------------------------------#

function RemoveTempDirectory {
    # Clean Up Download
    $removeDirErr = $null
    Log-Message "Attempting to remove temp download directory"
    if (Test-Path -Path "$($rootTempPath)\$($appDirectoryName)"){
        $removeDir = Remove-Item -Path "$($rootTempPath)\$($appDirectoryName)" -Recurse -Confirm:$false -Force -ErrorAction SilentlyContinue -ErrorVariable +removeDirErr
        if (-not ($removeDirErr)){
            if (-not (Test-Path -Path "$($rootTempPath)\$($appDirectoryName)")){
                Log-Message " -Temp download directory removed successfully"
            }else{
                Log-Message " -Cleanup Temp Folder Unsuccessful. Please Clean up $($rootTempPath)\$($appDirectoryName) Folder"
            }
        }else{
            Log-Error $removeDirErr
            Log-Message " -Cleanup Temp Folder Unsuccessful. Please Clean up $($rootTempPath)\$($appDirectoryName) Folder"
        }
    }else{
        Log-Message " -No temp download directory found."
    }
}

#----------------------------------------------------------------#
# Read report as PS Object from JSON file

## Validated
#----------------------------------------------------------------#

function ReadJSONReport {
    $Global:rebootRequired = $false
    $Global:Summary = $null
    $reportFile = $null
    $reportFile = Get-ChildItem -Path $hpiaReportDir | Where-Object { $_.Extension -eq ".json" }
    if ($reportFile){
        Log-Message "Report File Found. Converting from JSON"
        $reportObj = Get-Content $reportFile.FullName | ConvertFrom-Json
        $reportObj = $reportObj.HPIA
        if ($reportObj.LastOperationStatus -eq "Success"){
            Log-Title "`nReport Details:"
            Log-Title "`n-----------------------------------------------------------"
            if ($($reportObj.ExitCode) -eq "0"){
                Log-Message " -HPIA Completed with exit code : '$($reportObj.ExitCode)'"
                Log-Message " -Last Operation Status Description : '$($reportObj.LastOperationStatusDesc)'"
                Log-Message " -HPIA Completed and installed recomendations successfully"
            }elseif ($($reportObj.ExitCode) -eq "256"){
                Log-Message " -HPIA Completed with exit code : '$($reportObj.ExitCode)'"
                Log-Message " -Last Operation Status Description : '$($reportObj.LastOperationStatusDesc)'"
                Log-Message " -HPIA Completed with no recomendations"
            }else{
                Log-Message " -Exit Code : '$($reportObj.ExitCode)'"
                Log-Message " -Last Operation Status Description : '$($reportObj.LastOperationStatusDesc)'"
                Log-Message " -HPIA Completed with alternative exit code"
            }
            $Global:Summary = "HP Image Assistant:`nCompleted Successfully"
            if ($reportObj.Recommendations){
                Log-Message " -Recomendations found : $($reportObj.Recommendations.Count)"
                Log-Title "`nRecommendations / Remediations:"
                Log-Title "`n-----------------------------------------------------------"
                [int]$Global:recCounter = 1
                foreach ($recDetails in $($reportObj.Recommendations)){
                    Log-Message " $($recCounter)) $($recDetails.Name)"
                    Log-Message " -Recomended version : $($recDetails.RecommendationValue)"
                    Log-Message " -Severity : $($recDetails.Severity)"
                    Log-Message " -HP Comments : $($recDetails.Comments)"
                    if ($recDetails.Remediation){
                        Log-Message " -Remediation Date / Time : $($recDetails.Date)"
                        Log-Message " -Remediation Status : $($recDetails.Remediation.Status)"
                        Log-Message " -Return Code : '$($recDetails.Remediation.ReturnCode)'"
                        $recResult = $recDetails.Remediation.ReturnDescription
                        $recResult = $recResult -split "="
                        $recShort = $recResult[0]
                        $recLong = $recResult[1]
                        $recShort = $recShort -split ":"
                        $recStatus = $recShort[0]
                        $recReboot = $recShort[1]
                        if ($recResult.Count -gt 2){
                            for ($i = 1; $i -le $recResult.Count; $i++){
                                Log-Message " -Return Details : $($recResult[$i].Remediation.ReturnDescription)"
                            }
                        }else{
                            Log-Message " -Return Details : $($recLong)"
                        }
                        if ($recReboot -eq "REBOOT"){
                            $Global:rebootRequired = $true
                            Log-Message " -Reboot : Required"
                        }elseif($recReboot -eq "NOREBOOT"){
                            Log-Message " -Reboot : Not Required"
                        }
                    }else{
                        Log-Message " -Remediations : No remidiations found"
                    }
                    $Global:recCounter++
                }
            }else{
                Log-Message " -No recommendations found"
            }
        }else{
            Log-Message " -Last Report Status: $($reportObj.LastOperationalStatus)"
        }
    }else{
        Log-Message " -Report File Missing / Not Found"
    }
    if ($rebootRequired){
        $Global:Summary += "`nReboot is Required`nPlease reboot to complete"
    }else{
        $Global:Summary += "`nNo Reboot is Required"
    }
}

#----------------------------------------------------------------#
# Toast Notifications

## Validated
#----------------------------------------------------------------#

function ToastMessageNotify {
    Log-Message "Attempting to toast user"
    $toastMod = Get-InstalledModule -Name BurntToast -ErrorAction SilentlyContinue
    $errToast = $null
    if ($toastMod.Name -eq "BurntToast"){
        Log-Message " -BurntToast module is installed"
        if ($toastMod.Version.Major -eq 0 -and $toastMod.Version.Minor -eq 8 -and $toastMod.Version.Build -le 5){
            Log-Message " -BurntToast Version: v$($toastMod.Version.Major).$($toastMod.Version.Minor).$($toastMod.Version.Build)"
            Log-Message " -Importing BurntToast module"
            $importToast = Import-Module -Name BurntToast -MinimumVersion 0.8.0 -MaximumVersion 0.8.5 -ErrorAction SilentlyContinue -Force
            $btButton = New-BTButton -Content "Read Log" -Arguments "file://$($logBasePath)\$($logFile)"
            if ($rebootRequired){
                $restartCmd = Join-Path $env:TEMP "btr.cmd"
                Set-Content -Path $restartCmd -Value "@echo off`r`nshutdown.exe /r /t /5" -Encoding ASCII
                $rbButton = New-BTButton -Content "Restart Now" -Arguments "file://$($restartCmd) -replace '\\','/')"
            }
            Log-Title "`n-----------------------------------------------------------"
            Log-Title " End Loging"
            Log-Title "`n-----------------------------------------------------------"
            if ($rebootRequired){
                $notify = New-BurntToastNotification -Confirm:$false -AppLogo $appImageFile -Text "HPIA v$($versionNumb) - Complete", "$Summary" -Button $btButton,$rbButton -Sound Reminder -ErrorVariable +errToast
            }else{
                $notify = New-BurntToastNotification -Confirm:$false -AppLogo $appImageFile -Text "HPIA v$($versionNumb) - Complete", "$Summary" -Button $btButton -Sound Reminder -ErrorVariable +errToast
            }
            Log-Title "`n-----------------------------------------------------------"
            Log-Title " Toast Loging"
            Log-Title "`n-----------------------------------------------------------"
            if ($errToast){
                Log-Error $errToast
                Log-Message "BurntToast module unable to notify user"
                Log-Title "`n-----------------------------------------------------------"
            }else{
                Log-Message "BurntToast module notified user with log details"
                Log-Title "`n-----------------------------------------------------------"
            }
        }else{
            Log-Message " -BurntToast Version: v$($toastMod.Version.Major).$($toastMod.Version.Minor).$($toastMod.Version.Build)"
            Log-Message " -BurntToast version is incorrect, and is being uninstalled"
            $errUninstModule
            Uninstall-Module -Name BurntToast -Confirm:$false -Force -ErrorVariable +errUninstModule
            if (-not ($errUninstModule)){
                $toastMod = Get-InstalledModule -Name BurntToast -ErrorAction SilentlyContinue
                if (-not $toastMod){
                    Log-Message " -BurntToast version uninstalled successfully"
                    Log-Message " -ttempting reinstall of BurntToast"
                    $errInstallModule = $null
                    $installToast = Install-Module -Name BurntToast -MinimumVersion 0.8.0 -MaximumVersion 0.8.5 -Scope AllUsers -ErrorAction SilentlyContinue -Confirm:$false -Force -ErrorVariable +errInstallModule
                    if (-not ($errInstallModule)){
                        Log-Message " -Importing BurntToast module"
                        $importToast = Import-Module -Name BurntToast -MinimumVersion 0.8.0 -MaximumVersion 0.8.5 -ErrorAction SilentlyContinue -Force
                        $btButton = New-BTButton -Content "Read Log" -Arguments "file://$($logBasePath)\$($logFile)"
                        Log-Title "`n-----------------------------------------------------------"
                        Log-Title " End Loging"
                        Log-Title "`n-----------------------------------------------------------"
                        $notify = New-BurntToastNotification -Confirm:$false -AppLogo $appImageFile -Text "HPIA v$($versionNumb) - Complete", "$Summary" -Button $btButton -Sound Reminder -ErrorVariable +errToast
                        Log-Title "`n-----------------------------------------------------------"
                        Log-Title " Toast Loging"
                        Log-Title "`n-----------------------------------------------------------"
                        if ($errToast){
                            Log-Error $errToast
                            Log-Message "BurntToast module unable to notify user"
                            Log-Title "`n-----------------------------------------------------------"
                        }else{
                            Log-Message "BurntToast module notified user with log details"
                            Log-Title "`n-----------------------------------------------------------"
                        }
                    }else{
                        Log-Error $errInstallModule
                    }
                }else{
                    Log-Message "Unable to uninstall old module"
                }
            }else{
                Log-Error $errUninstModule
            }
        }
    }else{
        Log-Message "BurntToast module is not installed, atempting to install module"
        $errInstallModule = $null
        $installToast = Install-Module -Name BurntToast -MinimumVersion 0.8.0 -MaximumVersion 0.8.5 -Scope AllUsers -ErrorAction SilentlyContinue -Confirm:$false -Force -ErrorVariable +errInstallModule
        if (-not ($errInstallModule)){
            Log-Message "Importing BurntToast module"
            $importToast = Import-Module -Name BurntToast -MinimumVersion 0.8.0 -MaximumVersion 0.8.5 -ErrorAction SilentlyContinue -Force
            $btButton = New-BTButton -Content "Read Log" -Arguments "file://$($logBasePath)\$($logFile)"
            Log-Title "`n-----------------------------------------------------------"
            Log-Title " End Loging"
            Log-Title "`n-----------------------------------------------------------"
            $notify = New-BurntToastNotification -Confirm:$false -AppLogo $appImageFile -Text "HPIA v$($versionNumb) - Complete", "$Summary" -Button $btButton -Sound Reminder -ErrorVariable +errToast
            Log-Title "`n-----------------------------------------------------------"
            Log-Title " Toast Loging"
            Log-Title "`n-----------------------------------------------------------"
            if ($errToast){
                Log-Error $errToast
                Log-Message "BurntToast module unable to notify user"
                Log-Title "`n-----------------------------------------------------------"
            }else{
                Log-Message "BurntToast module notified user with log details"
                Log-Title "`n-----------------------------------------------------------"
            }
        }else{
            Log-Error $errInstallModule
        }
    }
}

#----------------------------------------------------------------#
# Set Update Cadence

## Validated
#----------------------------------------------------------------#
    function SetUpdateCadence{
        $localTask = Get-ScheduledTask -TaskName "sAutoHPIA-Update-Cadence" -ErrorAction SilentlyContinue
        if (-not ($localTask)){
            Log-Message "No current task found"
            CreateNewTask
        }else{
            Log-Message "No current task found"
            Log-Title "Task Details"
            Log-Title "`n-----------------------------------------------------------"

        }
    }

    function CreateNewTask {
        Log-Message "Setting up new task sequence with user input GUI"
    }

#================================================================#
# Variables
#================================================================#

#----------------------------------------------------------------#
# Setting variables
#----------------------------------------------------------------#
    $AppTitle = "sAutoHPIA"
    $AppVersion = "2.0"
    $AppCpDate = "July 2026"
    $AppCpAuthor = "acybermonk"
    $AppReqAdm = $true

    Log-Message "Setting Package Variables"
    $appDirectoryName = "hpia_download"
    $rootTempPath = "C:\Temp"
    $URLBase_Downlaod = "https://hpia.hpcloud.hp.com/downloads/hpia/hp-hpia-"
    $URLBase_Site = "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"
    $Global:URL_Download = $null
    $Global:version_Download = "hpia-ver-unknown"
    Log-Message " -Varables unpacked and added"

    $server = "\\serverName"
    $image = "hp.png"
    $icon = "hp.ico"

    $psoRepoPath = "$($server)\Auto\AutoHPIA"
    $imageRepoPath = "$($server)\Auto\img\repo"
    $iconRepoPath = "$($server)\Auto\img\repo\ico"

    # HPIA Viaribles
    $hpiaLogDir = "C:\Logs\Auto\HPIA\Auto_HPIA_LOGS"
    $hpiaReportDir = "C:\Logs\Auto\HPIA\Reports"
    $proxyURL = ""
    $proxyPort = ""

#================================================================#
# Start Script
#================================================================#
    ValidateImage
    StopHPIA
    CheckCurrentHPIAVersion
    ValidateHPIAVersion
    DownloadFromHP
    RemoveTempDirectory
    ReadJSONReport
    ToastMessageNotify
    #SetUpdateCadence v2.1.0

    Exit
