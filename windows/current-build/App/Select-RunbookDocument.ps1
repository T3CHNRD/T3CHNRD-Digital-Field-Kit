#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ResultPath)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms

$dialog=New-Object System.Windows.Forms.OpenFileDialog
$dialog.Title='Add document to T3CHNRD Runbook'
$dialog.Filter='Supported documents|*.md;*.txt;*.html;*.htm;*.pdf;*.doc;*.docx;*.rtf|All files|*.*'
$dialog.Multiselect=$true
$dialog.CheckFileExists=$true
$dialog.CheckPathExists=$true
$dialog.RestoreDirectory=$true

try {
    if($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
        $dialog.FileNames | Set-Content -LiteralPath $ResultPath -Encoding Unicode
        exit 0
    }
    if(Test-Path -LiteralPath $ResultPath){Remove-Item -LiteralPath $ResultPath -Force -ErrorAction SilentlyContinue}
    exit 2
}
finally {
    $dialog.Dispose()
}
