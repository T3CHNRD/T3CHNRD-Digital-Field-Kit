$ErrorActionPreference='Continue'
Write-Output '=== DISK SUMMARY ==='
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID,VolumeName,@{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}},@{N='FreeGB';E={[math]::Round($_.FreeSpace/1GB,2)}} | Format-Table -AutoSize | Out-String | Write-Output
