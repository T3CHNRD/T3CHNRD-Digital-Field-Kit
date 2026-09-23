#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$WifiAlias,
    [switch]$SkipAdapterRestart
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

function Get-ReportRoot {
    if ($env:TTK_REPORT_DIR -and -not [string]::IsNullOrWhiteSpace($env:TTK_REPORT_DIR)) { return $env:TTK_REPORT_DIR }
    return (Join-Path $PSScriptRoot 'Diagnostic-Reports')
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

function Log { param([string]$Text) $Text | Tee-Object -FilePath $script:LogFile -Append }
function Run {
    param([string]$Label,[scriptblock]$Command)
    Log ''
    Log "===== $Label ====="
    try { & $Command 2>&1 | Out-String -Width 300 | Tee-Object -FilePath $script:LogFile -Append }
    catch { Log "[ERROR] $($_.Exception.Message)" }
}

$root = Get-ReportRoot
New-Item -ItemType Directory -Path $root -Force | Out-Null
$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$session = Join-Path $root ("WiFi-Reset_{0}_{1}" -f $env:COMPUTERNAME,$stamp)
New-Item -ItemType Directory -Path $session -Force | Out-Null
$script:LogFile = Join-Path $session 'WiFi-Reset.txt'
$ipResetLog = Join-Path $session 'netsh-ip-reset.log'

$wifi = Get-WifiAdapter -Alias $WifiAlias
if (-not $wifi) { throw 'No Wi-Fi adapter was detected. Specify -WifiAlias if the adapter uses a nonstandard name.' }

Log "Wi-Fi reset started: $(Get-Date)"
Log "Computer: $env:COMPUTERNAME"
Log "Wi-Fi adapter: $($wifi.Name)"
Log "Description: $($wifi.InterfaceDescription)"
Log "Status before: $($wifi.Status)"
Log 'WARNING: Winsock/TCP-IP reset affects the Windows network stack and normally warrants a reboot.'

Run 'Before - ipconfig /all' { & ipconfig.exe /all }
Run 'Before - Wi-Fi Interface' { & netsh.exe wlan show interfaces }
Run 'Before - Wi-Fi Profiles' { & netsh.exe wlan show profiles }
Run 'Before - Connection Profile' { Get-NetConnectionProfile -InterfaceAlias $wifi.Name -ErrorAction SilentlyContinue | Format-List * }
Run 'Reset Winsock Catalog' { & netsh.exe winsock reset }
Run 'Reset TCP/IP Stack' { & netsh.exe int ip reset "$ipResetLog" }
Run "Release DHCP Lease - $($wifi.Name)" { & ipconfig.exe /release "$($wifi.Name)" }
Start-Sleep -Seconds 2
Run "Renew DHCP Lease - $($wifi.Name)" { & ipconfig.exe /renew "$($wifi.Name)" }
Run 'Flush DNS Resolver Cache' { & ipconfig.exe /flushdns }

if (-not $SkipAdapterRestart) {
    Run "Restart Wi-Fi Adapter - $($wifi.Name)" {
        Disable-NetAdapter -Name $wifi.Name -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 3
        Enable-NetAdapter -Name $wifi.Name -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 5
        Get-NetAdapter -Name $wifi.Name | Format-Table Name,InterfaceDescription,Status,LinkSpeed,MacAddress -AutoSize
    }
}

Run 'Restart WLAN AutoConfig Service' {
    Restart-Service -Name WlanSvc -Force -ErrorAction Stop
    Get-Service -Name WlanSvc | Format-Table Name,Status,StartType -AutoSize
}
Run 'After - ipconfig /all' { & ipconfig.exe /all }
Run 'After - Wi-Fi Interface' { & netsh.exe wlan show interfaces }
Run 'After - Visible Networks / BSSIDs' { & netsh.exe wlan show networks mode=bssid }
Run 'Generate WLAN Report' { & netsh.exe wlan show wlanreport }
Run 'Recent WLAN AutoConfig Warnings/Errors' {
    $start = (Get-Date).AddHours(-8)
    Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-WLAN-AutoConfig/Operational'; StartTime=$start } -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in 'Error','Warning' -or $_.Id -in 8001,8002,8003,11000,11001,11004,12011 } |
        Select-Object TimeCreated,Id,LevelDisplayName,Message | Format-List
}

Log ''
Log '===== IMPORTANT ====='
Log '1. REBOOT RECOMMENDED: Winsock/TCP-IP resets may not be fully applied until Windows restarts.'
Log '2. This script did NOT delete any saved Wi-Fi profile.'
Log '3. This script did NOT change AP/Client/MultiAP isolation; that is configured on the AP/controller.'
Log '4. If Guest Wi-Fi works but the corporate SSID still fails, inspect 802.1X/EAP/certificate/profile/RADIUS policy next.'
Log "Report folder: $session"

Write-Host ''
Write-Host '[PASS] Wi-Fi/network stack reset completed.' -ForegroundColor Green
Write-Host 'A Windows reboot is recommended before deciding whether the repair worked.' -ForegroundColor Yellow
Write-Host "Report: $script:LogFile" -ForegroundColor Cyan
