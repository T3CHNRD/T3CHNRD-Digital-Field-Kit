#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$toolkitRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$preferredLogDir=if($env:TTK_REPORT_DIR){$env:TTK_REPORT_DIR}else{Join-Path $toolkitRoot 'Logs'}
try{New-Item -Path $preferredLogDir -ItemType Directory -Force -ErrorAction Stop|Out-Null;$logDir=$preferredLogDir}catch{$logDir=Join-Path $env:TEMP 'Windows-Master-Diagnostic-Toolkit-Reports';New-Item $logDir -ItemType Directory -Force -ErrorAction Stop|Out-Null}
$report=Join-Path $logDir ("LocalNetworkScan-{0:yyyyMMdd-HHmmss}.csv" -f (Get-Date))
Write-Output 'Local network scan: /24 host discovery and common TCP-port probes.'
try{$config=Get-NetIPConfiguration -ErrorAction Stop|Where-Object{$_.IPv4DefaultGateway -and $_.IPv4Address}|Select-Object -First 1}catch{Write-Error "Unable to read network configuration: $($_.Exception.Message)";exit 1}
if(-not $config){Write-Output 'No active IPv4 gateway found. Scan skipped.';exit 0}
$ip=[string]$config.IPv4Address.IPAddress
if($ip -notmatch '^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$'){Write-Error "Unexpected IPv4 address: $ip";exit 1}
$prefix="$($matches[1]).$($matches[2]).$($matches[3])";$ports=@(22,80,135,139,443,445,3389,5985,8080,9100);$results=New-Object System.Collections.Generic.List[object]
1..254|ForEach-Object{$target="$prefix.$_";$pingReply=& ping.exe -n 1 -w 300 $target 2>$null;if($LASTEXITCODE -eq 0 -and ($pingReply -match 'TTL=')){$name=try{[Net.Dns]::GetHostEntry($target).HostName}catch{''};$open=foreach($port in $ports){$client=New-Object Net.Sockets.TcpClient;try{$iar=$client.BeginConnect($target,$port,$null,$null);if($iar.AsyncWaitHandle.WaitOne(200,$false)){$client.EndConnect($iar);$port}}catch{}finally{$client.Close()}};$obj=[pscustomobject]@{IP=$target;Hostname=$name;OpenPorts=($open -join ',')};$results.Add($obj);Write-Output ("Found {0} {1} ports: {2}" -f $target,$name,($open -join ','))}}
$results|Export-Csv -NoTypeInformation -Path $report -ErrorAction Stop;Write-Output "Scan complete. Hosts found: $($results.Count). Report: $report";exit 0
