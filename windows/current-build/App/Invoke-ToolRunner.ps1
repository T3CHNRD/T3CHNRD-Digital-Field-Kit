#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ManifestPath)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Read-RunnerManifest {
    param([string]$Path)
    if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ throw "Runner manifest not found: $Path" }
    $argsList = New-Object 'System.Collections.Generic.List[string]'
    $data=[ordered]@{
        ScriptPath=$null;ToolkitRoot=$null;ReportDir=$null;LogPath=$null;ErrorPath=$null
        DonePath=$null;StartedPath=$null;LaunchErrorPath=$null;CancelPath=$null;Interactive=$false;Args=$argsList
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
            'LaunchErrorPath' {$data.LaunchErrorPath=$value}
            'CancelPath' {$data.CancelPath=$value}
            'Interactive' {$data.Interactive=($value -eq '1' -or $value -eq 'true')}
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
$child=$null
try {
    $m=Read-RunnerManifest -Path $ManifestPath
    foreach($name in 'ScriptPath','ToolkitRoot','ReportDir','LogPath','ErrorPath','DonePath','StartedPath'){
        if([string]::IsNullOrWhiteSpace([string]$m.$name)){throw "Runner manifest missing: $name"}
    }
    if(-not (Test-Path -LiteralPath $m.ScriptPath -PathType Leaf)){throw "Tool script not found: $($m.ScriptPath)"}
    New-Item -Path $m.ReportDir -ItemType Directory -Force | Out-Null
    Set-Content -LiteralPath $m.LogPath -Value ("Runner started: {0}`r`nScript: {1}`r`n" -f (Get-Date),$m.ScriptPath) -Encoding Unicode
    Set-Content -LiteralPath $m.ErrorPath -Value '' -Encoding Unicode

    if($m.CancelPath -and (Test-Path -LiteralPath $m.CancelPath -PathType Leaf)){
        $exitCode=1223
        throw [System.OperationCanceledException]::new('Tool launch cancelled before child process start.')
    }

    $psi=New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName=Resolve-WindowsPowerShell

    # Use an encoded PowerShell command instead of powershell.exe -File. The field
    # diagnostic proved that powershell.exe -Command starts correctly on the target
    # machine while -File returns exit code 1 before the broker can become ready.
    # This still invokes the original .ps1 by path, so normal PowerShell policy and
    # script errors remain visible; it does not replace or rewrite the tool script.
    function ConvertTo-PsLiteral {
        param([AllowNull()][string]$Text)
        if($null -eq $Text){ return "''" }
        return "'" + $Text.Replace("'","''") + "'"
    }
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
    $toolCommand="& $scriptLiteral $argText *>&1"
    $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($toolCommand))
    $psi.Arguments="-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -EncodedCommand $encoded"
    $psi.WorkingDirectory=$m.ToolkitRoot
    $env:TTK_TOOLKIT_ROOT=$m.ToolkitRoot
    $env:TTK_REPORT_DIR=$m.ReportDir

    if($m.Interactive){
        $psi.UseShellExecute=$true
        $psi.CreateNoWindow=$false
        $psi.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Normal
        Add-Content -LiteralPath $m.LogPath -Value 'Interactive tool window opened.' -Encoding Unicode
    }
    else {
        $psi.UseShellExecute=$false
        $psi.CreateNoWindow=$true
        $psi.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Hidden
        $psi.RedirectStandardOutput=$true
        $psi.RedirectStandardError=$true
        $psi.EnvironmentVariables['TTK_TOOLKIT_ROOT']=$m.ToolkitRoot
        $psi.EnvironmentVariables['TTK_REPORT_DIR']=$m.ReportDir
    }

    $child=New-Object System.Diagnostics.Process
    $child.StartInfo=$psi
    if(-not $child.Start()){throw 'PowerShell child process did not start.'}
    Set-Content -LiteralPath $m.StartedPath -Value ([string]$child.Id) -Encoding ASCII

    $outTask=$null
    $errTask=$null
    if(-not $m.Interactive){
        $outTask=$child.StandardOutput.ReadToEndAsync()
        $errTask=$child.StandardError.ReadToEndAsync()
    }

    $cancelled=$false
    while(-not $child.WaitForExit(250)){
        if($m.CancelPath -and (Test-Path -LiteralPath $m.CancelPath -PathType Leaf)){
            $cancelled=$true
            try{
                $taskkill=Join-Path $env:WINDIR 'System32\taskkill.exe'
                if(-not(Test-Path -LiteralPath $taskkill -PathType Leaf)){$taskkill='taskkill.exe'}
                Start-Process -FilePath $taskkill -ArgumentList @('/PID',[string]$child.Id,'/T','/F') -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue | Out-Null
            }catch{
                try{$child.Kill()}catch{}
            }
            break
        }
    }
    try{if(-not $child.HasExited){$child.WaitForExit()}}catch{}

    if(-not $m.Interactive){
        try{$stdout=$outTask.Result}catch{$stdout=''}
        try{$stderr=$errTask.Result}catch{$stderr=''}
        if($stdout){Add-Content -LiteralPath $m.LogPath -Value $stdout -Encoding Unicode}
        if($stderr){Add-Content -LiteralPath $m.ErrorPath -Value $stderr -Encoding Unicode}
    }
    if($cancelled){$exitCode=1223}else{$exitCode=[int]$child.ExitCode}
}
catch {
    if($_.Exception -is [System.OperationCanceledException]){
        $exitCode=1223
    } else {
        try{if($m -and $m.ErrorPath){Add-Content -LiteralPath $m.ErrorPath -Value ($_ | Out-String -Width 4096) -Encoding Unicode}}catch{}
        $exitCode=1
    }
}
finally {
    try{if($child){$child.Dispose()}}catch{}
    try{if($m -and $m.DonePath){Set-Content -LiteralPath $m.DonePath -Value ([string]$exitCode) -Encoding ASCII}}catch{}
}
exit $exitCode
