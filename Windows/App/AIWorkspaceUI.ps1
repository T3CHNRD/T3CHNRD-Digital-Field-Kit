# DivaByte local-first diagnostic assistant workspace.
# Local drafts, evidence, memory, Runbook editing, research policy, and result storage
# work without an AI provider. Model inference and Internet research plug in later.

$legacyAiRoot=Join-Path $dataRoot 'AI-Workspace'
$aiRoot=Join-Path $dataRoot 'DivaByte'
$aiResultsRoot=Join-Path $aiRoot 'Results'
$divaMemoryRoot=Join-Path $aiRoot 'Memory'
$divaResearchRoot=Join-Path $aiRoot 'ResearchCache'
$divaSessionRoot=Join-Path $aiRoot 'Sessions'
$divaModePath=Join-Path $aiRoot 'Research-Mode.txt'
New-Item -ItemType Directory -Force -Path $aiRoot,$aiResultsRoot,$divaMemoryRoot,$divaResearchRoot,$divaSessionRoot | Out-Null

if((Test-Path -LiteralPath $legacyAiRoot) -and -not(Test-Path -LiteralPath (Join-Path $aiRoot '.legacy-migrated'))){
 try{
  foreach($item in @(Get-ChildItem -LiteralPath $legacyAiRoot -Force -ErrorAction SilentlyContinue)){
   $destination=Join-Path $aiRoot $item.Name
   if(-not(Test-Path -LiteralPath $destination)){
    Copy-Item -LiteralPath $item.FullName -Destination $destination -Recurse -Force -ErrorAction Stop
   }
  }
  Set-Content -LiteralPath (Join-Path $aiRoot '.legacy-migrated') -Value (Get-Date).ToString('o') -Encoding UTF8
 }catch{}
}

$script:DivaByteResearchModes=@('Offline','Local + Research','Ask Before Researching')
$script:DivaByteResearchMode=if(Test-Path -LiteralPath $divaModePath){
 (Get-Content -LiteralPath $divaModePath -Raw -Encoding UTF8).Trim()
}else{'Ask Before Researching'}
if($script:DivaByteResearchModes -notcontains $script:DivaByteResearchMode){
 $script:DivaByteResearchMode='Ask Before Researching'
}
function Set-DivaByteResearchMode([string]$Mode){
 if($script:DivaByteResearchModes -notcontains $Mode){throw "Unsupported DivaByte research mode: $Mode"}
 $script:DivaByteResearchMode=$Mode
 Set-Content -LiteralPath $divaModePath -Value $Mode -Encoding UTF8
 if($script:DivaByteCoreOnline){
  try{Invoke-DivaByteApi -Method PUT -Path '/v1/research/mode' -Body @{mode=$Mode} | Out-Null}catch{}
 }
}

. (Join-Path $appDirectory 'DivaByteClient.ps1')
$script:DivaByteCaseId=$null
$script:DivaByteCoreOnline=Start-DivaByteCore -ToolkitRoot $root -DataRoot $aiRoot -RunbookRoot $runbookRoot -ReportRoot $reportRoot
if($script:DivaByteCoreOnline){
 try{
  $coreStatus=Get-DivaByteCoreStatus
  if($coreStatus -and $script:DivaByteResearchModes -contains [string]$coreStatus.researchMode){
   $script:DivaByteResearchMode=[string]$coreStatus.researchMode
  }
 }catch{}
}

$aiPanel=New-Object Windows.Forms.TabControl
$aiPanel.Dock='Fill';$aiPanel.Visible=$false
$viewHost.Controls.Add($aiPanel)
$chatPage=New-Object Windows.Forms.TabPage;$chatPage.Text='Case / Chat'
$logsPage=New-Object Windows.Forms.TabPage;$logsPage.Text='Diagnostic evidence'
$memoryPage=New-Object Windows.Forms.TabPage;$memoryPage.Text='Memory'
$runbookKnowledgePage=New-Object Windows.Forms.TabPage;$runbookKnowledgePage.Text='Runbook knowledge'
$researchPage=New-Object Windows.Forms.TabPage;$researchPage.Text='Research'
$resultsPage=New-Object Windows.Forms.TabPage;$resultsPage.Text='Analysis results'
$aiPanel.TabPages.AddRange(@($chatPage,$logsPage,$memoryPage,$runbookKnowledgePage,$researchPage,$resultsPage))

$chatDraft=New-Object Windows.Forms.TextBox
$chatDraft.Multiline=$true;$chatDraft.ScrollBars='Vertical';$chatDraft.Dock='Fill'
$chatPage.Controls.Add($chatDraft)
$chatStatus=New-Object Windows.Forms.Label
$chatStatus.Dock='Top';$chatStatus.Height=70
$chatStatus.Text=if($script:DivaByteCoreOnline){'DivaByte Core is online. Local cases, evidence, memory, Runbook knowledge and deterministic analysis are available. Local LLM and live Internet research are not connected yet.'}else{'DivaByte Core is unavailable in this package. Local drafts, evidence browsing, memory and Runbook editing remain available.'}
$chatPage.Controls.Add($chatStatus)

$modeBar=New-Object Windows.Forms.FlowLayoutPanel;$modeBar.Dock='Top';$modeBar.Height=40
$modeLabel=New-Object Windows.Forms.Label;$modeLabel.Text='Research mode:';$modeLabel.AutoSize=$true;$modeLabel.Padding=New-Object Windows.Forms.Padding(0,8,4,0)
$researchModeCombo=New-Object Windows.Forms.ComboBox;$researchModeCombo.DropDownStyle='DropDownList';$researchModeCombo.Width=190
foreach($mode in $script:DivaByteResearchModes){[void]$researchModeCombo.Items.Add($mode)}
$researchModeCombo.SelectedItem=$script:DivaByteResearchMode
[void]$modeBar.Controls.Add($modeLabel);[void]$modeBar.Controls.Add($researchModeCombo)
$chatPage.Controls.Add($modeBar)

$caseBar=New-Object Windows.Forms.FlowLayoutPanel
$caseBar.Dock='Bottom';$caseBar.Height=42
$chatPage.Controls.Add($caseBar)

$saveDraft=New-Object Windows.Forms.Button
$saveDraft.AutoSize=$true;$saveDraft.Height=34;$saveDraft.Text='Save notes locally'
[void]$caseBar.Controls.Add($saveDraft)

$newCaseButton=New-Object Windows.Forms.Button
$newCaseButton.AutoSize=$true;$newCaseButton.Height=34;$newCaseButton.Text='New diagnostic case'
[void]$caseBar.Controls.Add($newCaseButton)

$addCaseNoteButton=New-Object Windows.Forms.Button
$addCaseNoteButton.AutoSize=$true;$addCaseNoteButton.Height=34;$addCaseNoteButton.Text='Add note to case'
[void]$caseBar.Controls.Add($addCaseNoteButton)

$analyzeCaseButton=New-Object Windows.Forms.Button
$analyzeCaseButton.AutoSize=$true;$analyzeCaseButton.Height=34;$analyzeCaseButton.Text='Analyze case'
[void]$caseBar.Controls.Add($analyzeCaseButton)

$caseStateLabel=New-Object Windows.Forms.Label
$caseStateLabel.AutoSize=$true;$caseStateLabel.Padding=New-Object Windows.Forms.Padding(8,8,0,0)
$caseStateLabel.Text=if($script:DivaByteCoreOnline){'No active case'}else{'Core offline'}
[void]$caseBar.Controls.Add($caseStateLabel)

$draftPath=Join-Path $aiRoot 'Chat-Draft.txt'
if(Test-Path -LiteralPath $draftPath){$chatDraft.Text=Get-Content -LiteralPath $draftPath -Raw -Encoding UTF8}
$saveDraft.Add_Click({
 try{[IO.File]::WriteAllText($draftPath,$chatDraft.Text,[Text.Encoding]::UTF8);$chatStatus.Text='Case notes saved locally in DivaByte. Nothing was uploaded.'}
 catch{$chatStatus.Text='Could not save case notes: '+$_.Exception.Message}
})

function New-DivaByteCase {
 if(-not $script:DivaByteCoreOnline){throw 'DivaByte Core is not online.'}
 $title=($chatDraft.Text -split "(`r`n|`n)")[0].Trim()
 if([string]::IsNullOrWhiteSpace($title)){$title='Field Kit Diagnostic Case'}
 $case=Invoke-DivaByteApi -Method POST -Path '/v1/cases' -Body @{title=$title}
 $script:DivaByteCaseId=[string]$case.id
 $caseStateLabel.Text='Case: '+$script:DivaByteCaseId.Substring(0,8)
 $chatStatus.Text='New DivaByte diagnostic case created locally.'
 return $case
}
function Ensure-DivaByteCase {
 if(-not $script:DivaByteCaseId){[void](New-DivaByteCase)}
 return $script:DivaByteCaseId
}
function Save-DivaByteAnalysisResult($Result){
 $name='Case-{0}-{1}.json' -f $script:DivaByteCaseId,(Get-Date -Format 'yyyyMMdd-HHmmss')
 $path=Join-Path $aiResultsRoot $name
 $Result | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path -Encoding UTF8
 Update-EvidenceList $resultBrowser $aiResultsRoot
 $aiPanel.SelectedTab=$resultsPage
 return $path
}
$newCaseButton.Add_Click({
 try{[void](New-DivaByteCase)}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'DivaByte case')|Out-Null}
})
$addCaseNoteButton.Add_Click({
 try{
  $id=Ensure-DivaByteCase
  if([string]::IsNullOrWhiteSpace($chatDraft.Text)){throw 'Enter a technician note or question first.'}
  Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$id+'/message') -Body @{text=$chatDraft.Text} | Out-Null
  $chatStatus.Text='Technician note added to the active case. DivaByte will treat it as technician-provided context.'
 }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'DivaByte case')|Out-Null}
})
$analyzeCaseButton.Add_Click({
 try{
  $id=Ensure-DivaByteCase
  $result=Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$id+'/analyze') -Body @{}
  $saved=Save-DivaByteAnalysisResult $result
  $chatStatus.Text='DivaByte analysis completed locally. Result saved: '+[IO.Path]::GetFileName($saved)
 }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'DivaByte analysis')|Out-Null}
})

$script:EvidenceTextExtensions=@('.txt','.log','.json','.csv','.md','.xml','.html','.htm','.ps1','.psd1','.ini','.cfg','.yaml','.yml')
$script:EvidencePreviewLimitBytes=1048576
function Show-EvidencePreview($Preview,$Entry){
 if(-not $Entry){return}
 $file=Get-Item -LiteralPath $Entry.Path -ErrorAction SilentlyContinue
 if(-not $file){$Preview.Text='This file is no longer available.';return}
 if($script:EvidenceTextExtensions -notcontains $file.Extension.ToLowerInvariant()){
  $Preview.Text=('Preview unavailable for {0} files ({1:N0} bytes). Use the containing folder to inspect it with its associated application.' -f $(if($file.Extension){$file.Extension}else{'extensionless'}),$file.Length)
  return
 }
 if($file.Length -gt $script:EvidencePreviewLimitBytes){
  $Preview.Text=('Preview limited to files up to 1 MiB. This file is {0:N0} bytes.' -f $file.Length);return
 }
 try{$Preview.Text=[IO.File]::ReadAllText($file.FullName,[Text.Encoding]::UTF8)}catch{$Preview.Text=$_.Exception.Message}
}
function New-EvidenceBrowser($Page){
 $split=New-Object Windows.Forms.SplitContainer;$split.Dock='Fill';$split.Size=New-Object Drawing.Size(850,400);$split.SplitterDistance=280
 $list=New-Object Windows.Forms.ListBox;$list.Dock='Fill';$list.DisplayMember='Label'
 $preview=New-Object Windows.Forms.RichTextBox;$preview.Dock='Fill';$preview.ReadOnly=$true
 $split.Panel1.Controls.Add($list);$split.Panel2.Controls.Add($preview);$Page.Controls.Add($split)
 $bar=New-Object Windows.Forms.FlowLayoutPanel;$bar.Dock='Top';$bar.Height=42;$Page.Controls.Add($bar)
 $list.Tag=$preview
 $list.Add_SelectedIndexChanged({
  $senderControl=$this
  $previewControl=$senderControl.Tag
  $entry=$senderControl.SelectedItem
  if(-not $previewControl -or -not $entry){return}
  $file=Get-Item -LiteralPath $entry.Path -ErrorAction SilentlyContinue
  if(-not $file){$previewControl.Text='This file is no longer available.';return}
  $textExtensions=@('.txt','.log','.json','.csv','.md','.xml','.html','.htm','.ps1','.psd1','.ini','.cfg','.yaml','.yml')
  if($textExtensions -notcontains $file.Extension.ToLowerInvariant()){
   $previewControl.Text=('Preview unavailable for {0} files ({1:N0} bytes). Use the containing folder to inspect it with its associated application.' -f $(if($file.Extension){$file.Extension}else{'extensionless'}),$file.Length)
   return
  }
  if($file.Length -gt 1048576){
   $previewControl.Text=('Preview limited to files up to 1 MiB. This file is {0:N0} bytes.' -f $file.Length)
   return
  }
  try{$previewControl.Text=[IO.File]::ReadAllText($file.FullName,[Text.Encoding]::UTF8)}catch{$previewControl.Text=$_.Exception.Message}
 })
 return [pscustomobject]@{List=$list;Preview=$preview;Bar=$bar}
}
function Update-EvidenceList($Browser,[string]$Directory){
 $Browser.List.Items.Clear()
 foreach($file in @(Get-ChildItem -LiteralPath $Directory -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)){
  $relative=$file.FullName.Substring($Directory.Length).TrimStart('\')
  [void]$Browser.List.Items.Add([pscustomobject]@{Label=('{0} ({1:N0} bytes)' -f $relative,$file.Length);Path=$file.FullName})
 }
 $Browser.Preview.Text=if($Browser.List.Items.Count){'Select evidence to preview. Current evidence must remain distinguishable from DivaByte inference, memory, Runbook knowledge, and external research.'}else{'No evidence files yet.'}
}
function Add-WorkspaceButton($Parent,[string]$Text,[scriptblock]$Action){
 $button=New-Object Windows.Forms.Button;$button.Text=$Text;$button.AutoSize=$true;$button.Height=34
 $button.Add_Click($Action);[void]$Parent.Controls.Add($button);return $button
}

$logBrowser=New-EvidenceBrowser $logsPage
$resultBrowser=New-EvidenceBrowser $resultsPage
$refreshLogs=Add-WorkspaceButton $logBrowser.Bar 'Refresh logs' {Update-EvidenceList $logBrowser $reportRoot}
$openLogs=Add-WorkspaceButton $logBrowser.Bar 'Open log folder' {Start-Process explorer.exe -ArgumentList ('"'+$reportRoot+'"')}
$addEvidenceToCase=Add-WorkspaceButton $logBrowser.Bar 'Add selected to case' {
 try{
  if(-not $logBrowser.List.SelectedItem){throw 'Select an evidence file first.'}
  $id=Ensure-DivaByteCase
  $result=Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$id+'/evidence') -Body @{path=$logBrowser.List.SelectedItem.Path}
  if($result.duplicate){$chatStatus.Text='That evidence file is already attached to the active case.'}
  else{$chatStatus.Text='Evidence attached to active case: '+[IO.Path]::GetFileName($logBrowser.List.SelectedItem.Path)}
 }catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'DivaByte evidence')|Out-Null}
}
$refreshResults=Add-WorkspaceButton $resultBrowser.Bar 'Refresh results' {Update-EvidenceList $resultBrowser $aiResultsRoot}
$importResult=Add-WorkspaceButton $resultBrowser.Bar 'Import analysis document' {
 $dialog=New-Object Windows.Forms.OpenFileDialog;$dialog.Filter='Analysis documents|*.txt;*.md;*.json;*.csv'
 try{if($dialog.ShowDialog() -eq 'OK'){
  $name=(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[IO.Path]::GetFileName($dialog.FileName)
  Copy-Item -LiteralPath $dialog.FileName -Destination (Join-Path $aiResultsRoot $name) -ErrorAction Stop
  Update-EvidenceList $resultBrowser $aiResultsRoot
 }}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Import failed')|Out-Null}finally{$dialog.Dispose()}
}
$resultsNote=New-Object Windows.Forms.Label;$resultsNote.Dock='Bottom';$resultsNote.Height=42
$resultsNote.Text='Results are local. Future DivaByte analysis must cite evidence and remain challengeable by the technician.'
$resultsPage.Controls.Add($resultsNote)

function Get-DivaByteMemoryEntries {
 $entries=@()
 foreach($file in @(Get-ChildItem -LiteralPath $divaMemoryRoot -File -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)){
  try{
   $entry=Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8|ConvertFrom-Json
   $entries+=[pscustomobject]@{Label=('{0} | {1} | {2}' -f $entry.type,$entry.title,$entry.createdAt);Path=$file.FullName;Entry=$entry}
  }catch{}
 }
 return @($entries)
}
function Refresh-DivaByteMemory {
 $memoryList.Items.Clear()
 foreach($entry in @(Get-DivaByteMemoryEntries)){[void]$memoryList.Items.Add($entry)}
 $memoryPreview.Text=if($memoryList.Items.Count){'Select a memory entry. Prior memory can guide an investigation, but it is not proof of the current incident.'}else{'No DivaByte memory entries yet.'}
}
function Add-DivaByteMemoryEntry([string]$Type,[string]$Trust,[string]$Title,[string]$Body,[string]$Source='Technician'){
 if([string]::IsNullOrWhiteSpace($Title)){throw 'Memory title is required.'}
 if([string]::IsNullOrWhiteSpace($Body)){throw 'Memory details are required.'}
 if($script:DivaByteCoreOnline){
  $result=Invoke-DivaByteApi -Method POST -Path '/v1/memory' -Body @{type=$Type;trust=$Trust;title=$Title.Trim();body=$Body.Trim();source=$Source}
  return [string]$result.memory.id
 }
 $record=[ordered]@{id=[guid]::NewGuid().ToString('N');createdAt=(Get-Date).ToString('o');type=$Type;trust=$Trust;title=$Title.Trim();body=$Body.Trim();source=$Source}
 $path=Join-Path $divaMemoryRoot ((Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+$record.id+'.json')
 $record|ConvertTo-Json -Depth 6|Set-Content -LiteralPath $path -Encoding UTF8
 return $path
}

$memorySplit=New-Object Windows.Forms.SplitContainer;$memorySplit.Dock='Fill';$memorySplit.SplitterDistance=310;$memoryPage.Controls.Add($memorySplit)
$memoryList=New-Object Windows.Forms.ListBox;$memoryList.Dock='Fill';$memoryList.DisplayMember='Label';$memorySplit.Panel1.Controls.Add($memoryList)
$memoryPreview=New-Object Windows.Forms.RichTextBox;$memoryPreview.Dock='Fill';$memoryPreview.ReadOnly=$true;$memorySplit.Panel2.Controls.Add($memoryPreview)
$memoryList.Add_SelectedIndexChanged({if($memoryList.SelectedItem){$memoryPreview.Text=($memoryList.SelectedItem.Entry|ConvertTo-Json -Depth 8)}})
$memoryEntryPanel=New-Object Windows.Forms.Panel;$memoryEntryPanel.Dock='Bottom';$memoryEntryPanel.Height=190;$memoryPage.Controls.Add($memoryEntryPanel)
$memoryType=New-Object Windows.Forms.ComboBox;$memoryType.DropDownStyle='DropDownList';$memoryType.SetBounds(10,10,180,26)
foreach($item in @('Observation','Confirmed Root Cause','Successful Fix','Failed Fix','Disproven Hypothesis','Technician Correction','Research Note')){[void]$memoryType.Items.Add($item)}
$memoryType.SelectedIndex=0
$memoryTrust=New-Object Windows.Forms.ComboBox;$memoryTrust.DropDownStyle='DropDownList';$memoryTrust.SetBounds(200,10,190,26)
foreach($item in @('Unverified Note','Technician Observation','Confirmed Local Knowledge','Cached Research')){[void]$memoryTrust.Items.Add($item)}
$memoryTrust.SelectedIndex=0
$memoryTitle=New-Object Windows.Forms.TextBox;$memoryTitle.SetBounds(400,10,360,26)
$memoryBody=New-Object Windows.Forms.TextBox;$memoryBody.Multiline=$true;$memoryBody.ScrollBars='Vertical';$memoryBody.SetBounds(10,46,750,90)
$memorySave=New-Object Windows.Forms.Button;$memorySave.Text='Save to DivaByte memory';$memorySave.SetBounds(10,145,180,32)
$memoryRefresh=New-Object Windows.Forms.Button;$memoryRefresh.Text='Refresh memory';$memoryRefresh.SetBounds(200,145,130,32)
foreach($control in @($memoryType,$memoryTrust,$memoryTitle,$memoryBody,$memorySave,$memoryRefresh)){[void]$memoryEntryPanel.Controls.Add($control)}
$memorySave.Add_Click({
 try{[void](Add-DivaByteMemoryEntry ([string]$memoryType.SelectedItem) ([string]$memoryTrust.SelectedItem) $memoryTitle.Text $memoryBody.Text);$memoryTitle.Clear();$memoryBody.Clear();Refresh-DivaByteMemory}
 catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Memory not saved')|Out-Null}
})
$memoryRefresh.Add_Click({Refresh-DivaByteMemory})

function Refresh-DivaByteRunbook {
 $runbookKnowledgeList.Items.Clear()
 foreach($file in @(Get-ChildItem -LiteralPath $runbookRoot -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue | Sort-Object FullName)){
  $relative=$file.FullName.Substring($runbookRoot.Length).TrimStart('\')
  [void]$runbookKnowledgeList.Items.Add([pscustomobject]@{Label=$relative;Path=$file.FullName})
 }
}
function Load-DivaByteRunbookArticle {
 if(-not $runbookKnowledgeList.SelectedItem){return}
 $runbookKnowledgeEditor.Text=Get-Content -LiteralPath $runbookKnowledgeList.SelectedItem.Path -Raw -Encoding UTF8
 $runbookKnowledgeStatus.Text='Loaded: '+$runbookKnowledgeList.SelectedItem.Label
}
function Save-DivaByteRunbookArticle([string]$Path){
 $rootPath=[IO.Path]::GetFullPath($runbookRoot).TrimEnd('\')+'\'
 $full=[IO.Path]::GetFullPath($Path)
 if(-not $full.StartsWith($rootPath,[StringComparison]::OrdinalIgnoreCase)){throw 'Runbook changes must stay inside the Field Kit Runbook folder.'}
 [IO.File]::WriteAllText($full,$runbookKnowledgeEditor.Text,[Text.Encoding]::UTF8)
 $runbookKnowledgeStatus.Text='Saved locally: '+$full.Substring($rootPath.Length)
 Refresh-DivaByteRunbook
}

$runbookKnowledgeSplit=New-Object Windows.Forms.SplitContainer;$runbookKnowledgeSplit.Dock='Fill';$runbookKnowledgeSplit.SplitterDistance=280;$runbookKnowledgePage.Controls.Add($runbookKnowledgeSplit)
$runbookKnowledgeList=New-Object Windows.Forms.ListBox;$runbookKnowledgeList.Dock='Fill';$runbookKnowledgeList.DisplayMember='Label';$runbookKnowledgeSplit.Panel1.Controls.Add($runbookKnowledgeList)
$runbookKnowledgeEditor=New-Object Windows.Forms.RichTextBox;$runbookKnowledgeEditor.Dock='Fill';$runbookKnowledgeEditor.AcceptsTab=$true;$runbookKnowledgeSplit.Panel2.Controls.Add($runbookKnowledgeEditor)
$runbookKnowledgeList.Add_SelectedIndexChanged({Load-DivaByteRunbookArticle})
$runbookKnowledgeBar=New-Object Windows.Forms.FlowLayoutPanel;$runbookKnowledgeBar.Dock='Top';$runbookKnowledgeBar.Height=42;$runbookKnowledgePage.Controls.Add($runbookKnowledgeBar)
$runbookRefresh=Add-WorkspaceButton $runbookKnowledgeBar 'Refresh articles' {Refresh-DivaByteRunbook}
$runbookSave=Add-WorkspaceButton $runbookKnowledgeBar 'Save selected article' {
 if(-not $runbookKnowledgeList.SelectedItem){return}
 if([Windows.Forms.MessageBox]::Show('Save these local Runbook changes?','DivaByte Runbook update','YesNo','Question') -eq 'Yes'){
  try{Save-DivaByteRunbookArticle $runbookKnowledgeList.SelectedItem.Path}catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Runbook save failed')|Out-Null}
 }
}
$runbookSaveAs=Add-WorkspaceButton $runbookKnowledgeBar 'Add new article' {
 $dialog=New-Object Windows.Forms.SaveFileDialog;$dialog.InitialDirectory=$runbookRoot;$dialog.Filter='Markdown article|*.md';$dialog.DefaultExt='md'
 try{if($dialog.ShowDialog() -eq 'OK'){Save-DivaByteRunbookArticle $dialog.FileName}}
 catch{[Windows.Forms.MessageBox]::Show($_.Exception.Message,'Runbook save failed')|Out-Null}finally{$dialog.Dispose()}
}
$runbookKnowledgeStatus=New-Object Windows.Forms.Label;$runbookKnowledgeStatus.Dock='Bottom';$runbookKnowledgeStatus.Height=42
$runbookKnowledgeStatus.Text='Offline Runbook editing is enabled. Future DivaByte-generated updates must be reviewed and approved by the technician.'
$runbookKnowledgePage.Controls.Add($runbookKnowledgeStatus)

$researchBrowser=New-EvidenceBrowser $researchPage
$refreshResearch=Add-WorkspaceButton $researchBrowser.Bar 'Refresh research cache' {Update-EvidenceList $researchBrowser $divaResearchRoot}
$openResearch=Add-WorkspaceButton $researchBrowser.Bar 'Open research cache' {Start-Process explorer.exe -ArgumentList ('"'+$divaResearchRoot+'"')}
$researchPolicy=New-Object Windows.Forms.Label;$researchPolicy.Dock='Bottom';$researchPolicy.Height=70
$researchPolicy.Text='Research policy: '+$script:DivaByteResearchMode+'. Future Internet research must honor this setting, save source/date locally, and remain separate from current evidence and DivaByte inference.'
$researchPage.Controls.Add($researchPolicy)

$researchModeCombo.Add_SelectedIndexChanged({
 if($researchModeCombo.SelectedItem){
  Set-DivaByteResearchMode ([string]$researchModeCombo.SelectedItem)
  $chatStatus.Text=('DivaByte research mode saved locally: '+$script:DivaByteResearchMode+'. No Internet research occurs until the research engine is connected and this policy permits it.')
  $researchPolicy.Text='Research policy: '+$script:DivaByteResearchMode+'. Future Internet research must honor this setting, save source/date locally, and remain separate from current evidence and DivaByte inference.'
 }
})

Update-EvidenceList $logBrowser $reportRoot
Update-EvidenceList $resultBrowser $aiResultsRoot
Update-EvidenceList $researchBrowser $divaResearchRoot
Refresh-DivaByteMemory
Refresh-DivaByteRunbook

$settings.Controls.Clear()
Add-Setting 'Local settings and folders' ('Reports: '+$reportRoot+[Environment]::NewLine+'Preferences: '+$stateRoot+[Environment]::NewLine+'DivaByte: '+$aiRoot)
Add-Setting 'DivaByte core and research policy' ('Core: '+$(if($script:DivaByteCoreOnline){'ONLINE'}else{'UNAVAILABLE'})+[Environment]::NewLine+'Research mode: '+$script:DivaByteResearchMode+[Environment]::NewLine+'Offline remains fully functional. Internet research is optional and policy-controlled.')
$settingsLogs=Add-WorkspaceButton $settings 'Open diagnostic logs' {Start-Process explorer.exe -ArgumentList ('"'+$reportRoot+'"')}
$settingsRunbook=Add-WorkspaceButton $settings 'Open runbook folder' {Start-Process explorer.exe -ArgumentList ('"'+$runbookRoot+'"')}
$settingsAI=Add-WorkspaceButton $settings 'Open DivaByte folder' {Start-Process explorer.exe -ArgumentList ('"'+$aiRoot+'"')}
$settingsTest=Add-WorkspaceButton $settings 'Run application integrity check' {Start-Tool (Get-Tool 'application-integrity-self-test')}
$wrapOutput=New-Object Windows.Forms.CheckBox;$wrapOutput.Text='Wrap Run Center output lines';$wrapOutput.AutoSize=$true
$wrapPath=Join-Path $stateRoot 'wrap-output.txt'
$wrapOutput.Checked=if(Test-Path $wrapPath){(Get-Content $wrapPath -Raw).Trim() -eq 'True'}else{$true}
foreach($pane in $script:RunPanes){$pane.Output.WordWrap=$wrapOutput.Checked}
$wrapOutput.Add_CheckedChanged({foreach($pane in $script:RunPanes){$pane.Output.WordWrap=$wrapOutput.Checked};Set-Content -LiteralPath $wrapPath -Value $wrapOutput.Checked -Encoding UTF8})
[void]$settings.Controls.Add($wrapOutput)
[void]$settings.Controls.Add($platformButton)
