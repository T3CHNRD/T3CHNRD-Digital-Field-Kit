<#
.SYNOPSIS
    Troubleshoots Exchange OWA/webmail availability flapping.

.DESCRIPTION
    This script checks:
    - IIS app pool state for OWA/ECP/Exchange services
    - Core IIS and Exchange services
    - Exchange Server health
    - Server component state
    - OWA/ECP virtual directory configuration
    - DNS resolution for webmail hostname
    - Local and external OWA HTTP response behavior
    - IIS W3SVC logs for monitor IP, HTTP 440, OWA path, and request ID
    - Exchange HttpProxy\Owa logs for monitor IP, HTTP 440, and request ID
    - Basic notes about possible false-positive monitoring if HTTP 440 is treated as down

.NOTES
    Run from elevated Exchange Management Shell on ALBL-EXCH2019.

    This script is read-only/diagnostic.
    It does not restart services, recycle app pools, or change Exchange/IIS configuration.
#>

# =========================
# User-configurable values
# =========================

$ServerName        = "ALBL-EXCH2019"
$WebmailHost       = "webmail.albl.com"
$ExternalOwaUrl    = "https://webmail.albl.com/owa"
$LocalOwaUrl       = "https://localhost/owa"
$MonitorIp         = "52.15.147.27"
$RequestId         = "9f924ce8-bf2f-4b24-bba9-059d50aa1071"

# Alert time from monitor:
# 2026-05-13 08:38:31 Eastern = 2026-05-13 12:38:31 UTC
$IncidentDateUtc   = "2026-05-13"
$IncidentHourUtc   = "12:38"

# IIS logs use UTC date naming: u_exYYMMDD.log
$IisLogFile        = "C:\inetpub\logs\LogFiles\W3SVC1\u_ex260513.log"
$IisLogWildcard    = "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log"
$HttpProxyOwaLogs  = "C:\Program Files\Microsoft\Exchange Server\V15\Logging\HttpProxy\Owa\*.log"

# Output location
$OutputRoot        = "C:\Temp\OWA-Troubleshooting"
$Timestamp         = Get-Date -Format "yyyyMMdd-HHmmss"
$OutputFolder      = Join-Path $OutputRoot $Timestamp
$ReportFile        = Join-Path $OutputFolder "OWA-Troubleshooting-Report.txt"

# =========================
# Setup
# =========================

New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null

function Write-Section {
    param(
        [string]$Title
    )

    $line = "=" * 80
    "`r`n$line`r`n$Title`r`n$line" | Tee-Object -FilePath $ReportFile -Append
}

function Write-SubSection {
    param(
        [string]$Title
    )

    "`r`n--- $Title ---" | Tee-Object -FilePath $ReportFile -Append
}

function Run-Check {
    param(
        [string]$Title,
        [scriptblock]$Command
    )

    Write-SubSection $Title

    try {
        & $Command 2>&1 | Out-String | Tee-Object -FilePath $ReportFile -Append
    }
    catch {
        "ERROR: $($_.Exception.Message)" | Tee-Object -FilePath $ReportFile -Append
    }
}

function Test-Url {
    param(
        [string]$Name,
        [string]$Url
    )

    Write-SubSection "URL Test: $Name - $Url"

    $start = Get-Date

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
        $elapsed = New-TimeSpan -Start $start -End (Get-Date)

        [PSCustomObject]@{
            Name              = $Name
            Url               = $Url
            StatusCode        = $response.StatusCode
            StatusDescription = $response.StatusDescription
            ResponseMs        = [math]::Round($elapsed.TotalMilliseconds, 0)
            Server            = $response.Headers["Server"]
            X_FEServer        = $response.Headers["X-FEServer"]
            RequestId         = $response.Headers["Request-Id"]
            ContentLength     = $response.RawContentLength
        } | Format-List | Out-String | Tee-Object -FilePath $ReportFile -Append
    }
    catch {
        $elapsed = New-TimeSpan -Start $start -End (Get-Date)

        $statusCode = $null
        $statusDescription = $null

        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
                $statusDescription = $_.Exception.Response.StatusDescription
            }
            catch {}
        }

        [PSCustomObject]@{
            Name              = $Name
            Url               = $Url
            StatusCode        = $statusCode
            StatusDescription = $statusDescription
            ResponseMs        = [math]::Round($elapsed.TotalMilliseconds, 0)
            Error             = $_.Exception.Message
            Note              = "HTTP 440 from OWA can indicate login/session timeout, not necessarily a full outage."
        } | Format-List | Out-String | Tee-Object -FilePath $ReportFile -Append
    }
}

# =========================
# Header
# =========================

Write-Section "OWA / Webmail Troubleshooting Report"

@"
Generated:       $(Get-Date)
ServerName:      $ServerName
WebmailHost:     $WebmailHost
ExternalOwaUrl:  $ExternalOwaUrl
LocalOwaUrl:     $LocalOwaUrl
MonitorIp:       $MonitorIp
RequestId:       $RequestId
Incident UTC:    $IncidentDateUtc $IncidentHourUtc
OutputFolder:    $OutputFolder

Primary goal:
- Determine whether OWA is truly failing or whether the monitor is treating HTTP 440 Login Time-out as a hard outage.
"@ | Tee-Object -FilePath $ReportFile -Append

# =========================
# Check PowerShell / Exchange context
# =========================

Write-Section "PowerShell and Exchange Context"

Run-Check "Current PowerShell host and user" {
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        UserName     = "$env:USERDOMAIN\$env:USERNAME"
        PSVersion    = $PSVersionTable.PSVersion.ToString()
        IsElevated   = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    } | Format-List
}

Run-Check "Exchange cmdlet availability check" {
    $cmdlets = "Get-ServerHealth","Get-ServerComponentState","Test-ServiceHealth","Get-OwaVirtualDirectory","Get-EcpVirtualDirectory"

    $results = foreach ($cmdlet in $cmdlets) {
        $found = Get-Command $cmdlet -ErrorAction SilentlyContinue

        [PSCustomObject]@{
            Cmdlet = $cmdlet
            Found  = [bool]$found
        }
    }

    $results | Format-Table -Auto
}

# =========================
# IIS module and app pools
# =========================

Write-Section "IIS Application Pool Checks"

Run-Check "Import WebAdministration module" {
    Import-Module WebAdministration -ErrorAction Stop
    "WebAdministration module imported successfully."
}

Run-Check "Exchange IIS app pool states" {
    $appPools = @(
        "MSExchangeOWAAppPool",
        "MSExchangeECPAppPool",
        "MSExchangeServicesAppPool",
        "MSExchangeAutodiscoverAppPool",
        "MSExchangeMapiFrontEndAppPool",
        "MSExchangeRpcProxyFrontEndAppPool",
        "MSExchangeSyncAppPool",
        "MSExchangePowerShellFrontEndAppPool"
    )

    $results = foreach ($pool in $appPools) {
        try {
            $state = Get-WebAppPoolState $pool -ErrorAction Stop

            [PSCustomObject]@{
                AppPool = $pool
                State   = $state.Value
            }
        }
        catch {
            [PSCustomObject]@{
                AppPool = $pool
                State   = "ERROR: $($_.Exception.Message)"
            }
        }
    }

    $results | Format-Table -Auto
}

# =========================
# Core service checks
# =========================

Write-Section "Windows and Exchange Service Checks"

Run-Check "Core webmail-related services" {
    Get-Service W3SVC,WAS,MSExchangeIS,MSExchangeADTopology,MSExchangeServiceHost -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Format-Table Name,Status,StartType,DisplayName -Auto
}

Run-Check "Stopped MSExchange services" {
    Get-Service MSExchange* |
        Where-Object {$_.Status -ne "Running"} |
        Sort-Object Name |
        Format-Table Name,Status,StartType,DisplayName -Auto
}

# =========================
# Exchange health
# =========================

Write-Section "Exchange Health Checks"

Run-Check "Test-ServiceHealth" {
    Test-ServiceHealth
}

Run-Check "All unhealthy Exchange health monitors" {
    Get-ServerHealth $ServerName |
        Where-Object {$_.AlertValue -ne "Healthy"} |
        Sort-Object HealthSetName,Name |
        Format-Table HealthSetName,Name,AlertValue,ServerComponent -Auto
}

Run-Check "OWA/ECP/Frontend/Proxy/IIS related unhealthy health monitors" {
    Get-ServerHealth $ServerName |
        Where-Object {
            $_.HealthSetName -match "OWA|ECP|Outlook|Frontend|Proxy|IIS" -and
            $_.AlertValue -ne "Healthy"
        } |
        Sort-Object HealthSetName,Name |
        Format-Table HealthSetName,Name,AlertValue,ServerComponent -Auto
}

Run-Check "Server component states" {
    Get-ServerComponentState $ServerName |
        Sort-Object Component |
        Format-Table Component,State -Auto
}

Run-Check "Inactive server components only" {
    Get-ServerComponentState $ServerName |
        Where-Object {$_.State -ne "Active"} |
        Sort-Object Component |
        Format-Table Component,State -Auto
}

# =========================
# Virtual directory checks
# =========================

Write-Section "OWA and ECP Virtual Directory Configuration"

Run-Check "OWA virtual directory settings" {
    Get-OwaVirtualDirectory -Server $ServerName |
        Format-List Name,InternalUrl,ExternalUrl,*Authentication*,BasicAuthentication,FormsAuthentication
}

Run-Check "ECP virtual directory settings" {
    Get-EcpVirtualDirectory -Server $ServerName |
        Format-List Name,InternalUrl,ExternalUrl,*Authentication*,BasicAuthentication,FormsAuthentication
}

# =========================
# DNS checks
# =========================

Write-Section "DNS Checks"

Run-Check "Resolve webmail DNS" {
    Resolve-DnsName $WebmailHost |
        Format-Table Name,Type,IPAddress,NameHost,TTL -Auto
}

# =========================
# URL tests
# =========================

Write-Section "OWA HTTP Response Tests"

Test-Url -Name "External OWA URL" -Url $ExternalOwaUrl
Test-Url -Name "Localhost OWA URL" -Url $LocalOwaUrl

Run-Check "curl.exe header check for external OWA" {
    curl.exe -I $ExternalOwaUrl
}

# =========================
# IIS log checks
# =========================

Write-Section "IIS Log Checks"

Run-Check "Newest IIS W3SVC1 logs" {
    Get-ChildItem "C:\inetpub\logs\LogFiles\W3SVC1" -ErrorAction Stop |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 10 Name,LastWriteTime,Length |
        Format-Table -Auto
}

Run-Check "Targeted IIS log search - exact incident log if present" {
    if (Test-Path $IisLogFile) {
        Select-String -Path $IisLogFile -Pattern $MonitorIp," 440 ",$IncidentHourUtc,"/owa",$RequestId |
            Select-Object -First 200 |
            Format-Table LineNumber,Line -Wrap
    }
    else {
        "Specific IIS log not found: $IisLogFile"
        "Falling back to wildcard IIS log search."

        Select-String -Path $IisLogWildcard -Pattern $MonitorIp," 440 ",$IncidentHourUtc,"/owa",$RequestId |
            Select-Object -First 200 |
            Format-Table Path,LineNumber,Line -Wrap
    }
}

Run-Check "IIS log search - monitor IP only" {
    Select-String -Path $IisLogWildcard -Pattern $MonitorIp -ErrorAction SilentlyContinue |
        Select-Object -First 200 |
        Format-Table Path,LineNumber,Line -Wrap
}

Run-Check "IIS log search - HTTP 440 only" {
    Select-String -Path $IisLogWildcard -Pattern " 440 " -ErrorAction SilentlyContinue |
        Select-Object -First 200 |
        Format-Table Path,LineNumber,Line -Wrap
}

Run-Check "IIS log search - request ID only" {
    Select-String -Path $IisLogWildcard -Pattern $RequestId -ErrorAction SilentlyContinue |
        Select-Object -First 200 |
        Format-Table Path,LineNumber,Line -Wrap
}

# =========================
# Exchange HttpProxy OWA log checks
# =========================

Write-Section "Exchange HttpProxy OWA Log Checks"

Run-Check "Newest OWA HttpProxy logs" {
    Get-ChildItem "C:\Program Files\Microsoft\Exchange Server\V15\Logging\HttpProxy\Owa" -ErrorAction Stop |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 10 Name,LastWriteTime,Length |
        Format-Table -Auto
}

Run-Check "HttpProxy OWA targeted search" {
    Select-String -Path $HttpProxyOwaLogs -Pattern $MonitorIp,"440",$RequestId,$IncidentHourUtc -ErrorAction SilentlyContinue |
        Select-Object -First 300 |
        Format-Table Path,LineNumber,Line -Wrap
}

Run-Check "HttpProxy OWA monitor IP only" {
    Select-String -Path $HttpProxyOwaLogs -Pattern $MonitorIp -ErrorAction SilentlyContinue |
        Select-Object -First 200 |
        Format-Table Path,LineNumber,Line -Wrap
}

Run-Check "HttpProxy OWA request ID only" {
    Select-String -Path $HttpProxyOwaLogs -Pattern $RequestId -ErrorAction SilentlyContinue |
        Select-Object -First 200 |
        Format-Table Path,LineNumber,Line -Wrap
}

# =========================
# Event log checks
# =========================

Write-Section "Event Log Checks Around Recent Time Window"

$Since = (Get-Date).AddHours(-24)

Run-Check "Recent IIS/WAS/W3SVC/.NET/Application errors - last 24 hours" {
    Get-WinEvent -FilterHashtable @{
        LogName   = "Application"
        StartTime = $Since
        Level     = 1,2,3
    } -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProviderName -match "IIS|W3SVC|WAS|ASP.NET|.NET Runtime|Application Error|MSExchange"
        } |
        Select-Object TimeCreated,ProviderName,Id,LevelDisplayName,Message |
        Select-Object -First 100 |
        Format-List
}

Run-Check "Recent System errors related to IIS/services/network - last 24 hours" {
    Get-WinEvent -FilterHashtable @{
        LogName   = "System"
        StartTime = $Since
        Level     = 1,2,3
    } -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProviderName -match "Service Control Manager|WAS|W3SVC|Tcpip|Schannel"
        } |
        Select-Object TimeCreated,ProviderName,Id,LevelDisplayName,Message |
        Select-Object -First 100 |
        Format-List
}

# =========================
# Basic interpretation
# =========================

Write-Section "Basic Interpretation Guide"

@"
Review these items in the report:

1. If MSExchangeOWAAppPool or MSExchangeECPAppPool is stopped:
   - That is likely a real server-side OWA/ECP issue.
   - Check Event Viewer for WAS, W3SVC, .NET Runtime, and Application Error events.

2. If OWA/ECP app pools are started and Invoke-WebRequest/curl receives HTTP 440:
   - Exchange is responding.
   - HTTP 440 often means OWA login/session timeout.
   - This may be a false-positive monitor issue if the monitor expects only HTTP 200.

3. If external URL fails but localhost works:
   - Check DNS, NAT, firewall, reverse proxy, SSL inspection, or public routing.
   - Confirm TCP 443 forwards to the right Exchange server or proxy.

4. If localhost fails:
   - Focus on Exchange/IIS/server health.
   - Check app pools, services, Exchange health, and Windows event logs.

5. If the monitor IP appears in IIS logs with HTTP 440:
   - The monitor is reaching Exchange.
   - Consider changing the monitor URL or allowed status codes.
   - Test https://webmail.albl.com/owa/healthcheck.htm if available.

6. If the monitor IP does not appear in IIS logs:
   - Traffic may not be reaching Exchange.
   - Check firewall, NAT, reverse proxy, WAF, ISP, or DNS path.

7. If Request-Id appears in HttpProxy logs:
   - Use surrounding lines to determine whether Exchange proxied the request successfully or failed internally.

Recommended monitor adjustment:
- Do not treat HTTP 440 by itself as proof that OWA is down.
- Use a more appropriate Exchange health endpoint if available.
- Or configure the monitor to alert only on connection failure, timeout, 5xx errors, or unexpected response behavior.
"@ | Tee-Object -FilePath $ReportFile -Append

# =========================
# Done
# =========================

Write-Section "Completed"

"Report saved to: $ReportFile" | Tee-Object -FilePath $ReportFile -Append

Write-Host ""
Write-Host "OWA troubleshooting completed." -ForegroundColor Green
Write-Host "Report saved to:" -ForegroundColor Cyan
Write-Host $ReportFile -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: open the report and look for app pool stops, failed URL tests, 440 entries, and whether the monitor IP appears in IIS/HttpProxy logs." -ForegroundColor Cyan
