#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InputFile,
    [string]$OutputFile,
    [string]$IconFile,
    [switch]$NoConsole,
    [switch]$CreateDesktopShortcut
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($InputFile)) {
    $InputFile = Read-Host 'Full path to the .ps1 file to compile'
}
if (-not (Test-Path -LiteralPath $InputFile -PathType Leaf)) {
    throw "Input script not found: $InputFile"
}
$InputFile = (Resolve-Path -LiteralPath $InputFile).Path

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $defaultOutput = [IO.Path]::ChangeExtension($InputFile, '.exe')
    $entered = Read-Host "Output EXE path [$defaultOutput]"
    $OutputFile = if ([string]::IsNullOrWhiteSpace($entered)) { $defaultOutput } else { $entered }
}

if ([string]::IsNullOrWhiteSpace($IconFile)) {
    $enteredIcon = Read-Host 'Optional .ico path (press Enter for none)'
    if (-not [string]::IsNullOrWhiteSpace($enteredIcon)) { $IconFile = $enteredIcon }
}
if ($IconFile -and -not (Test-Path -LiteralPath $IconFile -PathType Leaf)) {
    throw "Icon file not found: $IconFile"
}

$cmd = Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
if (-not $cmd) { $cmd = Get-Command ps2exe -ErrorAction SilentlyContinue }

if (-not $cmd) {
    Write-Host 'The ps2exe module is not installed.' -ForegroundColor Yellow
    $answer = Read-Host 'Install ps2exe for the current user from PowerShell Gallery? Type INSTALL to continue'
    if ($answer -cne 'INSTALL') { throw 'ps2exe installation cancelled.' }
    Install-Module -Name ps2exe -Scope CurrentUser -Force -AllowClobber
    Import-Module ps2exe -Force
    $cmd = Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue
    if (-not $cmd) { $cmd = Get-Command ps2exe -ErrorAction SilentlyContinue }
    if (-not $cmd) { throw 'ps2exe installed but no compiler command was found.' }
}

$params = @{ InputFile = $InputFile; OutputFile = $OutputFile }
if ($IconFile) { $params.IconFile = $IconFile }
if ($NoConsole) { $params.NoConsole = $true }

& $cmd @params

if (-not (Test-Path -LiteralPath $OutputFile -PathType Leaf)) {
    throw "Compilation did not create the expected EXE: $OutputFile"
}

Write-Host "EXE created: $OutputFile" -ForegroundColor Green

if ($CreateDesktopShortcut) {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktop (([IO.Path]::GetFileNameWithoutExtension($OutputFile)) + '.lnk')
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $OutputFile
    $shortcut.WorkingDirectory = Split-Path -Parent $OutputFile
    $shortcut.IconLocation = "$OutputFile,0"
    $shortcut.Save()
    Write-Host "Shortcut created: $shortcutPath" -ForegroundColor Green
}
