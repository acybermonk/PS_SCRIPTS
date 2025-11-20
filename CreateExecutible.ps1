#Import-Module ps2exe
$sourceFileName = ""
$sourceFileRoot = ""
$sourceFile_FullPath = "$sourceFileRoot\$sourceFileName"
# Create Executable 
#############################

#############################

# Test if PS2EXE is installed as module for use
$module_check = get-Module -Name ps2exe | select -Property Name -ExpandProperty Name
if (!$module_check -ne $null){
    # Read Inputs 
<#
    $Root = Read-Host "Enter Root Path"
    $InputName = Read-Host "Enter File Name (With Extension)"
    $OutputFileName = Read-Host "Enter Output Name (With Extenstion)"
    $IconFilePath = Read-Host "Enter Icon Path (With Extension)"
    $AppTitle = Read-Host "Enter App Tittle"
    $AppVersion = Read-Host "Enter App Version"
    $AppCopyright = Read-Host "Enter Copyright Date"
    $AppProduct = Read-Host "Enter App Product Name"
#>
    # Manual Override
	Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $FileSelect_Object = $FileBrowser = [System.Windows.Forms.OpenFileDialog]
    $Input_FileBrowser = New-Object $FileSelect_Object
    $Input_FileBrowser.InitialDirectory = $env:USERPROFILE
    $Input_FileBrowser.ShowDialog() | Out-Null
    $InputPath = ($Input_FileBrowser.FileName)
    #$Root = $Input_FileBrowser
    #$InputName = "ctrlbr.ps1"
    $OutputFileName = [System.IO.Path]::GetFileNameWithoutExtension($Input_FileBrowser.SafeFileName)
    $IconFile_FileBrowser = New-Object $FileBrowser
    $IconFile_FileBrowser.InitialDirectory = $env:USERPROFILE
    $IconFile_FileBrowser.ShowDialog() | Out-Null
    $IconFilePath = ($IconFile_FileBrowser.FileName)

    #$IconFilePath = "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\iconRP_64.ico"
    $AppTitle = "Control Bridge Utility"
    #$AppVersion = Get-Content $InputPath | $._
    $AppVersionText = Select-String -Path $InputPath -Pattern "Global:AppVer" -Context 0,0 | select -Index 0
    $AppVersion = (($($AppVersionText).Line -split "=" | select -Index 1) -replace " ","") -replace '"',''
    $AppCopyrightText = Select-String -Path "$($Root)\$($InputName)" -Pattern "Date Created" -Context 0,0 | select -Index 0
    $AppCopyrightDate = ($($AppCopyrightText).Line -split ":" | select -Index 1).Substring(1)
    $AppProduct = "Control Bridge"

    $directorySet = [System.IO.Path]::GetDirectoryName($Input_FileBrowser.FileName)
    Set-Location -Path $directorySet
    Invoke-ps2exe -inputFile "$($Root)\$($InputName)" -outputFile "$($OutputFileName)_$($AppVersion).exe" -iconFile $IconFilePath -title $AppTitle -version $AppVersion -copyright $AppCopyrightDate -product $AppProduct -x64 -requireAdmin -Verbose -noConsole
    
    #Invoke-ps2exe -inputFile "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\ctrlbr.ps1" -outputFile ctrlbr.exe -iconFile "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\iconRP_64.ico" -noConsole -title "Control Bridge Utility" -version "1.11.25.19" -x64 -copyright "November 2025" -product "Control Bridge" -requireAdmin -Verbose
}else{
    Write-Host "Installing PS2EXE Module"
    $scriptBlockTest = 'Install-Module -Name ps2exe -Force -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue'
    Start-Process powershell.exe -Verb RunAs -ArgumentList $scriptBlockTest
    $module_check = get-Module -Name ps2exe | select -Property Name -ExpandProperty Name
    if (!$module_check){
        Write-Host "Install Successful"

        # Read Inputs
        $Root= ""
        $InputPath = Read-Host "Enter Input Path (With Extension)"
        $OutputFileName = Read-Host "Enter Output Path (With Extenstion)"
        $IconFilePath = Read-Host "Enter Icon Path (With Extension)"
        $AppTitle = Read-Host "Enter App Tittle"
        $AppVersion = Read-Host "Enter App Version"
        $AppCopyright = Read-Host "Enter Copyright Date"
        $AppProduct = Read-Host "Enter App Product Name"
    
        # Manual Override
        $Root= ""
        $InputPath = "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\ctrlbr.ps1"
        $OutputFileName = "ctrlbr.exe"
        $IconFilePath = "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\iconRP_64.ico"
        $AppTitle = "Control Bridge Utility"
        $AppVersion = "1.11.25.19"
        $AppCopyright = "November 2025"
        $AppProduct = "Control Bridge"

        Invoke-ps2exe -inputFile $InputPath -outputFile $OutputFileName -iconFile $IconFilePath -title $AppTitle -version $AppVersion -copyright $AppCopyright -product $AppProduct -x64 -requireAdmin -Verbose -noConsole
    }else{
        Write-Error "Install Module Failed"
        Start-Sleep -Seconds 5
        Exit
    }
}
