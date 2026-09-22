#Requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$testState=Join-Path $env:TEMP ('FK-workflows-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testState | Out-Null
try {
 # Exercise actual star and Favorites tab click handlers using isolated state.
 Set-Content (Join-Path $testState 'favorites.txt') 'tool-05'
 $code=Get-Content (Join-Path $PSScriptRoot 'T3DFK-Windows.ps1') -Raw
 $code=$code.Replace("`$stateRoot = Join-Path `$env:LOCALAPPDATA 'T3DFK'",'$stateRoot = $testState')
 $code=$code.Replace('if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){','if($false){')
 $checks=@'
$form.Opacity=0;$form.ShowInTaskbar=$false;$form.Show()
try {
 $tabs['Tools'].PerformClick()
 $card=@($cards.Controls | Where-Object {$_.Tag -and $_.Tag.Id -eq 'tool-06'})[0]
 $star=@($card.Controls | Where-Object {$_ -is [Windows.Forms.Button]})[0]
 $star.PerformClick()
 $tabs['Favorites'].PerformClick()
 if($cards.Controls.Count -ne 2){throw 'Favorites tab did not show both pinned cards.'}
 $saved=@(Get-Content $script:FavoritesFile)
 if($saved.Count -ne 2 -or $saved -notcontains 'tool-05' -or $saved -notcontains 'tool-06'){throw 'Favorites did not persist as separate IDs.'}
 # Simulate reopening with the persisted state, then unpin both through clicks.
 $script:Favorites=@(Get-Content $script:FavoritesFile)
 foreach($id in @('tool-05','tool-06')){
  $card=@($cards.Controls | Where-Object {$_.Tag -and $_.Tag.Id -eq $id})[0]
  @($card.Controls | Where-Object {$_ -is [Windows.Forms.Button]})[0].PerformClick()
 }
 if(@(Get-Content $script:FavoritesFile | Where-Object {$_}).Count){throw 'Unpinning the last favorite did not clear the file.'}
 Write-Output 'PASS: star clicks, Favorites tab, persistence, reload, and removing the last favorite.'
 Set-RunnerHeight 220
 if($layout.RowStyles[2].Height -ne 220){throw 'Run Center did not resize.'}
 Hide-Runner
 Set-RunnerHeight $script:RunnerHeight
 if($layout.RowStyles[2].Height -ne 220){throw 'Run Center did not retain its height.'}
 Set-RunnerHeight 9999
 if($layout.RowStyles[2].Height -gt ($layout.ClientSize.Height-310)){throw 'Run Center exceeded layout bounds.'}
 foreach($tool in $script:ToolCatalog){
  Show-ToolHelp $tool.Id
  if(-not $rbView.Text.StartsWith($tool.Name) -or $rbView.Text -notmatch 'HOW TO RUN'){throw ('Missing help for '+$tool.Id)}
 }
 $rbSearch.Text='Sleep Hold'
 if($rbList.Items.Count -ne 1){throw 'Tool help search failed.'}
 Write-Output 'PASS: Run Center resize bounds, retained height, all 64 tool guides and help search.'
 $script:View='AI Workspace';Update-View
 if(-not $aiPanel.Visible){throw 'AI workspace navigation failed.'}
 $draftPath=Join-Path $testState 'draft.txt'
 $chatDraft.Text='Test case question';$saveDraft.PerformClick()
 if((Get-Content $draftPath -Raw) -ne 'Test case question'){throw 'Chat draft did not save.'}
 Set-Content (Join-Path $testState 'sample.log') 'Example diagnostic evidence'
 $aiPanel.SelectedTab=$logsPage
 Update-EvidenceList $logBrowser $testState
 for($i=0;$i -lt $logBrowser.List.Items.Count;$i++){
  if($logBrowser.List.Items[$i].Label -eq 'sample.log'){$logBrowser.List.SelectedIndex=$i;break}
 }
 if($logBrowser.Preview.Text -notmatch 'Example diagnostic evidence'){throw 'Log preview failed.'}
 $script:View='Settings';Update-View
 $wrapOutput.Checked=-not $wrapOutput.Checked
 foreach($pane in $script:RunPanes){if($pane.Output.WordWrap -ne $wrapOutput.Checked){throw 'Output preference not applied.'}}
 if(-not(Test-Path $wrapPath)){throw 'Output preference did not persist.'}
 if(-not @($sideFlow.Controls | Where-Object Text -eq 'Log Files').Count){throw 'Missing log shortcut.'}
 Write-Output 'PASS: AI workspace navigation, local draft save, log preview and persisted settings.'


}finally{$form.Close();$form.Dispose()}
'@
 $code=$code.Replace('[void]$form.ShowDialog()',$checks)
 . ([scriptblock]::Create($code)) -ToolkitRoot $root
 # Exercise chooser selection without opening any system consoles.
 $script:Opened=@()
 function Start-Process {param($FilePath,$ArgumentList) $script:Opened+= $FilePath}
 $chooser=Get-Content (Join-Path $root 'Windows/Scripts/Core/Select-DiagnosticConsole.ps1') -Raw
 $chooser=$chooser.Replace('if($form.ShowDialog()',"if(`$(if(`$list.CheckedItems.Count -ne 0 -or `$launch.Enabled){throw 'Chooser preselected consoles'};`$list.SetItemChecked(2,`$true);[Windows.Forms.DialogResult]::OK)")
 & ([scriptblock]::Create($chooser))
 if($script:Opened.Count -ne 1 -or $script:Opened[0] -ne 'taskmgr.exe'){throw 'Chooser opened unselected consoles.'}
 Write-Output 'PASS: chooser starts empty and opens only the selected console.'
 # Mock antivirus providers. Never invoke a real antivirus scan in this test.
 function Get-CimInstance {param($Namespace,$ClassName,$ErrorAction) [pscustomobject]@{displayName='Test Vendor Antivirus';productState=1;pathToSignedProductExe='test';pathToSignedReportingExe='test'}}
 function Get-MpComputerStatus {param($ErrorAction) [pscustomobject]@{AMRunningMode='Passive Mode';AntivirusEnabled=$false;RealTimeProtectionEnabled=$false;AntivirusSignatureVersion='test';QuickScanStartTime=$null;QuickScanEndTime=$null}}
 function Start-MpScan {throw 'A disabled Defender scan must not be invoked.'}
 $env:TTK_REPORT_DIR=$testState
 & (Join-Path $root 'Windows/Scripts/Security/Invoke-AntivirusQuickScan.ps1')
 $json=Get-ChildItem $testState -Recurse -Filter Antivirus-Status.json | Select-Object -First 1
 $record=Get-Content $json.FullName -Raw|ConvertFrom-Json
 if($record.Result -ne 'Skipped' -or $record.Products[0].displayName -ne 'Test Vendor Antivirus' -or $record.ProtectionChanged){throw 'Antivirus skip evidence incorrect.'}
 if(-not(Test-Path (Join-Path $json.DirectoryName 'Antivirus-Run.txt'))){throw 'Antivirus transcript missing.'}
 if((Get-Content (Join-Path $json.DirectoryName 'Antivirus-Run.txt') -Raw) -notmatch 'Test Vendor Antivirus'){throw 'Transcript omitted antivirus identity.'}
 Write-Output 'PASS: third-party antivirus identified; Defender skipped; text/JSON evidence retained; no protection changed.'
 $global:FieldKitTestScanCalls=0
 function Get-MpComputerStatus {param($ErrorAction) [pscustomobject]@{AMRunningMode='Normal';AntivirusEnabled=$true;RealTimeProtectionEnabled=$true;AntivirusSignatureVersion='test';AntivirusSignatureAge=0;QuickScanAge=0;QuickScanStartTime=Get-Date;QuickScanEndTime=Get-Date}}
 function Start-MpScan {param($ScanType) if($ScanType -ne 'QuickScan'){throw 'Unexpected scan type'};$global:FieldKitTestScanCalls++}
 function Get-MpThreatDetection {return @()}
 & (Join-Path $root 'Windows/Scripts/Security/Invoke-AntivirusQuickScan.ps1')
 if($global:FieldKitTestScanCalls -ne 1){throw 'Active Defender did not invoke exactly one quick scan.'}
 $completed=@(Get-ChildItem $testState -Recurse -Filter Antivirus-Status.json | ForEach-Object {Get-Content $_.FullName -Raw|ConvertFrom-Json}|Where-Object Result -eq 'DefenderWorkflowCompleted')
 if($completed.Count -ne 1){throw 'Completed Defender workflow evidence missing.'}
 Write-Output 'PASS: active Defender delegates one quick scan and saves completed workflow evidence (mock scanner).'
}finally{
 if(-not ([IO.Path]::GetFullPath($testState)).StartsWith(([IO.Path]::GetFullPath($env:TEMP)).TrimEnd('\')+'\')){throw 'Unexpected cleanup path'}
 Remove-Item -LiteralPath $testState -Recurse -Force
}
