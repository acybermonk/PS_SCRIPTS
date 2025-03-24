#Import-Module ps2exe
#Install-Module -Name ps2exe -Force -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Invoke-ps2exe -inputFile "C:\Users\Cybermonk\Proton Drive\for.captcha.only\My files\Code\Testing\RP.ps1" -outputFile RP.exe -noConsole -title "RiP" -version "1.0" -x64 -copyright "October 2024" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
