#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Write-Output 'STARTED: embedded cancel self-test'
for($i=0;$i -lt 120;$i++){ Start-Sleep -Milliseconds 500 }
Write-Output 'ERROR: cancel self-test reached natural completion'
exit 99
