#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
Temporarily prevents a Windows computer from sleeping and restores its previous settings automatically.

.DESCRIPTION
Portable T3CHNRD Digital Field Kit version. This script has no dependency on a domain,
Lansweeper, a file server, a VPN client, or a corporate UNC path.

It saves rollback state locally under ProgramData\T3DFK\SleepHold and writes reports
to TTK_REPORT_DIR when launched from the Field Kit.

It disables sleep, hibernate timeout, and disk timeout for the active power scheme,
without changing display timeout. By default it also disables scheduled tasks that
clearly invoke shutdown/restart/logoff commands, then restores only those tasks it
changed when the hold expires.

.EXAMPLE
.\Disable-Sleep24.ps1

.EXAMPLE
.\Disable-Sleep24.ps1 -DurationHours 8

.EXAMPLE
.\Disable-Sleep24.ps1 -Rollback
#>
[CmdletBinding()]
param(
 [switch]$Rollback,
 [ValidateRange(0.25,168)][double]$DurationHours=24,
 [switch]$SkipScheduledShutdownTaskDisable,
 [switch]$SkipPendingShutdownAbort
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$StateRoot=Join-Path $env:ProgramData 'T3DFK\SleepHold'
$StateFile=Join-Path $StateRoot 'PreviousPowerSettings.json'
$TaskStateFile=Join-Path $StateRoot 'DisabledScheduledTasks.json'
$RollbackScriptPath=Join-Path $StateRoot 'SleepHold-Rollback.ps1'
$RollbackTaskName='T3DFK Temporary Sleep Hold Rollback'
$ReportRoot=if($env:TTK_REPORT_DIR){$env:TTK_REPORT_DIR}else{Join-Path $StateRoot 'Reports'}
New-Item -ItemType Directory -Path $StateRoot,$ReportRoot -Force | Out-Null
$ReportFile=Join-Path $ReportRoot ("SleepHold_{0}_{1}.txt" -f $env:COMPUTERNAME,(Get-Date -Format 'yyyy-MM-dd_HHmmss'))

function Write-Log([string]$Text){
 $Text | Tee-Object -FilePath $ReportFile -Append
}
function Get-ActiveScheme {
 $o=powercfg /getactivescheme 2>&1
 if($LASTEXITCODE -ne 0){throw "Unable to read active power scheme: $o"}
 if($o -match 'GUID:\s+([a-fA-F0-9-]+)'){return $matches[1]}
 throw 'Unable to parse active power scheme GUID.'
}
function Get-PowerValue([string]$Scheme,[string]$Subgroup,[string]$Setting){
 $o=powercfg /query $Scheme $Subgroup $Setting 2>&1
 if($LASTEXITCODE -ne 0){return [pscustomobject]@{Supported=$false;AC=$null;DC=$null}}
 $ac=$null;$dc=$null
 foreach($line in $o){
  if($line -match 'Current AC Power Setting Index:\s+0x([a-fA-F0-9]+)'){$ac=[Convert]::ToInt64($matches[1],16)}
  if($line -match 'Current DC Power Setting Index:\s+0x([a-fA-F0-9]+)'){$dc=[Convert]::ToInt64($matches[1],16)}
 }
 if($null -eq $ac -or $null -eq $dc){return [pscustomobject]@{Supported=$false;AC=$null;DC=$null}}
 [pscustomobject]@{Supported=$true;AC=[int]($ac/60);DC=[int]($dc/60)}
}
function Set-PowerValue([string]$Scheme,[string]$Subgroup,[string]$Setting,[int]$AC,[int]$DC,[bool]$Required=$true){
 $a=powercfg /setacvalueindex $Scheme $Subgroup $Setting ($AC*60) 2>&1
 if($LASTEXITCODE -ne 0){if($Required){throw "Failed setting AC $($Setting): $a"}else{return}}
 $d=powercfg /setdcvalueindex $Scheme $Subgroup $Setting ($DC*60) 2>&1
 if($LASTEXITCODE -ne 0){if($Required){throw "Failed setting DC $($Setting): $d"}else{return}}
 powercfg /setactive $Scheme | Out-Null
}
function Get-ShutdownTasks {
 @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
  $_.TaskName -ne $RollbackTaskName -and $_.State -ne 'Disabled' -and
  (@($_.Actions | Where-Object {(($_.Execute+' '+$_.Arguments) -match '(?i)shutdown(\.exe)?|Stop-Computer|Restart-Computer|logoff(\.exe)?')}).Count -gt 0)
 })
}
function Save-TaskState($Tasks){
 @($Tasks | ForEach-Object {[pscustomobject]@{TaskName=$_.TaskName;TaskPath=$_.TaskPath}}) |
  ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $TaskStateFile -Encoding UTF8
}
function Restore-Tasks {
 if(-not(Test-Path $TaskStateFile)){return}
 $items=@(Get-Content $TaskStateFile -Raw | ConvertFrom-Json)
 foreach($i in $items){
  try{
   Enable-ScheduledTask -TaskName $i.TaskName -TaskPath $i.TaskPath -ErrorAction Stop | Out-Null
   Write-Log "[PASS] Restored task $($i.TaskPath)$($i.TaskName)"
  }catch{Write-Log "[WARN] Could not restore task $($i.TaskPath)$($i.TaskName): $($_.Exception.Message)"}
 }
 Remove-Item $TaskStateFile -Force -ErrorAction SilentlyContinue
}
function Register-Rollback([datetime]$When){
 Copy-Item -LiteralPath $PSCommandPath -Destination $RollbackScriptPath -Force
 $quoted='"'+$RollbackScriptPath+'"'
 $args='-NoLogo -NoProfile -ExecutionPolicy Bypass -File '+$quoted+' -Rollback'
 $action=New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $args
 $trigger=New-ScheduledTaskTrigger -Once -At $When
 $principal=New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
 $settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
 Register-ScheduledTask -TaskName $RollbackTaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
}

if($Rollback){
 Write-Log "Rollback started: $(Get-Date)"
 if(Test-Path $StateFile){
  $s=Get-Content $StateFile -Raw | ConvertFrom-Json
  if($s.Sleep.Supported){Set-PowerValue $s.Scheme 'SUB_SLEEP' 'STANDBYIDLE' ([int]$s.Sleep.AC) ([int]$s.Sleep.DC)}
  if($s.Hibernate.Supported){Set-PowerValue $s.Scheme 'SUB_SLEEP' 'HIBERNATEIDLE' ([int]$s.Hibernate.AC) ([int]$s.Hibernate.DC) $false}
  if($s.Disk.Supported){Set-PowerValue $s.Scheme 'SUB_DISK' 'DISKIDLE' ([int]$s.Disk.AC) ([int]$s.Disk.DC) $false}
  Remove-Item $StateFile -Force -ErrorAction SilentlyContinue
 }
 Restore-Tasks
 Unregister-ScheduledTask -TaskName $RollbackTaskName -Confirm:$false -ErrorAction SilentlyContinue
 Remove-Item $RollbackScriptPath -Force -ErrorAction SilentlyContinue
 Write-Log '[PASS] Previous power settings restored.'
 exit 0
}

Write-Log "Sleep hold started: $(Get-Date)"
Write-Log "Computer: $env:COMPUTERNAME"
Write-Log "Duration: $DurationHours hours"

$scheme=Get-ActiveScheme
$sleep=Get-PowerValue $scheme 'SUB_SLEEP' 'STANDBYIDLE'
$hibernate=Get-PowerValue $scheme 'SUB_SLEEP' 'HIBERNATEIDLE'
$disk=Get-PowerValue $scheme 'SUB_DISK' 'DISKIDLE'

[pscustomobject]@{Scheme=$scheme;Sleep=$sleep;Hibernate=$hibernate;Disk=$disk;SavedAt=(Get-Date)} |
 ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $StateFile -Encoding UTF8

if(-not $SkipPendingShutdownAbort){
 try{
  $null=shutdown.exe /a 2>&1
  if($LASTEXITCODE -eq 0){Write-Log '[PASS] Pending shutdown timer aborted.'}
  else{Write-Log '[INFO] No pending shutdown timer was active.'}
 }catch{Write-Log "[WARN] Pending shutdown check failed: $($_.Exception.Message)"}
}

if(-not $SkipScheduledShutdownTaskDisable){
 $tasks=Get-ShutdownTasks
 Save-TaskState $tasks
 foreach($t in $tasks){
  try{
   Disable-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction Stop | Out-Null
   Write-Log "[PASS] Disabled task $($t.TaskPath)$($t.TaskName)"
  }catch{Write-Log "[WARN] Could not disable task $($t.TaskPath)$($t.TaskName): $($_.Exception.Message)"}
 }
}

Set-PowerValue $scheme 'SUB_SLEEP' 'STANDBYIDLE' 0 0
Set-PowerValue $scheme 'SUB_SLEEP' 'HIBERNATEIDLE' 0 0 $false
Set-PowerValue $scheme 'SUB_DISK' 'DISKIDLE' 0 0 $false

$rollbackAt=(Get-Date).AddHours($DurationHours)
Register-Rollback $rollbackAt

Write-Log '[PASS] Sleep hold applied.'
Write-Log "Rollback scheduled for: $rollbackAt"
Write-Log "Local state: $StateRoot"
Write-Log "Report: $ReportFile"
Write-Host "[PASS] Sleep hold active until $rollbackAt" -ForegroundColor Green
Write-Host "Report: $ReportFile" -ForegroundColor Cyan
