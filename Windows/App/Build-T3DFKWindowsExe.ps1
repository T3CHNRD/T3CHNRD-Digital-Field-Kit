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

$iconPath=Join-Path ([IO.Path]::GetTempPath()) 'T3DFK-generated.ico'
Add-Type -AssemblyName System.Drawing
$bitmap=New-Object Drawing.Bitmap(256,256)
$graphics=[Drawing.Graphics]::FromImage($bitmap)
try{
    $graphics.Clear([Drawing.Color]::FromArgb(7,48,72))
    $brush=New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(40,145,210))
    $accent=New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(181,225,55))
    try{
        $graphics.FillRectangle($brush,24,24,208,208)
        $graphics.FillRectangle($accent,58,58,58,58)
        $graphics.FillRectangle($accent,140,58,58,58)
        $graphics.FillRectangle($accent,58,140,58,58)
        $graphics.FillRectangle($accent,140,140,58,58)
    }finally{$brush.Dispose();$accent.Dispose()}
    $icon=[Drawing.Icon]::FromHandle($bitmap.GetHicon())
    try{$stream=[IO.File]::Open($iconPath,[IO.FileMode]::Create);try{$icon.Save($stream)}finally{$stream.Dispose()}}finally{$icon.Dispose()}
}finally{$graphics.Dispose();$bitmap.Dispose()}

$params=@{InputFile=$launcher;OutputFile=$OutputFile;IconFile=$iconPath;NoConsole=$true}
try{
    & $command @params -ErrorAction Stop
}finally{
    Remove-Item -LiteralPath $iconPath -Force -ErrorAction SilentlyContinue
}
if(-not(Test-Path -LiteralPath $OutputFile -PathType Leaf)){throw "EXE was not created: $OutputFile"}
Write-Output "Created: $OutputFile"
