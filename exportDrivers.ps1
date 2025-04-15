# Get SerialNumber of system from BIOS
$sn = Get-WmiObject -Class Win32_BIOS  | Select-Object -ExpandProperty SerialNumber
# Export System Drivers to csv file and name it with SerialNumber variable
Get-WmiObject Win32_PnPSignedDriver | select DeviceName,DriverVersion,DriverProviderName | Export-Csv -Path C:\temp\${sn}_drivers.csv
