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

function Collect-SlownessReport {
    Write-Host ''
    Write-Host 'Collecting performance/slowness snapshot...' -ForegroundColor Cyan

    $errorLog = Join-Path $SessionFolder 'Slowness-Collection-Warnings.txt'
    $warnings = New-Object System.Collections.Generic.List[string]
    $completed = 0

    function Add-SlownessWarning {
        param(
            [string]$Section,
            [string]$Message
        )
        $line = "[{0}] {1}: {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Section, $Message
        $warnings.Add($line)
        Write-Host "[WARN] $Section failed: $Message" -ForegroundColor Yellow
    }

    try {
        $processRows = foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {
            try {
                [pscustomobject]@{
                    Name         = $p.ProcessName
                    Id           = $p.Id
                    CPU          = $p.CPU
                    WorkingSetMB = [math]::Round(($p.WorkingSet64 / 1MB), 1)
                    Handles      = $p.HandleCount
                    Threads      = $p.Threads.Count
                }
            }
            catch {}
        }

        $processRows |
            Sort-Object CPU -Descending |
            Select-Object -First 35 |
            Format-Table -AutoSize |
            Out-File (Join-Path $SessionFolder 'Top-Processes.txt') -Width 260

        $completed++
        Write-Host '[PASS] Process snapshot collected.' -ForegroundColor Green
    }
    catch {
        Add-SlownessWarning 'Top processes' $_.Exception.Message
    }

    try {
        Get-CimInstance Win32_OperatingSystem -ErrorAction Stop |
            Select-Object Caption,Version,BuildNumber,LastBootUpTime,
                @{N='TotalMemoryGB';E={[math]::Round($_.TotalVisibleMemorySize / 1MB, 2)}},
                @{N='FreeMemoryGB';E={[math]::Round($_.FreePhysicalMemory / 1MB, 2)}} |
            Format-List |
            Out-File (Join-Path $SessionFolder 'OS-Memory-Uptime.txt') -Width 260

        $completed++
        Write-Host '[PASS] OS / memory / uptime collected.' -ForegroundColor Green
    }
    catch {
        Add-SlownessWarning 'OS / memory / uptime' $_.Exception.Message
    }

    try {
        Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop |
            Select-Object DeviceID,VolumeName,
                @{N='SizeGB';E={if ($_.Size) {[math]::Round($_.Size / 1GB, 2)} else {$null}}},
                @{N='FreeGB';E={if ($null -ne $_.FreeSpace) {[math]::Round($_.FreeSpace / 1GB, 2)} else {$null}}},
                @{N='FreePercent';E={
                    if ($_.Size -gt 0 -and $null -ne $_.FreeSpace) {
                        [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
                    } else {
                        $null
                    }
                }} |
            Format-Table -AutoSize |
            Out-File (Join-Path $SessionFolder 'Disk-Space.txt') -Width 260

        $completed++
        Write-Host '[PASS] Logical disk space collected.' -ForegroundColor Green
    }
    catch {
        Add-SlownessWarning 'Logical disks' $_.Exception.Message
    }

    try {
        Get-CimInstance Win32_DiskDrive -ErrorAction Stop |
            Select-Object Model,InterfaceType,MediaType,Status,
                @{N='SizeGB';E={if ($_.Size) {[math]::Round($_.Size / 1GB, 2)} else {$null}}} |
            Format-Table -AutoSize |
            Out-File (Join-Path $SessionFolder 'Physical-Disks.txt') -Width 260

        $completed++
        Write-Host '[PASS] Physical disk inventory collected.' -ForegroundColor Green
    }
    catch {
        Add-SlownessWarning 'Physical disks' $_.Exception.Message
    }

    try {
        Get-CimInstance Win32_StartupCommand -ErrorAction Stop |
            Select-Object Name,Command,Location,User |
            Format-Table -Wrap |
            Out-File (Join-Path $SessionFolder 'Startup-Programs.txt') -Width 260

        $completed++
        Write-Host '[PASS] Startup programs collected.' -ForegroundColor Green
    }
    catch {
        Add-SlownessWarning 'Startup programs' $_.Exception.Message
    }

    try {
        $driverFile = Join-Path $SessionFolder 'Drivers.csv'
        $driverOutput = & driverquery.exe /v /fo csv 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "driverquery.exe exited with code $LASTEXITCODE. $($driverOutput | Out-String)"
        }
        $driverOutput | Out-File $driverFile -Width 500 -Encoding utf8

        $completed++
        Write-Host '[PASS] Driver inventory collected.' -ForegroundColor Green
    }
    catch {
        Add-SlownessWarning 'Driver inventory' $_.Exception.Message
    }

    try {
        $counterFile = Join-Path $SessionFolder 'Performance-Counters.txt'
        $counterPaths = @(
            '\Processor(_Total)\% Processor Time',
            '\Memory\Available MBytes',
            '\Memory\% Committed Bytes In Use',
            '\PhysicalDisk(_Total)\% Disk Time',
            '\PhysicalDisk(_Total)\Avg. Disk Queue Length'
        )

        Get-Counter -Counter $counterPaths -SampleInterval 1 -MaxSamples 3 -ErrorAction Stop |
            ForEach-Object {
                $_.CounterSamples |
                    Select-Object Path,CookedValue
            } |
            Format-Table -AutoSize |
            Out-File $counterFile -Width 260

        $completed++
        Write-Host '[PASS] Performance counters collected.' -ForegroundColor Green
    }
    catch {
        Add-SlownessWarning 'Performance counters' $_.Exception.Message
    }

    if ($warnings.Count -gt 0) {
        $warnings | Out-File $errorLog -Encoding utf8 -Width 260
        Write-Host ''
        Write-Host "[PARTIAL] Completed $completed diagnostic sections with $($warnings.Count) warning(s)." -ForegroundColor Yellow
        Write-Host "Warnings: $errorLog" -ForegroundColor Yellow
    }
    else {
        Write-Host ''
        Write-Host "[PASS] All $completed performance/slowness sections completed." -ForegroundColor Green
    }

    Write-Host "Report folder: $SessionFolder" -ForegroundColor Cyan
}

Collect-SlownessReport
