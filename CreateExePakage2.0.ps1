
########################################################################################
#
#    -----------------------------------------------------------------------------------
#    Application Name : Executable Packager 2.0
#
#    Date Created     : November 2025
#
#    Current as of    : November 2025
#    -----------------------------------------------------------------------------------
#    Functionality    : Create Executable From Ps1 file useing File selection
#                     :
#    -----------------------------------------------------------------------------------
#
########################################################################################
########################################################################################

$Global:AppName = "Executable Packager"
$Global:AppVer = "2.0"
$Global:CpDate = "November 2025"
$Global:CpAuthor = "acybermonk"

Write-Host "`n`n--- Welcome to the Executable Creation Tool ---"
Write-Host "===============================================`n"
$StartScript = Read-Host -Prompt "Start File Selection? Press 1 to continue."
if ($StartScript -ne 1){
    Write-Host "Cancelling. Goodbye for now."
    Exit
}else{
    # Test if PS2EXE is installed as module for use
    $module_check = get-Module -Name ps2exe | select -Property Name -ExpandProperty Name
    if (!$module_check -ne $null){
        # Variables
	    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $FileSelect_Object = $FileBrowser = [System.Windows.Forms.OpenFileDialog]
        # File Selection for Input File
        $Input_FileBrowser = New-Object $FileSelect_Object
        $Input_FileBrowser.InitialDirectory = $env:USERPROFILE
        $Input_FileBrowser.Filter = "Windows PowerShell Script (*.ps1)|*.ps1"
        $Input_FileBrowser.ShowDialog() | Out-Null
        $Input_FileName = $Input_FileBrowser.SafeFileName
        if (-not ($Input_FileName -eq "")){
            $InputPath = ($Input_FileBrowser.FileName)  # Final Input Path
            # File Selection for Icon File
            $IconFile_FileBrowser = New-Object $FileBrowser
            $IconFile_FileBrowser.InitialDirectory = $env:USERPROFILE
            $IconFile_FileBrowser.Filter = 'Icon File (*.ico)|*.ico'
            $IconFile_FileBrowser.ShowDialog() | Out-Null
            $IconFilePath = ($IconFile_FileBrowser.FileName)  # Final Icon Path
            # App Title from Input File Name
            $AppTitleText = Select-String -Path $InputPath -Pattern "Global:AppName" -Context 0,0 -ErrorAction SilentlyContinue | select -Index 0
            if ($AppTitleText -ne $null){$AppTitle = (($($AppTitleText).Line -split "=" | select -Index 1).Substring(1)) -replace '"',''}else{$AppTitle = $null}
            # Get App Version from ps1 file code
            $AppVersionText = Select-String -Path $InputPath -Pattern "Global:AppVer" -Context 0,0 -ErrorAction SilentlyContinue | select -Index 0
            if ($AppVersionText -ne $null){$AppVersion = (($($AppVersionText).Line -split "=" | select -Index 1) -replace " ","") -replace '"',''}else{$AppVersion = $null}
            # Output File Name from Input File Name
            $OutputFileNameBase = [System.IO.Path]::GetFileNameWithoutExtension($Input_FileBrowser.SafeFileName)  # Final Output Name
            $OutputFileName = "$($OutputFileNameBase)_$($AppVersion).exe"
            # Get Copyright Date from ps1 file code
            $AppCopyrightDateString = Select-String -Path $InputPath -Pattern "Global:CpDate" -Context 0,0 -ErrorAction SilentlyContinue | select -Index 0
            if ($AppCopyrightDateString -ne $null){$AppCopyrightDate = (($($AppCopyrightDateString).Line -split "=" | select -Index 1).Substring(1)) -replace '"',''}else{$AppCopyrightDate = $null}
            $AppCopyrightAuthorString = Select-String -Path $InputPath -Pattern "Global:CpAuthor" -Context 0,0 -ErrorAction SilentlyContinue | select -Index 0
            if ($AppCopyrightAuthorString -ne $null){$AppCopyrightAuthor = (($($AppCopyrightAuthorString).Line -split "=" | select -Index 1).Substring(1)) -replace '"',''}else{$AppCopyrightAuthor = $null}
            $AppCopyright = "$($AppCopyrightAuthor) - $($AppCopyrightDate)"
            # Set Output Directory same as Input Directory
            $directorySet = [System.IO.Path]::GetDirectoryName($Input_FileBrowser.FileName)
    
            if ($AppTitle -eq "" -or $AppTitle -eq $null){
                Write-Warning -Message "[Missing App Title. Required Item Needed]"
                $AppTitle = (Read-Host "[Missing App Title. Please Enter App Title (Letters and Spaces Only)]") -replace '[^a-zA-Z ]', ''
                if ($AppTitle -eq $null -or $AppTitle -eq ""){
                    Write-Error -Message "Error missing app title. ERR(02)."
                    Start-Sleep -Seconds 5
                    Exit
                }
            }
            if ($AppVersion -eq "" -or $AppVersion -eq $null){
                Write-Warning -Message "[Missing App Version. Required Item Needed]"
                $AppVersion = (Read-Host "[Missing App Version. Please Enter Version Number (Numbers and .s only)]") -replace '[^0-9.]', ''
                if ($AppVersion -eq $null -or $AppVersion -eq ""){
                    Write-Error -Message "Error missing verion number. ERR(03)."
                    Start-Sleep -Seconds 5
                    Exit
                }else{
                    $OutputFileName = "$($OutputFileNameBase)_$($AppVersion).exe"
                }
            }
            if ($AppCopyright -eq "" -or $AppCopyright -eq $null){
                Write-Warning -Message "[Missing App Copyright. Using SYSTEM.Date and USERNAME as Copyright]"
                $AppCopyrightDate = Get-date -Format "MMMM yyyy"
                $AppCopyrightAuthor = $env:USERNAME
                $AppCopyright = "$($AppCopyrightAuthor) - $($AppCopyrightDate)"
            }

            Write-Host "      Createing EXE with Attributes"
            Write-Host "========================================="
            Write-Host "App Title        : $($AppTitle)"
            Write-Host "App Version      : $($AppVersion)"
            Write-Host "Input File Path  : $($InputPath)"
            Write-Host "Output File Name : $($OutputFileName)"
            Write-Host "Icon File path   : $($IconFilePath)"
            Write-Host "Copyright        : $($AppCopyright)"

            $confirmResult = Read-Host "Confirm Createing Executable?(y/n)"
            $confirmResult = $confirmResult.ToLower()
            if ($confirmResult -eq "y" -or $confirmResult -eq "yes"){
                Write-Host "Creating Executable. Please Wait." -ForegroundColor Yellow
                Invoke-ps2exe -inputFile $InputPath -outputFile "$($directorySet)\$($OutputFileName)" -iconFile $IconFilePath -title $AppTitle -version $AppVersion -copyright "$($AppCopyrightAuthor) - $($AppCopyrightDate)" -x64 -Verbose -noConsole
            }elseif($confirmResult -eq "n" -or $confirmResult -eq "no"){
                Write-Host "Cancelling Creation."
                Start-Sleep -Seconds 2
                Exit
            }else{
                Write-Host "Ibvalid Answer"
                Start-Sleep -Seconds 5
                Exit
            }
        }elseif($Input_FileName -eq ""){
            Write-Error -Message "No Input File Selected"
        }
    }else{
        Write-Host "Installing and Importing PS2EXE Module"
        $scriptBlockTest = 
        '
        Install-Module -Name ps2exe -Force -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose
        Import-Module -Name ps2exe -Force -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $module_check = get-Module -Name ps2exe | select -Property Name -ExpandProperty Name
        if (!$module_check -ne $null){
            Write-Host "Install was successfull. Please reopen application."
        }else{
            Write-Error -Message "Error Could not install neccessary module"
        }
        '
        Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList $scriptBlockTest
        $module_check = get-Module -Name ps2exe | select -Property Name -ExpandProperty Name
        if ($module_check -ne $null){
            Write-Error "Error Installing Module. ERR(01)."
            Pause        
        }
    }
}
