# Exchange OWA Diagnostic

## What this tool does

**Exchange OWA Diagnostic** is a generic, read-only troubleshooting tool for Microsoft Exchange Outlook on the web (OWA), IIS, and related Exchange web services.

The Field Kit version is portable and is not tied to a specific company, Exchange server, webmail hostname, monitoring service, IP address, request ID, incident date, or fixed log path.

## When to use it

Use it when users or monitoring report problems such as:

- OWA/webmail is unavailable,
- OWA availability is flapping,
- the login page opens intermittently,
- external OWA fails while local OWA works,
- HTTP 440 appears in monitoring or IIS logs,
- Exchange web app pools appear unhealthy,
- you need evidence before deciding whether the problem is IIS, Exchange, DNS, TLS, routing, proxying, or monitoring.

## What it checks

### Windows / PowerShell context

Records:

- computer name,
- current user,
- PowerShell version,
- elevation state.

### IIS

Attempts to inspect Exchange-related IIS application pools including names associated with:

- OWA,
- ECP,
- Autodiscover,
- MAPI,
- RPC,
- Sync,
- PowerShell,
- Exchange.

### Services

Lists:

- IIS `W3SVC`,
- IIS `WAS`,
- detected `MSExchange*` services.

### Exchange Management Shell

If Exchange cmdlets are available, it uses them automatically.

Possible checks include:

- `Test-ServiceHealth`
- `Get-ServerHealth`
- `Get-ServerComponentState`
- `Get-OwaVirtualDirectory`
- `Get-EcpVirtualDirectory`

If those cmdlets are unavailable, the rest of the diagnostic still runs.

### HTTP

Tests:

- local OWA, default `https://localhost/owa`,
- optional external OWA URL.

It records:

- HTTP status,
- response time,
- server header when available,
- request ID when available,
- error information.

### DNS

If a webmail hostname is supplied, the tool runs DNS resolution for it.

### Windows events

Reviews recent relevant warnings/errors from:

- Application log,
- System log,
- IIS/WAS providers,
- .NET/Application Error,
- Exchange providers,
- Schannel,
- TCP/IP,
- Service Control Manager.

### IIS / Exchange logs

The script dynamically looks for:

`%SystemDrive%\inetpub\logs\LogFiles`

and, when Exchange is installed, reads the Exchange install path from the registry and looks for:

`Logging\HttpProxy\Owa`

It can search recent logs for:

- OWA requests,
- HTTP 440,
- optional monitor IP,
- optional request ID.

## What it does NOT do

This diagnostic does **not**:

- restart Exchange services,
- restart IIS,
- recycle app pools,
- modify virtual directories,
- change authentication,
- change DNS,
- change firewall rules,
- modify certificates,
- modify Exchange configuration.

It is intended to collect evidence before a repair decision.

## HOW TO RUN

From the app, open **System Management -> Exchange OWA Diagnostic** and click the tool card. It runs read-only inside the Field Kit Run Center.

### Running from the app

Open:

**System Management -> Exchange OWA Diagnostic**

With no parameters, it analyzes the local computer and attempts:

`https://localhost/owa`

This is useful when running directly on an Exchange server.

## Optional parameters

### External OWA URL

```powershell
.\Troubleshoot-Exchange-OWA-Portable.ps1 -ExternalOwaUrl "https://mail.example.com/owa"
```

### Webmail hostname

```powershell
.\Troubleshoot-Exchange-OWA-Portable.ps1 -WebmailHost "mail.example.com"
```

If only `-WebmailHost` is supplied, the tool builds:

`https://<host>/owa`

for the external OWA test.

### Exchange server name

```powershell
.\Troubleshoot-Exchange-OWA-Portable.ps1 -ServerName "EXCH01"
```

### Lookback period

Default:

**24 hours**

Example:

```powershell
.\Troubleshoot-Exchange-OWA-Portable.ps1 -LookbackHours 12
```

### Monitor IP

Useful when a monitoring system is repeatedly hitting OWA:

```powershell
.\Troubleshoot-Exchange-OWA-Portable.ps1 -MonitorIp "192.0.2.25"
```

### Request ID

Useful when a specific IIS/Exchange request ID is already known:

```powershell
.\Troubleshoot-Exchange-OWA-Portable.ps1 -RequestId "REQUEST-ID-HERE"
```

## Understanding HTTP 440

A 440 response in Exchange OWA commonly relates to an OWA login/session timeout.

The tool deliberately does **not** interpret a 440 alone as proof that OWA is down.

Correlate:

- local vs external OWA,
- IIS app-pool state,
- Exchange health,
- monitor IP,
- request ID,
- nearby IIS/HttpProxy entries,
- event logs.

## Reports

When run through the Field Kit, reports are saved under the Field Kit diagnostic report directory in a folder similar to:

`Exchange-OWA_COMPUTERNAME_YYYY-MM-DD_HHMMSS`

Main report:

`Exchange-OWA-Diagnostic.txt`

## How to interpret common patterns

### Local OWA works, external OWA fails

Investigate:

- DNS,
- firewall,
- NAT,
- reverse proxy,
- load balancer,
- TLS/certificate path,
- external routing.

### Local and external OWA both fail

Focus more heavily on:

- IIS,
- OWA/ECP app pools,
- Exchange services,
- Exchange server health,
- server components,
- local certificate/service errors.

### Monitoring reports down but users can open OWA

Correlate the monitor IP and HTTP status in IIS/HttpProxy logs. A monitor may be treating an expected authentication/session response as a service outage.

## Preserved original

The original supplied site-specific diagnostic remains unchanged at:

`Windows\Scripts\Server\Troubleshoot-Exchange-OWA.ps1`

The app runs the portable adaptation:

`Windows\Scripts\FieldKit\Troubleshoot-Exchange-OWA-Portable.ps1`
