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

function Copy-Minidumps {
    try {
        $source = Join-Path $env:SystemRoot 'Minidump'
        $destination = Join-Path $SessionFolder 'Minidumps'
        $dumps = @(Get-ChildItem -Path $source -Filter '*.dmp' -File -ErrorAction SilentlyContinue)
        if ($dumps.Count -gt 0) {
            New-Item -Path $destination -ItemType Directory -Force -ErrorAction Stop | Out-Null
            $dumps | Copy-Item -Destination $destination -Force -ErrorAction Stop
            Write-Host "[PASS] $($dumps.Count) minidump(s) copied to $destination" -ForegroundColor Green
        } else {
            Write-Host "[INFO] No minidumps found in $source" -ForegroundColor Yellow
        }
    }
    catch { Write-ToolkitError -Context 'Copy minidumps' -ErrorRecord $_ }
}

Copy-Minidumps
