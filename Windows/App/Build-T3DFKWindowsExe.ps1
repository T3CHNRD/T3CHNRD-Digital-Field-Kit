#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ToolkitRoot='',
    [string]$OutputFile=''
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ToolkitRoot)){$ToolkitRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$ToolkitRoot=[IO.Path]::GetFullPath($ToolkitRoot).TrimEnd('\')
if([string]::IsNullOrWhiteSpace($OutputFile)){$OutputFile=Join-Path $ToolkitRoot 'T3CHNRD Digital Field Kit.exe'}
$OutputFile=[IO.Path]::GetFullPath($OutputFile)
$launcher=Join-Path $ToolkitRoot 'Windows\App\T3DFK-Windows-Launcher.ps1'
if(-not(Test-Path -LiteralPath $launcher -PathType Leaf)){throw "Launcher source is missing: $launcher"}

$command=Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
if(-not $command){
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
    Import-Module ps2exe -Force
    $command=Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
}
if(-not $command){throw 'The ps2exe compiler command is unavailable.'}

$iconPath=Join-Path $ToolkitRoot 'Windows\App\T3DFK.ico'
$params=@{InputFile=$launcher;OutputFile=$OutputFile;IconFile=$iconPath;NoConsole=$true}
& $command @params -ErrorAction Stop
if(-not(Test-Path -LiteralPath $OutputFile -PathType Leaf)){throw "EXE was not created: $OutputFile"}
Write-Output "Created: $OutputFile"
