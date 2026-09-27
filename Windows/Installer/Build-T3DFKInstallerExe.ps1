#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$ToolkitRoot='',
    [string]$OutputFile=''
)

$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ToolkitRoot)){$ToolkitRoot=Split-Path -Parent $PSScriptRoot}
$ToolkitRoot=[IO.Path]::GetFullPath($ToolkitRoot)
if([string]::IsNullOrWhiteSpace($OutputFile)){$OutputFile=Join-Path $ToolkitRoot 'INSTALL T3CHNRD Digital Field Kit.exe'}
$OutputFile=[IO.Path]::GetFullPath($OutputFile)
$launcher=Join-Path $ToolkitRoot 'Windows\Installer\T3DFK-Installer-Launcher.ps1'
$icon=Join-Path $ToolkitRoot 'Windows\App\T3DFK.ico'
if(-not(Test-Path -LiteralPath $launcher -PathType Leaf)){throw "Installer launcher source is missing: $launcher"}
if(-not(Test-Path -LiteralPath $icon -PathType Leaf)){throw "Installer icon is missing: $icon"}

$compiler=Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
if(-not $compiler){throw 'PS2EXE is required. Install it with: Install-Module ps2exe -Scope CurrentUser'}

& $compiler -InputFile $launcher -OutputFile $OutputFile -IconFile $icon -NoConsole -RequireAdmin -STA -Title 'Install T3CHNRD Digital Field Kit' -Description 'Install or update T3CHNRD Digital Field Kit' -Product 'T3CHNRD Digital Field Kit' -Version '11.0.0.0'
if(-not(Test-Path -LiteralPath $OutputFile -PathType Leaf)){throw "Installer EXE was not created: $OutputFile"}
Write-Output "Created branded elevated installer: $OutputFile"