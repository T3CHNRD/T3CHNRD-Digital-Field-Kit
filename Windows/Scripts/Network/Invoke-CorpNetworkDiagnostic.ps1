#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [ValidateSet('Snapshot','LAN','WiFi','RenewLAN','All')]
    [string]$Action = 'All',
    [string]$LanAlias,
    [string]$WifiAlias,
    [bool]$EnableNetworkDiscovery = $true,
    [switch]$RenewLAN
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ReportRoot {
    if ($env:TTK_REPORT_DIR -and -not [string]::IsNullOrWhiteSpace($env:TTK_REPORT_DIR)) {
        return $env:TTK_REPORT_DIR
    }
    return (Join-Path $PSScriptRoot 'Diagnostic-Reports')
}

function Write-Section {
    param([string]$Title)
    "`r`n===== $Title =====`r`n" | Tee-Object -FilePath $script:ReportFile -Append
}

function Add-Report {
    param([Parameter(ValueFromPipeline=$true)]$InputObject)
    process { $InputObject | Out-String -Width 300 | Tee-Object -FilePath $script:ReportFile -Append }
}

function Invoke-Capture {
    param([string]$Label,[scriptblock]$ScriptBlock)
    Write-Section $Label
    try { & $ScriptBlock 2>&1 | Add-Report }
    catch { "[ERROR] $($_.Exception.Message)" | Tee-Object -FilePath $script:ReportFile -Append }
}

function Get-WifiAdapter {
    param([string]$Alias)
    if ($Alias) { return Get-NetAdapter -Name $Alias -ErrorAction Stop }
    $adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {
        $_.InterfaceDescription -match '(?i)wireless|wi-?fi|802\.11|wlan' -or $_.Name -match '(?i)^wi-?fi$|wireless|wlan'
    })
    $up = @($adapters | Where-Object Status -eq 'Up')
    if ($up.Count -eq 1) { return $up[0] }
    if ($adapters.Count -eq 1) { return $adapters[0] }
    return $adapters | Sort-Object ifIndex | Select-Object -First 1
}

function Get-LanAdapter {
    param([string]$Alias,[string]$WifiName)
    if ($Alias) { return Get-NetAdapter -Name $Alias -ErrorAction Stop }
    $adapters = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ne $WifiName -and
        $_.InterfaceDescription -notmatch '(?i)wireless|wi-?fi|802\.11|wlan|bluetooth' -and
        $_.Name -notmatch '(?i)wi-?fi|wireless|wlan|bluetooth'
    })
    $up = @($adapters | Where-Object Status -eq 'Up')
    if ($up.Count -gt 0) { return $up | Sort-Object LinkSpeed -Descending | Select-Object -First 1 }
    return $adapters | Sort-Object ifIndex | Select-Object -First 1
}

function Enable-NetworkDiscoverySafely {
    Write-Section 'Network Discovery Check / Enable'
    $services = @(
        @{ Name='FDResPub'; Startup='Automatic' },
        @{ Name='fdPHost';  Startup='Manual'    },
        @{ Name='SSDPSRV';  Startup='Manual'    },
        @{ Name='upnphost'; Startup='Manual'    }
    )
    foreach ($svcInfo in $services) {
        try {
            $svc = Get-Service -Name $svcInfo.Name -ErrorAction Stop
            "Before: $($svc.Name) Status=$($svc.Status) StartType=$($svc.StartType)" | Tee-Object -FilePath $script:ReportFile -Append
            Set-Service -Name $svcInfo.Name -StartupType $svcInfo.Startup -ErrorAction Stop
            if ((Get-Service -Name $svcInfo.Name).Status -ne 'Running') { Start-Service -Name $svcInfo.Name -ErrorAction Stop }
            $svc = Get-Service -Name $svcInfo.Name
            "After : $($svc.Name) Status=$($svc.Status) StartType=$($svc.StartType)" | Tee-Object -FilePath $script:ReportFile -Append
        } catch {
            "[WARN] Service $($svcInfo.Name): $($_.Exception.Message)" | Tee-Object -FilePath $script:ReportFile -Append
        }
    }
    try {
        $rules = @(Get-NetFirewallRule -DisplayGroup 'Network Discovery' -ErrorAction Stop)
        "Firewall rules enabled before: $(@($rules | Where-Object Enabled -eq 'True').Count) / $($rules.Count)" | Tee-Object -FilePath $script:ReportFile -Append
        Set-NetFirewallRule -DisplayGroup 'Network Discovery' -Profile Domain,Private -Enabled True -ErrorAction Stop
        $rules = @(Get-NetFirewallRule -DisplayGroup 'Network Discovery' -ErrorAction Stop)
        "Firewall rules enabled after : $(@($rules | Where-Object Enabled -eq 'True').Count) / $($rules.Count)" | Tee-Object -FilePath $script:ReportFile -Append
    } catch {
        "[WARN] Network Discovery firewall group: $($_.Exception.Message)" | Tee-Object -FilePath $script:ReportFile -Append
    }
}

$root = Get-ReportRoot
New-Item -ItemType Directory -Path $root -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$session = Join-Path $root ("Network-Diagnostic_{0}_{1}" -f $env:COMPUTERNAME,$stamp)
New-Item -ItemType Directory -Path $session -Force | Out-Null
$script:ReportFile = Join-Path $session 'Network-Diagnostic.txt'
"Network diagnostic started: $(Get-Date)" | Set-Content -LiteralPath $script:ReportFile -Encoding UTF8
"Computer: $env:COMPUTERNAME" | Add-Content -LiteralPath $script:ReportFile
"Action: $Action" | Add-Content -LiteralPath $script:ReportFile

if ($EnableNetworkDiscovery) { Enable-NetworkDiscoverySafely }

$wifi = Get-WifiAdapter -Alias $WifiAlias
$wifiName = if ($wifi) { $wifi.Name } else { $null }
$lan = Get-LanAdapter -Alias $LanAlias -WifiName $wifiName

Write-Section 'Detected Adapters'
if ($lan) { "LAN  : $($lan.Name) | $($lan.InterfaceDescription) | Status=$($lan.Status) | Link=$($lan.LinkSpeed)" | Tee-Object -FilePath $script:ReportFile -Append }
else { 'LAN  : NOT DETECTED' | Tee-Object -FilePath $script:ReportFile -Append }
if ($wifi) { "Wi-Fi: $($wifi.Name) | $($wifi.InterfaceDescription) | Status=$($wifi.Status) | Link=$($wifi.LinkSpeed)" | Tee-Object -FilePath $script:ReportFile -Append }
else { 'Wi-Fi: NOT DETECTED' | Tee-Object -FilePath $script:ReportFile -Append }

Invoke-Capture 'ipconfig /all - Current State' { & ipconfig.exe /all }
Invoke-Capture 'Network Adapters' { Get-NetAdapter | Sort-Object ifIndex | Format-Table Name,InterfaceDescription,Status,LinkSpeed,MacAddress,ifIndex -AutoSize }
Invoke-Capture 'IP Configuration' { Get-NetIPConfiguration -Detailed | Format-List InterfaceAlias,InterfaceDescription,NetProfile,IPv4Address,IPv4DefaultGateway,DNSServer }
Invoke-Capture 'Connection Profiles' { Get-NetConnectionProfile | Format-Table Name,InterfaceAlias,NetworkCategory,IPv4Connectivity,IPv6Connectivity -AutoSize }
Invoke-Capture 'Routes' { Get-NetRoute -AddressFamily IPv4 | Sort-Object RouteMetric,DestinationPrefix | Format-Table ifIndex,DestinationPrefix,NextHop,RouteMetric,State -AutoSize }
Invoke-Capture 'DNS Client Configuration' { Get-DnsClientServerAddress | Format-Table InterfaceAlias,AddressFamily,ServerAddresses -AutoSize }
Invoke-Capture 'Domain / Join State' {
    $cs = Get-CimInstance Win32_ComputerSystem
    [pscustomobject]@{ PartOfDomain=$cs.PartOfDomain; Domain=$cs.Domain; Workgroup=$cs.Workgroup } | Format-List
    if ($cs.PartOfDomain -and $cs.Domain) { "`r`n--- nltest /dsgetdc:$($cs.Domain) ---"; & nltest.exe "/dsgetdc:$($cs.Domain)" }
}
Invoke-Capture 'Applied Computer Policy Summary' { & gpresult.exe /r /scope computer }

if ($Action -in @('WiFi','All','Snapshot','RenewLAN')) {
    Invoke-Capture 'Wi-Fi - netsh wlan show interfaces' { & netsh.exe wlan show interfaces }
    Invoke-Capture 'Wi-Fi - netsh wlan show drivers' { & netsh.exe wlan show drivers }
    Invoke-Capture 'Wi-Fi - netsh wlan show profiles' { & netsh.exe wlan show profiles }
    Invoke-Capture 'Wi-Fi - Visible Networks / BSSIDs' { & netsh.exe wlan show networks mode=bssid }
    Invoke-Capture 'Wi-Fi - WLAN AutoConfig recent warnings/errors' {
        $start = (Get-Date).AddHours(-8)
        Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-WLAN-AutoConfig/Operational'; StartTime=$start } -ErrorAction SilentlyContinue |
            Where-Object { $_.LevelDisplayName -in 'Error','Warning' -or $_.Id -in 8001,8002,8003,11000,11001,11004,12011 } |
            Select-Object TimeCreated,Id,LevelDisplayName,Message | Format-List
    }
    Invoke-Capture 'Wi-Fi - Generate wlanreport' { & netsh.exe wlan show wlanreport }
}

if ($Action -in @('LAN','All','RenewLAN')) {
    Invoke-Capture 'LAN Adapter Focus' {
        if (-not $lan) { throw 'No wired adapter was detected.' }
        Get-NetIPConfiguration -InterfaceIndex $lan.ifIndex -Detailed | Format-List *
    }
}

$doRenew = ($Action -eq 'RenewLAN') -or ($Action -eq 'All' -and $RenewLAN)
if ($doRenew) {
    Write-Section 'LAN DHCP Renew Sequence'
    if (-not $lan) {
        '[ERROR] No wired adapter detected. DHCP renew skipped.' | Tee-Object -FilePath $script:ReportFile -Append
    } elseif ($lan.Status -ne 'Up') {
        "[ERROR] Wired adapter '$($lan.Name)' is not Up. Connect the LAN cable first. DHCP renew skipped." | Tee-Object -FilePath $script:ReportFile -Append
    } else {
        "Target LAN adapter: $($lan.Name)" | Tee-Object -FilePath $script:ReportFile -Append
        & ipconfig.exe /flushdns 2>&1 | Add-Report
        & ipconfig.exe /release "$($lan.Name)" 2>&1 | Add-Report
        Start-Sleep -Seconds 2
        & ipconfig.exe /renew "$($lan.Name)" 2>&1 | Add-Report
        Invoke-Capture 'ipconfig /all - After LAN Renew' { & ipconfig.exe /all }
    }
}

Write-Section 'Important Note - AP / MultiAP Isolation'
@'
AP/Client/MultiAP isolation is an access-point/controller policy, not a Windows laptop adapter setting.
This script intentionally does not change it. Verify the SSID policy in the wireless controller/AP configuration.
'@ | Tee-Object -FilePath $script:ReportFile -Append

Write-Section 'Summary'
"Report folder: $session" | Tee-Object -FilePath $script:ReportFile -Append
"Primary report: $script:ReportFile" | Tee-Object -FilePath $script:ReportFile -Append
"Completed: $(Get-Date)" | Tee-Object -FilePath $script:ReportFile -Append

Write-Host ''
Write-Host '[PASS] Network diagnostic completed.' -ForegroundColor Green
Write-Host "Report: $script:ReportFile" -ForegroundColor Cyan
