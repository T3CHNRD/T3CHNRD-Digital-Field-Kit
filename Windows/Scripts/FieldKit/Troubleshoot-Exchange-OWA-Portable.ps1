#Requires -Version 5.1
<#
.SYNOPSIS
Portable read-only Exchange OWA / IIS diagnostic.

.DESCRIPTION
Generic Field Kit diagnostic. No company, server, hostname, monitor IP, request ID, or date is hard-coded.
It checks IIS/Exchange services, Exchange-related app pools, optional Exchange Management Shell health,
local/optional external OWA HTTP response, DNS, recent events, and recent IIS/HttpProxy OWA logs.
It makes no Exchange, IIS, firewall, DNS, certificate, service, or virtual-directory changes.
#>
[CmdletBinding()]
param(
 [string]$ServerName=$env:COMPUTERNAME,
 [string]$WebmailHost,
 [string]$ExternalOwaUrl,
 [string]$LocalOwaUrl='https://localhost/owa',
 [string]$MonitorIp,
 [string]$RequestId,
 [ValidateRange(1,168)][int]$LookbackHours=24
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'

if(-not $WebmailHost -and $ExternalOwaUrl){try{$WebmailHost=([uri]$ExternalOwaUrl).Host}catch{}}
if($WebmailHost -and -not $ExternalOwaUrl){$ExternalOwaUrl='https://'+$WebmailHost+'/owa'}

$ReportRoot=if($env:TTK_REPORT_DIR){$env:TTK_REPORT_DIR}else{Join-Path $env:TEMP 'T3DFK-Exchange-OWA'}
$OutputFolder=Join-Path $ReportRoot ('Exchange-OWA_{0}_{1}' -f $env:COMPUTERNAME,(Get-Date -Format 'yyyy-MM-dd_HHmmss'))
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
$ReportFile=Join-Path $OutputFolder 'Exchange-OWA-Diagnostic.txt'

function Write-Section([string]$Title){
 $nl=[Environment]::NewLine
 $line='='*78
 ($nl+$line+$nl+$Title+$nl+$line) | Tee-Object -FilePath $ReportFile -Append
}
function Invoke-Check([string]$Title,[scriptblock]$Command){
 ([Environment]::NewLine+'--- '+$Title+' ---') | Tee-Object -FilePath $ReportFile -Append
 try{& $Command 2>&1 | Out-String -Width 300 | Tee-Object -FilePath $ReportFile -Append}
 catch{('ERROR: '+$_.Exception.Message) | Tee-Object -FilePath $ReportFile -Append}
}
function Test-OwaUrl([string]$Name,[string]$Url){
 if([string]::IsNullOrWhiteSpace($Url)){return}
 Invoke-Check ('URL Test: '+$Name+' - '+$Url) {
  $sw=[Diagnostics.Stopwatch]::StartNew()
  try{
   $r=Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
   $sw.Stop()
   [pscustomobject]@{Name=$Name;Url=$Url;StatusCode=[int]$r.StatusCode;ResponseMs=$sw.ElapsedMilliseconds;Server=$r.Headers['Server'];RequestId=$r.Headers['Request-Id']} | Format-List
  }catch{
   $sw.Stop();$code=$null
   try{$code=[int]$_.Exception.Response.StatusCode}catch{}
   [pscustomobject]@{Name=$Name;Url=$Url;StatusCode=$code;ResponseMs=$sw.ElapsedMilliseconds;Error=$_.Exception.Message;Note='HTTP 440 can represent OWA login/session timeout and does not by itself prove OWA is down.'} | Format-List
  }
 }
}

Write-Section 'Exchange OWA / IIS Diagnostic'
@"
Generated:      $(Get-Date)
Computer:       $env:COMPUTERNAME
ServerName:     $ServerName
WebmailHost:    $WebmailHost
ExternalOwaUrl: $ExternalOwaUrl
LocalOwaUrl:    $LocalOwaUrl
MonitorIp:      $MonitorIp
RequestId:      $RequestId
LookbackHours:  $LookbackHours
Report:         $ReportFile
"@ | Tee-Object -FilePath $ReportFile -Append

Invoke-Check 'PowerShell / OS context' {
 [pscustomobject]@{
  ComputerName=$env:COMPUTERNAME
  User=($env:USERDOMAIN+'\'+$env:USERNAME)
  PSVersion=$PSVersionTable.PSVersion.ToString()
  IsElevated=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 } | Format-List
}

$exchangeCmdlets=@('Get-ServerHealth','Get-ServerComponentState','Test-ServiceHealth','Get-OwaVirtualDirectory','Get-EcpVirtualDirectory')
$available=@{}
foreach($cmd in $exchangeCmdlets){$available[$cmd]=[bool](Get-Command $cmd -ErrorAction SilentlyContinue)}
Write-Section 'Exchange Cmdlet Availability'
$available.GetEnumerator() | Sort-Object Name | Format-Table Name,Value -Auto | Out-String | Tee-Object -FilePath $ReportFile -Append

Write-Section 'IIS Checks'
Invoke-Check 'Exchange-related IIS application pools' {
 Import-Module WebAdministration -ErrorAction Stop
 Get-ChildItem IIS:\AppPools | Where-Object {$_.Name -match 'Exchange|OWA|ECP|Autodiscover|Mapi|Rpc|Sync|PowerShell'} | ForEach-Object {
  $state=try{(Get-WebAppPoolState -Name $_.Name -ErrorAction Stop).Value}catch{'Unknown'}
  [pscustomobject]@{AppPool=$_.Name;State=$state}
 } | Format-Table -Auto
}

Write-Section 'Service Checks'
Invoke-Check 'IIS and Exchange services' {
 Get-Service -ErrorAction SilentlyContinue | Where-Object {$_.Name -in 'W3SVC','WAS' -or $_.Name -like 'MSExchange*'} | Sort-Object Name | Format-Table Name,Status,StartType,DisplayName -Auto
}
if($available['Test-ServiceHealth']){Invoke-Check 'Exchange Test-ServiceHealth' {Test-ServiceHealth}}
if($available['Get-ServerHealth']){Invoke-Check 'Unhealthy Exchange health monitors' {Get-ServerHealth $ServerName | Where-Object {$_.AlertValue -ne 'Healthy'} | Sort-Object HealthSetName,Name | Format-Table HealthSetName,Name,AlertValue,ServerComponent -Auto}}
if($available['Get-ServerComponentState']){Invoke-Check 'Inactive Exchange components' {Get-ServerComponentState $ServerName | Where-Object {$_.State -ne 'Active'} | Sort-Object Component | Format-Table Component,State -Auto}}
if($available['Get-OwaVirtualDirectory']){Invoke-Check 'OWA virtual directories' {Get-OwaVirtualDirectory -Server $ServerName | Format-List Name,InternalUrl,ExternalUrl,*Authentication*}}
if($available['Get-EcpVirtualDirectory']){Invoke-Check 'ECP virtual directories' {Get-EcpVirtualDirectory -Server $ServerName | Format-List Name,InternalUrl,ExternalUrl,*Authentication*}}

if($WebmailHost){Write-Section 'DNS';Invoke-Check ('Resolve '+$WebmailHost) {Resolve-DnsName $WebmailHost | Format-Table Name,Type,IPAddress,NameHost,TTL -Auto}}

Write-Section 'HTTP Tests'
Test-OwaUrl 'External OWA' $ExternalOwaUrl
Test-OwaUrl 'Local OWA' $LocalOwaUrl
if($ExternalOwaUrl -and (Get-Command curl.exe -ErrorAction SilentlyContinue)){Invoke-Check 'curl.exe response headers' {& curl.exe -I $ExternalOwaUrl}}

$since=(Get-Date).AddHours(-$LookbackHours)
Write-Section 'Event Logs'
Invoke-Check ('Application warnings/errors - last '+$LookbackHours+' hours') {
 Get-WinEvent -FilterHashtable @{LogName='Application';StartTime=$since;Level=1,2,3} -ErrorAction SilentlyContinue | Where-Object {$_.ProviderName -match 'IIS|W3SVC|WAS|ASP.NET|\.NET Runtime|Application Error|MSExchange'} | Select-Object -First 150 TimeCreated,ProviderName,Id,LevelDisplayName,Message | Format-List
}
Invoke-Check ('System warnings/errors - last '+$LookbackHours+' hours') {
 Get-WinEvent -FilterHashtable @{LogName='System';StartTime=$since;Level=1,2,3} -ErrorAction SilentlyContinue | Where-Object {$_.ProviderName -match 'Service Control Manager|WAS|W3SVC|Tcpip|Schannel'} | Select-Object -First 150 TimeCreated,ProviderName,Id,LevelDisplayName,Message | Format-List
}

$iisRoot=Join-Path $env:SystemDrive 'inetpub\logs\LogFiles'
$exchangeInstall=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\ExchangeServer\v15\Setup' -ErrorAction SilentlyContinue).MsiInstallPath
$httpProxyRoot=if($exchangeInstall){Join-Path $exchangeInstall 'Logging\HttpProxy\Owa'}else{$null}

Write-Section 'Log Discovery'
Invoke-Check 'IIS log folders' {if(Test-Path $iisRoot){Get-ChildItem $iisRoot -Directory | Select-Object FullName,LastWriteTime | Format-Table -Auto}else{'IIS log root not found: '+$iisRoot}}
Invoke-Check 'Exchange HttpProxy OWA log folder' {if($httpProxyRoot -and (Test-Path $httpProxyRoot)){Get-ChildItem $httpProxyRoot -File -Filter '*.log' | Sort-Object LastWriteTime -Descending | Select-Object -First 10 FullName,LastWriteTime,Length | Format-Table -Auto}else{'Exchange HttpProxy OWA log folder was not detected.'}}

$patterns=@(' 440 ','/owa')
if($MonitorIp){$patterns+=$MonitorIp}
if($RequestId){$patterns+=$RequestId}
if(Test-Path $iisRoot){Invoke-Check 'Recent IIS OWA / 440 / optional monitor/request matches' {
 $logs=Get-ChildItem $iisRoot -Recurse -File -Filter '*.log' -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -ge $since} | Sort-Object LastWriteTime -Descending | Select-Object -First 50
 if($logs){Select-String -Path $logs.FullName -Pattern $patterns -ErrorAction SilentlyContinue | Select-Object -First 300 Path,LineNumber,Line | Format-Table -Wrap}
}}
if($httpProxyRoot -and (Test-Path $httpProxyRoot)){Invoke-Check 'Recent Exchange HttpProxy OWA matches' {
 $logs=Get-ChildItem $httpProxyRoot -File -Filter '*.log' -ErrorAction SilentlyContinue | Where-Object {$_.LastWriteTime -ge $since} | Sort-Object LastWriteTime -Descending | Select-Object -First 50
 if($logs){Select-String -Path $logs.FullName -Pattern $patterns -ErrorAction SilentlyContinue | Select-Object -First 300 Path,LineNumber,Line | Format-Table -Wrap}
}}

Write-Section 'Interpretation Guide'
@'
- If OWA/ECP app pools are stopped, investigate IIS/WAS/.NET/Application event errors.
- If localhost OWA works but external OWA fails, investigate DNS, firewall, NAT, reverse proxy, TLS, or routing.
- If both local and external OWA fail, focus on Exchange/IIS/service health.
- HTTP 440 often means an OWA login/session timeout; by itself it does not prove OWA is down.
- If a monitor IP or request ID is supplied and appears in IIS/HttpProxy logs, inspect nearby lines to trace that request.
- If Exchange cmdlets are unavailable, run this tool on an Exchange server or from Exchange Management Shell for deeper Exchange health data.
'@ | Tee-Object -FilePath $ReportFile -Append

Write-Host '[PASS] Exchange OWA diagnostic completed.' -ForegroundColor Green
Write-Host ('Report: '+$ReportFile) -ForegroundColor Cyan
