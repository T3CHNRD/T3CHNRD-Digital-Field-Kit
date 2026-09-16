#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ManifestPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-RunnerManifest {
    param([Parameter(Mandatory=$true)][string]$Path)
    if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ throw "Runner manifest not found: $Path" }
    $argsList = New-Object 'System.Collections.Generic.List[string]'
    $data=[ordered]@{
        ScriptPath=$null; ToolkitRoot=$null; ReportDir=$null;
        LogPath=$null; ErrorPath=$null; DonePath=$null; StartedPath=$null;
        Args=$argsList
    }
    foreach($line in Get-Content -LiteralPath $Path -ErrorAction Stop){
        if([string]::IsNullOrWhiteSpace($line)){continue}
        $idx=$line.IndexOf('='); if($idx -lt 1){continue}
        $key=$line.Substring(0,$idx); $value=$line.Substring($idx+1)
        switch($key){
            'ScriptPath' {$data.ScriptPath=$value}
            'ToolkitRoot' {$data.ToolkitRoot=$value}
            'ReportDir' {$data.ReportDir=$value}
            'LogPath' {$data.LogPath=$value}
            'ErrorPath' {$data.ErrorPath=$value}
            'DonePath' {$data.DonePath=$value}
            'StartedPath' {$data.StartedPath=$value}
            'Arg' {[void]$data.Args.Add($value)}
        }
    }
    [pscustomobject]$data
}

function Resolve-WindowsPowerShell {
    $win=$env:WINDIR
    if([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess){
        $p=Join-Path $win 'Sysnative\WindowsPowerShell\v1.0\powershell.exe'
        if(Test-Path -LiteralPath $p -PathType Leaf){return $p}
    }
    $p=Join-Path $win 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if(Test-Path -LiteralPath $p -PathType Leaf){return $p}
    'powershell.exe'
}

function ConvertTo-PsLiteral {
    param([AllowNull()][string]$Text)
    if($null -eq $Text){return "''"}
    "'" + $Text.Replace("'","''") + "'"
}

$m=$null
$exitCode=1
try {
    $m=Read-RunnerManifest -Path $ManifestPath
    foreach($name in 'ScriptPath','ToolkitRoot','ReportDir','LogPath','ErrorPath','DonePath','StartedPath'){
        if([string]::IsNullOrWhiteSpace([string]$m.$name)){throw "Runner manifest missing: $name"}
    }
    if(-not (Test-Path -LiteralPath $m.ScriptPath -PathType Leaf)){throw "Tool script not found: $($m.ScriptPath)"}
    if(-not (Test-Path -LiteralPath $m.ToolkitRoot -PathType Container)){throw "Toolkit root not found: $($m.ToolkitRoot)"}

    New-Item -Path $m.ReportDir -ItemType Directory -Force | Out-Null
    Set-Content -LiteralPath $m.LogPath -Value ("Runner host started: {0}`r`nTool: {1}`r`n" -f (Get-Date),$m.ScriptPath) -Encoding Unicode
    Set-Content -LiteralPath $m.ErrorPath -Value '' -Encoding Unicode

    # Child inherits these variables. Existing diagnostic scripts are untouched.
    $env:TTK_TOOLKIT_ROOT=$m.ToolkitRoot
    $env:TTK_REPORT_DIR=$m.ReportDir

    $scriptLiteral=ConvertTo-PsLiteral $m.ScriptPath
    $argTokens=New-Object 'System.Collections.Generic.List[string]'
    foreach($a in $m.Args){
        if($a -match '^-[A-Za-z][A-Za-z0-9_-]*$'){
            [void]$argTokens.Add($a)
        } else {
            [void]$argTokens.Add((ConvertTo-PsLiteral $a))
        }
    }
    $argText=$argTokens -join ' '

    # *>&1 merges all PowerShell streams (including Information/Write-Host in PS5+)
    # into the child process stdout. The parent redirects that stdout to the live log.
    # If a target script calls exit, only the child exits; the parent still writes DonePath.
    $childCommand = @"
Set-Location -LiteralPath $(ConvertTo-PsLiteral $m.ToolkitRoot)
`$env:TTK_TOOLKIT_ROOT = $(ConvertTo-PsLiteral $m.ToolkitRoot)
`$env:TTK_REPORT_DIR = $(ConvertTo-PsLiteral $m.ReportDir)
`$ProgressPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::Unicode
`$OutputEncoding = [Text.Encoding]::Unicode
& $scriptLiteral $argText *>&1
if(-not `$?){ exit 1 }
exit 0
"@
    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childCommand))
    $ps=Resolve-WindowsPowerShell
    $args="-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -EncodedCommand $encoded"

    # Start-Process redirection writes continuously to disk while the child is running.
    $p=Start-Process -FilePath $ps -ArgumentList $args -WorkingDirectory $m.ToolkitRoot `
        -RedirectStandardOutput $m.LogPath -RedirectStandardError $m.ErrorPath `
        -WindowStyle Hidden -PassThru -ErrorAction Stop
    Set-Content -LiteralPath $m.StartedPath -Value ([string]$p.Id) -Encoding ASCII

    while(-not $p.HasExited){ Start-Sleep -Milliseconds 200; $p.Refresh() }
    $exitCode=[int]$p.ExitCode
    $p.Dispose()
}
catch {
    try{($_ | Out-String -Width 4096) | Add-Content -LiteralPath $m.ErrorPath -Encoding Unicode}catch{}
    $exitCode=1
}
finally {
    try{if($m -and $m.DonePath){Set-Content -LiteralPath $m.DonePath -Value ([string]$exitCode) -Encoding ASCII}}catch{}
}
exit $exitCode
