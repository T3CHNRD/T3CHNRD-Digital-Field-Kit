#Requires -Version 5.1
[CmdletBinding()]
param([string]$ToolkitRoot='')

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

if([string]::IsNullOrWhiteSpace($ToolkitRoot)){
    $commandPath=[Environment]::GetCommandLineArgs()[0]
    $commandDirectory=if($commandPath -and (Test-Path -LiteralPath $commandPath -PathType Leaf)){Split-Path -Parent ([IO.Path]::GetFullPath($commandPath))}else{$null}
    if($commandDirectory -and (Test-Path -LiteralPath (Join-Path $commandDirectory 'Windows\App\T3DFK-Windows.ps1') -PathType Leaf)){$root=$commandDirectory}
    elseif($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'Windows\App\T3DFK-Windows.ps1') -PathType Leaf)){$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
    else{$root=(Get-Location).Path}
}else{$root=[IO.Path]::GetFullPath($ToolkitRoot).TrimEnd('\')}
$ui=Join-Path $root 'Windows\App\T3DFK-Windows.ps1'
$logDir=Join-Path $env:LOCALAPPDATA 'T3DFK\StartupLogs'
$logPath=Join-Path $logDir 'last-startup-error.txt'

if(-not(Test-Path -LiteralPath $ui -PathType Leaf)){throw "Windows application source is missing: $ui"}
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if(Test-Path -LiteralPath $logPath){Remove-Item -LiteralPath $logPath -Force}

$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=New-Object Security.Principal.WindowsPrincipal($identity)
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    $commandPath=[Environment]::GetCommandLineArgs()[0]
    if($commandPath -and [IO.Path]::GetExtension($commandPath) -ieq '.exe' -and [IO.Path]::GetFileNameWithoutExtension($commandPath) -notin @('powershell','pwsh')){
        Start-Process -FilePath $commandPath -WorkingDirectory $root -Verb RunAs | Out-Null
    }else{
        $psExe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        Start-Process -FilePath $psExe -ArgumentList ('-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$ui+'" -ToolkitRoot "'+$root+'"') -WorkingDirectory $root -Verb RunAs -WindowStyle Hidden | Out-Null
    }
    return
}

try{
    . $ui -ToolkitRoot $root
}catch{
    ($_ | Out-String) | Set-Content -LiteralPath $logPath -Encoding UTF8
    throw
}
