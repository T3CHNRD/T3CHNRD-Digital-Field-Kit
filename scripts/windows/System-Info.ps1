$ErrorActionPreference='Continue'
Write-Output '=== SYSTEM INFORMATION ==='
Get-ComputerInfo | Select-Object CsName,WindowsProductName,WindowsVersion,OsBuildNumber,CsManufacturer,CsModel,CsTotalPhysicalMemory | Format-List | Out-String | Write-Output
