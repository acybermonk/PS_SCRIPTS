#Import-Module ps2exe
#Install-Module -Name ps2exe -Force -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
cd "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing"
Invoke-ps2exe -inputFile "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\RP.ps1" -outputFile RP.exe -iconFile "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\iconRP_64.ico" -noConsole -title "RiP" -version "1.0" -x64 -copyright "October 2024" -requireAdmin -Verbose
