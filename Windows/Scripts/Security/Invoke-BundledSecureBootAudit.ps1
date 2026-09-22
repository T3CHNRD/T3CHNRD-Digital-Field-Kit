#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param([ValidateSet('Multi','Production')][string]$Mode = 'Production')
$ErrorActionPreference = 'Stop'
$reports = $env:TTK_REPORT_DIR
if (-not $reports) {
    $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    $reports = Join-Path $root 'Diagnostic-Reports'
}
$output = Join-Path $reports ('SecureBoot-' + $Mode + '-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $output -Force | Out-Null
$name = if ($Mode -eq 'Multi') { 'Check-SecureBootCert-MultiComputer.ps1' } else { 'Check-SecureBootCert_PRODUCTION_READY.ps1' }
& (Join-Path $PSScriptRoot $name) -OutputFolder $output
