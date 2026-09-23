#Requires -Version 5.1
# Harmless transport test: no diagnostic, installer, or system-change tools run.
$ErrorActionPreference='Stop'
if (-not ('RunCenterProcess' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'RunCenterProcess.cs') }
$testRoot=Join-Path ([IO.Path]::GetTempPath()) ('Field Kit Runner Test '+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$fixture=Join-Path $testRoot 'prompt fixture.ps1'
@'
param([string]$Label,[switch]$TestSwitch)
Write-Output "ARG=$Label"
Write-Output "SWITCH=$TestSwitch"
Write-Output "ENV=$env:TTK_TOOLKIT_ROOT"
$reply=Read-Host 'Enter test input'
Write-Output "INPUT=$reply"
[Console]::Error.WriteLine('EXPECTED_STDERR')
exit 7
'@ | Set-Content -LiteralPath $fixture -Encoding UTF8
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$argumentJson=ConvertTo-Json -InputObject @('-Label','argument with spaces', '-TestSwitch') -Compress
$encodedArguments=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($argumentJson))
$info.Arguments='-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "'+(Join-Path $PSScriptRoot 'Invoke-RunCenterScript.ps1')+'" -TargetScript "'+$fixture+'" -ArgumentsBase64 '+$encodedArguments
$info.UseShellExecute=$false
$info.CreateNoWindow=$true
$info.RedirectStandardOutput=$true
$info.RedirectStandardError=$true
$info.RedirectStandardInput=$true
$info.EnvironmentVariables['TTK_TOOLKIT_ROOT']=$testRoot
$capture=New-Object RunCenterProcess($info)
try {
    $capture.Start()
    $text='';$chunk='';$sent=$false
    $deadline=[DateTime]::UtcNow.AddSeconds(20)
    while([DateTime]::UtcNow -lt $deadline){
        while($capture.Output.TryDequeue([ref]$chunk)){$text+=$chunk}
        if(-not $sent -and $text.Contains('Enter test input')){
            $bytes=[Text.Encoding]::UTF8.GetBytes("hello from Run Center`r`n")
            $capture.Process.StandardInput.BaseStream.Write($bytes,0,$bytes.Length)
            $capture.Process.StandardInput.BaseStream.Flush()
            $sent=$true
        }
        if($capture.Finished -and $capture.Output.IsEmpty){break}
        Start-Sleep -Milliseconds 25
    }
    if(-not $capture.Finished){throw "Timed out waiting for prompt/input/exit. Captured: $text"}
    foreach($expected in @('ARG=argument with spaces','SWITCH=True',"ENV=$testRoot",'Enter test input','INPUT=hello from Run Center','EXPECTED_STDERR')){
        if(-not $text.Contains($expected)){throw "Missing captured text: $expected; received: $text"}
    }
    if($capture.Process.ExitCode -ne 7){throw 'Exit code was not preserved.'}
    Write-Output 'PASS: hidden process, spaced path/argument, environment, live prompt, stdin, stdout, stderr, and exit code.'
    $capture.Dispose()
    @'
$child=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList '-NoProfile -Command "Start-Sleep -Seconds 60"' -WindowStyle Hidden -PassThru
Write-Output "CHILD=$($child.Id)"
Start-Sleep -Seconds 60
'@ | Set-Content -LiteralPath $fixture -Encoding UTF8
    $capture=New-Object RunCenterProcess($info)
    $capture.Start()
    $text='';$childId=0;$deadline=[DateTime]::UtcNow.AddSeconds(15)
    while([DateTime]::UtcNow -lt $deadline){
        while($capture.Output.TryDequeue([ref]$chunk)){$text+=$chunk}
        if($text -match 'CHILD=(\d+)[\r\n]'){$childId=[int]$matches[1];break}
        Start-Sleep -Milliseconds 25
    }
    if(-not $childId){throw 'Cancellation fixture did not start its child.'}
    & taskkill.exe /PID $capture.Process.Id /T /F | Out-Null
    if($LASTEXITCODE -ne 0){throw 'Process-tree cancellation failed.'}
    $deadline=[DateTime]::UtcNow.AddSeconds(10)
    do {
        $childProcess=Get-Process -Id $childId -ErrorAction SilentlyContinue
        $childRunning=$childProcess -and -not $childProcess.HasExited
        if($capture.Finished -and -not $childRunning){break}
        Start-Sleep -Milliseconds 25
    } while([DateTime]::UtcNow -lt $deadline)
    if(-not $capture.Finished -or $childRunning) {throw 'Cancellation left a fixture process running.'}
    Write-Output 'PASS: process-tree cancellation terminates the tool and its child.'
} finally {
    if(-not $capture.Process.HasExited){& taskkill.exe /PID $capture.Process.Id /T /F | Out-Null}
    $capture.Dispose()
    # Only remove the two exact fixture paths this test created.
    Remove-Item -LiteralPath $fixture -Force
    Remove-Item -LiteralPath $testRoot -Force
}
