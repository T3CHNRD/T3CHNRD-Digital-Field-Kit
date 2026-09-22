#Requires -Version 5.1
#Requires -RunAsAdministrator
# Interactive replacement for the archived site-specific subnet toggle.
$ErrorActionPreference='Stop'
function Test-HostIPv4([string]$Value){
 $parts=@($Value -split '\.')
 if($parts.Count -ne 4){return $false}
 foreach($part in $parts){if($part -notmatch '^(0|[1-9][0-9]{0,2})$' -or [int]$part -gt 255){return $false}}
 return ([int]$parts[0] -gt 0 -and [int]$parts[0] -lt 224 -and [int]$parts[0] -ne 127)
}
function Read-IPv4([string]$Prompt,[bool]$Optional=$false){
 while($true){
  $value=Read-Host $Prompt
  if($null -eq $value){throw 'Input closed; operation cancelled.'}
  $value=$value.Trim()
  if($Optional -and -not $value){return ''}
  if(Test-HostIPv4 $value){return $value}
  Write-Output 'Enter a valid unicast IPv4 address using four decimal octets.'
 }
}
function Get-SubnetMask([int]$Prefix){
 if($Prefix -lt 1 -or $Prefix -gt 32){throw 'Prefix must be between 1 and 32.'}
 return ((0..3 | ForEach-Object {$bits=[Math]::Min(8,[Math]::Max(0,$Prefix-8*$_));[int](256-[Math]::Pow(2,8-$bits))}) -join '.')
}
function Invoke-NetworkCommand([string[]]$CommandArgs){
 & netsh.exe @CommandArgs | Out-String | Write-Output
 if($LASTEXITCODE -ne 0){throw "netsh failed with exit code $LASTEXITCODE. Settings may be partially applied; inspect the adapter before continuing."}
}
$adapters=@(Get-NetAdapter -Physical | Sort-Object Name)
if(-not $adapters.Count){throw 'No physical network adapter found.'}
for($i=0;$i -lt $adapters.Count;$i++){Write-Output ("{0}. {1} ({2})" -f ($i+1),$adapters[$i].Name,$adapters[$i].Status)}
$selection=Read-Host 'Adapter number (blank cancels)'
if([string]::IsNullOrWhiteSpace($selection)){return}
$number=0
if(-not [int]::TryParse($selection,[ref]$number) -or $number -lt 1 -or $number -gt $adapters.Count){throw 'Invalid adapter selection; no changes made.'}
$adapter=$adapters[$number-1]
Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex | Format-List | Out-String | Write-Output
$mode=Read-Host 'Enter STATIC for custom addresses, DHCP for automatic addressing, or blank to cancel'
if([string]::IsNullOrWhiteSpace($mode)){return}
if($mode -notin @('STATIC','DHCP')){throw 'Choose STATIC or DHCP; no changes made.'}
$dns=@()
if($mode -eq 'STATIC'){
 $address=Read-IPv4 'IPv4 address'
 $prefixText=Read-Host 'Prefix length (1-32)'
 $prefix=0
 if(-not [int]::TryParse($prefixText,[ref]$prefix) -or $prefix -lt 1 -or $prefix -gt 32){throw 'Invalid prefix; no changes made.'}
 $mask=Get-SubnetMask $prefix
 $gateway=Read-IPv4 'Gateway (blank for none)' $true
 $dnsText=Read-Host 'DNS server IPv4 addresses, separated by commas (blank for no DNS servers)'
 if(-not [string]::IsNullOrWhiteSpace($dnsText)){
  $dns=@($dnsText.Split(',') | ForEach-Object {$_.Trim()})
  foreach($server in $dns){if(-not(Test-HostIPv4 $server)){throw 'Invalid DNS server; no changes made.'}}
 }
 Write-Output "Selected adapter: $($adapter.Name); address: $address/$prefix; mask: $mask; gateway: $gateway; DNS: $($dns -join ', ')"
}else{Write-Output "Selected adapter: $($adapter.Name); automatic IPv4 address and DNS (DHCP)."}
Write-Output 'This can disconnect your network or remote session. Existing static settings will be replaced.'
if((Read-Host 'Type APPLY to change this adapter') -cne 'APPLY'){Write-Output 'Cancelled; no changes made.';return}
$reportDirectory=$env:TTK_REPORT_DIR
if([string]::IsNullOrWhiteSpace($reportDirectory)){$reportDirectory=Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Diagnostic-Reports'}
New-Item -ItemType Directory -Force -Path $reportDirectory -ErrorAction Stop | Out-Null
$backup=Join-Path $reportDirectory ('Network-Before-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'.json')
[ordered]@{Adapter=$adapter.Name;InterfaceIndex=$adapter.ifIndex;Addresses=@(Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4);Interfaces=@(Get-NetIPInterface -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4);Routes=@(Get-NetRoute -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4);DNS=@(Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4)} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $backup -Encoding UTF8 -ErrorAction Stop
Write-Output "Previous configuration recorded: $backup (reference only; not an automatic rollback)."
if($mode -eq 'DHCP'){
 Invoke-NetworkCommand @('interface','ipv4','set','address',"name=$($adapter.ifIndex)",'source=dhcp')
 Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -ErrorAction Stop
}else{
 $gatewayArgument=if($gateway){$gateway}else{'none'}
 Invoke-NetworkCommand @('interface','ipv4','set','address',"name=$($adapter.ifIndex)",'source=static',"address=$address","mask=$mask","gateway=$gatewayArgument")
 if($dns.Count){Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses $dns -ErrorAction Stop}
 else{Invoke-NetworkCommand @('interface','ipv4','set','dnsservers',"name=$($adapter.ifIndex)",'source=static','address=none')}
}
Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex | Format-List | Out-String | Write-Output
Write-Output 'Configuration applied. Verify connectivity and DNS before leaving this machine.'
