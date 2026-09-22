<#
.SYNOPSIS
Temporarily prevents Windows 11 machines from sleeping for 24 hours,
temporarily disables scheduled shutdown/restart/logoff tasks,
then restores previous settings automatically.

.DESCRIPTION
Designed for Lansweeper deployment.

This script:
- Runs silently with no prompts or popups.
- Disables system sleep timeout on AC and DC power.
- Disables hibernate timeout on AC and DC power where supported.
- Disables hard disk timeout on AC and DC power.
- Does NOT change display/screen timeout.
- Attempts to abort a pending shutdown timer, if one exists.
- Temporarily disables enabled scheduled tasks that appear to shut down, restart, or log off the machine.
- Saves previous power settings locally for rollback.
- Saves only the scheduled shutdown tasks that this script disabled locally for rollback.
- Creates or replaces a scheduled rollback task.
- Restores original power settings and re-enables only the scheduled tasks it disabled.
- Checks Cisco AnyConnect / Cisco Secure Client VPN status.
- Writes ALL result logs to ONE required CSV only.

.REQUIRED CSV
\\alblnetapp02\public\IT Tracking - Requests_Projects\bootcheck_results\updated_machines\SleepHold_Results.csv

.NOTES
Run as Administrator.
Designed for Lansweeper deployment.
#>

param(
    [switch]$Rollback,

    [double]$DurationHours = 24,

    [switch]$SkipScheduledShutdownTaskDisable,

    [switch]$SkipPendingShutdownAbort
)

# -----------------------------
# Script Config
# -----------------------------

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$ScriptVersion = "1.5.1"
$SchemaVersion = "6"

$RequiredReportPath = "\\alblnetapp02\public\IT Tracking - Requests_Projects\bootcheck_results\updated_machines\SleepHold_Results.csv"

$LocalStateRoot = "C:\ProgramData\ALBL\SleepHold"
$StateFile = Join-Path $LocalStateRoot "SleepHold_PreviousPowerSettings.json"
$TaskStateFile = Join-Path $LocalStateRoot "SleepHold_DisabledScheduledShutdownTasks.json"
$RollbackScriptPath = Join-Path $LocalStateRoot "SleepHold.ps1"

$RollbackTaskName = "ALBL Temporary Sleep Hold Rollback"

$ExpectedCsvHeader = @(
    "Timestamp",
    "ComputerName",
    "UserName",
    "Action",
    "Result",
    "FailureReason",
    "ScriptVersion",
    "SchemaVersion",
    "DurationHours",
    "ActivePowerSchemeGuid",
    "HoldAlreadyActive",
    "PreviousSleepAcMinutes",
    "PreviousSleepDcMinutes",
    "PreviousHibernateAcMinutes",
    "PreviousHibernateDcMinutes",
    "PreviousDiskAcMinutes",
    "PreviousDiskDcMinutes",
    "NewSleepAcMinutes",
    "NewSleepDcMinutes",
    "NewHibernateAcMinutes",
    "NewHibernateDcMinutes",
    "NewDiskAcMinutes",
    "NewDiskDcMinutes",
    "PendingShutdownAbortResult",
    "ScheduledShutdownTasksDisabledCount",
    "ScheduledShutdownTasksDisabled",
    "ScheduledShutdownTaskDisableFailureCount",
    "ScheduledShutdownTaskDisableFailures",
    "ScheduledShutdownTasksRestoredCount",
    "ScheduledShutdownTasksRestored",
    "ScheduledShutdownTaskRestoreFailureCount",
    "ScheduledShutdownTaskRestoreFailures",
    "VpnServiceName",
    "VpnServiceStatus",
    "VpnAdapterStatus",
    "VpnIpDetected",
    "VpnStatus",
    "RequiredReportPath",
    "RunningAsAdmin",
    "RollbackTaskName",
    "RollbackScheduledFor"
)

# -----------------------------
# Basic Helpers
# -----------------------------

function Test-IsAdministrator {
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Verbose "Could not determine administrator status: $($_.Exception.Message)"
        return $false
    }
}

function Initialize-FolderPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function ConvertTo-CsvSafeString {
    param(
        [object]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return [string]$Value
}

function ConvertTo-ListText {
    param(
        [object[]]$Items,
        [string]$PropertyName = "DisplayName"
    )

    if (-not $Items -or $Items.Count -eq 0) {
        return ""
    }

    $values = @()

    foreach ($item in $Items) {
        if ($item.PSObject.Properties.Name -contains $PropertyName -and -not [string]::IsNullOrWhiteSpace([string]$item.$PropertyName)) {
            $values += [string]$item.$PropertyName
        }
    }

    return ($values -join "; ")
}

# -----------------------------
# Power Config Helpers
# -----------------------------

function Get-ActivePowerSchemeGuid {
    $output = powercfg /getactivescheme 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get active power scheme. Output: $output"
    }

    if ($output -match "GUID:\s+([a-fA-F0-9\-]+)") {
        return $matches[1]
    }

    throw "Could not parse active power scheme GUID from output: $output"
}

function Get-PowerCfgSettingMinute {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SchemeGuid,

        [Parameter(Mandatory = $true)]
        [string]$SubGroup,

        [Parameter(Mandatory = $true)]
        [string]$Setting
    )

    $output = powercfg /query $SchemeGuid $SubGroup $Setting 2>&1

    if ($LASTEXITCODE -ne 0) {
        return [PSCustomObject]@{
            Supported = $false
            ACMinutes = ""
            DCMinutes = ""
            Error = "Failed to query power setting $Setting. Output: $output"
        }
    }

    $acHex = $null
    $dcHex = $null

    foreach ($line in $output) {
        if ($line -match "Current AC Power Setting Index:\s+0x([a-fA-F0-9]+)") {
            $acHex = $matches[1]
        }

        if ($line -match "Current DC Power Setting Index:\s+0x([a-fA-F0-9]+)") {
            $dcHex = $matches[1]
        }
    }

    if ($null -eq $acHex -or $null -eq $dcHex) {
        return [PSCustomObject]@{
            Supported = $false
            ACMinutes = ""
            DCMinutes = ""
            Error = "Could not parse AC/DC values for setting $Setting."
        }
    }

    $acSeconds = [Convert]::ToInt64($acHex, 16)
    $dcSeconds = [Convert]::ToInt64($dcHex, 16)

    return [PSCustomObject]@{
        Supported = $true
        ACMinutes = [int]($acSeconds / 60)
        DCMinutes = [int]($dcSeconds / 60)
        Error = ""
    }
}

function Set-PowerCfgSettingMinute {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SchemeGuid,

        [Parameter(Mandatory = $true)]
        [string]$SubGroup,

        [Parameter(Mandatory = $true)]
        [string]$Setting,

        [Parameter(Mandatory = $true)]
        [int]$ACMinutes,

        [Parameter(Mandatory = $true)]
        [int]$DCMinutes,

        [bool]$Required = $true
    )

    $acSeconds = $ACMinutes * 60
    $dcSeconds = $DCMinutes * 60

    if (-not $PSCmdlet.ShouldProcess("$SchemeGuid $SubGroup $Setting", "Set AC/DC values to $ACMinutes/$DCMinutes minutes")) {
        return $false
    }

    $acOutput = powercfg /setacvalueindex $SchemeGuid $SubGroup $Setting $acSeconds 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($Required) {
            throw "Failed to set AC value for $Setting. Output: $acOutput"
        }
        return $false
    }

    $dcOutput = powercfg /setdcvalueindex $SchemeGuid $SubGroup $Setting $dcSeconds 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($Required) {
            throw "Failed to set DC value for $Setting. Output: $dcOutput"
        }
        return $false
    }

    $activeOutput = powercfg /setactive $SchemeGuid 2>&1
    if ($LASTEXITCODE -ne 0) {
        if ($Required) {
            throw "Failed to re-activate power scheme $SchemeGuid. Output: $activeOutput"
        }
        return $false
    }

    return $true
}

# -----------------------------
# VPN Helper
# -----------------------------

function Get-CiscoVpnStatus {
    $vpnServiceNames = @(
        "vpnagent",
        "csc_vpnagent",
        "Cisco AnyConnect Secure Mobility Agent",
        "Cisco Secure Client - AnyConnect VPN Agent"
    )

    $service = $null

    foreach ($name in $vpnServiceNames) {
        $service = Get-Service -Name $name -ErrorAction SilentlyContinue
        if ($service) {
            break
        }
    }

    if (-not $service) {
        $service = Get-Service -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -like "*vpnagent*" -or
                $_.DisplayName -like "*AnyConnect*" -or
                $_.DisplayName -like "*Cisco Secure Client*"
            } |
            Select-Object -First 1
    }

    $adapter = Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object {
            $_.InterfaceDescription -like "*AnyConnect*" -or
            $_.InterfaceDescription -like "*Cisco Secure Client*" -or
            $_.Name -like "*AnyConnect*" -or
            $_.Name -like "*Cisco*"
        } |
        Sort-Object Status -Descending |
        Select-Object -First 1

    $vpnIpDetected = $false

    if ($adapter) {
        $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -and
                $_.IPAddress -notlike "169.254.*"
            } |
            Select-Object -First 1

        if ($ip) {
            $vpnIpDetected = $true
        }
    }

    $serviceName = if ($service) { $service.Name } else { "NotFound" }
    $serviceStatus = if ($service) { $service.Status.ToString() } else { "NotFound" }
    $adapterStatus = if ($adapter) { $adapter.Status.ToString() } else { "NotFound" }

    $vpnStatus = "Unknown"

    if (-not $service) {
        $vpnStatus = "CiscoVpnServiceNotFound"
    }
    elseif ($service.Status -ne "Running") {
        $vpnStatus = "CiscoVpnServiceNotRunning"
    }
    elseif (-not $adapter) {
        $vpnStatus = "CiscoVpnAdapterNotFound"
    }
    elseif ($adapter.Status -ne "Up") {
        $vpnStatus = "CiscoVpnAdapterNotUp"
    }
    elseif (-not $vpnIpDetected) {
        $vpnStatus = "CiscoVpnNoIpDetected"
    }
    else {
        $vpnStatus = "CiscoVpnAppearsConnected"
    }

    return [PSCustomObject]@{
        VpnServiceName   = $serviceName
        VpnServiceStatus = $serviceStatus
        VpnAdapterStatus = $adapterStatus
        VpnIpDetected    = $vpnIpDetected
        VpnStatus        = $vpnStatus
    }
}

# -----------------------------
# CSV Helpers - REQUIRED ONE CSV ONLY
# -----------------------------

function Initialize-RequiredCsvFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CsvPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Header
    )

    $folder = Split-Path -Path $CsvPath -Parent

    if (-not (Test-Path -LiteralPath $folder)) {
        throw "Required CSV folder does not exist or is not accessible: $folder"
    }

    $expectedHeaderLine = ($Header -join ",")

    if (Test-Path -LiteralPath $CsvPath) {
        $existingHeader = Get-Content -LiteralPath $CsvPath -TotalCount 1 -ErrorAction Stop

        if ($existingHeader -ne $expectedHeaderLine) {
            throw "Required CSV already exists but its header does not match this script version. Required path: $CsvPath"
        }
    }
    else {
        Set-Content -LiteralPath $CsvPath -Value $expectedHeaderLine -Encoding UTF8
    }
}

function Write-RequiredCsv {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Row
    )

    $targetPath = $RequiredReportPath

    Initialize-RequiredCsvFile -CsvPath $targetPath -Header $ExpectedCsvHeader

    $Row["RequiredReportPath"] = $targetPath

    $ordered = [ordered]@{}

    foreach ($column in $ExpectedCsvHeader) {
        if ($Row.ContainsKey($column)) {
            $ordered[$column] = ConvertTo-CsvSafeString -Value $Row[$column]
        }
        else {
            $ordered[$column] = ""
        }
    }

    $csvLine = ([PSCustomObject]$ordered | ConvertTo-Csv -NoTypeInformation)[1]

    $maxAttempts = 10
    $attempt = 0
    $written = $false
    $lastError = ""

    while (-not $written -and $attempt -lt $maxAttempts) {
        $attempt++

        try {
            Add-Content -LiteralPath $targetPath -Value $csvLine -Encoding UTF8
            $written = $true
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Milliseconds (300 * $attempt)
        }
    }

    if (-not $written) {
        throw "Failed to write required CSV after $maxAttempts attempts. Path: $targetPath. Last error: $lastError"
    }
}

# -----------------------------
# Scheduled Shutdown Task Helpers
# -----------------------------

function ConvertTo-TaskDisplayName {
    param(
        [string]$TaskPath,
        [string]$TaskName
    )

    if ([string]::IsNullOrWhiteSpace($TaskPath)) {
        return "\$TaskName"
    }

    return "$TaskPath$TaskName"
}

function Test-ScheduledShutdownTask {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Task
    )

    if ($Task.TaskName -eq $RollbackTaskName) {
        return $false
    }

    if ($Task.State -eq "Disabled") {
        return $false
    }

    foreach ($action in $Task.Actions) {
        $execute = ""
        $arguments = ""

        try {
            $execute = [string]$action.Execute
        }
        catch {
            Write-Verbose "Could not read scheduled task action Execute value: $($_.Exception.Message)"
            $execute = ""
        }

        try {
            $arguments = [string]$action.Arguments
        }
        catch {
            Write-Verbose "Could not read scheduled task action Arguments value: $($_.Exception.Message)"
            $arguments = ""
        }

        $combined = "$execute $arguments"

        if ($combined -match '(?i)(^|\\|\s|")shutdown(\.exe)?("|\s|$)') {
            return $true
        }

        if ($combined -match "(?i)Stop-Computer") {
            return $true
        }

        if ($combined -match "(?i)Restart-Computer") {
            return $true
        }

        if ($combined -match '(?i)(^|\\|\s|")logoff(\.exe)?("|\s|$)') {
            return $true
        }
    }

    return $false
}

function Read-DisabledTaskState {
    if (-not (Test-Path -LiteralPath $TaskStateFile)) {
        return @()
    }

    $raw = Get-Content -LiteralPath $TaskStateFile -Raw -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    return @($raw | ConvertFrom-Json)
}

function Save-DisabledTaskState {
    param(
        [object[]]$Tasks
    )

    @($Tasks) |
        ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath $TaskStateFile -Encoding UTF8 -Force
}

function Disable-ScheduledShutdownTaskTemporarily {
    $results = @()
    $existingSavedTasks = @(Read-DisabledTaskState)
    $savedTasks = @($existingSavedTasks)

    $existingKeys = @{}
    foreach ($savedTask in $existingSavedTasks) {
        $key = "$($savedTask.TaskPath)|$($savedTask.TaskName)"
        $existingKeys[$key] = $true
    }

    $tasks = Get-ScheduledTask -ErrorAction Stop

    foreach ($task in $tasks) {
        if (Test-ScheduledShutdownTask -Task $task) {
            $displayName = ConvertTo-TaskDisplayName -TaskPath $task.TaskPath -TaskName $task.TaskName
            $key = "$($task.TaskPath)|$($task.TaskName)"

            try {
                Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop | Out-Null

                $result = [PSCustomObject]@{
                    TaskName = $task.TaskName
                    TaskPath = $task.TaskPath
                    DisplayName = $displayName
                    DisabledAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    Result = "Disabled"
                    Error = ""
                }

                $results += $result

                if (-not $existingKeys.ContainsKey($key)) {
                    $savedTasks += [PSCustomObject]@{
                        TaskName = $task.TaskName
                        TaskPath = $task.TaskPath
                        DisplayName = $displayName
                        DisabledAt = $result.DisabledAt
                    }
                    $existingKeys[$key] = $true
                }
            }
            catch {
                $results += [PSCustomObject]@{
                    TaskName = $task.TaskName
                    TaskPath = $task.TaskPath
                    DisplayName = $displayName
                    DisabledAt = ""
                    Result = "Failed"
                    Error = $_.Exception.Message
                }
            }
        }
    }

    Save-DisabledTaskState -Tasks $savedTasks

    return $results
}

function Restore-TemporarilyDisabledScheduledShutdownTask {
    $restoredTasks = @()
    $savedTasks = @(Read-DisabledTaskState)

    if ($savedTasks.Count -eq 0) {
        return $restoredTasks
    }

    foreach ($savedTask in $savedTasks) {
        $displayName = ConvertTo-TaskDisplayName -TaskPath $savedTask.TaskPath -TaskName $savedTask.TaskName

        try {
            Enable-ScheduledTask -TaskName $savedTask.TaskName -TaskPath $savedTask.TaskPath -ErrorAction Stop | Out-Null

            $restoredTasks += [PSCustomObject]@{
                TaskName = $savedTask.TaskName
                TaskPath = $savedTask.TaskPath
                DisplayName = $displayName
                RestoredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Result = "Restored"
                Error = ""
            }
        }
        catch {
            $restoredTasks += [PSCustomObject]@{
                TaskName = $savedTask.TaskName
                TaskPath = $savedTask.TaskPath
                DisplayName = $displayName
                RestoredAt = ""
                Result = "Failed"
                Error = $_.Exception.Message
            }
        }
    }

    return $restoredTasks
}

function Invoke-PendingShutdownAbort {
    param(
        [bool]$SkipAbort = $false
    )

    if ($SkipAbort) {
        return "Skipped"
    }

    try {
        $output = shutdown.exe /a 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            return "Pending shutdown aborted. Output: $output"
        }

        return "No pending shutdown detected or abort was not needed. ExitCode: $exitCode Output: $output"
    }
    catch {
        return "Pending shutdown abort check failed: $($_.Exception.Message)"
    }
}

# -----------------------------
# State Helpers
# -----------------------------

function Read-ExistingPowerState {
    if (-not (Test-Path -LiteralPath $StateFile)) {
        return $null
    }

    $raw = Get-Content -LiteralPath $StateFile -Raw -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    return ($raw | ConvertFrom-Json)
}

function ConvertTo-PowerSettingObject {
    param(
        [object]$Source,
        [string]$AcProperty,
        [string]$DcProperty,
        [bool]$Supported = $true
    )

    return [PSCustomObject]@{
        Supported = $Supported
        ACMinutes = $Source.$AcProperty
        DCMinutes = $Source.$DcProperty
        Error = ""
    }
}

# -----------------------------
# Result Row Helper
# -----------------------------

function ConvertTo-BaseResultRow {
    param(
        [string]$Action,
        [string]$Result,
        [string]$FailureReason,
        [object]$VpnInfo,
        [string]$SchemeGuid,
        [bool]$HoldAlreadyActive,
        [object]$PreviousSleep,
        [object]$PreviousHibernate,
        [object]$PreviousDisk,
        [object]$NewSleep,
        [object]$NewHibernate,
        [object]$NewDisk,
        [string]$PendingShutdownAbortResult,
        [object[]]$ScheduledShutdownTaskDisableResults,
        [object[]]$ScheduledShutdownTaskRestoreResults,
        [string]$RollbackScheduledFor
    )

    $disableSuccesses = @($ScheduledShutdownTaskDisableResults | Where-Object { $_.Result -eq "Disabled" })
    $disableFailures = @($ScheduledShutdownTaskDisableResults | Where-Object { $_.Result -eq "Failed" })

    $restoreSuccesses = @($ScheduledShutdownTaskRestoreResults | Where-Object { $_.Result -eq "Restored" })
    $restoreFailures = @($ScheduledShutdownTaskRestoreResults | Where-Object { $_.Result -eq "Failed" })

    return @{
        Timestamp                                = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName                             = $env:COMPUTERNAME
        UserName                                 = "$env:USERDOMAIN\$env:USERNAME"
        Action                                   = $Action
        Result                                   = $Result
        FailureReason                            = $FailureReason
        ScriptVersion                            = $ScriptVersion
        SchemaVersion                            = $SchemaVersion
        DurationHours                            = $DurationHours
        ActivePowerSchemeGuid                    = $SchemeGuid
        HoldAlreadyActive                        = $HoldAlreadyActive

        PreviousSleepAcMinutes                   = if ($PreviousSleep) { $PreviousSleep.ACMinutes } else { "" }
        PreviousSleepDcMinutes                   = if ($PreviousSleep) { $PreviousSleep.DCMinutes } else { "" }

        PreviousHibernateAcMinutes               = if ($PreviousHibernate) { $PreviousHibernate.ACMinutes } else { "" }
        PreviousHibernateDcMinutes               = if ($PreviousHibernate) { $PreviousHibernate.DCMinutes } else { "" }

        PreviousDiskAcMinutes                    = if ($PreviousDisk) { $PreviousDisk.ACMinutes } else { "" }
        PreviousDiskDcMinutes                    = if ($PreviousDisk) { $PreviousDisk.DCMinutes } else { "" }

        NewSleepAcMinutes                        = if ($NewSleep) { $NewSleep.ACMinutes } else { "" }
        NewSleepDcMinutes                        = if ($NewSleep) { $NewSleep.DCMinutes } else { "" }

        NewHibernateAcMinutes                    = if ($NewHibernate) { $NewHibernate.ACMinutes } else { "" }
        NewHibernateDcMinutes                    = if ($NewHibernate) { $NewHibernate.DCMinutes } else { "" }

        NewDiskAcMinutes                         = if ($NewDisk) { $NewDisk.ACMinutes } else { "" }
        NewDiskDcMinutes                         = if ($NewDisk) { $NewDisk.DCMinutes } else { "" }

        PendingShutdownAbortResult               = $PendingShutdownAbortResult

        ScheduledShutdownTasksDisabledCount      = $disableSuccesses.Count
        ScheduledShutdownTasksDisabled           = ConvertTo-ListText -Items $disableSuccesses
        ScheduledShutdownTaskDisableFailureCount = $disableFailures.Count
        ScheduledShutdownTaskDisableFailures     = ConvertTo-ListText -Items $disableFailures

        ScheduledShutdownTasksRestoredCount      = $restoreSuccesses.Count
        ScheduledShutdownTasksRestored           = ConvertTo-ListText -Items $restoreSuccesses
        ScheduledShutdownTaskRestoreFailureCount = $restoreFailures.Count
        ScheduledShutdownTaskRestoreFailures     = ConvertTo-ListText -Items $restoreFailures

        VpnServiceName                           = if ($VpnInfo) { $VpnInfo.VpnServiceName } else { "" }
        VpnServiceStatus                         = if ($VpnInfo) { $VpnInfo.VpnServiceStatus } else { "" }
        VpnAdapterStatus                         = if ($VpnInfo) { $VpnInfo.VpnAdapterStatus } else { "" }
        VpnIpDetected                            = if ($VpnInfo) { $VpnInfo.VpnIpDetected } else { "" }
        VpnStatus                                = if ($VpnInfo) { $VpnInfo.VpnStatus } else { "" }

        RequiredReportPath                       = $RequiredReportPath
        RunningAsAdmin                           = Test-IsAdministrator
        RollbackTaskName                         = $RollbackTaskName
        RollbackScheduledFor                     = $RollbackScheduledFor
    }
}

# -----------------------------
# Main
# -----------------------------

Initialize-FolderPath -Path $LocalStateRoot

try {
    if ($PSCommandPath) {
        $currentScriptContent = Get-Content -LiteralPath $PSCommandPath -Raw -ErrorAction Stop
        Set-Content -LiteralPath $RollbackScriptPath -Value $currentScriptContent -Encoding UTF8 -Force
    }
    elseif (-not (Test-Path -LiteralPath $RollbackScriptPath)) {
        throw "PSCommandPath is empty and rollback script does not already exist at $RollbackScriptPath. Run this script from a saved .ps1 file."
    }
}
catch {
    Write-Verbose "Could not copy script to rollback path: $($_.Exception.Message)"
}

$vpnInfo = Get-CiscoVpnStatus

if (-not (Test-IsAdministrator)) {
    $row = ConvertTo-BaseResultRow `
        -Action $(if ($Rollback) { "Rollback" } else { "Apply" }) `
        -Result "Failed" `
        -FailureReason "Script must run as Administrator." `
        -VpnInfo $vpnInfo `
        -SchemeGuid "" `
        -HoldAlreadyActive $false `
        -PreviousSleep $null `
        -PreviousHibernate $null `
        -PreviousDisk $null `
        -NewSleep $null `
        -NewHibernate $null `
        -NewDisk $null `
        -PendingShutdownAbortResult "" `
        -ScheduledShutdownTaskDisableResults @() `
        -ScheduledShutdownTaskRestoreResults @() `
        -RollbackScheduledFor ""

    Write-RequiredCsv -Row $row
    exit 1
}

# Power setting aliases:
# SUB_SLEEP / STANDBYIDLE = Sleep after
# SUB_SLEEP / HIBERNATEIDLE = Hibernate after
# SUB_DISK / DISKIDLE = Turn off hard disk after
# Display timeout is intentionally not changed.

$SubSleep = "SUB_SLEEP"
$SleepSetting = "STANDBYIDLE"
$HibernateSetting = "HIBERNATEIDLE"

$SubDisk = "SUB_DISK"
$DiskSetting = "DISKIDLE"

if ($Rollback) {
    try {
        $restoredShutdownTasks = Restore-TemporarilyDisabledScheduledShutdownTask

        if (-not (Test-Path -LiteralPath $StateFile)) {
            throw "State file not found. Cannot restore previous power settings: $StateFile"
        }

        $state = Get-Content -LiteralPath $StateFile -Raw | ConvertFrom-Json
        $schemeGuid = $state.ActivePowerSchemeGuid

        $previousSleep = [PSCustomObject]@{
            Supported = $true
            ACMinutes = [int]$state.PreviousSleepAcMinutes
            DCMinutes = [int]$state.PreviousSleepDcMinutes
            Error = ""
        }

        $previousHibernate = [PSCustomObject]@{
            Supported = [bool]$state.PreviousHibernateSupported
            ACMinutes = $state.PreviousHibernateAcMinutes
            DCMinutes = $state.PreviousHibernateDcMinutes
            Error = ""
        }

        $previousDisk = [PSCustomObject]@{
            Supported = $true
            ACMinutes = [int]$state.PreviousDiskAcMinutes
            DCMinutes = [int]$state.PreviousDiskDcMinutes
            Error = ""
        }

        Set-PowerCfgSettingMinute `
            -SchemeGuid $schemeGuid `
            -SubGroup $SubSleep `
            -Setting $SleepSetting `
            -ACMinutes ([int]$previousSleep.ACMinutes) `
            -DCMinutes ([int]$previousSleep.DCMinutes) `
            -Required $true | Out-Null

        if ($previousHibernate.Supported -eq $true -and $previousHibernate.ACMinutes -ne "" -and $previousHibernate.DCMinutes -ne "") {
            Set-PowerCfgSettingMinute `
                -SchemeGuid $schemeGuid `
                -SubGroup $SubSleep `
                -Setting $HibernateSetting `
                -ACMinutes ([int]$previousHibernate.ACMinutes) `
                -DCMinutes ([int]$previousHibernate.DCMinutes) `
                -Required $false | Out-Null
        }

        Set-PowerCfgSettingMinute `
            -SchemeGuid $schemeGuid `
            -SubGroup $SubDisk `
            -Setting $DiskSetting `
            -ACMinutes ([int]$previousDisk.ACMinutes) `
            -DCMinutes ([int]$previousDisk.DCMinutes) `
            -Required $true | Out-Null

        $restoredSleep = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubSleep -Setting $SleepSetting
        $restoredHibernate = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubSleep -Setting $HibernateSetting
        $restoredDisk = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubDisk -Setting $DiskSetting

        $vpnInfo = Get-CiscoVpnStatus
        $restoreFailures = @($restoredShutdownTasks | Where-Object { $_.Result -eq "Failed" })

        $result = "Success"
        $failureMessages = @()

        if ($restoreFailures.Count -gt 0) {
            $result = "SuccessWithWarning"
            $failureMessages += "Power settings restored, but one or more scheduled shutdown/restart/logoff tasks could not be restored."
        }

        $failureReason = ($failureMessages -join " | ")

        $row = ConvertTo-BaseResultRow `
            -Action "Rollback" `
            -Result $result `
            -FailureReason $failureReason `
            -VpnInfo $vpnInfo `
            -SchemeGuid $schemeGuid `
            -HoldAlreadyActive $false `
            -PreviousSleep $previousSleep `
            -PreviousHibernate $previousHibernate `
            -PreviousDisk $previousDisk `
            -NewSleep $restoredSleep `
            -NewHibernate $restoredHibernate `
            -NewDisk $restoredDisk `
            -PendingShutdownAbortResult "" `
            -ScheduledShutdownTaskDisableResults @() `
            -ScheduledShutdownTaskRestoreResults $restoredShutdownTasks `
            -RollbackScheduledFor ""

        Write-RequiredCsv -Row $row

        try {
            Unregister-ScheduledTask -TaskName $RollbackTaskName -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose "Could not unregister rollback task: $($_.Exception.Message)"
        }

        try {
            Remove-Item -LiteralPath $StateFile -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $TaskStateFile -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Verbose "Could not remove state files after rollback: $($_.Exception.Message)"
        }

        exit 0
    }
    catch {
        $vpnInfo = Get-CiscoVpnStatus

        $row = ConvertTo-BaseResultRow `
            -Action "Rollback" `
            -Result "Failed" `
            -FailureReason $_.Exception.Message `
            -VpnInfo $vpnInfo `
            -SchemeGuid "" `
            -HoldAlreadyActive $false `
            -PreviousSleep $null `
            -PreviousHibernate $null `
            -PreviousDisk $null `
            -NewSleep $null `
            -NewHibernate $null `
            -NewDisk $null `
            -PendingShutdownAbortResult "" `
            -ScheduledShutdownTaskDisableResults @() `
            -ScheduledShutdownTaskRestoreResults @() `
            -RollbackScheduledFor ""

        Write-RequiredCsv -Row $row
        exit 1
    }
}
else {
    try {
        $schemeGuid = Get-ActivePowerSchemeGuid
        $existingState = Read-ExistingPowerState
        $holdAlreadyActive = $false

        if ($existingState) {
            $holdAlreadyActive = $true

            $previousSleep = ConvertTo-PowerSettingObject `
                -Source $existingState `
                -AcProperty "PreviousSleepAcMinutes" `
                -DcProperty "PreviousSleepDcMinutes" `
                -Supported $true

            $previousHibernate = ConvertTo-PowerSettingObject `
                -Source $existingState `
                -AcProperty "PreviousHibernateAcMinutes" `
                -DcProperty "PreviousHibernateDcMinutes" `
                -Supported ([bool]$existingState.PreviousHibernateSupported)

            $previousDisk = ConvertTo-PowerSettingObject `
                -Source $existingState `
                -AcProperty "PreviousDiskAcMinutes" `
                -DcProperty "PreviousDiskDcMinutes" `
                -Supported $true
        }
        else {
            $previousSleep = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubSleep -Setting $SleepSetting
            $previousHibernate = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubSleep -Setting $HibernateSetting
            $previousDisk = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubDisk -Setting $DiskSetting

            if (-not $previousSleep.Supported) {
                throw "Could not read current sleep timeout setting. $($previousSleep.Error)"
            }

            if (-not $previousDisk.Supported) {
                throw "Could not read current disk timeout setting. $($previousDisk.Error)"
            }
        }

        $state = [PSCustomObject]@{
            ComputerName                  = $env:COMPUTERNAME
            SavedAt                       = if ($existingState -and $existingState.SavedAt) { $existingState.SavedAt } else { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
            LastAppliedAt                 = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ScriptVersion                 = $ScriptVersion
            SchemaVersion                 = $SchemaVersion
            ActivePowerSchemeGuid         = $schemeGuid

            PreviousSleepAcMinutes        = $previousSleep.ACMinutes
            PreviousSleepDcMinutes        = $previousSleep.DCMinutes

            PreviousHibernateSupported    = $previousHibernate.Supported
            PreviousHibernateAcMinutes    = $previousHibernate.ACMinutes
            PreviousHibernateDcMinutes    = $previousHibernate.DCMinutes

            PreviousDiskAcMinutes         = $previousDisk.ACMinutes
            PreviousDiskDcMinutes         = $previousDisk.DCMinutes

            DurationHours                 = $DurationHours
        }

        $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $StateFile -Encoding UTF8 -Force

        $pendingShutdownAbortResult = Invoke-PendingShutdownAbort -SkipAbort $SkipPendingShutdownAbort.IsPresent

        $disabledShutdownTasks = @()
        if (-not $SkipScheduledShutdownTaskDisable) {
            $disabledShutdownTasks = Disable-ScheduledShutdownTaskTemporarily
        }

        $disabledShutdownTaskFailures = @($disabledShutdownTasks | Where-Object { $_.Result -eq "Failed" })

        Set-PowerCfgSettingMinute `
            -SchemeGuid $schemeGuid `
            -SubGroup $SubSleep `
            -Setting $SleepSetting `
            -ACMinutes 0 `
            -DCMinutes 0 `
            -Required $true | Out-Null

        if ($previousHibernate.Supported -eq $true) {
            Set-PowerCfgSettingMinute `
                -SchemeGuid $schemeGuid `
                -SubGroup $SubSleep `
                -Setting $HibernateSetting `
                -ACMinutes 0 `
                -DCMinutes 0 `
                -Required $false | Out-Null
        }

        Set-PowerCfgSettingMinute `
            -SchemeGuid $schemeGuid `
            -SubGroup $SubDisk `
            -Setting $DiskSetting `
            -ACMinutes 0 `
            -DCMinutes 0 `
            -Required $true | Out-Null

        $newSleep = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubSleep -Setting $SleepSetting
        $newHibernate = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubSleep -Setting $HibernateSetting
        $newDisk = Get-PowerCfgSettingMinute -SchemeGuid $schemeGuid -SubGroup $SubDisk -Setting $DiskSetting

        if (-not (Test-Path -LiteralPath $RollbackScriptPath)) {
            throw "Rollback script was not found at $RollbackScriptPath. Save and run this script from a .ps1 file so it can copy itself for rollback."
        }

        $rollbackAt = (Get-Date).AddHours($DurationHours)
        $rollbackAtText = $rollbackAt.ToString("yyyy-MM-dd HH:mm:ss")

        $taskArgument = "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$RollbackScriptPath`" -Rollback -DurationHours $DurationHours"

        $taskAction = New-ScheduledTaskAction `
            -Execute "powershell.exe" `
            -Argument $taskArgument

        $taskTrigger = New-ScheduledTaskTrigger -Once -At $rollbackAt

        $taskPrincipal = New-ScheduledTaskPrincipal `
            -UserId "SYSTEM" `
            -RunLevel Highest

        $taskSettings = New-ScheduledTaskSettingsSet `
            -AllowStartIfOnBatteries `
            -DontStopIfGoingOnBatteries `
            -StartWhenAvailable `
            -ExecutionTimeLimit (New-TimeSpan -Minutes 30)

        Register-ScheduledTask `
            -TaskName $RollbackTaskName `
            -Action $taskAction `
            -Trigger $taskTrigger `
            -Principal $taskPrincipal `
            -Settings $taskSettings `
            -Force | Out-Null

        $vpnInfo = Get-CiscoVpnStatus

        $result = "Success"
        $failureMessages = @()

        if ($vpnInfo.VpnStatus -ne "CiscoVpnAppearsConnected") {
            $result = "SuccessWithWarning"
            $failureMessages += "Sleep hold applied, but Cisco VPN check returned: $($vpnInfo.VpnStatus)"
        }

        if ($disabledShutdownTaskFailures.Count -gt 0) {
            $result = "SuccessWithWarning"
            $failureMessages += "One or more scheduled shutdown/restart/logoff tasks could not be disabled."
        }

        if ($holdAlreadyActive) {
            $result = "SuccessWithWarning"
            $failureMessages += "A previous sleep hold state file already existed, so the original saved power settings were preserved and the rollback task was rescheduled."
        }

        $failureReason = ($failureMessages -join " | ")

        $row = ConvertTo-BaseResultRow `
            -Action "Apply" `
            -Result $result `
            -FailureReason $failureReason `
            -VpnInfo $vpnInfo `
            -SchemeGuid $schemeGuid `
            -HoldAlreadyActive $holdAlreadyActive `
            -PreviousSleep $previousSleep `
            -PreviousHibernate $previousHibernate `
            -PreviousDisk $previousDisk `
            -NewSleep $newSleep `
            -NewHibernate $newHibernate `
            -NewDisk $newDisk `
            -PendingShutdownAbortResult $pendingShutdownAbortResult `
            -ScheduledShutdownTaskDisableResults $disabledShutdownTasks `
            -ScheduledShutdownTaskRestoreResults @() `
            -RollbackScheduledFor $rollbackAtText

        Write-RequiredCsv -Row $row

        exit 0
    }
    catch {
        $vpnInfo = Get-CiscoVpnStatus

        $row = ConvertTo-BaseResultRow `
            -Action "Apply" `
            -Result "Failed" `
            -FailureReason $_.Exception.Message `
            -VpnInfo $vpnInfo `
            -SchemeGuid "" `
            -HoldAlreadyActive $false `
            -PreviousSleep $null `
            -PreviousHibernate $null `
            -PreviousDisk $null `
            -NewSleep $null `
            -NewHibernate $null `
            -NewDisk $null `
            -PendingShutdownAbortResult "" `
            -ScheduledShutdownTaskDisableResults @() `
            -ScheduledShutdownTaskRestoreResults @() `
            -RollbackScheduledFor ""

        Write-RequiredCsv -Row $row
        exit 1
    }
}