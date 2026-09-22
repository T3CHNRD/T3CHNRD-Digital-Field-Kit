#Requires -Version 5.1
[CmdletBinding()]
param([switch]$InventoryOnly)
$ErrorActionPreference='Stop'
$reportRoot=$env:TTK_REPORT_DIR
if(-not $reportRoot){$reportRoot=Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'Diagnostic-Reports'}
$folder=Join-Path $reportRoot ('Antivirus-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+$PID)
New-Item -ItemType Directory -Path $folder -Force | Out-Null
$record=[ordered]@{SchemaVersion=1;Computer=$env:COMPUTERNAME;Started=(Get-Date).ToString('o');Finished=$null;InventoryStatus='Unknown';InventoryError=$null;Products=@();Defender=$null;Result='NotStarted';Error=$null;ProtectionChanged=$false}
$transcribing=$false
try{
 Start-Transcript -Path (Join-Path $folder 'Antivirus-Run.txt') -Force | Out-Null
 $transcribing=$true
 Write-Output "Antivirus evidence folder: $folder"
 try{
  $record.Products=@(Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop | Select-Object displayName,productState,pathToSignedProductExe,pathToSignedReportingExe)
  $record.InventoryStatus='Available'
  if($record.Products.Count){foreach($product in $record.Products){Write-Output ('Registered antivirus: '+$product.displayName)}}
  else{Write-Output 'Windows Security Center returned no registered antivirus products. This does not establish that no protection is installed.'}
 }catch{
  $record.InventoryStatus='Unavailable';$record.InventoryError=$_.Exception.Message
  Write-Output 'Antivirus registration could not be queried. Security Center inventory may be unavailable on Windows Server or restricted systems.'
 }
 if(Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue){
  try{$record.Defender=Get-MpComputerStatus -ErrorAction Stop | Select-Object AMRunningMode,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureVersion,QuickScanStartTime,QuickScanEndTime}
  catch{Write-Output ('Defender status unavailable: '+$_.Exception.Message)}
 }
 if($record.Defender){Write-Output ('Defender mode: '+$record.Defender.AMRunningMode+'; AntivirusEnabled: '+$record.Defender.AntivirusEnabled)}
 if($InventoryOnly){$record.Result='InventoryOnly';return}
 if(-not $record.Defender -or -not $record.Defender.AntivirusEnabled -or -not(Get-Command Start-MpScan -ErrorAction SilentlyContinue)){
  $record.Result='Skipped'
  Write-Output 'SCAN SKIPPED: Defender scanning is not available or active. Use the installed antivirus product listed above (or verify it in Windows Security). No antivirus was disabled.'
  Write-Output 'Export the installed product scan results into this evidence folder for later AI review. Its scanner has not been run by Field Kit.'
  return
 }
 $record.Result='Running'
 $global:LASTEXITCODE=0
 & (Join-Path (Split-Path -Parent $PSScriptRoot) 'Invoke-DefenderQuickScan.ps1')
 $record.Result=if($LASTEXITCODE -eq 0){'DefenderWorkflowCompleted'}else{'Failed'}
 if($record.Result -eq 'Failed'){throw "Defender workflow exited with code $LASTEXITCODE"}
}catch{
 $record.Result='Failed';$record.Error=$_.Exception.Message
 Write-Error $_
}finally{
 $record.Finished=(Get-Date).ToString('o')
 $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $folder 'Antivirus-Status.json') -Encoding UTF8
 Write-Output ('Result: '+$record.Result)
 Write-Output "Evidence saved: $folder"
 if($transcribing){Stop-Transcript | Out-Null}
}
