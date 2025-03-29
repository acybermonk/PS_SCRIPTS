$ipconf = ipconfig
[string]$ipv4 = $null
foreach ($line in $ipconf){
    if ($line -like "*IPv4 Address*"){
        # Found
        $ipv4 = $line
        break
    }
}

$ipline = $($ipv4.Trim()) -split ":"
$ipv4 = $($ipline[1]).Trim()
Write-Host $ipv4
#195.72.49.1
