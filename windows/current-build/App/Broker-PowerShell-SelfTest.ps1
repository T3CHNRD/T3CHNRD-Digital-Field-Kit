#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ReadyPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
[IO.File]::WriteAllText($ReadyPath,(Get-Date).ToString('o'),[Text.Encoding]::ASCII)
exit 0
