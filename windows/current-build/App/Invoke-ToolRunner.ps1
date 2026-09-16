#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ManifestPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-RunnerManifest {
    param([string]$Path)
    if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ throw "Runner manifest not found: $Path" }
    $argsList = New-Object 'System.Collections.Generic.List[string]'
    $data=[ordered]@{ScriptPath=$null;ToolkitRoot=$null;ReportDir=$null;LogPath=$null;ErrorPath=$null;DonePath=$null;StartedPath=$null;Args=$argsList}
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
            'Arg' {$data.Args.Add($value)}
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

function Quote-ProcessArgument {
    param([AllowEmptyString()][string]$Value)
    '"' + ($Value -replace '"','\"') + '"'
}

$m=$null
$exitCode=1
try {
    $m=Read-RunnerManifest -Path $ManifestPath
    foreach($name in 'ScriptPath','ToolkitRoot','ReportDir','LogPath','ErrorPath','DonePath','StartedPath'){
        if([string]::IsNullOrWhiteSpace([string]$m.$name)){throw "Runner manifest missing: $name"}
    }
    if(-not (Test-Path -LiteralPath $m.ScriptPath -PathType Leaf)){throw "Tool script not found: $($m.ScriptPath)"}
    New-Item -Path $m.ReportDir -ItemType Directory -Force | Out-Null
    Set-Content -LiteralPath $m.LogPath -Value ("Runner started: {0}`r`nScript: {1}`r`n" -f (Get-Date),$m.ScriptPath) -Encoding Unicode
    Set-Content -LiteralPath $m.ErrorPath -Value '' -Encoding Unicode
    Set-Content -LiteralPath $m.StartedPath -Value (Get-Date).ToString('o') -Encoding ASCII

    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName=Resolve-WindowsPowerShell
    $argList=New-Object 'System.Collections.Generic.List[string]'
    foreach($a in @('-NoLogo','-NoProfile','-STA','-ExecutionPolicy','Bypass','-File',$m.ScriptPath)){[void]$argList.Add((Quote-ProcessArgument $a))}
    foreach($a in $m.Args){[void]$argList.Add((Quote-ProcessArgument $a))}
    $psi.Arguments=($argList -join ' ')
    $psi.WorkingDirectory=$m.ToolkitRoot
    $psi.UseShellExecute=$false
    $psi.CreateNoWindow=$true
    $psi.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Hidden
    $psi.RedirectStandardOutput=$true
    $psi.RedirectStandardError=$true
    $psi.EnvironmentVariables['TTK_TOOLKIT_ROOT']=$m.ToolkitRoot
    $psi.EnvironmentVariables['TTK_REPORT_DIR']=$m.ReportDir

    $p=New-Object System.Diagnostics.Process
    $p.StartInfo=$psi
    if(-not $p.Start()){throw 'PowerShell child process did not start.'}

    $outTask=$p.StandardOutput.ReadToEndAsync()
    $errTask=$p.StandardError.ReadToEndAsync()
    $p.WaitForExit()
    $stdout=$outTask.Result
    $stderr=$errTask.Result
    if($stdout){Add-Content -LiteralPath $m.LogPath -Value $stdout -Encoding Unicode}
    if($stderr){Add-Content -LiteralPath $m.ErrorPath -Value $stderr -Encoding Unicode}
    $exitCode=[int]$p.ExitCode
    $p.Dispose()
}
catch {
    try{Add-Content -LiteralPath $m.ErrorPath -Value ($_ | Out-String -Width 4096) -Encoding Unicode}catch{}
    $exitCode=1
}
finally {
    try{if($m -and $m.DonePath){Set-Content -LiteralPath $m.DonePath -Value ([string]$exitCode) -Encoding ASCII}}catch{}
}
exit $exitCode
