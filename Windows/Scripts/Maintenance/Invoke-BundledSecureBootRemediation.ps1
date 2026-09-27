#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$reports=$env:TTK_REPORT_DIR
if(-not $reports){
    $root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $reports=Join-Path $root 'Diagnostic-Reports'
}
$output=Join-Path $reports 'SecureBoot2023'
New-Item -ItemType Directory -Path $output -Force | Out-Null
Write-Output 'Secure Boot remediation report may include BitLocker recovery keys. Protect the report directory.'
Write-Output 'This workflow writes the Secure Boot update trigger and starts the Microsoft scheduled task when the device is eligible; it does not request a reboot.'
Write-Output ("Detailed status and results: {0}" -f $output)
# Only adapt output paths; preserve the supplied original and its eligibility checks.
$reportDrive=[IO.Path]::GetPathRoot([IO.Path]::GetFullPath($output))
& (Join-Path $PSScriptRoot 'Invoke-SecureBoot2023Update.ps1') -MappedDriveLetter $reportDrive.TrimEnd('\') -MappedDriveRoot $reportDrive -CsvDirectory $output -LocalLogDirectory $output
