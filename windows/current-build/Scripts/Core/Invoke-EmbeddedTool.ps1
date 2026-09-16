#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ScriptPath,
    [Parameter(Mandatory=$true)][string]$ReportDir,
    [string[]]$ToolArgs = @()
)
$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath $ScriptPath -PathType Leaf)){throw "Tool script not found: $ScriptPath"}
New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null
$env:TTK_REPORT_DIR=$ReportDir
$env:TTK_TOOLKIT_ROOT=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
& $ScriptPath @ToolArgs
exit $LASTEXITCODE
