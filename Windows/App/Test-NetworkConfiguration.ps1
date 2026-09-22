#Requires -Version 5.1
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scriptPath=Join-Path $root 'Windows/Scripts/Network/Set-InteractiveNetworkConfiguration.ps1'
$code=(Get-Content $scriptPath -Raw) -replace '(?m)^#Requires -RunAsAdministrator\r?\n',''
$script:answers=New-Object 'Collections.Generic.Queue[string]'
$script:changes=0
function Read-Host {param($Prompt) if(-not $script:answers.Count){throw 'Unexpected prompt: '+$Prompt};$script:answers.Dequeue()}
function Get-NetAdapter {[pscustomobject]@{Name='Test adapter';ifIndex=9;Status='Up'}}
function Get-NetIPConfiguration {param($InterfaceIndex) [pscustomobject]@{Adapter='Test adapter'}}
function Get-NetIPAddress {param($InterfaceIndex,$AddressFamily) @()}
function Get-NetIPInterface {param($InterfaceIndex,$AddressFamily) @()}
function Get-NetRoute {param($InterfaceIndex,$AddressFamily) @()}
function Get-DnsClientServerAddress {param($InterfaceIndex,$AddressFamily) @()}
function Set-DnsClientServerAddress {param($InterfaceIndex,$ServerAddresses,[switch]$ResetServerAddresses,$ErrorAction) $script:changes++}
function netsh.exe {$script:changes++;$global:LASTEXITCODE=0}
$fixture=Join-Path $env:TEMP ('FK-network-test-'+[guid]::NewGuid().ToString('N'))
$previous=$env:TTK_REPORT_DIR
try{
 $env:TTK_REPORT_DIR=$fixture
 foreach($answer in @('1','STATIC','10.20.30.40','24','','','CANCEL')){$script:answers.Enqueue($answer)}
 & ([scriptblock]::Create($code)) | Out-Null
 if($script:changes -ne 0){throw 'Cancel changed settings.'}
 foreach($answer in @('1','STATIC','bad','10.20.30.40','24','','','APPLY')){$script:answers.Enqueue($answer)}
 & ([scriptblock]::Create($code)) | Out-Null
 if($script:changes -ne 2 -or -not(Get-ChildItem $fixture -Filter 'Network-Before-*.json')){throw 'Static configuration or snapshot failed.'}
 foreach($answer in @('1','DHCP','APPLY')){$script:answers.Enqueue($answer)}
 & ([scriptblock]::Create($code)) | Out-Null
 if($script:changes -ne 4){throw 'DHCP did not apply address and DNS.'}
 Write-Output 'PASS: mocked network commands; invalid address reprompt, cancellation, custom static settings, snapshot and DHCP.'
}finally{$env:TTK_REPORT_DIR=$previous}
