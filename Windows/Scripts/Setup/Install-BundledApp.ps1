#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [ValidateSet('ChromeSetup (1).exe','Firefox Installer.exe','MBSetup-8.8.exe','avg_antivirus_free_setup.exe','ccsetup_online_setup.exe')]
    [string]$Installer,
    [switch]$All
)
$ErrorActionPreference = 'Stop'
$root = $env:TTK_TOOLKIT_ROOT
if (-not $root) { $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) }
$names = if ($All) { @('ChromeSetup (1).exe','Firefox Installer.exe','MBSetup-8.8.exe','avg_antivirus_free_setup.exe','ccsetup_online_setup.exe') } elseif ($Installer) { @($Installer) } else { throw 'Specify -Installer or -All.' }
foreach ($name in $names) {
    $path = Join-Path $root ('Windows\Resources\NewComputerSetup\' + $name)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Bundled installer missing: $path" }
    Write-Output "Starting bundled installer: $name. Complete its setup window; Internet may be required."
    $process = Start-Process -FilePath $path -WorkingDirectory (Split-Path -Parent $path) -PassThru -Wait
    Write-Output ("Installer exit code: {0} ({1})" -f $process.ExitCode, $name)
    if ($process.ExitCode -notin @(0,3010,1641)) { exit $process.ExitCode }
}
