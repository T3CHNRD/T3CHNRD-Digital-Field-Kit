#Requires -Version 5.1
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Path (Join-Path $PSScriptRoot 'RunCenterProcess.cs')
. (Join-Path $PSScriptRoot 'RunCenterUI.ps1')
$appDirectory=$PSScriptRoot
$root=Join-Path $env:TEMP ('FK-dual-'+[guid]::NewGuid().ToString('N'))
$reportRoot=$root;$runbookRoot=$root
New-Item -ItemType Directory -Path $root | Out-Null
$fixture=Join-Path $root 'fixture.ps1'
@'
param([string]$Label)
Write-Output "START-$Label"
$answer=Read-Host "INPUT-$Label"
Write-Output "REPLY-$Label=$answer"
if($Label -eq 'A'){Start-Sleep -Seconds 30}
exit 0
'@ | Set-Content -LiteralPath $fixture -Encoding UTF8
$form=New-Object Windows.Forms.Form
$form.Size=New-Object Drawing.Size(1050,700);$form.Opacity=0;$form.ShowInTaskbar=$false
$runnerTabs=New-Object Windows.Forms.TabControl;$runnerTabs.Dock='Fill';$form.Controls.Add($runnerTabs)
$layout=New-Object Windows.Forms.TableLayoutPanel
1..3|ForEach-Object{[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle))}
$status=New-Object Windows.Forms.Label
$script:RunPanes=@((New-RunPane 1),(New-RunPane 2))
foreach($pane in $script:RunPanes){[void]$runnerTabs.TabPages.Add($pane.Page)}
$script:AdminDefault=$false
function Add-Recent($Id){}
function Test-AppAdministrator{return $true}
$ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'T3DFK-Windows.ps1'),[ref]$null,[ref]$null)
$script:RunnerHeight=340
foreach($name in @('Set-RunnerHeight','Write-Run','Show-Runner','Hide-Runner','Start-Tool')){
 $node=$ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$true)|Where-Object Name -eq $name|Select-Object -First 1
 . ([scriptblock]::Create($node.Extent.Text))
}
$runnerTimer=New-Object Windows.Forms.Timer
try{
 $form.Show()
 foreach($label in @('A','B')){
  Start-Tool ([pscustomobject]@{Id=$label;Name="Fixture $label";Ready=$true;Risk='ReadOnly';Path='fixture.ps1';interactive=$true;args=@('-Label',$label)})
 }
 if(Get-FreeRunPane){throw 'Two occupied slots incorrectly permit a third tool.'}
 $deadline=[DateTime]::UtcNow.AddSeconds(15)
 do{Update-RunPanes;[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 25}until(($script:RunPanes[0].Output.Text -match 'INPUT-A' -and $script:RunPanes[1].Output.Text -match 'INPUT-B') -or [DateTime]::UtcNow -gt $deadline)
 foreach($i in 0,1){$runnerTabs.SelectedTab=$script:RunPanes[$i].Page;[Windows.Forms.Application]::DoEvents();$script:RunPanes[$i].Input.Text="answer-$i";$script:RunPanes[$i].Send.PerformClick()}
 $deadline=[DateTime]::UtcNow.AddSeconds(15)
 do{Update-RunPanes;[Windows.Forms.Application]::DoEvents();Start-Sleep -Milliseconds 25}until(($script:RunPanes[0].Output.Text -match 'REPLY-A=answer-0' -and -not $script:RunPanes[1].Capture) -or [DateTime]::UtcNow -gt $deadline)
 if($script:RunPanes[1].State.Text -ne "Completed`r`nExit code: 0"){throw 'Second tool did not complete independently.'}
 if($script:RunPanes[0].Output.Text -notmatch 'REPLY-A=answer-0' -or $script:RunPanes[1].Output.Text -notmatch 'REPLY-B=answer-1'){throw 'Input routing failed.'}
 Stop-RunPane $script:RunPanes[0]
 $deadline=[DateTime]::UtcNow.AddSeconds(10)
 do{Update-RunPanes;Start-Sleep -Milliseconds 25}until(-not $script:RunPanes[0].Capture -or [DateTime]::UtcNow -gt $deadline)
 if($script:RunPanes[0].State.Text -notmatch '^Cancelled'){throw 'First tool cancellation failed.'}
 foreach($i in 0,1){
  $pane=$script:RunPanes[$i]
  if($pane.State.Bounds.Right -gt $pane.Cancel.Bounds.Left){throw 'Status overlaps cancel button.'}
  $other=if($i -eq 0){'B'}else{'A'}
  if((Get-Content $pane.Log -Raw) -match "REPLY-$other"){throw 'Logs are mixed.'}
 }
 if($script:RunPanes[0].Log -eq $script:RunPanes[1].Log){throw 'Shared log path.'}
 Write-Output 'PASS: two concurrent tools; third-slot limit; separate stdin/output/logs; independent completion/cancel; nonoverlapping header.'
}finally{
 foreach($pane in $script:RunPanes){Stop-RunPane $pane;if($pane.Capture){$pane.Capture.Dispose()}}
 $form.Dispose();$runnerTimer.Dispose()
 if(-not ([IO.Path]::GetFullPath($root)).StartsWith(([IO.Path]::GetFullPath($env:TEMP)).TrimEnd('\')+'\')){throw 'Unexpected cleanup path'}
 Remove-Item -LiteralPath $root -Recurse -Force
}

