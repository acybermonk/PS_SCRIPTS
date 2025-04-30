$Path = "F:\CameraBackup\CameraBackup_4.7.25\100GOPRO\Videography"
$Date = Get-Date -Format MM.dd.yy-HH.mm
$logFile = "$Path\MOVE_$Date.log"
$content = Get-ChildItem -Path $Path -File -Force | Where-Object {$_.Extension -ne ".log"}

function logging {
    param ([string]$logData)
    Add-Content -Path "$logFile" -Value $logData
}

if ($content -ne $null){
    Write-Host "** Sorting Started **"
    logging "** Sorting Started **"
    logging "Date : $Date"
    logging "User : $env:USERNAME"
    logging "Path : $path"
    logging "*********************`n"

}

foreach ($c in $content){
    $video = New-Object -ComObject Shell.Application
    $file = $video.Namespace($Path).ParseName($c.Name)
    $fr = $file.ExtendedProperty("System.Video.FrameRate") / 1000
    
    # Check if there is a bin created for that Frame Rate
    if (Test-Path "$Path\$fr"){
        # Move Item to correct bin for Frame Rate
        Move-Item -Path "$Path\$c" -Destination "$Path\$fr\$c" -Confirm:$false -Force
        # Check if successful
        if ((-not (Test-Path "$Path\$c")) -and (Test-Path "$Path\$fr\$c")){
            Write-Host "$c moved -> '$Path\$fr\$c'"
            logging "$c moved -> '$Path\$fr\$c'"
        }else{
            Write-Error -Message "`nError: '$c' not moved" -Category InvalidArgument -ErrorId "MoveFileError"
            logging "ERR: '$c' not moved"
        }
    }else{
        # Create a new bin if new Frame Rate
        New-Item -ItemType Directory -Path $Path -Name $fr -Confirm:$false -Force
        # Check if successful
        if (Test-Path "$Path\$fr"){
            Write-Host "New Frame Rate Bin ==> ($fr)"
            logging "New Frame Rate Bin ==> ($fr)"
            # Move Item to correct bin for Frame Rate
            Move-Item -Path "$Path\$c" -Destination "$Path\$fr\$c" -Confirm:$false -Force
            # Check if successful
            if ((-not (Test-Path "$Path\$c")) -and (Test-Path "$Path\$fr\$c")){
                Write-Host "$c moved -> '$Path\$fr\$c'"
                logging "$c moved -> '$Path\$fr\$c'"
            }else{
                Write-Error -Message "`nError: '$c' not moved" -Category InvalidArgument -ErrorId "MoveFileError"
                logging "ERR: '$c' not moved"
            }
        }else{
            Write-Error -Message "`nError: Directory ($fr) not created" -Category InvalidArgument -ErrorId "DirectoryCreationError"
            logging "ERR: Failed to create ($fr) directory"
        }
    }
}

if ($content -ne $null){
    Write-Host "** Sorting Completed **"
    logging "** Sorting Completed **"

    # Display the different frame rates found and how many of each
    $FRTypes = Get-ChildItem -Path $Path -Directory
    Write-Host "---------- Data Collected ----------"
    Write-Host "-`n-      Frame Rates Found"

    logging "---------- Data Collected ----------"
    logging "-`n-      Frame Rates Found"

    foreach ($fr in $FRTypes){
        $FRCount = (Get-ChildItem -Path "$Path\$fr" -File).count
        Write-Host "-      ($fr) : $FRCount Files"
        logging "-      ($fr) : $FRCount Files"
    }
    Write-Host "------------------------------------`n"
    logging "------------------------------------`n"
}else{
   Write-Error -Message "`nError: Nothing Sorted.`nPlease chose bin path with a collection of files." -Category InvalidData -ErrorId "NoFilesToSortError"
}

