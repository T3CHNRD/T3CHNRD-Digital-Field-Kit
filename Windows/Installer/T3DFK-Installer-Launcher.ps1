#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms

$commandPath=[Environment]::GetCommandLineArgs()[0]
$sourceRoot=Split-Path -Parent ([IO.Path]::GetFullPath($commandPath))
$installer=Join-Path $sourceRoot 'Windows\Installer\Install-Windows.ps1'

try{
    if(-not(Test-Path -LiteralPath $installer -PathType Leaf)){
        throw "Installer source is missing: $installer"
    }
    . $installer -SourceRoot $sourceRoot
}catch{
    [Windows.Forms.MessageBox]::Show($_.Exception.Message,'T3CHNRD Digital Field Kit installer','OK','Error')|Out-Null
    exit 1
}