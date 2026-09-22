#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$OutputFile)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$output=[IO.Path]::GetFullPath($OutputFile)
if([IO.Path]::GetExtension($output) -ne '.zip'){throw 'OutputFile must end in .zip.'}
if(Test-Path -LiteralPath $output){throw "Output already exists: $output"}
New-Item -ItemType Directory -Path (Split-Path -Parent $output) -Force | Out-Null
# A short archive name and root avoid the doubled repo-name/SHA paths created
# when Explorer extracts GitHub source archives to their default destination.
& git -C $root archive --format=zip --prefix=FK/ ("--output="+$output) HEAD
if($LASTEXITCODE -ne 0){throw 'git archive failed.'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($output)
try {
    $longest=$zip.Entries | Sort-Object { $_.FullName.Length } -Descending | Select-Object -First 1
    if($longest.FullName.Length -gt 160){throw "Package path exceeds the 160-character budget: $($longest.FullName)"}
    Write-Output ("Created {0}; {1} entries; longest ZIP path {2} characters." -f $output,$zip.Entries.Count,$longest.FullName.Length)
}finally{$zip.Dispose()}
