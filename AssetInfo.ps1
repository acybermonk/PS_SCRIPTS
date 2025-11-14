
########################################################################################
#
#    -----------------------------------------
#    Application Name : Asset Information (TCAI)
#    Created by       : DK
#    Date started     : November 2025
#    Current as of    : November 2025
#
#    -----------------------------------------------------------------------------------
#    Functionality    : Gathers Important System Info for validting System Info
#
#    -----------------------------------------
#
########################################################################################
########################################################################################

# Variables
    #----------
    Set-StrictMode -Version Latest
    # App Variables (Updated)
	    $Global:AppName = "Asset Information"
	    $Global:AppVer = "1.0"
        $Global:Copyright = [System.Net.WebUtility]::HtmlDecode("&#169;")
        $Global:CpDate = "November 2025"
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
	    $RichTextbox_Object = [System.Windows.Forms.RichTextBox]
	    $ToolbarMenuStrip_Object = [System.Windows.Forms.MenuStrip]
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
        function getDate{
            $Global:Date = Get-Date -DisplayHint DateTime
        }
    # Get date abriviation
        function GetShortDate{
            $Global:ShortDate = Get-Date -Format dd-MM-yyyy
        }

# Functions
#-----

    # Gather Data
        function GatherDataOutput{
            #$Global:ComputerData_Full = Get-ComputerInfo
            $DataPane_RichText.Text = "Generating Data. Please Wait..."
            Start-Sleep -Seconds 2
            $Global:ComputerName = $env:COMPUTERNAME
            $Global:UserName = $env:USERNAME
            #$Global:ComputerBIOS = Get-ComputerInfo -Property BiosBIOSVersion | Select -Property BiosBIOSVersion -ExpandProperty BiosBIOSVersion
            #$Global:KBPatches = Get-HotFix | select HotFixID,InstalledOn,InstalledBy
            $Global:OSCurrent = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
            $Global:WindowsType = Get-ComputerInfo -Property OsName -WarningAction SilentlyContinue -ErrorAction SilentlyContinue| select -Property OsName -ExpandProperty OsName
            $Global:OSBuild = "10.$($Global:OSCurrent.CurrentBuildNumber).$($Global:OSCurrent.UBR)"
            getDate
            $Global:data = "DATE : $($Global:Date)`nUSERNAME : $($Global:UserName)`nSYSTEM NAME : $($Global:ComputerName)`nWINDOWS TYPE : $($Global:WindowsType)`nOS BUILD : $($Global:OSBuild)"
            <#
            $Global:data += "`n`nWindows Update Patches"
            foreach ($kb in $Global:KBPatches){
                $Global:data += "`n$($kb.HotFixID) : Installed on $($kb.InstalledOn) by $($kb.InstalledBy)"
            }
            #>

            $DataPane_RichText.Text = $Global:data
            
        }
##############################################
#******************
# Create GUI
#******************

# Main Form Element
#==================
    $Main_Form = New-Object $Form_Object
    $Main_Form.Text = "$AppName : $AppVer"
    $Main_Form.ClientSize = New-Object System.Drawing.Point(350,200)
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
    })
    # Gather Data Button
    $GatherData_Button = New-Object $Button_Object
    $GatherData_Button.Text = "Gather Data"
    $GatherData_Button.AutoSize = $true
    $GatherData_Button.Font = New-Object System.Drawing.Font("Calibri",10)
    $GatherData_Button.Location = New-Object System.Drawing.Point(10,10)
    $GatherData_Button.Add_click({
        GatherDataOutput
    })

    # Data Pane
    $DataPane_RichText = New-Object $RichTextBox_Object
    $DataPane_RichText.Text = $null
    $DataPane_RichText.ReadOnly = $true
    $DataPane_RichText.Size = New-Object System.Drawing.Point(330,140)
    $DataPane_RichText.Font = New-Object System.Drawing.Font("Calibri",12)
    $DataPane_RichText.Location = New-Object System.Drawing.Point(10,50)
    $DataPane_RichText.BackColor = [System.Drawing.Color]::LightYellow
    $DataPane_RichText.ForeColor = [System.Drawing.Color]::DarkBlue

    $Main_Form.Controls.AddRange(@(
        $GatherData_Button,
        $DataPane_RichText
    ))


$Main_Form.ShowDialog() | Out-Null
