########################################################################################
#
#    -----------------------------------------
#    Application Name : PingIt 1.0 GUI (RiP)
#    Created by       : DK
#    Date started     : April 2025
#    Current as of    : April 2025
#    -----------------------------------------------------------------------------------
#    Functionality    : Loop through list of computers or users performing a script
#                     :
#                     : For computers - it will target the system and remote run script
#                     :     or will perform Admin tasks on the object
#                     :
#                     : For users - it will perform AD tasks on object 
#    -----------------------------------------
#
########################################################################################
########################################################################################

# Variables
#----------
Set-StrictMode -Version Latest
# App Variables (Updated)
	$Global:AppName = "RiP"
	$Global:AppVer = "1.0"
    $Global:Copyright = [System.Net.WebUtility]::HtmlDecode("&#169;")
    $Global:CpDate = "April 2025"
    $Global:Author = "DK"
    $Global:Username = whoami
# App Executing Path
    $Global:ExecutePath = Get-Location
    $Global:DefaultEditor = "notepad.exe"
    #$Global:DefaultEditor = "notepad++.exe"
# Add Form functionality
	Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
# Form Object Variables - Create objects used in Application
	$Form_Object = [System.Windows.Forms.Form]
	$Label_Object = [System.Windows.Forms.Label]
	$Checkbox_Object = [System.Windows.Forms.CheckBox]
	$Textbox_Object = [System.Windows.Forms.TextBox]
	$Button_Object = [System.Windows.Forms.Button]
    $FileSelect_Object = $FileBrowser = [System.Windows.Forms.OpenFileDialog]
	#$RichTextbox_Object = [System.Windows.Forms.RichTextBox]
	$ToolbarMenuStrip_Object = [System.Windows.Forms.MenuStrip]
# Default File Path
    $Default_FilePath = "$env:USERPROFILE\Documents\RiP"
# Write PingIt file
    $PingIt_fileText = 
                   '# Ping It
                    param(
                        [string]$ActionPath,[string]$TargetPath
                    )

                    # Date
                    #-----
                    # Get date
                        $Global:Date = Get-Date -DisplayHint Date
                        function getDate{
                            $Global:Date = Get-Date -DisplayHint Date
                        }
                    # Get date abriviation
                        function GetShortDate{
                            $Global:ShortDate = Get-Date -Format dd-MM-yyyy_HH-mm-ss
                        }
                    # Parent App Variables (Updated)
	                    $Global:AppName = "RiP"
	                    $Global:AppVer = "1.0"
                        $Global:Copyright = [System.Net.WebUtility]::HtmlDecode("&#169;")
                        $Global:CpDate = "Oct. 2024"
                        $Global:Author = "DK"
                    # Username
                        $Global:Username = whoami
                    # Internal Ping Variables
                        [System.Collections.ArrayList]$Global:found = @()
                        $Global:i = 0
                        $Global:c = 0
                        $Global:tryCount = 350 # longer will trigger infinite loop error
                        $Global:sleep = 180 # 3 minutes
                        $Global:dataCount = 0
                        [System.Collections.ArrayList]$Global:FileList = @()
                    # Type
                        $ActionExtType = [System.IO.Path]::GetExtension($ActionPath)
                        if ($ActionExtType -eq ".ps1"){
                            $ActionType = "powershell.exe"
                        }elseif ($ActionExtType -eq ".bat" -or $ActionExtType -eq ".cmd"){
                            $ActionType = "cmd.exe"
                        }
                    # Local Log
                        GetShortDate
                        $LocalLog = "$env:USERPROFILE\Documents\$AppName\logs\$ShortDate.log"
                    # LocalLog write
                        function localLogWrite{
                            Param ([string]$logstring)
                            Add-Content $LocalLog -Value $logstring -Confirm:$false -Force
                        }


                    function displayHeader{
                        # Write Title
                        Write-Host -ForegroundColor Magenta "-----------------------------------"
                        Write-Host -ForegroundColor Magenta "Action Path  : $ActionPath"
                        Write-Host -ForegroundColor Magenta "Action Type  : $ActionType"
                        Write-Host -ForegroundColor Magenta "Tartget Path : $TargetPath"
                        Write-Host -ForegroundColor Magenta "Username     : $username"
                        Write-Host -ForegroundColor Magenta "-----------------------------------"
                        Write-Host -ForegroundColor Magenta "Max Attempts : $Global:tryCount"
                        getDate
                        localLogWrite "Start : $Global:Date`n$username"
                        localLogWrite "Max Attempts : $Global:tryCount"
                    }
                    displayHeader
                    getDate
                    localLogWrite "Starting Auto Run : $Global:Date"
                    Write-Host -ForegroundColor Magenta "Starting Auto Run : $Date"

                    function doIt{
                        # Get list of items form File
                        $list = Get-Content $TargetPath
                        # Put list into an arrayList
                        foreach ($value in $list){
                            if ($value -ne ""){
                                if ((-not ([string]::IsNullOrEmpty($value))) -and (-not ([string]::IsNullOrWhiteSpace($value)))){
                                    $Global:FileList += $value
                                }
                            }
                        }

                        # Check If Completed
                        if($Global:FileList.Count -gt 0){
                            $Global:dataCount = $Global:FileList.count
                        }else{
                            Write-Host("*COMPLETED ALL DATA*")
                            localLogWrite "*COMPLETED ALL DATA*"
                            exit
                        }

                        # Check if Data list

                        # Format : Computer;User;Group
                        # Optional Variables:
                        #    Computer - computer variable to target (*Required)
                        #    User - user variable to target
                        #    Group - AD Group;User Group to target 

                        foreach ($data in $Global:FileList){
                            # Convert Data to strings
                            $data = $data.ToString()
                            $dataSplit = $data -split ";"
                            $length = $dataSplit.Length

                            if ($length -eq 3){
                                $system = $dataSplit[0]
                                $user = $dataSplit[1]
                                $group = $dataSplit[2]
                            }elseif ($length -eq 2){
                                $system = $dataSplit[0]
                                $user = $dataSplit[1]
                                $group = $null
                            }elseif ($length -eq 1){
                                $system = $dataSplit[0]
                                $user = $null
                                $group = $null
                            }
                            # ping it
                            $pingCheck = ping $system -n 1

                            if ($pingCheck -like "reply*"){
                                Write-Host("$system is Online")
                                # system is online
                                localLogWrite "$system is Online"
                                try{
                                    # run cmd command or bat file
                                    # log header
                                    getDate
                                    localLogWrite "Running $ActionType Process : $Date`n$username;System $system;User $user"
                                    localLogWrite "Action Path : $ActionPath"

                                    if ($ActionType -eq "powershell.exe"){
                                        $process = Start-Process -FilePath $ActionType -Verb RunAs -Wait -PassThru -ArgumentList "-File $ActionPath $system $user $group"
                                    }elseif ($ActionType -eq "cmd.exe"){
                                        $process = Start-Process -Wait -PassThru -FilePath $ActionType -Verb RunAs -ArgumentList "/c $ActionPath $system $user $group"
                                    }
                                    #$process = Start-Process -Wait -PassThru -FilePath "cmd" -Verb RunAs -ArgumentList "/c $Path\$Global:ScriptPath $system $user $group"
                                    #$process = Start-Process -Wait -PassThru -FilePath "powershell" -Verb RunAs -ArgumentList "$Path\$Global:ScriptPath",$system,$user,$group
                    
                                    # process was successful
                                    $processErrCode = $process.ExitCode
                                    Write-Host("  **Process Completed with ErrorCode $processErrCode")
                                    localLogWrite "  **Process Completed with ErrorCode $processErrCode"
                                    $Global:found.Add("$data") | Out-Null
                                }catch{
                                    # fail to open cmd
                                    Write-Error "  **Process FAILED" 
                                    localLogWrite "  **Process FAILED"
                                }
                            }elseif ($pingCheck -like "Request timed out."){
                                Write-Host("$system request timed out")
                            }elseif ($pingCheck -like "Ping request could not find host*"){
                                Write-Host("$system is Offline")
                            }elseif ($pingCheck -like "Destination Host Unreachable*"){
                                Write-Host("$system is unreachable")
                            }else {
                                Write-Host("unkown value error : $system")
                                Write-Host("PINGCHECK : $pingCheck")
                            }
                        }
                        if ($Global:found.Count -ge 1){
                            Write-Host("_____")
                            #Write-Output($Global:found)
                            foreach ($d in $Global:found){
                                Write-Host("Removing : ${d}")
                                localLogWrite "Removed ${d}"
                                $c += 1
                                $out = Get-Content $TargetPath | Select-String -Pattern $d -notmatch 
                                Set-Content -Path $TargetPath -Value $out
                            }
                            Write-Host("..")
                            if ($c -ne 0){
                                Write-Host("Remove Count : ${c}")
                            }
                            Write-Host("_____")
                            localLogWrite "*---------------------------*"
                        }
                        $Global:tryCount = $Global:tryCount - 1
                        Write-Host -ForegroundColor Magenta "Attempts remaining : ${Global:tryCount}"
                        Write-Host -ForegroundColor Magenta "*---------------------------*"
                        if ($Global:tryCount -gt 0){
                            if (($Global:dataCount - $c) -gt 0){
                                [System.Collections.ArrayList]$Global:found = @()
                                [System.Collections.ArrayList]$Global:FileList = @()
                                $c = 0
                                $data = $null
                                $dataSplit = $null
                                $system = $null
                                $user = $null
                                $group = $null
                                $pingCheck = $null
                                $Global:dataCount = 0
                                $minutes = $sleep / 60
                                Write-Host -ForegroundColor Magenta "*PREPARING TO LOOP DATA*"
                                Write-Host -ForegroundColor Magenta "Sleeping for ${minutes} minutes. Please wait..."
                                Start-Sleep -Seconds $sleep
                                doIt
                            }else{
                                Write-Host("*COMPLETED ALL DATA*")
                                localLogWrite "*COMPLETED ALL DATA*"
                            }
                        }else{
                            Write-Host("*COMPLETED ALL ATTEMPTS*")
                            localLogWrite "*COMPLETED ALL ATTEMPTS*"
                            exit
                        }
                    }
                    doIt' # EOF
    # Create Fil
    New-Item -ItemType File -Name PingIt.ps1 -Value $PingIt_fileText -Path "$env:USERPROFILE\$AppName\$AppVer" -Confirm:$false -Force | Out-Null
# If PSExec does not exist in App directory; install it from url path
    if (-not (Test-Path "$env:USERPROFILE\$AppName\PSTools\PSExec.exe")){
        if (Test-Path "$env:USERPROFILE\$AppName\PSTools"){
            Remove-Item -Path "$env:USERPROFILE\$AppName\PSTools" -Confirm:$false -Force -Recurse | Out-Null
        }
        # Define the URL for PsExec
        $url = "https://download.sysinternals.com/files/PSTools.zip"

        # Define the destination path
        $destinationPath = "$env:USERPROFILE\$AppName\PSTools.zip"

        # Download the file
        Invoke-WebRequest -Uri $url -OutFile $destinationPath

        # Extract the zip file
        $extractPath = "$env:USERPROFILE\$AppName\PSTools"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($destinationPath, $extractPath)

        # Optional: Remove the zip file after extraction
        Remove-Item $destinationPath
    }
# Create Templates
    # PS ONE FILE (.ps1)
    $psonetemplate_fileText = 
        '#PSONE TEMPLATE
        # Input Parameters*
        param(
            [parameter(Mandatory)]
            [string]$systemName,[string]$user,[string]$group
        )
        Write-Host "Attepting connect to $systemName" -ForegroundColor Magenta
        Invoke-Command -ComputerName $systemName -ScriptBlock {
            # Use passed variables in Invoke-Command request (Using variables are required)
            $systemName = $Using:systemName
            $user = $Using:user
            $group = $Using:group

            Write-Host "$env:COMPUTERNAME Connection Successful" -ForegroundColor Green
            Write-Host "---------------------"
            Write-Host "Args =" 
            Write-Host "   - System: $systemName"
            Write-Host "   - User  : $user"
            Write-Host "   - Group : $group"

            # Your Code Here
            ################
            ################
            
            
        }
        Start-Sleep -Seconds 3
        pause'
    New-Item -ItemType File -Name psonetemplate.ps1 -Value $psonetemplate_fileText -Path "$env:USERPROFILE\Documents\$AppName\templates" -Confirm:$false -Force | Out-Null
    # BAT (.bat)
    $battemplate_fileText = 
        'REM BAT TEMPLATE
        @echo off
        C:
        cd %userprofile%\RiP\PsTools
        REM PSexec cam be called from this location

        echo Initialized by:
        whoami
        echo ------------------------------

        set system=%1
        set user=%2
        set group=%3'
    New-Item -ItemType File -Name battemplate.bat -Value $battemplate_fileText -Path "$env:USERPROFILE\Documents\$AppName\templates" -Confirm:$false -Force | Out-Null
    # CMD (.cmd)
    $cmdtemplate_fileText =
        'REM CMD file here
        @echo off
        C:
        cd %userprofile%\RiP\PsTools
        REM PSexec cam be called from this location

        echo Initialized by:
        whoami
        echo ------------------------------

        set system=%1
        set user=%2
        set group=%3'
    New-Item -ItemType File -Name cmdtemplate.cmd -Value $battemplate_fileText -Path "$env:USERPROFILE\Documents\$AppName\templates" -Confirm:$false -Force | Out-Null
# Logging
#--------
# Running Log
    $Global:RunningLog = "$env:USERPROFILE\$Global:AppName\$Global:AppVer\rp.log"
    # Check and Create Log directory
    #Write-Host "Checking for Log Directory"
    if (-not (Test-Path $env:USERPROFILE\$Global:AppName)){
        New-Item -ItemType Directory -Name $Global:AppName -Path $env:USERPROFILE -Confirm:$false -Force | Out-Null
        New-Item -ItemType Directory -Name $Global:AppVer -Path $env:USERPROFILE\$Global:AppName -Confirm:$false -Force | Out-Null
        #Write-Host "    Generating Log" -ForegroundColor Yellow
        New-Item -ItemType File -Name rp.log -Path $env:USERPROFILE\$Global:AppName\$Global:AppVer -Confirm:$false -Force | Out-Null
        # Test
        #Write-Host "Testing Log"
        if (test-path $Global:RunningLog){
            #Write-Host "    Log: Verified" -ForegroundColor Yellow
        }else{
            [System.Windows.Forms.MessageBox]::Show("Failed to verify log file. EL01", "Error - Log Unverified", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }else{
        if (-not (Test-Path $env:USERPROFILE\$Global:AppName\$Global:AppVer)){
            New-Item -ItemType Directory -Name $Global:AppVer -Path $env:USERPROFILE\$Global:AppName -Confirm:$false -Force | Out-Null
            New-Item -ItemType File -Name rp.log -Path $env:USERPROFILE\$Global:AppName\$Global:AppVer -Confirm:$false -Force | Out-Null
            #Write-Host "    Generating Log" -ForegroundColor Yellow
            #Write-Host "    Log Directory: New version Created" -ForegroundColor Yellow
            # Test
            #Write-Host "Testing Log"
            if (test-path $Global:RunningLog){
                #Write-Host "    Log: Verified" -ForegroundColor Yellow
            }else{
                [System.Windows.Forms.MessageBox]::Show("Failed to verify log file. EL02.", "Error - Log Unverified", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }else{
            #Write-Host "    Log Directory: Version Found" -ForegroundColor Yellow
            if (-not ($Global:RunningLog)){
                New-Item -ItemType File -Name rp.log -Path $env:USERPROFILE\$Global:AppName\$Global:AppVer -Confirm:$false -Force | Out-Null
                #Write-Host "    Generating Log" -ForegroundColor Yellow
                #Write-Host "Creating log"
                # Test
                #Write-Host "Testing Log"
                if (test-path $Global:RunningLog){
                    #Write-Host "    Log Path: Verified" -ForegroundColor Yellow
                }else{
                    [System.Windows.Forms.MessageBox]::Show("Failed to verify log file. EL03", "Error - Log Unverified", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }else{
                #Write-Host "    Log: Verified" -ForegroundColor Yellow
            }
        }
    }
# ErrLog write
    function UtilErr{
        Param ([string]$logstring)
        Add-Content $RunningLog -Value $logstring
    }
# LocalLog write
    function localLogWrite{
        Param ([string]$logstring)
        Add-Content $LocalLog -Value $logstring
    }

# Date
#-----
# Get date
    $Global:Date = Get-Date -DisplayHint Date
    function getDate{
        $Global:Date = Get-Date -DisplayHint Date
    }
# Get date abriviation
    function GetShortDate{
        $Global:ShortDate = Get-Date -Format dd-MM-yyyy
    }

# Internal Ping Variables
    [System.Collections.ArrayList]$Global:found = @()
    $Global:i = 0
    $Global:c = 0
    $Global:tryCount = 574 # 24hrs
    $Global:sleep = 300 # 5 minutes
    $Global:dataCount = 0
    [System.Collections.ArrayList]$Global:FileList = @()


##############################################
#******************
# Create GUI
#******************

# Main Form Element
#==================

    $Main_Form = New-Object $Form_Object
    $Main_Form.Text = "$AppName : $AppVer"
    $Main_Form.ClientSize = New-Object System.Drawing.Point(500,200)
    $Main_Form.FormBorderStyle = "FixedDialog" #FixedDialog, Fixed3D
    $Main_Form.MaximizeBox = $false
    $Main_Form.Font = New-Object System.Drawing.Font("Calibri",10)
    $Main_Form.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
    $Main_Form.Add_FormClosing({
        $Main_Form.Dispose()
    })
    $Main_Form.Add_Load({
        $Main_Form.TopLevel = $true
        $Main_Form.Add_Shown({ $this.Activate() })
        # Check file directory
        #Write-Host "Checking for App Directory"
        $appDirPath = "$env:USERPROFILE\Documents"
        if (-not (Test-path $appDirPath\$Global:AppName)){
            #Write-Host "    Creating App Directory" -ForegroundColor Yellow
            New-item -ItemType Directory -Name $AppName -Path $appDirPath -Confirm:$false -Force | Out-Null
            New-Item -ItemType Directory -Name logs -Path $appDirPath\$AppName -Confirm:$false -Force | Out-Null
            # Test
            #Write-Host "Testing App Directory"
            if (Test-Path $appDirPath\$AppName){
                # Verify Directory
                #Write-Host "    App Directory: Verified" -ForegroundColor Yellow
                # Test
                #Write-Host "Testing log directory"
                if (Test-Path "$appDirPath\$AppName\logs"){
                    #Write-Host "    Logs Directory: Verified"
                }else{
                    [System.Windows.Forms.MessageBox]::Show("Failed to verify logs directory. EL11.", "Error - Local Log", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    $error = "Error - Local Log : Failed to verify logs directory. EL11."
                    UtilErr $error
                }
            }else{
                [System.Windows.Forms.MessageBox]::Show("Failed to verify logs directory. EL12", "Error - Local Log", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $error = "Error - Local Log : Failed to verify logs directory. EL12."
                UtilErr $error
            }
        }else{
            #Write-Host "    App Directory: Verified" -ForegroundColor Yellow
            if (-not (Test-Path "$appDirPath\$AppName\logs")){
                #Write-Host "    Creating Log Directory" -ForegroundColor Yellow
                New-Item -ItemType Directory -Name logs -Path $appDirPath\$AppName -Confirm:$false -Force | Out-Null
                # Test
                #Write-Host "Testing Log Directory"
                if (Test-Path "$appDirPath\$AppName\logs"){
                    #Write-Host "    Log Directory: Verified"
                }else{
                    [System.Windows.Forms.MessageBox]::Show("Failed to verify logs directory . EL13.", "Error - Local Log", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    $error = "Error - Local Log : Failed to verify logs directory. EL13."
                    UtilErr $error
                }
            }else{
                #Write-Host "    Log Directory: Verified" -ForegroundColor Yellow
            }
        }
    })

    $RunAction_Label = New-Object $Label_Object
    $RunAction_Label.Text = "Action Probe"
    $RunAction_Label.Autosize = $true
    $RunAction_Label.Font = New-Object System.Drawing.Font("Calibri",10)
    $RunAction_Label.Location = New-Object System.Drawing.Point(25,50)
    $RunAction_Label.TextAlign = "MiddleCenter"

    $RunTargetFile_Label = New-Object $Label_Object
    $RunTargetFile_Label.Text = "Target File"
    $RunTargetFile_Label.Autosize = $true
    $RunAction_Label.Font = New-Object System.Drawing.Font("Calibri",10)
    $RunTargetFile_Label.Location = New-Object System.Drawing.Point(25,100)
    $RunTargetFile_Label.TextAlign = "MiddleCenter"

    $ActionSelectFile_Textbox = New-Object $Textbox_Object
    $ActionSelectFile_Textbox.Size = New-Object System.Drawing.Point(250,75)
    $ActionSelectFile_Textbox.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $ActionSelectFile_Textbox.Location = New-Object System.Drawing.Point(150,50)
    $ActionSelectFile_Textbox.ReadOnly = $true
    $ActionSelectFile_Textbox.Enabled = $false
    $ActionSelectFile_Textbox.BackColor = [System.Drawing.Color]::LightSkyBlue
    $ActionSelectFile_Textbox.ForeColor = [System.Drawing.Color]::Black
    $ActionSelectFile_Textbox.Add_TextChanged({
        $ActionPath = $ActionSelectFile_Textbox.Text
        if (-not ([string]::IsNullOrEmpty($ActionPath)) -or -not([string]::IsNullOrWhiteSpace($ActionPath))){
            $EditMenu_EditAction.Enabled = $true
        }else{
            $EditMenu_EditAction.Enabled = $false
        }
    })

    $TargetSelectFile_TextBox = New-Object $Textbox_Object
    $TargetSelectFile_TextBox.Size = New-Object System.Drawing.Point(250,75)
    $TargetSelectFile_TextBox.Font = New-Object System.Drawing.Font("Calibri",12,[System.Drawing.FontStyle]::Bold)
    $TargetSelectFile_TextBox.Location = New-Object System.Drawing.Point(150,100)
    $TargetSelectFile_TextBox.ReadOnly = $true
    $TargetSelectFile_TextBox.Enabled = $false
    $TargetSelectFile_TextBox.BackColor = [System.Drawing.Color]::LightSkyBlue
    $TargetSelectFile_TextBox.ForeColor = [System.Drawing.Color]::Black
    $TargetSelectFile_TextBox.Add_TextChanged({
        $TargetPath = $TargetSelectFile_TextBox.Text
        if (-not ([string]::IsNullOrEmpty($TargetPath)) -or -not([string]::IsNullOrWhiteSpace($TargetPath))){
            $EditMenu_EditTarget.Enabled = $true
        }else{
            $EditMenu_EditTarget.Enabled = $false
        }
    })

    $ActionSelectFile_Button = New-Object $Button_Object
    $ActionSelectFile_Button.TabIndex = "0"
    $ActionSelectFile_Button.Text = "Select"
    $ActionSelectFile_Button.Width = "75"
    $ActionSelectFile_Button.Height = "30"
    $ActionSelectFile_Button.Font = New-Object System.Drawing.Font("Calibri",10)
    $ActionSelectFile_Button.Location = New-Object System.Drawing.Point(405,50)
    $ActionSelectFile_Button.Add_click({
        $ActionFile_Browser = New-Object $FileSelect_Object
        $ActionPath = $ActionSelectFile_Textbox.Text
        if (-not [string]::IsNullOrEmpty($ActionPath)){
            if (-not [string]::IsNullOrWhiteSpace($ActionPath)){
                if ([System.IO.Directory]::Exists($ActionPath)){
                    $ActionFile_Browser.InitialDirectory = $ActionPath
                }else{
                    $ActionFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
                }
            }else{
                $ActionFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
            }
        }else{
            $ActionFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
        }
        #$ActionFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
        $ActionFile_Browser.Filter = 'Windows PowerShell Script (*.ps1)|*.ps1|Windows Batch File (*.bat)|*.bat|Windows Command Script (*.cmd)|*.cmd'
    
        $ActionFile_Browser.ShowDialog() | Out-Null
        $fileName = $ActionFile_Browser.SafeFileName
        $filePath = $ActionFile_Browser.FileName
        if (-not ($fileName -eq "")){
            $fileDir = Split-Path $ActionFile_Browser.FileName
        }else{
            $fileDir = ""
        }

        if ($ActionFile_Browser.CheckFileExists){
            if ($fileDir -eq "$env:USERPROFILE\Documents\$AppName"){
                $ActionSelectFile_Textbox.Text = $filePath
            }elseif ($fileDir -eq ""){
                [System.Windows.Forms.MessageBox]::Show("No File Selected.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                $ActionSelectFile_Textbox.Text = $filePath
            }else{
                [System.Windows.Forms.MessageBox]::Show("Can only use and edit files within the local App Directory.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                $ActionSelectFile_Textbox.Text = "$env:USERPROFILE\Documents\$AppName"
            } 
        }else{
            [System.Windows.Forms.MessageBox]::Show("Failed selecting Action path. Not a valid file path.", "Error - Action File Select", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $error = "Error - Action File Select : Failed selecting Action path. Not a valid file path."
            UtilErr $error
        }
        $ActionSelectFile_Textbox.SelectionStart = $ActionSelectFile_Textbox.Text.Length
        #$ActionSelectFile_Textbox.ScrollToCaret()

    })

    $TargetSelectFile_Button = New-Object $Button_Object
    $TargetSelectFile_Button.TabIndex = "1"
    $TargetSelectFile_Button.Text = "Select"
    $TargetSelectFile_Button.Width = "75"
    $TargetSelectFile_Button.Height = "30"
    $TargetSelectFile_Button.Font = New-Object System.Drawing.Font("Calibri",10)
    $TargetSelectFile_Button.Location = New-Object System.Drawing.Point(405,100)
    $TargetSelectFile_Button.Add_Click({
        $TargetFile_Browser = New-Object $FileSelect_Object
        $TargetPath = $TargetSelectFile_TextBox.Text
        if (-not [string]::IsNullOrEmpty($TargetPath)){
            if (-not [string]::IsNullOrWhiteSpace($TargetPath)){
                if ([System.IO.Directory]::Exists($TargetPath)){
                    $TargetFile_Browser.InitialDirectory = $TargetPath
                }else{
                    $TargetFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
                }
            }else{
                $TargetFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
            }
        }else{
            $TargetFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
        }
        #$TargetFile_Browser.InitialDirectory = "$env:USERPROFILE\Documents\$AppName"
        $TargetFile_Browser.Filter = 'Text Document (*.txt)|*.txt'

        $TargetFile_Browser.ShowDialog() | Out-Null
        $fileName = $TargetFile_Browser.SafeFileName
        $filePath = $TargetFile_Browser.FileName
        if (-not ($fileName -eq "")){
            $fileDir = Split-Path $TargetFile_Browser.FileName
        }else{
            $fileDir = ""
        }

        if ($TargetFile_Browser.CheckFileExists){
            if ($fileDir -eq "$env:USERPROFILE\Documents\$AppName"){
                $TargetSelectFile_TextBox.Text = $filePath
            }elseif ($fileDir -eq ""){
                [System.Windows.Forms.MessageBox]::Show("No File Selected.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                $ActionSelectFile_Textbox.Text = $filePath
            }else{
                [System.Windows.Forms.MessageBox]::Show("Can only use and edit files within the local App Directory.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
                $TargetSelectFile_TextBox.Text = "$env:USERPROFILE\Documents\$AppName"
            }
        }else{
            [System.Windows.Forms.MessageBox]::Show("Failed selecting Target path. Not a valid file path.", "Error - Target File Select", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $error = "Error - Target File Select : Failed selecting Target path. Not a valid file path."
            UtilErr $error
        }
        $TargetSelectFile_TextBox.SelectionStart = $TargetSelectFile_TextBox.Text.Length
        #$TargetSelectFile_TextBox.ScrollToCaret()
    })

    $TargetFormat_Label = New-Object $Label_Object
    $TargetFormat_Label.Text = "Format : COMPUTER;USER;GROUP"
    $TargetFormat_Label.AutoSize = $true
    $TargetFormat_Label.Font = New-Object System.Drawing.Font("Arial",9)
    $TargetFormat_Label.Location = New-Object System.Drawing.Point(175,130)

    $ProcessPrbe_Button = New-Object $Button_Object
    $ProcessPrbe_Button.TabIndex = "2"
    $ProcessPrbe_Button.Text = "==>==>>"
    $ProcessPrbe_Button.width = "100"
    $ProcessPrbe_Button.TextAlign = "MiddleCenter"
    $ProcessPrbe_Button.Location = New-Object System.Drawing.Point(200,155)
    $ProcessPrbe_Button.Add_click({
        GetShortDate
        $LocalLog = "$env:USERPROFILE\Documents\$AppName\logs\$ShortDate.log"

        $ActionPath = $ActionSelectFile_Textbox.Text
        $TargetPath = $TargetSelectFile_TextBox.Text
        if ((-not [string]::IsNullOrEmpty($ActionPath)) -and (-not [string]::IsNullOrEmpty($TargetPath))){
            if ((-not [string]::IsNullOrWhiteSpace($ActionPath)) -and (-not [string]::IsNullOrWhiteSpace($TargetPath))){
                if (([System.IO.File]::Exists($ActionPath)) -and ([System.IO.File]::Exists($TargetPath))){
                    $ActionExtType = [System.IO.Path]::GetExtension($ActionPath)
                    if ($ActionExtType -eq ".ps1"){
                        $ActionType = "powershell.exe"
                    }elseif ($ActionExtType -eq ".bat" -or $ActionExtType -eq ".cmd"){
                        $ActionType = "cmd.exe"
                    }

                    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList "$env:USERPROFILE\$AppName\$AppVer\PingIt.ps1",$ActionPath,$TargetPath
                
                }else{
                    [System.Windows.Forms.MessageBox]::Show("Failed to Run. Action or Target not valid file path.", "Error - Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                    $error = "Error - Failed : Failed to Run. Action or Target not valid file path."
                    UtilErr $error
                }
            }
        }else{
            [System.Windows.Forms.MessageBox]::Show("Failed to Run. Missing Action or Target file.", "Error - Missing File Path", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $error = "Error - Missing File Path : Failed to Run. Missing Action or Target file."
            UtilErr $error
        }
    })

# Create Toolbar Menu
##############################################

# Main Toolbar
    $Toolbar_Menu = New-Object $ToolbarMenuStrip_Object
    $Toolbar_Menu.BackColor = "#E5E4E2"
    $Toolbar_Menu.Font = New-Object System.Drawing.Font("Arial",10)
# EDIT Menu
    $ToolbarEdit_Menu = New-Object System.Windows.Forms.ToolStripMenuItem("Edit")
    $ToolbarEdit_Menu.Enabled = $true
# Clear Menu
    $ToolbarCLear_Menu = New-Object System.Windows.Forms.ToolStripMenuItem("Clear")
    $ToolbarCLear_Menu.Enabled = $true
    $ToolbarCLear_Menu.Add_Click({
        $ActionPath = $ActionSelectFile_Textbox.Text
        $TargetPath = $TargetSelectFile_TextBox.Text
        if ($ActionPath -eq "" -and $TargetPath -eq ""){
            if (([string]::IsNullOrEmpty($ActionPath)) -and ([string]::IsNullOrEmpty($TargetPath))){
                if (([string]::IsNullOrWhiteSpace($ActionPath))-and ([string]::IsNullOrWhiteSpace($TargetPath))){
                    [System.Windows.Forms.MessageBox]::Show("Clear Invalid", "Info - Cannot Clear", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                }else{
                    $ActionSelectFile_Textbox.Text = $null
                    $TargetSelectFile_TextBox.Text = $null
                }
            }else{
                $ActionSelectFile_Textbox.Text = $null
                $TargetSelectFile_TextBox.Text = $null
            }
        }else{
            $ActionSelectFile_Textbox.Text = $null
            $TargetSelectFile_TextBox.Text = $null
        }
    })

# Add Menu
    $ToolbarAdd_Menu = New-Object System.Windows.Forms.ToolStripMenuItem("Add")
    $ToolbarAdd_Menu.Enabled = $true
    $ToolbarAdd_Menu.Add_Click({
        $AddFile_Browser = New-Object $FileSelect_Object
        $AddFileDestinationPath = "$env:USERPROFILE\Documents\$AppName"
        $AddFile_Browser.InitialDirectory = $env:USERPROFILE
        $AddFile_Browser.Filter = 'Text Document (*.txt)|*.txt|Windows PowerShell Script (*.ps1)|*.ps1|Windows Batch File (*.bat)|*.bat|Windows Command Script (*.cmd)|*.cmd'

        $AddFile_Browser.ShowDialog() | Out-Null
        $fileName = $AddFile_Browser.SafeFileName
        $filePath = $AddFile_Browser.FileName
        if (-not ($fileName -eq "")){
            $fileDir = Split-Path $AddFile_Browser.FileName
        }else{
            $fileDir = ""
        }

        if ($AddFile_Browser.CheckFileExists){
            if ($fileDir -eq ""){
                [System.Windows.Forms.MessageBox]::Show("No File Selected.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }elseif($fileDir.Contains("$AddFileDestinationPath\logs")){
                [System.Windows.Forms.MessageBox]::Show("Cannot edit local log files. Canceled adding file", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }elseif ($fileDir.Contains($AddFileDestinationPath)){
                # Copy File Ove
                [System.Windows.Forms.MessageBox]::Show("File already exists in directory. Canceled adding file to avoid a duplicate", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }else{
                # Copy File
                Copy-Item -Path $filePath -Destination "$AddFileDestinationPath\$fileName" -Confirm:$false -Force -ErrorAction SilentlyContinue | Out-Null
                # Test if Copy was success
                if (-not ([System.IO.File]::Exists("$AddFileDestinationPath\$fileName"))){
                    [System.Windows.Forms.MessageBox]::Show("Failed verifying the file exists. Add file was unsuccessful.", "Error - Add File Select", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }else{
                    [System.Windows.Forms.MessageBox]::Show("Successfully added $fileName.", "File Added", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::None)
                }
            }
        }else{
            if ($fileDir -eq ""){
                [System.Windows.Forms.MessageBox]::Show("No File Selected.", "Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }elseif($fileDir.Contains("$AddFileDestinationPath\logs")){
                [System.Windows.Forms.MessageBox]::Show("Cannot edit local log files. Canceled adding file", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }elseif ($fileDir.Contains($AddFileDestinationPath)){
                # Copy File Ove
                [System.Windows.Forms.MessageBox]::Show("File already exists in directory. Canceled adding file to avoid a duplicate", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }else{
                [System.Windows.Forms.MessageBox]::Show("Failed verifying the file exists. Not a valid File.", "Error - Add File Select", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        }
    })


# Edit Menu
    $EditMenu_EditAction = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Action")
    $EditMenu_EditAction.Enabled = $false
    $EditMenu_EditAction.Add_Click({
        $ActionPath = $ActionSelectFile_Textbox.text
        if ([System.IO.File]::Exists($ActionPath)){
            Start-Process -FilePath powershell_ise.exe -ArgumentList $ActionPath
        }else{
            [System.Windows.Forms.MessageBox]::Show("Failed to edit Action Path. Not a valid file path.", "Error - Edit Action", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $error = "Error - Edit Action : Failed to edit Action Path. Not a valid file path."
            UtilErr $error
        }
    })

    $EditMenu_EditTarget = New-Object System.Windows.Forms.ToolStripMenuItem("Edit Target")
    $EditMenu_EditTarget.Enabled = $false
    $EditMenu_EditTarget.Add_Click({
        $TargetPath = $TargetSelectFile_TextBox.text
        if ([System.IO.File]::Exists($TargetPath)){
            Start-Process -FilePath $DefaultEditor -ArgumentList $TargetPath
        }else{
            [System.Windows.Forms.MessageBox]::Show("Failed to edit Target Path. Not a valid file path.", "Error - Edit Target", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $error = "Error - Edit Target : Failed to edit Target Path. Not a valid file path."
            UtilErr $error
        }
    })

    $ToolbarEdit_Menu.DropDownItems.AddRange(@($EditMenu_EditAction,$EditMenu_EditTarget)) | Out-Null

    $Toolbar_Menu.Items.AddRange(@($ToolbarEdit_Menu,$ToolbarCLear_Menu,$ToolbarAdd_Menu)) | Out-Null

$Copyright_Label = New-Object $Label_Object
$Copyright_Label.Text = "$Author $Copyright $Global:CpDate"
$Copyright_Label.Font = New-Object System.Drawing.Font("Calibri",9,[System.Drawing.FontStyle]::Bold)
$Copyright_Label.AutoSize = $true
$Copyright_Label.Location = New-Object System.Drawing.Point(390,175)


$Main_Form.Controls.AddRange(@(
    $Toolbar_Menu
    $RunAction_Label
    $RunTargetFile_Label
    $ActionSelectFile_Textbox
    $TargetSelectFile_TextBox
    $ActionSelectFile_Button
    $TargetSelectFile_Button
    $TargetFormat_Label
    $ProcessPrbe_Button
    $Copyright_Label
))

$Main_Form.ShowDialog() | Out-Null
