#Requires -Version 5.1
[CmdletBinding()]
param([string]$ComputerName)

if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    $ComputerName = Read-Host 'Enter the remote computer name'
}
if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    Write-Warning 'No computer name entered.'
    exit 1
}

$NetworkPath = "\\$ComputerName\c$"
Write-Host "Checking SMB access to $ComputerName..." -ForegroundColor Cyan

$port445 = $false
try {
    $port445 = Test-NetConnection -ComputerName $ComputerName -Port 445 -InformationLevel Quiet -WarningAction SilentlyContinue
}
catch {
    Write-Warning "SMB connectivity test failed: $($_.Exception.Message)"
}

if (-not $port445) {
    Write-Warning 'TCP 445 did not respond. Ping/SMB may be filtered by policy.'
    $answer = Read-Host "Try opening $NetworkPath anyway? Type OPEN to continue"
    if ($answer -cne 'OPEN') { exit 2 }
}

try {
    Start-Process explorer.exe -ArgumentList $NetworkPath
    Write-Host "Opened: $NetworkPath" -ForegroundColor Green
}
catch {
    Write-Error "Unable to open $NetworkPath. $($_.Exception.Message)"
    exit 3
}
