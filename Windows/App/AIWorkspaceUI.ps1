# Local preparation workspace. No provider, network requests, or automatic analysis.
$aiRoot=Join-Path $dataRoot 'AI-Workspace'
$aiResultsRoot=Join-Path $aiRoot 'Results'
New-Item -ItemType Directory -Force -Path $aiResultsRoot | Out-Null
$aiPanel=New-Object Windows.Forms.TabControl
$aiPanel.Dock='Fill';$aiPanel.Visible=$false
$viewHost.Controls.Add($aiPanel)
$chatPage=New-Object Windows.Forms.TabPage;$chatPage.Text='Chat draft'
$logsPage=New-Object Windows.Forms.TabPage;$logsPage.Text='Diagnostic logs'
$resultsPage=New-Object Windows.Forms.TabPage;$resultsPage.Text='Analysis results'
$aiPanel.TabPages.AddRange(@($chatPage,$logsPage,$resultsPage))
$chatDraft=New-Object Windows.Forms.TextBox
$chatDraft.Multiline=$true;$chatDraft.ScrollBars='Vertical';$chatDraft.Dock='Fill'
$chatPage.Controls.Add($chatDraft)
$chatStatus=New-Object Windows.Forms.Label
$chatStatus.Dock='Top';$chatStatus.Height=54
$chatStatus.Text="AI is not connected. Write a question or case notes here and save a local draft.`r`nNo messages or logs are sent; no automated analysis has been performed."
$chatPage.Controls.Add($chatStatus)
$saveDraft=New-Object Windows.Forms.Button
$saveDraft.Dock='Bottom';$saveDraft.Height=38;$saveDraft.Text='Save draft locally'
$chatPage.Controls.Add($saveDraft)
$draftPath=Join-Path $aiRoot 'Chat-Draft.txt'
if(Test-Path -LiteralPath $draftPath){$chatDraft.Text=Get-Content -LiteralPath $draftPath -Raw -Encoding UTF8}
$saveDraft.Add_Click({
 try{[IO.File]::WriteAllText($draftPath,$chatDraft.Text,[Text.Encoding]::UTF8);$chatStatus.Text='Draft saved locally. AI is not connected; nothing was sent.'}
 catch{$chatStatus.Text='Could not save draft: '+$_.Exception.Message}
})
function New-EvidenceBrowser($Page){
 $split=New-Object Windows.Forms.SplitContainer
 $split.Dock='Fill';$split.Size=New-Object Drawing.Size(850,400);$split.SplitterDistance=280
 $list=New-Object Windows.Forms.ListBox;$list.Dock='Fill';$list.DisplayMember='Label'
 $preview=New-Object Windows.Forms.RichTextBox;$preview.Dock='Fill';$preview.ReadOnly=$true
 $split.Panel1.Controls.Add($list);$split.Panel2.Controls.Add($preview);$Page.Controls.Add($split)
 $bar=New-Object Windows.Forms.FlowLayoutPanel;$bar.Dock='Top';$bar.Height=42
 $Page.Controls.Add($bar)
 $list.Tag=$preview
 $list.Add_SelectedIndexChanged({param($sender)
  $entry=$sender.SelectedItem
  if($entry){try{$sender.Tag.Text=([IO.File]::ReadAllText($entry.Path))}catch{$sender.Tag.Text=$_.Exception.Message}}
 })
 return [pscustomobject]@{List=$list;Preview=$preview;Bar=$bar}
}
$logBrowser=New-EvidenceBrowser $logsPage
$resultBrowser=New-EvidenceBrowser $resultsPage
function Update-EvidenceList($Browser,[string]$Directory){
 $Browser.List.Items.Clear()
 foreach($file in @(Get-ChildItem -LiteralPath $Directory -Recurse -File -ErrorAction SilentlyContinue | Where-Object {$_.Extension -in @('.txt','.log','.json','.csv','.md')} | Sort-Object LastWriteTime -Descending)){
  [void]$Browser.List.Items.Add([pscustomobject]@{Label=$file.FullName.Substring($Directory.Length).TrimStart('\');Path=$file.FullName})
 }
 $Browser.Preview.Text=if($Browser.List.Items.Count){'Select a file to preview. Logs may contain sensitive information; review before sharing.'}else{'No files yet. AI is not connected and no automatic analysis has run.'}
}
function Add-WorkspaceButton($Parent,[string]$Text,[scriptblock]$Action){
 $button=New-Object Windows.Forms.Button;$button.Text=$Text;$button.AutoSize=$true;$button.Height=34
 $button.Add_Click($Action);[void]$Parent.Controls.Add($button)
 return $button
}
$refreshLogs=Add-WorkspaceButton $logBrowser.Bar 'Refresh logs' {Update-EvidenceList $logBrowser $reportRoot}
$openLogs=Add-WorkspaceButton $logBrowser.Bar 'Open log folder' {Start-Process explorer.exe -ArgumentList ('"'+$reportRoot+'"')}
$refreshResults=Add-WorkspaceButton $resultBrowser.Bar 'Refresh results' {Update-EvidenceList $resultBrowser $aiResultsRoot}
$importResult=Add-WorkspaceButton $resultBrowser.Bar 'Import analysis document' {
 $dialog=New-Object Windows.Forms.OpenFileDialog
 $dialog.Filter='Text analysis documents|*.txt;*.md;*.json;*.csv'
 try{if($dialog.ShowDialog() -eq 'OK'){
  $name=(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[IO.Path]::GetFileName($dialog.FileName)
  Copy-Item -LiteralPath $dialog.FileName -Destination (Join-Path $aiResultsRoot $name) -ErrorAction Stop
  Update-EvidenceList $resultBrowser $aiResultsRoot
 }}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Import failed')|Out-Null}finally{$dialog.Dispose()}
}
$resultsNote=New-Object Windows.Forms.Label;$resultsNote.Dock='Bottom';$resultsNote.Height=36
$resultsNote.Text='Documents here are manually imported. Field Kit has not generated or verified AI analysis.'
$resultsPage.Controls.Add($resultsNote)
# Replace informational placeholders with actual local actions and preferences.
$settings.Controls.Clear()
Add-Setting 'Local settings and folders' ('Reports: '+$reportRoot+[Environment]::NewLine+'Preferences: '+$stateRoot)
$settingsLogs=Add-WorkspaceButton $settings 'Open diagnostic logs' {Start-Process explorer.exe -ArgumentList ('"'+$reportRoot+'"')}
$settingsRunbook=Add-WorkspaceButton $settings 'Open runbook folder' {Start-Process explorer.exe -ArgumentList ('"'+$runbookRoot+'"')}
$settingsAI=Add-WorkspaceButton $settings 'Open AI workspace folder' {Start-Process explorer.exe -ArgumentList ('"'+$aiRoot+'"')}
$settingsTest=Add-WorkspaceButton $settings 'Run application integrity check' {Start-Tool (Get-Tool 'application-integrity-self-test')}
$wrapOutput=New-Object Windows.Forms.CheckBox;$wrapOutput.Text='Wrap Run Center output lines';$wrapOutput.AutoSize=$true
$wrapPath=Join-Path $stateRoot 'wrap-output.txt'
$wrapOutput.Checked=if(Test-Path $wrapPath){(Get-Content $wrapPath -Raw).Trim() -eq 'True'}else{$true}
foreach($pane in $script:RunPanes){$pane.Output.WordWrap=$wrapOutput.Checked}
$wrapOutput.Add_CheckedChanged({
 foreach($pane in $script:RunPanes){$pane.Output.WordWrap=$wrapOutput.Checked}
 Set-Content -LiteralPath $wrapPath -Value $wrapOutput.Checked -Encoding UTF8
})
$settings.Controls.Add($wrapOutput)
$settings.Controls.Add($platformButton)
