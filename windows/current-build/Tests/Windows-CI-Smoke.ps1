#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$Root=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$fail=New-Object 'System.Collections.Generic.List[string]'
function Pass([string]$m){Write-Host "PASS: $m" -ForegroundColor Green}
function Fail([string]$m){Write-Host "FAIL: $m" -ForegroundColor Red;$fail.Add($m)}
function Assert([bool]$ok,[string]$m){if($ok){Pass $m}else{Fail $m}}
$psFiles=@(Get-ChildItem -LiteralPath $Root -Filter *.ps1 -File -Recurse | Where-Object {$_.FullName -notmatch '\\R\\Setup\\'})
foreach($file in $psFiles){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors);if($errors.Count){Fail ("PowerShell parse: {0}: {1}" -f $file.FullName,(($errors|ForEach-Object {$_.Message}) -join ' | '))}}
if(-not $fail.Count){Pass ("PowerShell parser accepted {0} scripts" -f $psFiles.Count)}
$vbs=@('OPEN-ME-GUI.vbs','RUN-PORTABLE.vbs','RUN-RUNNER-DIAGNOSTICS.vbs','INSTALL-T3DFK.vbs','UNINSTALL-T3DFK.vbs','App\RunnerBroker.vbs','App\Runner-Diagnostics.vbs')
foreach($rel in $vbs){$p=Join-Path $Root $rel;if(-not(Test-Path -LiteralPath $p)){Fail "Missing VBS $rel";continue};$proc=Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\cscript.exe') -ArgumentList @('//nologo',('"{0}"' -f $p),'/syntax-only') -Wait -PassThru -WindowStyle Hidden;Assert ($proc.ExitCode -eq 0) "VBScript compiles: $rel"}
$q=Join-Path $env:TEMP ('T3DFK-CI-Broker-'+[guid]::NewGuid().ToString('N'));$r=Join-Path $env:TEMP ('T3DFK-CI-Reports-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $q,$r -Force|Out-Null
$broker=Join-Path $Root 'App\RunnerBroker.vbs';$cscript=Join-Path $env:SystemRoot 'System32\cscript.exe';$bp=Start-Process -FilePath $cscript -ArgumentList @('//nologo',('"{0}"' -f $broker),('"{0}"' -f $q),('"{0}"' -f $Root)) -PassThru -WindowStyle Hidden
$ready=Join-Path $q 'broker.ready';for($i=0;$i -lt 100 -and -not(Test-Path $ready);$i++){Set-Content -LiteralPath (Join-Path $q 'heartbeat.txt') -Value (Get-Date);Start-Sleep -Milliseconds 100};Assert (Test-Path $ready) 'Broker creates broker.ready on Windows'
if(Test-Path $ready){$stamp=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds();$log=Join-Path $r "ci-$stamp.log";$err=Join-Path $r "ci-$stamp.err.log";$done=Join-Path $r "ci-$stamp.done";$started=Join-Path $r "ci-$stamp.started";$launch=Join-Path $r "ci-$stamp.launch-error";$cancel=Join-Path $r "ci-$stamp.cancel";$manifest=Join-Path $r "ci-$stamp.runner.txt";@("ScriptPath=$(Join-Path $Root 'App\Embedded-Runner-SelfTest.ps1')","ToolkitRoot=$Root","ReportDir=$r","LogPath=$log","ErrorPath=$err","DonePath=$done","StartedPath=$started","LaunchErrorPath=$launch","CancelPath=$cancel","Interactive=0")|Set-Content -LiteralPath $manifest -Encoding Unicode;Set-Content -LiteralPath (Join-Path $q "request-ci-$stamp.txt") -Value $manifest -Encoding Unicode;for($i=0;$i -lt 200 -and -not(Test-Path $done);$i++){Set-Content -LiteralPath (Join-Path $q 'heartbeat.txt') -Value (Get-Date);Start-Sleep -Milliseconds 100};Assert (Test-Path $started) 'Embedded runner creates started marker';Assert (Test-Path $done) 'Embedded runner creates completion marker';if(Test-Path $done){Assert ((Get-Content $done -Raw).Trim() -eq '0') 'Embedded runner exits 0'};if(Test-Path $log){Assert ((Get-Content $log -Raw) -match 'PASS: embedded app runner') 'Embedded runner output reaches log'};Assert (-not(Test-Path $launch)) 'No broker launch-error marker'}
Set-Content -LiteralPath (Join-Path $q 'shutdown.txt') -Value shutdown;try{$bp.WaitForExit(5000)|Out-Null}catch{}
if($fail.Count){Write-Host "`nFAILURES: $($fail.Count)" -ForegroundColor Red;$fail|ForEach-Object{Write-Host " - $_"};exit 1};Write-Host "`nALL WINDOWS CI SMOKE TESTS PASSED" -ForegroundColor Green;exit 0
