#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Write-Output 'Embedded Runner Self-Test'
Write-Output ("Time: {0}" -f (Get-Date))
Write-Output ("Computer: {0}" -f $env:COMPUTERNAME)
Write-Output ("PowerShell: {0}" -f $PSVersionTable.PSVersion)
Write-Output ("Toolkit root: {0}" -f $env:TTK_TOOLKIT_ROOT)
Write-Output ("Report dir: {0}" -f $env:TTK_REPORT_DIR)
if([string]::IsNullOrWhiteSpace($env:TTK_TOOLKIT_ROOT)){throw 'TTK_TOOLKIT_ROOT was not provided by the app runner.'}
if([string]::IsNullOrWhiteSpace($env:TTK_REPORT_DIR)){throw 'TTK_REPORT_DIR was not provided by the app runner.'}
if(-not (Test-Path -LiteralPath $env:TTK_TOOLKIT_ROOT -PathType Container)){throw 'Toolkit root does not exist.'}
if(-not (Test-Path -LiteralPath $env:TTK_REPORT_DIR -PathType Container)){throw 'Report directory does not exist.'}
Write-Output 'PASS: embedded app runner launched PowerShell and supplied the expected environment.'
exit 0
