#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ToolkitRoot = if ($env:TTK_TOOLKIT_ROOT) { $env:TTK_TOOLKIT_ROOT } else { Split-Path -Parent (Split-Path -Parent $PSScriptRoot) }
$ReportRoot = if ($env:TTK_REPORT_DIR) { $env:TTK_REPORT_DIR } else { Join-Path $ToolkitRoot 'Diagnostic-Reports' }
New-Item -Path $ReportRoot -ItemType Directory -Force | Out-Null
$SessionFolder = Join-Path $ReportRoot ("{0}_{1}" -f $env:COMPUTERNAME,(Get-Date -Format 'yyyy-MM-dd_HHmmss'))
New-Item -Path $SessionFolder -ItemType Directory -Force | Out-Null
$ToolkitErrorLog = Join-Path $SessionFolder 'Toolkit-Errors.log'
function Write-ToolkitError {
    param([string]$Context,[System.Management.Automation.ErrorRecord]$ErrorRecord)
    $line = '[{0}] {1}: {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Context, $ErrorRecord.Exception.Message
    try { Add-Content -LiteralPath $ToolkitErrorLog -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue } catch {}
    Write-Host "[ERROR] ${Context}: $($ErrorRecord.Exception.Message)" -ForegroundColor Red
}

function Collect-CrashReport {
    Write-Host ''
    Write-Host 'Collecting recent BSOD/crash evidence...' -ForegroundColor Cyan
    $startTime = (Get-Date).AddDays(-14)
    $warnings = New-Object System.Collections.Generic.List[string]

    $jobs = @(
        @{ Name='System crash events'; Run={
            Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=$startTime} -ErrorAction Stop |
                Where-Object { $_.Id -in 41,1001,6008 -or $_.ProviderName -match 'WHEA|disk|stor|nvme|volmgr|Kernel-Power' } |
                Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message |
                Format-List | Out-File (Join-Path $SessionFolder 'BSOD-System-Events.txt') -Width 260
        }},
        @{ Name='Application crash events'; Run={
            Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=$startTime} -ErrorAction Stop |
                Where-Object { $_.Id -in 1000,1001,1002 -or $_.ProviderName -match 'Application Error|Application Hang|Windows Error Reporting' } |
                Select-Object TimeCreated,Id,ProviderName,LevelDisplayName,Message |
                Format-List | Out-File (Join-Path $SessionFolder 'Application-Crashes.txt') -Width 260
        }},
        @{ Name='WER archive'; Run={
            $wer = 'C:\ProgramData\Microsoft\Windows\WER\ReportArchive'
            if (Test-Path -LiteralPath $wer) {
                Get-ChildItem $wer -Directory -ErrorAction Stop | Sort-Object LastWriteTime -Descending |
                    Select-Object -First 50 FullName,LastWriteTime | Format-Table -AutoSize |
                    Out-File (Join-Path $SessionFolder 'WER-Recent.txt') -Width 260
            } else { 'WER ReportArchive not present.' | Out-File (Join-Path $SessionFolder 'WER-Recent.txt') }
        }},
        @{ Name='System information'; Run={
            $output = & systeminfo.exe 2>&1
            if ($LASTEXITCODE -ne 0) { throw "systeminfo.exe exited with code $LASTEXITCODE" }
            $output | Out-File (Join-Path $SessionFolder 'SystemInfo.txt') -Width 260
        }}
    )

    $done=0
    foreach ($job in $jobs) {
        try { & $job.Run; $done++; Write-Host "[PASS] $($job.Name)" -ForegroundColor Green }
        catch { $warnings.Add("$($job.Name): $($_.Exception.Message)"); Write-Host "[WARN] $($job.Name): $($_.Exception.Message)" -ForegroundColor Yellow }
    }
    if ($warnings.Count) { $warnings | Out-File (Join-Path $SessionFolder 'Crash-Collection-Warnings.txt') -Encoding UTF8 }
    Write-Host "[PASS] Crash collection finished ($done/$($jobs.Count) sections). Reports: $SessionFolder" -ForegroundColor Green
}

Collect-CrashReport
