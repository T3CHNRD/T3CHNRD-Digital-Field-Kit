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
function Wait-File([string]$Path,[int]$Seconds=10){$sw=[Diagnostics.Stopwatch]::StartNew();while($sw.Elapsed.TotalSeconds -lt $Seconds){if(Test-Path -LiteralPath $Path){return $true};Start-Sleep -Milliseconds 100};return $false}

Write-Host '=== POWERSHELL PARSE ==='
$scanRoots=@('App','Installer','Scripts','Tests')
$psFiles=@()
foreach($rel in $scanRoots){$p=Join-Path $Root $rel;if(Test-Path $p){$psFiles+=Get-ChildItem -LiteralPath $p -Filter *.ps1 -File -Recurse}}
foreach($file in $psFiles){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors);if($errors.Count){Fail ("PowerShell parse: {0}: {1}" -f $file.FullName,(($errors|ForEach-Object{$_.Message}) -join ' | '))}}
if(-not($fail|Where-Object{$_ -like 'PowerShell parse:*'})){Pass ("PowerShell parser accepted {0} scripts" -f $psFiles.Count)}

Write-Host '=== VBSCRIPT COMPILE ==='
$vbs=@('OPEN-ME-GUI.vbs','RUN-PORTABLE.vbs','RUN-RUNNER-DIAGNOSTICS.vbs','INSTALL-T3DFK.vbs','UNINSTALL-T3DFK.vbs','App\RunnerBroker.vbs','App\Runner-Diagnostics.vbs')
$cscript=Join-Path $env:SystemRoot 'System32\cscript.exe'
foreach($rel in $vbs){$p=Join-Path $Root $rel;if(-not(Test-Path -LiteralPath $p)){Fail "Missing VBS $rel";continue};$proc=Start-Process -FilePath $cscript -ArgumentList @('//nologo',('"{0}"' -f $p),'/syntax-only') -Wait -PassThru -WindowStyle Hidden;Assert ($proc.ExitCode -eq 0) "VBScript compiles: $rel"}

Write-Host '=== C# LAUNCHER COMPILE ==='
$csc=@((Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),(Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'))|Where-Object{Test-Path $_}|Select-Object -First 1
if($csc){$tmpExe=Join-Path $env:TEMP ('T3DFK-CI-'+[guid]::NewGuid().ToString('N')+'.exe');foreach($rel in 'App\PortableLauncher.cs','App\SetupLauncher.cs','App\WindowHost.cs'){$src=Join-Path $Root $rel;$args=@('/nologo','/target:winexe','/r:System.Windows.Forms.dll','/r:System.Drawing.dll',('/out:{0}' -f $tmpExe),$src);$p=Start-Process -FilePath $csc -ArgumentList $args -Wait -PassThru -WindowStyle Hidden;Assert ($p.ExitCode -eq 0) "C# compiles: $rel";Remove-Item $tmpExe -Force -ErrorAction SilentlyContinue}}else{Fail 'C# compiler not found on Windows runner'}

Write-Host '=== BROKER / EMBEDDED RUNNER ==='
$q=Join-Path $env:TEMP ('T3DFK-CI-Broker-'+[guid]::NewGuid().ToString('N'));$r=Join-Path $env:TEMP ('T3DFK-CI-Reports-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $q,$r -Force|Out-Null
$broker=Join-Path $Root 'App\RunnerBroker.vbs';$bp=Start-Process -FilePath $cscript -ArgumentList @('//nologo',('"{0}"' -f $broker),('"{0}"' -f $q),('"{0}"' -f $Root)) -PassThru -WindowStyle Hidden;$ready=Join-Path $q 'broker.ready';$heart=Join-Path $q 'heartbeat.txt';Set-Content $heart (Get-Date);Assert (Wait-File $ready 12) 'Broker creates broker.ready on Windows'
if(Test-Path $ready){$stamp=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds();$log=Join-Path $r "ci-$stamp.log";$err=Join-Path $r "ci-$stamp.err.log";$done=Join-Path $r "ci-$stamp.done";$started=Join-Path $r "ci-$stamp.started";$launch=Join-Path $r "ci-$stamp.launch-error";$cancel=Join-Path $r "ci-$stamp.cancel";$manifest=Join-Path $r "ci-$stamp.runner.txt";@("ScriptPath=$(Join-Path $Root 'App\Embedded-Runner-SelfTest.ps1')","ToolkitRoot=$Root","ReportDir=$r","LogPath=$log","ErrorPath=$err","DonePath=$done","StartedPath=$started","LaunchErrorPath=$launch","CancelPath=$cancel","Interactive=0")|Set-Content -LiteralPath $manifest -Encoding Unicode;Set-Content -LiteralPath (Join-Path $q "request-ci-$stamp.txt") -Value $manifest -Encoding Unicode;Set-Content $heart (Get-Date);Assert (Wait-File $started 12) 'Embedded runner creates started marker';Assert (Wait-File $done 20) 'Embedded runner creates completion marker';if(Test-Path $done){Assert ((Get-Content $done -Raw).Trim() -eq '0') 'Embedded runner exits 0'};if(Test-Path $log){Assert ((Get-Content $log -Raw) -match 'PASS: embedded app runner') 'Embedded runner output reaches log'}else{Fail 'Embedded runner log missing'};Assert (-not(Test-Path $launch)) 'No broker launch-error marker';Write-Host '=== CANCEL PATH ===';$stamp2=[DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds();$log2=Join-Path $r "cancel-$stamp2.log";$err2=Join-Path $r "cancel-$stamp2.err.log";$done2=Join-Path $r "cancel-$stamp2.done";$started2=Join-Path $r "cancel-$stamp2.started";$launch2=Join-Path $r "cancel-$stamp2.launch-error";$cancel2=Join-Path $r "cancel-$stamp2.cancel";$manifest2=Join-Path $r "cancel-$stamp2.runner.txt";@("ScriptPath=$(Join-Path $Root 'App\Embedded-Runner-CancelSelfTest.ps1')","ToolkitRoot=$Root","ReportDir=$r","LogPath=$log2","ErrorPath=$err2","DonePath=$done2","StartedPath=$started2","LaunchErrorPath=$launch2","CancelPath=$cancel2","Interactive=0")|Set-Content -LiteralPath $manifest2 -Encoding Unicode;Set-Content -LiteralPath (Join-Path $q "request-cancel-$stamp2.txt") -Value $manifest2 -Encoding Unicode;Set-Content $heart (Get-Date);Assert (Wait-File $started2 12) 'Cancel test starts child process';if(Test-Path $started2){Set-Content -LiteralPath $cancel2 -Value 'cancel' -Encoding ASCII;Assert (Wait-File $done2 15) 'Cancel test produces completion marker';if(Test-Path $done2){Assert ((Get-Content $done2 -Raw).Trim() -eq '1223') 'Cancel test returns 1223'}}}
Set-Content -LiteralPath (Join-Path $q 'shutdown.txt') -Value shutdown;try{if(-not $bp.WaitForExit(5000)){$bp.Kill()}}catch{}

Write-Host '=== INSTALLER INITIALIZATION ==='
$readyInstall=Join-Path $env:TEMP ('T3DFK-CI-Installer-'+[guid]::NewGuid().ToString('N')+'.ready');$wizard=Join-Path $Root 'Installer\Install-Wizard.ps1';$ps=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe';$cmd="$ErrorActionPreference='Stop';`$code=[IO.File]::ReadAllText('$($wizard.Replace("'","''"))');`$sb=[ScriptBlock]::Create(`$code);& `$sb -SourceRoot '$($Root.Replace("'","''"))' -ReadyPath '$($readyInstall.Replace("'","''"))'";$enc=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd));$ip=Start-Process -FilePath $ps -ArgumentList "-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -EncodedCommand $enc" -PassThru -WindowStyle Hidden;Assert (Wait-File $readyInstall 15) 'Graphical installer reaches UI-ready marker';try{if(-not $ip.HasExited){$ip.Kill()}}catch{};Remove-Item $readyInstall -Force -ErrorAction SilentlyContinue
Remove-Item $q,$r -Recurse -Force -ErrorAction SilentlyContinue
if($fail.Count){Write-Host "`nFAILURES: $($fail.Count)" -ForegroundColor Red;$fail|ForEach-Object{Write-Host " - $_"};exit 1};Write-Host "`nALL WINDOWS CI SMOKE TESTS PASSED" -ForegroundColor Green;exit 0
