#Requires -Version 5.1
param([Parameter(Mandatory=$true)][string]$InstallRoot)
$ErrorActionPreference='SilentlyContinue';$root=[IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
Remove-Item (Join-Path([Environment]::GetFolderPath('Programs'))'T3CHNRD Digital Field Kit') -Recurse -Force
Remove-Item (Join-Path([Environment]::GetFolderPath('Desktop'))'T3CHNRD Digital Field Kit.lnk') -Force
Remove-Item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\T3CHNRDDigitalFieldKit' -Recurse -Force
Start-Process $env:ComSpec -ArgumentList '/c',('timeout /t 2 /nobreak >nul & rmdir /s /q "'+$root+'"') -WindowStyle Hidden
