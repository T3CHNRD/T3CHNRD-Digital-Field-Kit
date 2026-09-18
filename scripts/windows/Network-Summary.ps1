$ErrorActionPreference='Continue'
Write-Output '=== NETWORK ADAPTERS ==='
Get-NetIPConfiguration | Format-List | Out-String | Write-Output
Write-Output '=== ROUTES ==='
route.exe print | Out-String | Write-Output
