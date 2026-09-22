#Requires -Version 5.1
$ErrorActionPreference='Stop'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testRoot=Join-Path ([IO.Path]::GetTempPath()) ("FK launch test 'quoted' "+[guid]::NewGuid().ToString('N'))
$app=Join-Path $testRoot 'Windows\App'
New-Item -ItemType Directory -Path $app -Force | Out-Null
$launcher=Join-Path $testRoot 'T3CHNRD Digital Field Kit.vbs'
Copy-Item -LiteralPath (Join-Path $root 'T3CHNRD Digital Field Kit.vbs') -Destination $launcher
$source=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'T3DFK-Windows.ps1') -Raw
# Run the real startup preamble, stopping before elevation or any tool/UI action.
$preamble=$source.Substring(0,$source.IndexOf('$identity='))
$assertions=@'
if(-not $PSScriptRoot){throw 'Launcher lost script file scope.'}
if(-not $PSCommandPath){throw 'Launcher lost script file identity.'}
if(-not ('RunCenterProcess' -as [type])){throw 'Runner helper was not loaded.'}
if(-not(Test-Path -LiteralPath (Join-Path $appDirectory 'Invoke-RunCenterScript.ps1'))){throw 'Runner host path is invalid.'}
[IO.File]::WriteAllText((Join-Path $ToolkitRoot 'startup-pass.txt'),'PASS')
'@
[IO.File]::WriteAllText((Join-Path $app 'T3DFK-Windows.ps1'),$preamble+$assertions,[Text.Encoding]::UTF8)
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'RunCenterProcess.cs'),(Join-Path $PSScriptRoot 'Invoke-RunCenterScript.ps1') -Destination $app
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName=Join-Path $env:SystemRoot 'System32\cscript.exe'
$info.Arguments='//nologo "'+$launcher+'"'
$info.UseShellExecute=$false
$info.CreateNoWindow=$true
$info.EnvironmentVariables['LOCALAPPDATA']=$testRoot
$process=[Diagnostics.Process]::Start($info)
try {
    if(-not $process.WaitForExit(20000)){throw 'VBS launcher did not finish within 20 seconds.'}
    if($process.ExitCode -ne 0 -or -not(Test-Path -LiteralPath (Join-Path $testRoot 'startup-pass.txt'))){throw 'VBS startup failed.'}
    Write-Output 'PASS: actual VBS launcher loads startup and runner paths from a folder containing spaces and apostrophes.'
}finally{
    if(-not $process.HasExited){& taskkill.exe /PID $process.Id /T /F | Out-Null}
    $process.Dispose()
    $resolved=[IO.Path]::GetFullPath($testRoot)
    $tempPrefix=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    if(-not $resolved.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Unexpected fixture cleanup path.'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
