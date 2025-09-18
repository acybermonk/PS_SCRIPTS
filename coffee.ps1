# DK's Cafe
# Created by Daniel Krysty; Updated November 2024
$Global:appName = "CoffeShop"
$Global:appVer = '1.0'
# Set execution Type
    $ExPol = Get-ExecutionPolicy -Scope CurrentUser
    if (-not ($ExPol -eq "Unrestricted")){
        #Write-Host "$env:COMPUTERNAME" -ForegroundColor Green
        #Write-Host "Execution Policy : $ExPol" -ForegroundColor Green
    }else{
        Write-Host "ERR: Please change Execution policy oout of restricted state and retry"
        Pause
        Exit
    }

# Add Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# User is ADM
$UserIdent = [Security.Principal.WindowsIdentity]::GetCurrent()
$UserIsADM_chk = (New-Object Security.Principal.WindowsPrincipal($UserIdent)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Message Variables
$Global:msg = New-Object -ComObject Wscript.Shell

# Create objects used in Application
$Form_Object = [System.Windows.Forms.Form]
$Label_Object = [System.Windows.Forms.Label]
$Button_Object = [System.Windows.Forms.Button]
$ComboBox_Object = [System.Windows.Forms.ComboBox]
$CheckBox_Object = [System.Windows.Forms.Form]
$PictureBox_Object = [System.Windows.Forms.PictureBox]

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

$ProgressBar_Object = [System.Windows.Forms.ProgressBar]
# Set default variables
$Global:DefaultFont = 'Calibri,10,style=bold'
$Global:DefaultColor1 = "#B70D0D" #Red
$Global:DefaultColor2 = "#F0EAEA" #Gray
$Global:SystemName = $env:COMPUTERNAME
$Global:SystemType = $Global:SystemName.Substring(0,2)
$Global:User = $env:USERNAME
$Global:DateTime = Get-Date -Format "MM/dd/yy HH:mm:ss"
$Global:DateShort = Get-Date -Format "MM-dd-yy_HH.mm"

$Cafe_Form = New-Object $Form_Object
$Cafe_Form.Text = "$Global:appName - $Global:appVer"
$Cafe_Form.FormBorderStyle = 'Fixed3D' #FixedDialog, Fixed3D
$Cafe_Form.ClientSize = '300,100'
$Cafe_Form.StartPosition = 'CenterScreen'

    # Welcome Banner Label
    $WelcomeBanner_Label = New-Object $Label_Object
    $WelcomeBanner_Label.Text = "Welcome to DK`'s Cafe! Order your Caffeine for your PC"
    $WelcomeBanner_Label.Width = '300'
    $WelcomeBanner_Label.Height = '30'
    $WelcomeBanner_Label.Location = New-Object System.Drawing.Point(0,10)
    $WelcomeBanner_Label.TextAlign = 'MiddleCenter'
    
    # Order Coffee Button
    $OrderCoffee_Button = New-Object $Button_Object
    $OrderCoffee_Button.Text = "Order Coffee"
    $OrderCoffee_Button.Width = '100'
    $OrderCoffee_Button.Height = '25'
    $OrderCoffee_Button.Location = New-Object System.Drawing.Point(25,50)
    $OrderCoffee_Button.Add_Click({
        orderCoffee
    })

    # Finish Coffee Button
    $FinishCoffee_Button = New-Object $Button_Object
    $FinishCoffee_Button.Text = "Finish Coffee"
    $FinishCoffee_Button.Width = '100'
    $FinishCoffee_Button.Height = '25'
    $FinishCoffee_Button.Location = New-Object System.Drawing.Point(175,50)
    $FinishCoffee_Button.Add_Click({
        finishCoffee
    })
    
    $Cafe_Form.Controls.AddRange(@($WelcomeBanner_Label, $OrderCoffee_Button, $FinishCoffee_Button))

# FUNCTIONS
#---------------------------------------------------


# Deactivate the sleep/idle state
function deactivateSleep{
    try{
        #Configuring the system to ignore any energy saving technologies
        $method::SetThreadExecutionState($Global:ES_SYSTEM_REQUIRED -bor $Global:ES_DISPLAY_REQUIRED -bor $Global:ES_CONTINUOUS)
        #Write-Host "Sleep deactivation successful"
    }catch{
        Write-Error -Message "  ERROR: Sleep deactivation failed" -Category InvalidArgument
        #Write-Host "Sleep deactivation failed"
    }
}

# Activate the sleep/idle state
function activateSleep{
    try{
        #Restoring saving mechanisms
        $method::SetThreadExecutionState($Global:ES_CONTINUOUS)
        #Write-Host "Sleep activation successful"
    }catch{
        Write-Error -Message "  ERROR: Sleep activation failed" -Category InvalidArgument
        #Write-Host "Sleep activation failed"
    }
}

function orderCoffee{
    $orderMessage = [Windows.Forms.MessageBox]::Show("Ordering Coffee to keep PC awake. Do you wish to continue?","Confirm",[System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($orderMessage -eq [System.Windows.Forms.DialogResult]::Yes){
        deactivateSleep
        [Windows.Forms.MessageBox]::Show("Coffee Ordered Successfully!","Awake",[System.Windows.Forms.MessageBoxButtons]::OK)
        $Cafe_Form.WindowState = [System.Windows.Forms.FormWindowState]::Minimized
    }elseif($orderMessage -eq [System.Windows.Forms.DialogResult]::No){
        # No action
    }
}

function finishCoffee{
    $finishMessage = [Windows.Forms.MessageBox]::Show("Finishing Coffee to allow PC to sleep. Do you wish to continue?","Confirm",[System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($finishMessage -eq [System.Windows.Forms.DialogResult]::Yes){
        activateSleep
        [Windows.Forms.MessageBox]::Show("Coffee Finished Successfully!","Sleepy",[System.Windows.Forms.MessageBoxButtons]::OK)
    }elseif($finishMessage -eq [System.Windows.Forms.DialogResult]::No){
        # No action
    }
}

function closingTime{
    deactivateSleep
    #[Windows.Forms.MessageBox]::Show("Closing Time!","Coffee Shop Closed",[System.Windows.Forms.MessageBoxButtons]::OK)
}

$Cafe_Form.Add_FormClosing({
    closingTime
    $Cafe_Form.Dispose() | Out-Null
})

# SHOW
#---------------------------------------------------

$Cafe_Form.ShowDialog() | Out-Null

# DISPOSE
#---------------------------------------------------

$Cafe_Form.Dispose() | Out-Null

# EOF
