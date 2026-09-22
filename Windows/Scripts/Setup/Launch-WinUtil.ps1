#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param([switch]$Offline)

$ErrorActionPreference='Stop'
$root=$env:TTK_TOOLKIT_ROOT
if([string]::IsNullOrWhiteSpace($root)){ $root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) }
$project=Join-Path $root 'Windows\Resources\WinUtil'
$compiler=Join-Path $project 'Compile.ps1'
if(-not(Test-Path -LiteralPath $compiler -PathType Leaf)){ throw "Bundled WinUtil project is missing: $compiler" }
# The upstream entrypoint is generated from scripts, functions, config and XAML.
# Compile in a writable cache so installed/USB source copies stay unchanged.
$cache=Join-Path $env:LOCALAPPDATA ('T3DFK\WinUtil\'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $cache -Force | Out-Null
foreach($name in @('Compile.ps1','scripts','functions','config','xaml','tools')){
    Copy-Item -LiteralPath (Join-Path $project $name) -Destination $cache -Recurse -Force
}
Push-Location $cache
try { & (Join-Path $cache 'Compile.ps1') } finally { Pop-Location }
$start=Join-Path $cache 'winutil.ps1'
if(-not(Test-Path -LiteralPath $start -PathType Leaf)){ throw 'Bundled WinUtil compilation did not produce winutil.ps1.' }
Write-Output ("Launching bundled WinUtil project" + $(if($Offline){' in Offline mode.'}else{'.'}))
if($Offline){ & $start -Offline }else{ & $start }
