#Requires -Version 5.1
[CmdletBinding()]
param([switch]$Offline)

$ErrorActionPreference='Stop'
$root=$env:TTK_TOOLKIT_ROOT
if([string]::IsNullOrWhiteSpace($root)){ $root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) }
$project=Join-Path $root 'Windows\Resources\NewComputerSetup\winutil-main\winutil-main'
$start=Join-Path $project 'scripts\start.ps1'
if(-not(Test-Path -LiteralPath $start -PathType Leaf)){ throw "Bundled WinUtil project is missing: $start" }
Write-Output ("Launching bundled WinUtil project" + $(if($Offline){' in Offline mode.'}else{'.'}))
if($Offline){ & $start -Offline }else{ & $start }
