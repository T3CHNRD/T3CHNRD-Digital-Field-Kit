#Requires -Version 5.1
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('T3DFK-MACE-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture|Out-Null
$child=Join-Path $fixture 'removable.tmp'
Set-Content -LiteralPath $child -Value 'fixture'
$process=$null
try{
    $info=New-Object Diagnostics.ProcessStartInfo
    $info.FileName=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $script=Join-Path $root 'Windows\Scripts\Maintenance\Invoke-MaceCleanup-FieldKit.ps1'
    $info.Arguments='-NoLogo -NoProfile -ExecutionPolicy Bypass -File "'+$script+'" -CleanupTarget "'+$fixture+'" -SkipRecycleBin'
    $info.UseShellExecute=$false
    $info.CreateNoWindow=$true
    $info.RedirectStandardOutput=$true
    $info.RedirectStandardError=$true
    $process=[Diagnostics.Process]::Start($info)
    $stdout=$process.StandardOutput.ReadToEnd()
    $stderr=$process.StandardError.ReadToEnd()
    if(-not $process.WaitForExit(20000)){throw 'MACE cleanup fixture timed out.'}
    if($process.ExitCode -ne 0){throw "MACE cleanup fixture failed: $stderr`n$stdout"}
    if(Test-Path -LiteralPath $child){throw 'MACE cleanup did not remove the fixture file.'}
    if($stdout -notmatch 'Cleanup summary: Completed=1; Skipped=0; Failed=0'){throw "Unexpected MACE summary: $stdout"}
    if($stdout -match 'property .FullName. cannot be found'){throw 'The prior FullName error regressed.'}
    Write-Output 'PASS: MACE removes a disposable temp fixture, reports counts, and avoids the FullName error.'
}finally{
    if($process){$process.Dispose()}
    if(Test-Path -LiteralPath $fixture){Remove-Item -LiteralPath $fixture -Recurse -Force}
}