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

function Launch-DiagnosticTools {
    Write-Host ''
    Write-Host 'Launching Windows diagnostic consoles...' -ForegroundColor Cyan
    $tools = @(
        @{ File='perfmon.exe'; Args='/rel'; Name='Reliability Monitor' },
        @{ File='resmon.exe'; Args=''; Name='Resource Monitor' },
        @{ File='taskmgr.exe'; Args=''; Name='Task Manager' },
        @{ File='eventvwr.msc'; Args='/c:Application'; Name='Event Viewer - Application' },
        @{ File='eventvwr.msc'; Args='/c:System'; Name='Event Viewer - System' },
        @{ File='msinfo32.exe'; Args=''; Name='System Information' },
        @{ File='perfmon.exe'; Args=''; Name='Performance Monitor' },
        @{ File='devmgmt.msc'; Args=''; Name='Device Manager' },
        @{ File='diskmgmt.msc'; Args=''; Name='Disk Management' }
    )
    foreach ($tool in $tools) {
        try {
            if ([string]::IsNullOrWhiteSpace($tool.Args)) { Start-Process $tool.File }
            else { Start-Process $tool.File -ArgumentList $tool.Args }
            Write-Host "[PASS] $($tool.Name)"
            Start-Sleep -Milliseconds 300
        } catch {
            Write-Host "[WARN] Could not open $($tool.Name): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
}

Launch-DiagnosticTools
