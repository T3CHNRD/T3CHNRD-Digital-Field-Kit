<#
.SYNOPSIS
    Production Microsoft Secure Boot 2026 certificate readiness audit for Lansweeper deployment.

.DESCRIPTION
    Audits and optionally triggers the Microsoft Secure Boot 2026 certificate update workflow.

    Production checks included:
      - Secure Boot support and enabled state
      - Active DB contains "Windows UEFI CA 2023"
      - KEK contains "Microsoft Corporation KEK 2K CA 2023"
      - DBDefault contains "Windows UEFI CA 2023" to detect stale firmware defaults
      - Active DB contains "Microsoft UEFI CA 2023" and "Microsoft Option ROM UEFI CA 2023" when required
      - Registry tracking from HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot, including:
          UEFICA2023Status, UEFICA2023Error, UEFICA2023ErrorEvent, AvailableUpdates,
          AvailableUpdatesPolicy, WindowsUEFICA2023Capable, HighConfidenceOptOut,
          MicrosoftUpdateManagedOptIn, BucketHash, ConfidenceLevel
      - Recent Secure Boot event-log summary where available
      - Optional remediation trigger sets AvailableUpdates=0x5944 and starts:
          \Microsoft\Windows\PI\Secure-Boot-Update

    Designed for Lansweeper: run locally on each endpoint and write one CSV per endpoint.
    Do not use mapped drives such as P: from Lansweeper/System deployments. Use a UNC path.

.NOTES
    Example deployment command:
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{PackageShare}\Scripts\Check-SecureBootCert.ps1" -OutputFolder "\\server\share\SecureBootAudit" -Verbose

    Recommended Lansweeper run mode:
      Scanning credentials, if that account has write access to the network share.

    If Run Mode is System Account, the network write uses the target computer account, e.g. DOMAIN\PCNAME$.
    In that case, grant the computer accounts or Domain Computers write access to the share and NTFS path.
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('Name','HostName','DNSHostName')]
    [string[]]$ComputerName = @($env:COMPUTERNAME),

    [pscredential]$Credential,

    [switch]$ApplyUpdate,

    # Use this if your environment requires Microsoft UEFI CA 2023 and Microsoft Option ROM UEFI CA 2023 even when the legacy Microsoft Corporation UEFI CA 2011 is not detected.
    [switch]$RequireThirdPartyUEFICA2023,

    [ValidateNotNullOrEmpty()]
    [string]$OutputFolder = '\\server\share\SecureBootAudit',

    [ValidateNotNullOrEmpty()]
    [string]$LocalFallbackFolder = 'C:\ProgramData\SecureBootCertAudit',

    [switch]$NoNetworkExport
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO'
    )

    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Output $line
}

function Ensure-Folder {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
    }
}

$auditBlock = {
    param(
        [bool]$DoApplyUpdate,
        [bool]$RequireThirdPartyCerts
    )

    function New-ResultObject {
        [ordered]@{
            ComputerName                               = $env:COMPUTERNAME
            ScanTime                                   = (Get-Date).ToString('s')
            ScanStatus                                 = 'Scanned'
            RunningAs                                  = $null

            OSName                                     = $null
            OSVersion                                  = $null
            OSBuild                                    = $null
            OSUBR                                      = $null

            FirmwareType                               = $null
            SecureBootSupported                        = $null
            SecureBootEnabled                          = $null
            SecureBootState                            = $null

            WindowsUEFICA2023_DB                       = $false
            MicrosoftKEK2KCA2023_KEK                   = $false
            WindowsUEFICA2023_DBDefault                = $false
            DBDefaultUpdated                           = $false

            MicrosoftCorporationUEFICA2011_DB          = $false
            MicrosoftUEFICA2023_DB                     = $false
            MicrosoftOptionROMUEFICA2023_DB            = $false
            ThirdPartyUEFICA2023Required               = $false
            ThirdPartyUEFICA2023RequirementMet          = $true

            MicrosoftCorporationUEFICA2011_DBDefault   = $false
            MicrosoftUEFICA2023_DBDefault              = $false
            MicrosoftOptionROMUEFICA2023_DBDefault     = $false
            ThirdPartyUEFICA2023DefaultsMet            = $true

            ActiveDbDefault2023Alignment               = $null

            UEFICA2023Status                           = $null
            UEFICA2023Error                            = $null
            UEFICA2023ErrorEvent                       = $null
            AvailableUpdates                           = $null
            AvailableUpdatesHex                        = $null
            AvailableUpdatesPolicy                     = $null
            WindowsUEFICA2023Capable                   = $null
            HighConfidenceOptOut                       = $null
            MicrosoftUpdateManagedOptIn                = $null
            BucketHash                                 = $null
            ConfidenceLevel                            = $null

            SecureBootUpdateTaskExists                 = $false
            SecureBootUpdateTaskState                  = $null
            UpdateAttempted                            = $false
            UpdateTriggerResult                        = $null

            RegistryErrorHealthy                       = $null
            RegistryStatusHealthy                      = $null
            RecentSecureBootEventCount                 = 0
            RecentSecureBootErrorEventCount            = 0
            RecentSecureBootEventSummary               = $null

            ComplianceCategory                         = $null
            RecommendedAction                          = $null
            Error                                      = $null
        }
    }

    function Add-ErrorText {
        param(
            [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Result,
            [Parameter(Mandatory = $true)][string]$Message
        )

        if ([string]::IsNullOrWhiteSpace([string]$Result.Error)) {
            $Result.Error = $Message
        }
        else {
            $Result.Error = '{0} | {1}' -f $Result.Error, $Message
        }
    }

    function Get-UefiVariableText {
        param([Parameter(Mandatory = $true)][string]$Name)

        try {
            $raw = Get-SecureBootUEFI -Name $Name -ErrorAction Stop
            if ($null -eq $raw -or $null -eq $raw.Bytes) {
                return $null
            }
            return [System.Text.Encoding]::ASCII.GetString($raw.Bytes)
        }
        catch {
            return $null
        }
    }

    function ConvertTo-HexString {
        param($Value)

        if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
            return $null
        }

        try {
            $intValue = [int64]$Value
            return ('0x{0:X}' -f $intValue)
        }
        catch {
            return [string]$Value
        }
    }

    function Test-ZeroOrBlank {
        param($Value)

        if ($null -eq $Value) { return $true }
        $text = ([string]$Value).Trim()
        if ([string]::IsNullOrWhiteSpace($text)) { return $true }
        if ($text -eq '0' -or $text -eq '0x0') { return $true }

        try {
            if ([int64]$Value -eq 0) { return $true }
        }
        catch {
            # leave as non-zero/non-blank
        }

        return $false
    }

    function Get-RecentSecureBootEvents {
        param([Parameter(Mandatory = $true)][System.Collections.IDictionary]$Result)

        $startTime = (Get-Date).AddDays(-30)
        $logsToTry = @(
            'Microsoft-Windows-Kernel-Boot/Operational',
            'System'
        )

        $events = @()

        foreach ($logName in $logsToTry) {
            try {
                $logEvents = Get-WinEvent -FilterHashtable @{ LogName = $logName; StartTime = $startTime } -ErrorAction Stop |
                    Where-Object {
                        ($_.ProviderName -match 'SecureBoot|Kernel-Boot|Microsoft-Windows-Kernel-Boot') -or
                        ($_.Message -match 'Secure Boot|UEFI CA 2023|UEFICA2023|AvailableUpdates|DBX|KEK')
                    } |
                    Select-Object -First 10

                if ($logEvents) {
                    $events += $logEvents
                }
            }
            catch {
                # Event logs vary by Windows version and policy; do not fail the audit if unavailable.
            }
        }

        if ($events.Count -gt 0) {
            $Result.RecentSecureBootEventCount = $events.Count
            $Result.RecentSecureBootErrorEventCount = @($events | Where-Object { $_.LevelDisplayName -match 'Error|Critical|Warning' }).Count
            $summaryItems = @()
            foreach ($evt in ($events | Select-Object -First 5)) {
                $msg = [string]$evt.Message
                if ($msg.Length -gt 180) {
                    $msg = $msg.Substring(0,180) + '...'
                }
                $summaryItems += ('{0} ID {1}: {2}' -f $evt.TimeCreated, $evt.Id, ($msg -replace "`r|`n", ' '))
            }
            $Result.RecentSecureBootEventSummary = ($summaryItems -join ' || ')
        }
    }

    $result = New-ResultObject

    try {
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        if ($identity -and $identity.Name) {
            $result.RunningAs = $identity.Name
        }
    }
    catch {
        $result.RunningAs = 'Unknown'
    }

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $result.OSName = $os.Caption
        $result.OSVersion = $os.Version
        $result.OSBuild = $os.BuildNumber
    }
    catch {
        Add-ErrorText -Result $result -Message ('OS inventory failed: {0}' -f $_.Exception.Message)
    }

    try {
        $cv = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop
        if ($cv.PSObject.Properties.Name -contains 'UBR') {
            $result.OSUBR = $cv.UBR
        }
    }
    catch {
        # UBR is helpful but not mandatory.
    }

    try {
        $secureBoot = Confirm-SecureBootUEFI -ErrorAction Stop
        $result.SecureBootSupported = $true
        $result.SecureBootEnabled = [bool]$secureBoot
        if ($result.SecureBootEnabled) {
            $result.SecureBootState = 'Enabled'
        }
        else {
            $result.SecureBootState = 'Disabled'
        }
        $result.FirmwareType = 'UEFI'
    }
    catch {
        $result.SecureBootSupported = $false
        $result.SecureBootEnabled = $false
        $result.SecureBootState = 'Unsupported or not UEFI'
        $result.FirmwareType = 'Legacy/Unknown'
        Add-ErrorText -Result $result -Message ('Confirm-SecureBootUEFI failed: {0}' -f $_.Exception.Message)
    }

    try {
        $secureBootRegPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
        $secureBootReg = Get-ItemProperty -Path $secureBootRegPath -ErrorAction Stop

        foreach ($propertyName in @(
            'UEFICA2023Status',
            'UEFICA2023Error',
            'UEFICA2023ErrorEvent',
            'AvailableUpdates',
            'AvailableUpdatesPolicy',
            'WindowsUEFICA2023Capable',
            'HighConfidenceOptOut',
            'MicrosoftUpdateManagedOptIn',
            'BucketHash',
            'ConfidenceLevel'
        )) {
            if ($secureBootReg.PSObject.Properties.Name -contains $propertyName) {
                $result[$propertyName] = $secureBootReg.$propertyName
            }
        }

        $result.AvailableUpdatesHex = ConvertTo-HexString -Value $result.AvailableUpdates
    }
    catch {
        Add-ErrorText -Result $result -Message ('Secure Boot registry tracking read failed: {0}' -f $_.Exception.Message)
    }

    $dbText = Get-UefiVariableText -Name 'db'
    $kekText = Get-UefiVariableText -Name 'KEK'
    $dbDefaultText = Get-UefiVariableText -Name 'dbdefault'

    $result.WindowsUEFICA2023_DB = if ($dbText) { $dbText -match 'Windows UEFI CA 2023' } else { $false }
    $result.MicrosoftKEK2KCA2023_KEK = if ($kekText) { $kekText -match 'Microsoft Corporation KEK 2K CA 2023' } else { $false }
    $result.WindowsUEFICA2023_DBDefault = if ($dbDefaultText) { $dbDefaultText -match 'Windows UEFI CA 2023' } else { $false }
    $result.DBDefaultUpdated = [bool]$result.WindowsUEFICA2023_DBDefault

    $result.MicrosoftCorporationUEFICA2011_DB = if ($dbText) { $dbText -match 'Microsoft Corporation UEFI CA 2011' } else { $false }
    $result.MicrosoftUEFICA2023_DB = if ($dbText) { $dbText -match 'Microsoft UEFI CA 2023' } else { $false }
    $result.MicrosoftOptionROMUEFICA2023_DB = if ($dbText) { $dbText -match 'Microsoft Option ROM UEFI CA 2023' } else { $false }

    $result.MicrosoftCorporationUEFICA2011_DBDefault = if ($dbDefaultText) { $dbDefaultText -match 'Microsoft Corporation UEFI CA 2011' } else { $false }
    $result.MicrosoftUEFICA2023_DBDefault = if ($dbDefaultText) { $dbDefaultText -match 'Microsoft UEFI CA 2023' } else { $false }
    $result.MicrosoftOptionROMUEFICA2023_DBDefault = if ($dbDefaultText) { $dbDefaultText -match 'Microsoft Option ROM UEFI CA 2023' } else { $false }

    if ($RequireThirdPartyCerts -or $result.MicrosoftCorporationUEFICA2011_DB) {
        $result.ThirdPartyUEFICA2023Required = $true
    }
    else {
        $result.ThirdPartyUEFICA2023Required = $false
    }

    if ($result.ThirdPartyUEFICA2023Required) {
        $result.ThirdPartyUEFICA2023RequirementMet = [bool]($result.MicrosoftUEFICA2023_DB -and $result.MicrosoftOptionROMUEFICA2023_DB)
    }
    else {
        $result.ThirdPartyUEFICA2023RequirementMet = $true
    }

    if ($RequireThirdPartyCerts -or $result.MicrosoftCorporationUEFICA2011_DBDefault) {
        $result.ThirdPartyUEFICA2023DefaultsMet = [bool]($result.MicrosoftUEFICA2023_DBDefault -and $result.MicrosoftOptionROMUEFICA2023_DBDefault)
    }
    else {
        $result.ThirdPartyUEFICA2023DefaultsMet = $true
    }

    if ($null -ne $dbText -and $null -ne $dbDefaultText) {
        if ($result.WindowsUEFICA2023_DB -eq $result.WindowsUEFICA2023_DBDefault) {
            $result.ActiveDbDefault2023Alignment = 'Aligned for Windows UEFI CA 2023 presence'
        }
        else {
            $result.ActiveDbDefault2023Alignment = 'Mismatch: active DB and DBDefault differ for Windows UEFI CA 2023'
        }
    }
    else {
        $result.ActiveDbDefault2023Alignment = 'Unable to compare DB and DBDefault'
    }

    try {
        $task = Get-ScheduledTask -TaskName 'Secure-Boot-Update' -TaskPath '\Microsoft\Windows\PI\' -ErrorAction Stop
        $result.SecureBootUpdateTaskExists = $true
        $result.SecureBootUpdateTaskState = $task.State.ToString()
    }
    catch {
        $result.SecureBootUpdateTaskExists = $false
        $result.SecureBootUpdateTaskState = 'Missing or inaccessible'
    }

    $result.RegistryErrorHealthy = Test-ZeroOrBlank -Value $result.UEFICA2023Error

    $statusText = ''
    if ($null -ne $result.UEFICA2023Status) {
        $statusText = ([string]$result.UEFICA2023Status).Trim()
    }

    if ([string]::IsNullOrWhiteSpace($statusText) -or $statusText -match 'Updated|NotStarted|0') {
        $result.RegistryStatusHealthy = $true
    }
    elseif ($statusText -match 'Error|Fail') {
        $result.RegistryStatusHealthy = $false
    }
    elseif ($statusText -match 'InProgress') {
        $result.RegistryStatusHealthy = $false
    }
    else {
        $result.RegistryStatusHealthy = $true
    }

    Get-RecentSecureBootEvents -Result $result

    if ($DoApplyUpdate) {
        $result.UpdateAttempted = $true

        if (-not $result.SecureBootSupported) {
            $result.UpdateTriggerResult = 'Skipped: Secure Boot is unsupported or system is not in UEFI mode.'
        }
        elseif (-not $result.SecureBootEnabled) {
            $result.UpdateTriggerResult = 'Skipped: Secure Boot is disabled. Enable Secure Boot before certificate deployment.'
        }
        elseif (-not $result.SecureBootUpdateTaskExists) {
            $result.UpdateTriggerResult = 'Skipped: Secure-Boot-Update scheduled task is missing.'
        }
        elseif ($result.WindowsUEFICA2023_DB -and $result.MicrosoftKEK2KCA2023_KEK -and $result.ThirdPartyUEFICA2023RequirementMet) {
            $result.UpdateTriggerResult = 'Skipped: active DB, KEK, and required Microsoft UEFI/Option ROM 2023 certificates are already present. Check DBDefault and firmware defaults separately.'
        }
        else {
            try {
                New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot' -Force -ErrorAction Stop | Out-Null
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot' -Name 'AvailableUpdates' -Type DWord -Value 0x5944 -ErrorAction Stop
                Start-ScheduledTask -TaskName 'Secure-Boot-Update' -TaskPath '\Microsoft\Windows\PI\' -ErrorAction Stop
                $result.AvailableUpdates = 0x5944
                $result.AvailableUpdatesHex = '0x5944'
                $result.UpdateTriggerResult = 'Triggered: AvailableUpdates set to 0x5944 and Secure-Boot-Update task started. Reboot twice as needed, then rescan.'
            }
            catch {
                $result.UpdateTriggerResult = 'Failed'
                Add-ErrorText -Result $result -Message ('Update trigger failed: {0}' -f $_.Exception.Message)
            }
        }
    }

    $activeRequiredCertsPresent = [bool]($result.WindowsUEFICA2023_DB -and $result.MicrosoftKEK2KCA2023_KEK -and $result.ThirdPartyUEFICA2023RequirementMet)
    $defaultsRequiredCertsPresent = [bool]($result.WindowsUEFICA2023_DBDefault -and $result.ThirdPartyUEFICA2023DefaultsMet)

    if (-not $result.SecureBootSupported) {
        $result.ComplianceCategory = 'Exception or Unsupported'
        $result.RecommendedAction = 'Device does not report UEFI Secure Boot support. Confirm firmware mode is UEFI, disable legacy/CSM if applicable, and validate whether this device is an exception.'
    }
    elseif (-not $result.SecureBootEnabled) {
        $result.ComplianceCategory = 'Firmware Remediation Required'
        $result.RecommendedAction = 'Secure Boot is disabled. Enable UEFI Secure Boot, confirm firmware support, update BIOS/firmware if needed, then rerun this audit.'
    }
    elseif (-not $result.RegistryErrorHealthy) {
        $result.ComplianceCategory = 'Firmware Remediation Required'
        $result.RecommendedAction = 'UEFICA2023Error is non-zero. Review Secure Boot event logs and UEFICA2023ErrorEvent, update BIOS/firmware and Windows servicing baseline, then rerun the Secure-Boot-Update workflow.'
    }
    elseif (-not $result.RegistryStatusHealthy) {
        $result.ComplianceCategory = 'Eligible for Update'
        $result.RecommendedAction = 'UEFICA2023Status indicates the update is not complete. Continue monitoring UEFICA2023Status/UEFICA2023Error, reboot as needed, run Secure-Boot-Update again if appropriate, then rescan.'
    }
    elseif ($activeRequiredCertsPresent -and $defaultsRequiredCertsPresent) {
        $result.ComplianceCategory = 'Fully Compliant'
        $result.RecommendedAction = 'No immediate Secure Boot certificate remediation required. Keep normal Windows and OEM firmware update cadence.'
    }
    elseif ($activeRequiredCertsPresent -and -not $defaultsRequiredCertsPresent) {
        $result.ComplianceCategory = 'Operationally Compliant (Defaults Outdated)'
        $result.RecommendedAction = 'Active DB and KEK have required 2023 certificates, but firmware defaults are stale. Apply OEM BIOS/firmware updates and avoid resetting Secure Boot keys to defaults until DBDefault is updated.'
    }
    elseif ($result.SecureBootUpdateTaskExists -and $result.SecureBootSupported -and $result.SecureBootEnabled) {
        $result.ComplianceCategory = 'Eligible for Update'
        $result.RecommendedAction = 'Confirm Windows servicing baseline is current, set AvailableUpdates=0x5944, run \Microsoft\Windows\PI\Secure-Boot-Update, reboot twice as needed, and rerun this audit.'
    }
    else {
        $result.ComplianceCategory = 'Firmware Remediation Required'
        $result.RecommendedAction = 'Device could not be updated by current OS mechanism. Update BIOS/firmware and Windows servicing baseline, then rerun this audit.'
    }

    [pscustomobject]$result
}

$results = New-Object System.Collections.Generic.List[object]

foreach ($computer in $ComputerName) {
    if ([string]::IsNullOrWhiteSpace($computer)) {
        continue
    }

    try {
        if ($computer -in @($env:COMPUTERNAME, 'localhost', '.', '127.0.0.1')) {
            $result = & $auditBlock ([bool]$ApplyUpdate) ([bool]$RequireThirdPartyUEFICA2023)
        }
        elseif ($PSBoundParameters.ContainsKey('Credential')) {
            $result = Invoke-Command -ComputerName $computer -Credential $Credential -ScriptBlock $auditBlock -ArgumentList ([bool]$ApplyUpdate),([bool]$RequireThirdPartyUEFICA2023) -ErrorAction Stop
        }
        else {
            $result = Invoke-Command -ComputerName $computer -ScriptBlock $auditBlock -ArgumentList ([bool]$ApplyUpdate),([bool]$RequireThirdPartyUEFICA2023) -ErrorAction Stop
        }
    }
    catch {
        $result = [pscustomobject]@{
            ComputerName                               = $computer
            ScanTime                                   = (Get-Date).ToString('s')
            ScanStatus                                 = 'Scan Failed'
            RunningAs                                  = $null
            OSName                                     = $null
            OSVersion                                  = $null
            OSBuild                                    = $null
            OSUBR                                      = $null
            FirmwareType                               = $null
            SecureBootSupported                        = $null
            SecureBootEnabled                          = $null
            SecureBootState                            = 'Unknown'
            WindowsUEFICA2023_DB                       = $false
            MicrosoftKEK2KCA2023_KEK                   = $false
            WindowsUEFICA2023_DBDefault                = $false
            DBDefaultUpdated                           = $false
            MicrosoftCorporationUEFICA2011_DB          = $false
            MicrosoftUEFICA2023_DB                     = $false
            MicrosoftOptionROMUEFICA2023_DB            = $false
            ThirdPartyUEFICA2023Required               = $null
            ThirdPartyUEFICA2023RequirementMet          = $null
            MicrosoftCorporationUEFICA2011_DBDefault   = $false
            MicrosoftUEFICA2023_DBDefault              = $false
            MicrosoftOptionROMUEFICA2023_DBDefault     = $false
            ThirdPartyUEFICA2023DefaultsMet            = $null
            ActiveDbDefault2023Alignment               = $null
            UEFICA2023Status                           = $null
            UEFICA2023Error                            = $null
            UEFICA2023ErrorEvent                       = $null
            AvailableUpdates                           = $null
            AvailableUpdatesHex                        = $null
            AvailableUpdatesPolicy                     = $null
            WindowsUEFICA2023Capable                   = $null
            HighConfidenceOptOut                       = $null
            MicrosoftUpdateManagedOptIn                = $null
            BucketHash                                 = $null
            ConfidenceLevel                            = $null
            SecureBootUpdateTaskExists                 = $false
            SecureBootUpdateTaskState                  = $null
            UpdateAttempted                            = [bool]$ApplyUpdate
            UpdateTriggerResult                        = 'Not attempted due to scan failure'
            RegistryErrorHealthy                       = $null
            RegistryStatusHealthy                      = $null
            RecentSecureBootEventCount                 = 0
            RecentSecureBootErrorEventCount            = 0
            RecentSecureBootEventSummary               = $null
            ComplianceCategory                         = 'Exception or Unsupported'
            RecommendedAction                          = 'Scan failed. Fix remote access, credentials, firewall/RPC/WinRM, or run locally as admin; then rerun production audit.'
            Error                                      = $_.Exception.Message
        }
    }

    $results.Add($result) | Out-Null
}

$orderedResults = $results | Sort-Object -Property ComputerName, WindowsUEFICA2023_DBDefault, ComplianceCategory
$orderedResults | Format-Table -AutoSize

$timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$safeComputerName = ($env:COMPUTERNAME -replace '[^a-zA-Z0-9._-]', '_')
$fileName = 'SecureBootCheckResults_{0}_{1}.csv' -f $safeComputerName, $timestamp

$networkExportSucceeded = $false
$networkExportPath = $null
$localExportPath = $null

try {
    Ensure-Folder -Path $LocalFallbackFolder
    $localExportPath = Join-Path -Path $LocalFallbackFolder -ChildPath $fileName
    $orderedResults | Export-Csv -Path $localExportPath -NoTypeInformation -Encoding UTF8 -Force
    Write-Log -Message ('Local fallback CSV saved to: {0}' -f $localExportPath)
}
catch {
    Write-Log -Level 'ERROR' -Message ('Local fallback CSV failed: {0}' -f $_.Exception.Message)
    exit 3
}

if (-not $NoNetworkExport) {
    try {
        if ($OutputFolder -match '^[A-Za-z]:') {
            throw 'OutputFolder is a mapped drive path. Lansweeper/System deployments cannot reliably use mapped drives. Use a UNC path such as \\server\share\SecureBootAudit.'
        }

        Ensure-Folder -Path $OutputFolder
        $networkExportPath = Join-Path -Path $OutputFolder -ChildPath $fileName
        $orderedResults | Export-Csv -Path $networkExportPath -NoTypeInformation -Encoding UTF8 -Force
        $networkExportSucceeded = Test-Path -LiteralPath $networkExportPath

        if ($networkExportSucceeded) {
            Write-Log -Message ('Network CSV saved to: {0}' -f $networkExportPath)
        }
        else {
            throw 'Export-Csv completed, but the output file was not found afterward.'
        }
    }
    catch {
        Write-Log -Level 'ERROR' -Message ('Network CSV export failed for OutputFolder "{0}": {1}' -f $OutputFolder, $_.Exception.Message)
        Write-Log -Level 'ERROR' -Message ('The audit data was saved locally on the endpoint instead: {0}' -f $localExportPath)
        Write-Log -Level 'ERROR' -Message 'This usually means the Lansweeper run identity cannot write to the share. Use Scanning Credentials with share rights, or grant the target computer accounts write access to the UNC path.'
        exit 2
    }
}
else {
    Write-Log -Level 'WARN' -Message 'NoNetworkExport was specified. Results were saved locally only.'
}

if ($ApplyUpdate) {
    Write-Log -Level 'WARN' -Message 'ApplyUpdate was requested. Reboot updated systems twice as needed and rerun this script to validate DB, KEK, DBDefault, UEFICA2023Status, and UEFICA2023Error.'
}

exit 0
