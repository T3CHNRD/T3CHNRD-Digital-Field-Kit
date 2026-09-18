#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$root=$env:TTK_TOOLKIT_ROOT
if([string]::IsNullOrWhiteSpace($root)){ $root=Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) }
$resources=Join-Path $root 'Windows\Resources\NewComputerSetup'
if(-not(Test-Path -LiteralPath $resources -PathType Container)){ throw "Setup resources are missing from this Field Kit package: $resources" }
Write-Output "Opening setup resources: $resources"
Start-Process explorer.exe -ArgumentList ('"'+$resources+'"')
