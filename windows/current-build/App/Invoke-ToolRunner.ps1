#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertFrom-RunnerManifest {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Runner manifest not found: $Path"
    }

    $argsList = New-Object 'System.Collections.Generic.List[string]'
    $data = [ordered]@{
        ScriptPath  = $null
        ToolkitRoot = $null
        ReportDir   = $null
        LogPath     = $null
        ErrorPath   = $null
        Args        = $argsList
    }

    foreach ($line in Get-Content -LiteralPath $Path -ErrorAction Stop) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $idx = $line.IndexOf('=')
        if ($idx -lt 1) { continue }

        $key = $line.Substring(0, $idx)
        $value = $line.Substring($idx + 1)

        switch ($key) {
            'ScriptPath'  { $data.ScriptPath  = $value }
            'ToolkitRoot' { $data.ToolkitRoot = $value }
            'ReportDir'   { $data.ReportDir   = $value }
            'LogPath'     { $data.LogPath     = $value }
            'ErrorPath'   { $data.ErrorPath   = $value }
            'Arg'         { $data.Args.Add($value) }
        }
    }

    return [pscustomobject]$data
}

function ConvertTo-SingleQuotedPowerShellLiteral {
    param([AllowNull()][string]$Text)
    if ($null -eq $Text) { return "''" }
    return "'" + $Text.Replace("'", "''") + "'"
}

function Resolve-64BitWindowsPowerShell {
    $windows = $env:WINDIR

    if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
        $sysnative = Join-Path $windows 'Sysnative\WindowsPowerShell\v1.0\powershell.exe'
        if (Test-Path -LiteralPath $sysnative -PathType Leaf) { return $sysnative }
    }

    $system32 = Join-Path $windows 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if (Test-Path -LiteralPath $system32 -PathType Leaf) { return $system32 }

    return 'powershell.exe'
}

$manifest = ConvertFrom-RunnerManifest -Path $ManifestPath

foreach ($required in 'ScriptPath','ToolkitRoot','ReportDir','LogPath','ErrorPath') {
    if ([string]::IsNullOrWhiteSpace([string]$manifest.$required)) {
        throw "Runner manifest is missing required value: $required"
    }
}

if (-not (Test-Path -LiteralPath $manifest.ScriptPath -PathType Leaf)) {
    throw "Tool script not found: $($manifest.ScriptPath)"
}

if (-not (Test-Path -LiteralPath $manifest.ToolkitRoot -PathType Container)) {
    throw "Toolkit root not found: $($manifest.ToolkitRoot)"
}

New-Item -Path $manifest.ReportDir -ItemType Directory -Force | Out-Null
Set-Content -LiteralPath $manifest.LogPath -Value '' -Encoding Unicode
Set-Content -LiteralPath $manifest.ErrorPath -Value '' -Encoding Unicode

$scriptLiteral = ConvertTo-SingleQuotedPowerShellLiteral $manifest.ScriptPath
$rootLiteral   = ConvertTo-SingleQuotedPowerShellLiteral $manifest.ToolkitRoot
$reportLiteral = ConvertTo-SingleQuotedPowerShellLiteral $manifest.ReportDir
$logLiteral    = ConvertTo-SingleQuotedPowerShellLiteral $manifest.LogPath
$errLiteral    = ConvertTo-SingleQuotedPowerShellLiteral $manifest.ErrorPath

$argTokens = New-Object 'System.Collections.Generic.List[string]'
foreach ($arg in $manifest.Args) {
    if ($arg -match '^-[A-Za-z][A-Za-z0-9_-]*$') {
        $argTokens.Add($arg)
    }
    else {
        $argTokens.Add((ConvertTo-SingleQuotedPowerShellLiteral $arg))
    }
}
$argumentText = $argTokens -join ' '

$childCommand = @"
Set-Location -LiteralPath $rootLiteral
`$env:TTK_TOOLKIT_ROOT = $rootLiteral
`$env:TTK_REPORT_DIR = $reportLiteral
`$ProgressPreference = 'Continue'
try {
    & $scriptLiteral $argumentText *>&1 |
        Out-String -Stream -Width 4096 |
        ForEach-Object {
            `$_ | Out-File -LiteralPath $logLiteral -Append -Encoding Unicode
        }
    exit 0
}
catch {
    (`$_ | Out-String -Width 4096) | Out-File -LiteralPath $errLiteral -Append -Encoding Unicode
    exit 1
}
"@

$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childCommand))
$powerShell = Resolve-64BitWindowsPowerShell

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $powerShell
$psi.Arguments = "-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -EncodedCommand $encoded"
$psi.WorkingDirectory = $manifest.ToolkitRoot
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden

$process = New-Object System.Diagnostics.Process
$process.StartInfo = $psi

try {
    if (-not $process.Start()) {
        throw 'Windows PowerShell child process did not start.'
    }
    $process.WaitForExit()
    exit [int]$process.ExitCode
}
catch {
    try {
        $_ | Out-String -Width 4096 | Out-File -LiteralPath $manifest.ErrorPath -Append -Encoding Unicode
    }
    catch {}
    exit 1
}
finally {
    if ($process) { $process.Dispose() }
}
