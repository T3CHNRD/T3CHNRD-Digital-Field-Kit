#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$root=$env:TTK_TOOLKIT_ROOT
if([string]::IsNullOrWhiteSpace($root)){ $root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) }
$project=Join-Path $root 'Windows\Resources\NewComputerSetup\Win11Debloat-master\Win11Debloat-master'
$script=Join-Path $project 'Win11Debloat.ps1'
if(-not(Test-Path -LiteralPath $script -PathType Leaf)){ throw "Bundled Win11Debloat project is missing: $script" }
Write-Output "Launching bundled Win11Debloat project."
& $script
