param([string]$ToolkitRoot='',[string]$AutoRunToolId='')



Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
if([string]::IsNullOrWhiteSpace($ToolkitRoot)){$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}else{$root=[IO.Path]::GetFullPath($ToolkitRoot).TrimEnd('\\')}
$appDirectory=Join-Path $root 'Windows\App'
$appScriptPath=Join-Path $appDirectory 'T3DFK-Windows.ps1'
if (-not ('RunCenterProcess' -as [type])) { Add-Type -Path (Join-Path $appDirectory 'RunCenterProcess.cs') }
[void][RunCenterBrand]::SetCurrentProcessExplicitAppUserModelID('T3CHNRD.DigitalFieldKit')
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$principal=New-Object Security.Principal.WindowsPrincipal($identity)
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
 $psExe=Join-Path $env:SystemRoot 'System32\\WindowsPowerShell\\v1.0\\powershell.exe'
 Start-Process -FilePath $psExe -ArgumentList ('-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$appScriptPath+'" -ToolkitRoot "'+$root+'" -AutoRunToolId "'+$AutoRunToolId+'"') -WorkingDirectory $root -Verb RunAs -WindowStyle Hidden | Out-Null
 return
}
$stateRoot = Join-Path $env:LOCALAPPDATA 'T3DFK'
$installedUnderProgramFiles = $false
$pf86=[Environment]::GetFolderPath('ProgramFilesX86')
foreach($pf in @($env:ProgramFiles,$pf86)){
 if($pf -and $root.StartsWith($pf,[StringComparison]::OrdinalIgnoreCase)){$installedUnderProgramFiles=$true}
}
if($installedUnderProgramFiles){
 $dataRoot = Join-Path $env:ProgramData 'T3DFK'
 $runbookRoot = Join-Path $dataRoot 'Runbook'
 $reportRoot = Join-Path $dataRoot 'Diagnostic-Reports'
}else{
 $dataRoot = $root
 $runbookRoot = Join-Path $root 'Runbook'
 $reportRoot = Join-Path $root 'Diagnostic-Reports'
}
New-Item -ItemType Directory -Force -Path $runbookRoot,$reportRoot,$stateRoot | Out-Null
if($installedUnderProgramFiles){
 $seedRunbook=Join-Path $root 'Runbook'
 if((Test-Path $seedRunbook) -and -not (Get-ChildItem $runbookRoot -Force -ErrorAction SilentlyContinue)){
  Copy-Item (Join-Path $seedRunbook '*') $runbookRoot -Recurse -Force -ErrorAction SilentlyContinue
 }
}
$env:TTK_TOOLKIT_ROOT=$root
$env:TTK_REPORT_DIR=$reportRoot
$env:TTK_RUNBOOK_DIR=$runbookRoot

$script:View = 'Favorites'
$script:Category = 'All Tools'
$script:FavoritesFile = Join-Path $stateRoot 'favorites.txt'
$script:RecentFile = Join-Path $stateRoot 'recent.txt'
$script:Favorites = @(if(Test-Path $script:FavoritesFile){Get-Content $script:FavoritesFile | Where-Object { $_ }})
$script:Recent = if(Test-Path $script:RecentFile){ @(Get-Content $script:RecentFile | Where-Object { $_ }) } else { @() }
$script:ExcludedRunbook = @('.venv312','ai_cowork','apps','deps.txt','static','templates','tmp-lo-test2','AB_Cluster.pdf','tmp_backend.html','tmp_backend_v.txt')

$manifestPath = Join-Path $root 'Windows\\Config\\tools.json'
if(-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)){[Windows.Forms.MessageBox]::Show('Tool manifest is missing: '+$manifestPath,'T3CHNRD Digital Field Kit','OK','Error')|Out-Null;exit 2}
$parsedToolCatalog = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$script:ToolCatalog = @()
foreach($toolEntry in $parsedToolCatalog){
 $script:ToolCatalog += $toolEntry
}
if($script:ToolCatalog.Count -eq 0){
 [Windows.Forms.MessageBox]::Show('The tool catalog loaded but contains zero tools.','T3CHNRD Digital Field Kit','OK','Error')|Out-Null
 exit 3
}
# Recover IDs concatenated by older scalar Favorites state, only on an exact match.
$favoritePattern=(@($script:ToolCatalog.id | Sort-Object Length -Descending | ForEach-Object {[regex]::Escape($_)}) -join '|')
$script:Favorites=@($(foreach($saved in $script:Favorites){
 $parts=[regex]::Matches($saved,$favoritePattern)
 if((@($parts | ForEach-Object Value) -join '') -eq $saved){foreach($part in $parts){$part.Value}}else{$saved}
}) | Select-Object -Unique)
$script:ReadyToolCount=@($script:ToolCatalog | Where-Object {$_.ready}).Count
$script:AdminDefault = $true

$navy=[Drawing.Color]::FromArgb(7,48,72)
$dark=[Drawing.Color]::FromArgb(3,22,31)
$paper=[Drawing.Color]::FromArgb(240,246,250)
$lime=[Drawing.Color]::FromArgb(181,225,55)
$text=[Drawing.Color]::FromArgb(18,40,74)
$sub=[Drawing.Color]::FromArgb(87,108,126)

$form=New-Object Windows.Forms.Form
$iconFile=Join-Path $root 'Windows\App\T3DFK.ico'
$form.Icon=New-Object Drawing.Icon($iconFile)
$form.Text='T3CHNRD Digital Field Kit - Windows'
$form.StartPosition='CenterScreen'
$form.Size=New-Object Drawing.Size(1500,900)
$form.MinimumSize=New-Object Drawing.Size(1050,700)
$form.BackColor=$paper
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.FormBorderStyle='Sizable'
$form.MaximizeBox=$true
$form.MinimizeBox=$true

$layout=New-Object Windows.Forms.TableLayoutPanel
$layout.Dock='Fill'
$layout.RowCount=4
$layout.ColumnCount=1
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle('Absolute',132)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle('Percent',100)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle('Absolute',0)))
[void]$layout.RowStyles.Add((New-Object Windows.Forms.RowStyle('Absolute',58)))
$form.Controls.Add($layout)

$header=New-Object Windows.Forms.Panel
$header.Dock='Fill'
$header.BackColor=[Drawing.Color]::FromArgb(10,82,118)
$layout.Controls.Add($header,0,0)

$orb=New-Object Windows.Forms.Panel
$orb.Size=New-Object Drawing.Size(72,72)
$orb.Location=New-Object Drawing.Point(28,14)
$orb.BackColor=[Drawing.Color]::FromArgb(40,145,210)
$header.Controls.Add($orb)
foreach($r in @(
 @(15,16,17,16),@(36,14,17,18),@(14,37,18,17),@(36,37,18,17)
)){
 $p=New-Object Windows.Forms.Panel
 $p.Location=New-Object Drawing.Point($r[0],$r[1])
 $p.Size=New-Object Drawing.Size($r[2],$r[3])
 $p.BackColor=[Drawing.Color]::FromArgb(80,185,245)
 $orb.Controls.Add($p)
}

$title=New-Object Windows.Forms.Label
$title.Text='T3CHNRD Digital Field Kit'
$title.Font=New-Object Drawing.Font('Segoe UI',23,[Drawing.FontStyle]::Bold)
$title.ForeColor='White'
$title.AutoSize=$true
$title.Location=New-Object Drawing.Point(118,18)
$header.Controls.Add($title)

$tag=New-Object Windows.Forms.Label
$tag.Text='Diagnose   |   Repair   |   Optimize   |   Deploy'
$tag.ForeColor=[Drawing.Color]::FromArgb(220,241,251)
$tag.AutoSize=$true
$tag.Location=New-Object Drawing.Point(121,58)
$header.Controls.Add($tag)

$brand=New-Object Windows.Forms.Label
$brand.Text='Windows Edition' + [Environment]::NewLine + 'Portable / Installed'
$brand.ForeColor='White'
$brand.TextAlign='TopRight'
$brand.Size=New-Object Drawing.Size(260,46)
$brand.Anchor='Top,Right'
$brand.Location=New-Object Drawing.Point(1200,18)
$header.Controls.Add($brand)

$tabsPanel=New-Object Windows.Forms.Panel
$tabsPanel.Dock='Bottom'
$tabsPanel.Height=44
$tabsPanel.BackColor=$dark
$header.Controls.Add($tabsPanel)

$tabs=@{}
$x=16
foreach($n in @('Favorites','Tools','Recent','Runbook','Settings')){
 $b=New-Object Windows.Forms.Button
 $b.Text=if($n -eq 'Runbook'){'HELP / RUNBOOK'}else{$n.ToUpperInvariant()}
 $b.Size=New-Object Drawing.Size(124,36)
 $b.Location=New-Object Drawing.Point($x,4)
 $b.FlatStyle='Flat'
 $b.FlatAppearance.BorderSize=0
 $b.BackColor=[Drawing.Color]::FromArgb(35,52,62)
 $b.ForeColor='White'
 $b.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
 $b.Tag=$n
 $b.Add_Click({
   param($control)
    if([string]$control.Tag -eq 'Log Files'){Start-Process explorer.exe -ArgumentList ('"'+$reportRoot+'"');return}
    $script:View=[string]$control.Tag
  if($script:View -eq 'Tools'){$script:Category='All Tools'}
  Update-View
 })
 $tabsPanel.Controls.Add($b)
 $tabs[$n]=$b
 $x+=130
}

$search=New-Object Windows.Forms.TextBox
$search.Size=New-Object Drawing.Size(320,30)
$search.Anchor='Top,Right'
$search.Location=New-Object Drawing.Point(1110,7)
$search.Font=New-Object Drawing.Font('Segoe UI',10)
$tabsPanel.Controls.Add($search)
$search.Add_TextChanged({
 param($control)
 if(-not [string]::IsNullOrWhiteSpace($control.Text)){
  $script:View='Tools'
  $script:Category='All Tools'
 }
 if($script:View -notin @('Runbook','Settings')){Update-View}
})

$body=New-Object Windows.Forms.TableLayoutPanel
$body.Dock='Fill'
$body.ColumnCount=2
$body.RowCount=1
[void]$body.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',230)))
[void]$body.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent',100)))
$layout.Controls.Add($body,0,1)

$side=New-Object Windows.Forms.Panel
$side.Dock='Fill'
$side.BackColor=[Drawing.Color]::FromArgb(13,49,71)
$body.Controls.Add($side,0,0)

$sideFlow=New-Object Windows.Forms.FlowLayoutPanel
$sideFlow.Dock='Fill'
$sideFlow.FlowDirection='TopDown'
$sideFlow.WrapContents=$false
$sideFlow.AutoScroll=$true
$sideFlow.Padding=New-Object Windows.Forms.Padding(10,14,10,10)
$side.Controls.Add($sideFlow)

$cats=@{}
foreach($n in @('All Tools','Diagnostics','Repair','Optimization','Security','Network','Deployment','System Management')){
 $b=New-Object Windows.Forms.Button
 $b.Text=if($n -eq 'Runbook'){'Help / Runbook'}else{$n}
 $b.Size=New-Object Drawing.Size(196,42)
 $b.FlatStyle='Flat'
 $b.FlatAppearance.BorderSize=0
 $b.BackColor=[Drawing.Color]::FromArgb(20,58,80)
 $b.ForeColor=[Drawing.Color]::FromArgb(225,238,245)
 $b.TextAlign='MiddleLeft'
 $b.Padding=New-Object Windows.Forms.Padding(12,0,0,0)
 $b.Tag=$n
 $b.Add_Click({
   param($control)
  $script:View='Tools'
    $script:Category=[string]$control.Tag
  Update-View
 })
 $sideFlow.Controls.Add($b)
 $cats[$n]=$b
}
$sep=New-Object Windows.Forms.Label
$sep.Width=190
$sep.Height=12
$sep.BorderStyle='Fixed3D'
$sideFlow.Controls.Add($sep)
foreach($n in @('Log Files','AI Workspace','Favorites','Recent','Runbook','Settings')){
 $b=New-Object Windows.Forms.Button
 $b.Text=if($n -eq 'Runbook'){'Help / Runbook'}else{$n}
 $b.Size=New-Object Drawing.Size(196,42)
 $b.FlatStyle='Flat'
 $b.FlatAppearance.BorderSize=0
 $b.BackColor=[Drawing.Color]::FromArgb(20,58,80)
 $b.ForeColor=[Drawing.Color]::FromArgb(225,238,245)
 $b.TextAlign='MiddleLeft'
 $b.Padding=New-Object Windows.Forms.Padding(12,0,0,0)
 $b.Tag=$n
 $b.Add_Click({
   param($control)
    if([string]$control.Tag -eq 'Log Files'){Start-Process explorer.exe -ArgumentList ('"'+$reportRoot+'"');return}
    $script:View=[string]$control.Tag
  Update-View
 })
 $sideFlow.Controls.Add($b)
}

$content=New-Object Windows.Forms.TableLayoutPanel
$content.Dock='Fill'
$content.RowCount=2
$content.ColumnCount=1
[void]$content.RowStyles.Add((New-Object Windows.Forms.RowStyle('Absolute',84)))
[void]$content.RowStyles.Add((New-Object Windows.Forms.RowStyle('Percent',100)))
$content.Padding=New-Object Windows.Forms.Padding(18,12,18,10)
$content.BackColor=$paper
$body.Controls.Add($content,1,0)

$pageHead=New-Object Windows.Forms.Panel
$pageHead.Dock='Fill'
$pageHead.BackColor=$paper
$content.Controls.Add($pageHead,0,0)

$pageTitle=New-Object Windows.Forms.Label
$pageTitle.Font=New-Object Drawing.Font('Segoe UI',20,[Drawing.FontStyle]::Bold)
$pageTitle.ForeColor=$text
$pageTitle.AutoSize=$true
$pageTitle.Location=New-Object Drawing.Point(0,4)
$pageHead.Controls.Add($pageTitle)

$pageSub=New-Object Windows.Forms.Label
$pageSub.ForeColor=$sub
$pageSub.AutoSize=$true
$pageSub.Location=New-Object Drawing.Point(2,42)
$pageHead.Controls.Add($pageSub)

$info=New-Object Windows.Forms.Label
$info.Anchor='Top,Right'
$info.Size=New-Object Drawing.Size(355,58)
$info.Location=New-Object Drawing.Point(760,4)
$info.BackColor=[Drawing.Color]::FromArgb(231,243,250)
$info.ForeColor=[Drawing.Color]::FromArgb(50,79,103)
$info.BorderStyle='FixedSingle'
$info.Padding=New-Object Windows.Forms.Padding(12,7,8,4)
$info.Text=('Loaded {0} tools ({1} ready).' -f $script:ToolCatalog.Count,$script:ReadyToolCount) + [Environment]::NewLine + 'Select a tool to run it in the embedded Run Center.'
$pageHead.Controls.Add($info)

$viewHost=New-Object Windows.Forms.Panel
$viewHost.Dock='Fill'
$viewHost.BackColor=$paper
$content.Controls.Add($viewHost,0,1)

$cards=New-Object Windows.Forms.FlowLayoutPanel
$cards.Dock='Fill'
$cards.AutoScroll=$true
$cards.WrapContents=$true
$cards.FlowDirection='LeftToRight'
$cards.BackColor=$paper
$viewHost.Controls.Add($cards)

$runbook=New-Object Windows.Forms.TableLayoutPanel
$runbook.Dock='Fill'
$runbook.Visible=$false
$runbook.RowCount=2
$runbook.ColumnCount=2
[void]$runbook.RowStyles.Add((New-Object Windows.Forms.RowStyle('Absolute',48)))
[void]$runbook.RowStyles.Add((New-Object Windows.Forms.RowStyle('Percent',100)))
[void]$runbook.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',340)))
[void]$runbook.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent',100)))
$viewHost.Controls.Add($runbook)

$rbTools=New-Object Windows.Forms.FlowLayoutPanel
$rbTools.Dock='Fill'
$rbTools.Padding=New-Object Windows.Forms.Padding(4)
$rbTools.WrapContents=$false
$runbook.SetColumnSpan($rbTools,2)
$runbook.Controls.Add($rbTools,0,0)

$rbSearch=New-Object Windows.Forms.TextBox
$rbSearch.Width=280
$rbTools.Controls.Add($rbSearch)
$rbAdd=New-Object Windows.Forms.Button
$rbAdd.Text='ADD DOCUMENT'
$rbAdd.AutoSize=$true
$rbTools.Controls.Add($rbAdd)
$rbOpen=New-Object Windows.Forms.Button
$rbOpen.Text='OPEN FOLDER'
$rbOpen.AutoSize=$true
$rbTools.Controls.Add($rbOpen)
$rbRefresh=New-Object Windows.Forms.Button
$rbRefresh.Text='REFRESH'
$rbRefresh.AutoSize=$true
$rbTools.Controls.Add($rbRefresh)

$rbList=New-Object Windows.Forms.ListBox
$rbList.Dock='Fill'
$runbook.Controls.Add($rbList,0,1)
$rbView=New-Object Windows.Forms.RichTextBox
$rbView.Dock='Fill'
$rbView.ReadOnly=$true
$rbView.BackColor='White'
$runbook.Controls.Add($rbView,1,1)

$settings=New-Object Windows.Forms.FlowLayoutPanel
$settings.Dock='Fill'
$settings.Visible=$false
$settings.FlowDirection='TopDown'
$settings.WrapContents=$false
$settings.AutoScroll=$true
$viewHost.Controls.Add($settings)

function Add-Setting([string]$Heading,[string]$Message){
 $p=New-Object Windows.Forms.Panel
 $p.Width=900
 $p.Height=115
 $p.BackColor='White'
 $p.BorderStyle='FixedSingle'
 $p.Margin=New-Object Windows.Forms.Padding(0,0,0,12)
 $h=New-Object Windows.Forms.Label
 $h.Text=$Heading
 $h.Font=New-Object Drawing.Font('Segoe UI',14,[Drawing.FontStyle]::Bold)
 $h.ForeColor=$text
 $h.AutoSize=$true
 $h.Location=New-Object Drawing.Point(18,14)
 $p.Controls.Add($h)
 $m=New-Object Windows.Forms.Label
 $m.Text=$Message
 $m.ForeColor=$sub
 $m.Size=New-Object Drawing.Size(845,55)
 $m.Location=New-Object Drawing.Point(20,48)
 $p.Controls.Add($m)
 $settings.Controls.Add($p)
}
Add-Setting 'Toolkit Settings' 'Portable-first Windows application. The final native build will retain this same navigation, card layout, Run Center, Runbook workflow and visual identity.'
Add-Setting 'Cross-platform Architecture' 'Windows is completed first. macOS Intel and macOS Apple Silicon are separate native apps sharing the same source and UX where practical.'
Add-Setting 'Current Gate' 'ACTIVE PHASE: Windows stabilization. Nothing advances to the next major phase until Windows is complete and field-validated.'

$platformButton=New-Object Windows.Forms.Button
$platformButton.Text='PLATFORM FALLBACK / START SCREEN'
$platformButton.Width=290
$platformButton.Height=38
$settings.Controls.Add($platformButton)

$runner=New-Object Windows.Forms.Panel
$runner.Dock='Fill'
$runner.BackColor=[Drawing.Color]::FromArgb(6,17,23)
$layout.Controls.Add($runner,0,2)

 . (Join-Path $appDirectory 'RunCenterUI.ps1')
$runnerTabs=New-Object Windows.Forms.TabControl
$runnerTabs.Dock='Fill'
$runnerTabs.Font=New-Object Drawing.Font('Segoe UI',10)
$runner.Controls.Add($runnerTabs)
$script:RunnerHeight=340
$script:RunnerDragging=$false
$runnerGrip=New-Object Windows.Forms.Label
$runnerGrip.Dock='Top';$runnerGrip.Height=24;$runnerGrip.Text='Drag here to resize Run Center'
$runnerGrip.TextAlign='MiddleCenter';$runnerGrip.ForeColor='White';$runnerGrip.BackColor=$navy
$runnerGrip.Cursor=[Windows.Forms.Cursors]::HSplit
$runner.Controls.Add($runnerGrip)
function Set-RunnerHeight([int]$Height){
 $maximum=[Math]::Max(180,$layout.ClientSize.Height-132-58-120)
 $script:RunnerHeight=[Math]::Max(180,[Math]::Min($Height,$maximum))
 $layout.RowStyles[2].Height=$script:RunnerHeight
}
$runnerGrip.Add_MouseDown({param($sender,$e)
 if($e.Button -eq [Windows.Forms.MouseButtons]::Left){
  $script:RunnerDragging=$true;$script:RunnerDragY=[Windows.Forms.Cursor]::Position.Y
  $script:RunnerDragHeight=$script:RunnerHeight;$runnerGrip.Capture=$true
 }
})
$runnerGrip.Add_MouseMove({
 if($script:RunnerDragging){Set-RunnerHeight ($script:RunnerDragHeight+$script:RunnerDragY-[Windows.Forms.Cursor]::Position.Y)}
})
$runnerGrip.Add_MouseUp({$script:RunnerDragging=$false;$runnerGrip.Capture=$false})
$runnerGrip.Add_MouseCaptureChanged({if(-not $runnerGrip.Capture){$script:RunnerDragging=$false}})
$form.Add_Resize({if($layout.RowStyles[2].Height -gt 0){Set-RunnerHeight $script:RunnerHeight}})

$script:RunPanes=@((New-RunPane 1),(New-RunPane 2))
foreach($pane in $script:RunPanes){[void]$runnerTabs.TabPages.Add($pane.Page)}
$footer=New-Object Windows.Forms.Panel
$footer.Dock='Fill'
$footer.BackColor=$navy
$layout.Controls.Add($footer,0,3)
$status=New-Object Windows.Forms.Label
$status.Text='●  READY'
$status.ForeColor='White'
$status.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$status.AutoSize=$true
$status.Location=New-Object Drawing.Point(18,19)
$footer.Controls.Add($status)
$sys=New-Object Windows.Forms.Label
$sys.Text='Computer: ' + $env:COMPUTERNAME + '    User: ' + $env:USERNAME
$sys.ForeColor=[Drawing.Color]::FromArgb(215,232,241)
$sys.AutoSize=$true
$sys.Location=New-Object Drawing.Point(390,20)
$footer.Controls.Add($sys)
$platform=New-Object Windows.Forms.Label
$platform.Text='WINDOWS | AUTO-DETECTED'
$platform.ForeColor=$lime
$platform.AutoSize=$true
$platform.Anchor='Top,Right'
$platform.Location=New-Object Drawing.Point(1180,20)
$footer.Controls.Add($platform)

function Save-State {
 Set-Content -LiteralPath $script:FavoritesFile -Value @($script:Favorites) -Encoding UTF8
 @($script:Recent | Select-Object -First 20) | Set-Content -LiteralPath $script:RecentFile -Encoding UTF8
}
function Get-Tool([string]$Id){ $script:ToolCatalog | Where-Object Id -eq $Id | Select-Object -First 1 }
function Add-Recent([string]$Id){
 $script:Recent=@($Id)+@($script:Recent | Where-Object {$_ -ne $Id})
 Save-State
}
function Set-Favorite {
 [CmdletBinding(SupportsShouldProcess=$true)]
 param([string]$Id)
 if($script:Favorites -contains $Id){$script:Favorites=@($script:Favorites | Where-Object {$_ -ne $Id})}
 else{$script:Favorites=@($script:Favorites)+@($Id)}
 Save-State
 Show-ToolCard
}
function Write-Run([string]$Line,$Pane=$null){
 if(-not $Pane){$Pane=$runnerTabs.SelectedTab.Tag}
 $Pane.Output.AppendText($Line+[Environment]::NewLine)
 $Pane.Output.SelectionStart=$Pane.Output.TextLength
 $Pane.Output.ScrollToCaret()
}
function Test-AppAdministrator {
 try{
  $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
  $principal=New-Object Security.Principal.WindowsPrincipal($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 }catch{return $false}
}
function Start-ElevatedToolApp {
 [CmdletBinding(SupportsShouldProcess=$true)]
 param($Tool)
 $psExe=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
 $appPath=Join-Path $root 'Windows\App\T3DFK-Windows.ps1'
 $argList='-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "'+$appPath+'" -ToolkitRoot "'+$root+'" -AutoRunToolId "'+[string]$Tool.Id+'"'
 try{
  if($PSCmdlet.ShouldProcess($Tool.Name,'Start elevated toolkit')){
   Start-Process -FilePath $psExe -ArgumentList $argList -WorkingDirectory $root -Verb RunAs -WindowStyle Hidden | Out-Null
  }
 }catch{
  [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Administrator launch cancelled or failed','OK','Error')|Out-Null
 }
}
function Show-Runner([string]$Name,[bool]$AllowInput,$Pane){
 Set-RunnerHeight $script:RunnerHeight
 $runnerTabs.SelectedTab=$Pane.Page
 $Pane.Page.Text=$Name
 $Pane.State.Text='Starting...'
 $Pane.Output.Clear();$Pane.Input.Clear();$Pane.InputPanel.Visible=$AllowInput
 $Pane.Cancel.Enabled=$false;$Pane.Cancelled=$false
}
function Hide-Runner{$layout.RowStyles[2].Height=0}

function Show-CorpNetworkDiagnosticOptions {
 $dialog=New-Object Windows.Forms.Form
 $dialog.Text='Corporate Network Diagnostic - Run Options'
 $dialog.StartPosition='CenterParent'
 $dialog.Size=New-Object Drawing.Size(680,560)
 $dialog.MinimumSize=New-Object Drawing.Size(680,560)
 $dialog.MaximumSize=New-Object Drawing.Size(680,560)
 $dialog.FormBorderStyle='FixedDialog'
 $dialog.MaximizeBox=$false
 $dialog.MinimizeBox=$false
 $dialog.ShowInTaskbar=$false

 $title=New-Object Windows.Forms.Label
 $title.Text='Choose how to run the Corporate Network Diagnostic'
 $title.Font=New-Object Drawing.Font('Segoe UI',13,[Drawing.FontStyle]::Bold)
 $title.AutoSize=$true
 $title.Location=New-Object Drawing.Point(20,18)
 $dialog.Controls.Add($title)

 $intro=New-Object Windows.Forms.Label
 $intro.Text='These options match README-CorpNetworkDiagnostic.md. The selected mode will run inside the Field Kit Run Center.'
 $intro.Size=New-Object Drawing.Size(620,44)
 $intro.Location=New-Object Drawing.Point(20,52)
 $dialog.Controls.Add($intro)

 $modeLabel=New-Object Windows.Forms.Label
 $modeLabel.Text='Run mode:'
 $modeLabel.AutoSize=$true
 $modeLabel.Location=New-Object Drawing.Point(20,104)
 $dialog.Controls.Add($modeLabel)

 $mode=New-Object Windows.Forms.ComboBox
 $mode.DropDownStyle='DropDownList'
 $mode.Size=New-Object Drawing.Size(620,28)
 $mode.Location=New-Object Drawing.Point(20,126)
 [void]$mode.Items.Add('Full Network Diagnostic')
 [void]$mode.Items.Add('LAN Cable Connected - Flush DNS / Release / Renew')
 [void]$mode.Items.Add('Force a Specific LAN Adapter')
 [void]$mode.Items.Add('Wi-Fi Diagnostic Only')
 [void]$mode.Items.Add('Force a Specific Wi-Fi Adapter')
 [void]$mode.Items.Add('LAN Diagnostic Only')
 [void]$mode.Items.Add('Current-State Snapshot')
 [void]$mode.Items.Add('Full Diagnostic + LAN Renew')
 $mode.SelectedIndex=0
 $dialog.Controls.Add($mode)

 $detail=New-Object Windows.Forms.Label
 $detail.Size=New-Object Drawing.Size(620,84)
 $detail.Location=New-Object Drawing.Point(20,164)
 $detail.BorderStyle='FixedSingle'
 $detail.Padding=New-Object Windows.Forms.Padding(8)
 $dialog.Controls.Add($detail)

 $lanLabel=New-Object Windows.Forms.Label
 $lanLabel.Text='LAN adapter alias (only required for "Force a Specific LAN Adapter"; example: Ethernet):'
 $lanLabel.AutoSize=$true
 $lanLabel.Location=New-Object Drawing.Point(20,260)
 $dialog.Controls.Add($lanLabel)

 $lanAlias=New-Object Windows.Forms.TextBox
 $lanAlias.Size=New-Object Drawing.Size(620,26)
 $lanAlias.Location=New-Object Drawing.Point(20,282)
 $dialog.Controls.Add($lanAlias)

 $wifiLabel=New-Object Windows.Forms.Label
 $wifiLabel.Text='Wi-Fi adapter alias (only required for "Force a Specific Wi-Fi Adapter"; example: Wi-Fi):'
 $wifiLabel.AutoSize=$true
 $wifiLabel.Location=New-Object Drawing.Point(20,320)
 $dialog.Controls.Add($wifiLabel)

 $wifiAlias=New-Object Windows.Forms.TextBox
 $wifiAlias.Size=New-Object Drawing.Size(620,26)
 $wifiAlias.Location=New-Object Drawing.Point(20,342)
 $dialog.Controls.Add($wifiAlias)

 $discovery=New-Object Windows.Forms.CheckBox
 $discovery.Text='Check / enable Network Discovery for Domain and Private profiles'
 $discovery.Checked=$true
 $discovery.AutoSize=$true
 $discovery.Location=New-Object Drawing.Point(20,382)
 $dialog.Controls.Add($discovery)

 $note=New-Object Windows.Forms.Label
 $note.Text='Network Discovery is never enabled on Public profiles. AP / MultiAP / Client Isolation is not changed by this script.'
 $note.Size=New-Object Drawing.Size(620,42)
 $note.Location=New-Object Drawing.Point(20,410)
 $dialog.Controls.Add($note)

 $runButton=New-Object Windows.Forms.Button
 $runButton.Text='RUN'
 $runButton.Size=New-Object Drawing.Size(120,34)
 $runButton.Location=New-Object Drawing.Point(390,468)
 $runButton.DialogResult=[Windows.Forms.DialogResult]::OK
 $dialog.AcceptButton=$runButton
 $dialog.Controls.Add($runButton)

 $cancelButton=New-Object Windows.Forms.Button
 $cancelButton.Text='CANCEL'
 $cancelButton.Size=New-Object Drawing.Size(120,34)
 $cancelButton.Location=New-Object Drawing.Point(520,468)
 $cancelButton.DialogResult=[Windows.Forms.DialogResult]::Cancel
 $dialog.CancelButton=$cancelButton
 $dialog.Controls.Add($cancelButton)

 $descriptions=@(
  'Collect the complete LAN/Wi-Fi/IP/DNS/domain/WLAN diagnostic picture. Does not release/renew the LAN address unless Full Diagnostic + LAN Renew is selected.',
  'Use after connecting the Ethernet cable. Runs flush DNS, releases and renews the detected wired adapter, then captures ipconfig /all.',
  'Same LAN renew workflow, but forces the exact wired adapter alias you enter below.',
  'Focus on wireless adapter, driver, profiles, visible BSSIDs, WLAN AutoConfig events and wlanreport.',
  'Same Wi-Fi diagnostic, but forces the exact wireless adapter alias you enter below.',
  'Focus on the wired adapter without performing DHCP release/renew.',
  'Capture the current network state without intentionally running the LAN DHCP renew sequence.',
  'Run the full diagnostic collection and also perform the wired LAN flush/release/renew sequence. Connect the LAN cable first.'
 )
 $updateDetail={
  $detail.Text=$descriptions[$mode.SelectedIndex]
  $lanAlias.Enabled=($mode.SelectedIndex -eq 2)
  $wifiAlias.Enabled=($mode.SelectedIndex -eq 4)
 }
 $mode.Add_SelectedIndexChanged($updateDetail)
 & $updateDetail

 while($true){
  $result=$dialog.ShowDialog($form)
  if($result -ne [Windows.Forms.DialogResult]::OK){
   $dialog.Dispose()
   return [pscustomobject]@{Cancelled=$true;Args=@()}
  }
  if($mode.SelectedIndex -eq 2 -and [string]::IsNullOrWhiteSpace($lanAlias.Text)){
   [Windows.Forms.MessageBox]::Show('Enter the LAN adapter alias, for example Ethernet.','LAN adapter required','OK','Warning')|Out-Null
   continue
  }
  if($mode.SelectedIndex -eq 4 -and [string]::IsNullOrWhiteSpace($wifiAlias.Text)){
   [Windows.Forms.MessageBox]::Show('Enter the Wi-Fi adapter alias, for example Wi-Fi.','Wi-Fi adapter required','OK','Warning')|Out-Null
   continue
  }
  break
 }

 $args=@()
 switch($mode.SelectedIndex){
  0 { $args=@('-Action','All') }
  1 { $args=@('-Action','RenewLAN') }
  2 { $args=@('-Action','RenewLAN','-LanAlias',$lanAlias.Text.Trim()) }
  3 { $args=@('-Action','WiFi') }
  4 { $args=@('-Action','WiFi','-WifiAlias',$wifiAlias.Text.Trim()) }
  5 { $args=@('-Action','LAN') }
  6 { $args=@('-Action','Snapshot') }
  7 { $args=@('-Action','All','-RenewLAN') }
 }
 if(-not $discovery.Checked){
  $args+=@('-EnableNetworkDiscovery','$false')
 }
 $dialog.Dispose()
 return [pscustomobject]@{Cancelled=$false;Args=@($args)}
}

function Start-Tool {
 [CmdletBinding(SupportsShouldProcess=$true)]
 param($tool)
 $pane=Get-FreeRunPane
 if(-not $pane){
  Set-RunnerHeight $script:RunnerHeight
  [Windows.Forms.MessageBox]::Show('Two tools are already running. Wait for one to finish or cancel it before starting another.','Run Center busy','OK','Information')|Out-Null
  return
 }
 Add-Recent $tool.Id
 if(-not $tool.Ready){
  [Windows.Forms.MessageBox]::Show($(if($tool.PSObject.Properties.Name -contains 'unavailableReason'){$tool.unavailableReason}else{'This tool is unavailable. See docs/ARCHIVE-INTEGRATION.md for its requirements.'}),'Tool requirements','OK','Information') | Out-Null
  return
 }
 if($tool.Risk -ne 'ReadOnly'){
  if([Windows.Forms.MessageBox]::Show('This tool can change system configuration. Continue?',$tool.Name,'YesNo','Warning') -ne 'Yes'){return}
 }
 $path=Join-Path $root $tool.Path
 if(-not(Test-Path $path)){[Windows.Forms.MessageBox]::Show('Missing script: '+$path,'Tool unavailable','OK','Error')|Out-Null;return}
 $scriptText=Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue
 $launchInspectionText=$scriptText
 $dependencyPattern='(?im)^\s*\.\s+\(Join-Path\s+\$PSScriptRoot\s+[''"]([^''"]+\.ps1)[''"]\)'
 foreach($match in [regex]::Matches($scriptText,$dependencyPattern)){
  $depPath=Join-Path (Split-Path -Parent $path) $match.Groups[1].Value
  if(Test-Path -LiteralPath $depPath -PathType Leaf){
   $launchInspectionText += [Environment]::NewLine + (Get-Content -LiteralPath $depPath -Raw -ErrorAction SilentlyContinue)
  }
 }
 $needsAdmin=($launchInspectionText -match '(?im)^\s*#Requires\s+-RunAsAdministrator\b') -or
             ($launchInspectionText -match '(?i)Ensure-TaskAdmin') -or
             ($launchInspectionText -match '(?i)Test-IsAdmin(?:istrator)?') -or
             ($launchInspectionText -match '(?i)IsInRole[^\r\n]*Administrator') -or
             ($launchInspectionText -match '(?i)Administrator (?:rights|privileges) are required') -or
             ($launchInspectionText -match '(?i)requires administrator rights')
 $needsInteractive=[bool]$tool.interactive -or
                   ($launchInspectionText -match '(?i)\bRead-Host\b|PromptForChoice')
 $toolArgs=@()
 if($tool.PSObject.Properties.Name -contains 'args' -and $tool.args){$toolArgs=@($tool.args)}
 $explicitAdmin=($tool.PSObject.Properties.Name -contains 'requiresAdmin') -and [bool]$tool.requiresAdmin
 $mustRunElevated = $script:AdminDefault -or $needsAdmin -or $explicitAdmin
 if($mustRunElevated -and -not (Test-AppAdministrator)){
  Start-ElevatedToolApp $tool
  return
 }
 if(($tool.PSObject.Properties.Name -contains 'preRunDialog') -and $tool.preRunDialog -eq 'CorpNetworkDiagnostic'){
  $selection=Show-CorpNetworkDiagnosticOptions
  if($selection.Cancelled){return}
  $toolArgs=@($selection.Args)
 }
 Show-Runner $tool.Name $needsInteractive $pane
 $pane.State.Text='RUNNING'
 $pane.Cancel.Enabled=$true
 $logDir=Join-Path $reportRoot 'AppLogs'
 New-Item -ItemType Directory -Force -Path $logDir | Out-Null
 $pane.Log=Join-Path $logDir (((Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+$pane.Number)+'-'+($tool.Name -replace '[^A-Za-z0-9._-]','_')+'.log')
 Set-Content $pane.Log ('Tool: '+$tool.Name)
 Write-Run ('Launching '+$tool.Name+' as Administrator...')
 $psi=New-Object Diagnostics.ProcessStartInfo
 $psi.FileName=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
 $argumentJson=ConvertTo-Json -InputObject @($toolArgs) -Compress
 $encodedArguments=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($argumentJson))
 $hostScript=Join-Path $appDirectory 'Invoke-RunCenterScript.ps1'
 $psi.Arguments='-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "'+$hostScript+'" -TargetScript "'+$path+'" -ArgumentsBase64 '+$encodedArguments
 $psi.WorkingDirectory=$root
 $psi.UseShellExecute=$false
 $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true
 $psi.RedirectStandardError=$true
 $psi.RedirectStandardInput=$true
 $psi.StandardInputEncoding=New-Object Text.UTF8Encoding($false)
 $psi.EnvironmentVariables['TTK_TOOLKIT_ROOT']=$root
 $psi.EnvironmentVariables['TTK_REPORT_DIR']=$reportRoot
 $psi.EnvironmentVariables['TTK_RUNBOOK_DIR']=$runbookRoot
 try {
  $pane.Capture=New-Object RunCenterProcess($psi)
  $pane.Capture.Start()
  $pane.Process=$pane.Capture.Process
  $status.Text='●  RUNNING'
  Write-Run ('PID: '+$pane.Process.Id)
  $runnerTimer.Start()
 } catch {
  Write-Run ('ERROR: '+$_.Exception.Message)
  $pane.State.Text='FAILED TO START'
  $pane.Cancel.Enabled=$false
  $pane.InputPanel.Visible=$false
  $pane.Process=$null
  if($pane.Capture){$pane.Capture.Dispose();$pane.Capture=$null}
 }
}

$runnerTimer=New-Object Windows.Forms.Timer
$runnerTimer.Interval=100
$runnerTimer.Add_Tick({Update-RunPanes})
$status.Cursor='Hand'
$status.Add_Click({Set-RunnerHeight $script:RunnerHeight})
$form.Add_FormClosing({foreach($pane in $script:RunPanes){Stop-RunPane $pane};$runnerTimer.Stop()})
function Add-Card($tool){
 $p=New-Object Windows.Forms.Panel
 $p.Width=365
 $p.Height=142
 $p.BackColor='White'
 $p.BorderStyle='FixedSingle'
 $p.Margin=New-Object Windows.Forms.Padding(0,0,12,12)
 $name=New-Object Windows.Forms.Label
 $name.Text=$tool.Name
 $name.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
 $name.ForeColor=$text
 $name.Size=New-Object Drawing.Size(285,25)
 $name.Location=New-Object Drawing.Point(18,17)
 $p.Controls.Add($name)
 $desc=New-Object Windows.Forms.Label
 $desc.Text=$tool.Description
 $desc.ForeColor=$sub
 $desc.Size=New-Object Drawing.Size(320,55)
 $desc.Location=New-Object Drawing.Point(18,50)
 $p.Controls.Add($desc)
 $risk=New-Object Windows.Forms.Label
 $risk.Text=if($tool.Ready){$tool.Risk.ToUpperInvariant()}else{'REQUIRES CONFIGURATION'}
 $risk.AutoSize=$true
 $risk.Location=New-Object Drawing.Point(18,115)
 $risk.Font=New-Object Drawing.Font('Segoe UI',7.5,[Drawing.FontStyle]::Bold)
 $risk.ForeColor=if($tool.Ready){[Drawing.Color]::SlateGray}else{[Drawing.Color]::DarkOrange}
 $p.Controls.Add($risk)
 $star=New-Object Windows.Forms.Button
 $star.Text=if($script:Favorites -contains $tool.Id){'★'}else{'☆'}
 $star.Font=New-Object Drawing.Font('Segoe UI Symbol',13)
 $star.FlatStyle='Flat'
 $star.FlatAppearance.BorderSize=0
 $star.BackColor='White'
 $star.ForeColor=[Drawing.Color]::Goldenrod
 $star.Size=New-Object Drawing.Size(36,32)
 $star.Location=New-Object Drawing.Point(320,4)
 $star.Tag=$tool.Id
 $star.Add_Click({
    param($control)
    Set-Favorite ([string]$control.Tag)
 })
 $p.Controls.Add($star)
 $help=New-Object Windows.Forms.Button
 $help.Text='Help';$help.Size=New-Object Drawing.Size(58,26)
 $help.Location=New-Object Drawing.Point(298,110);$help.Tag=$tool.Id
 $help.Add_Click({param($control) Show-ToolHelp ([string]$control.Tag)})
 $p.Controls.Add($help)

 foreach($c in @($p,$name,$desc,$risk)){
  $c.Cursor='Hand'
  $c.Tag=$tool
  $c.Add_Click({
     param($control)
     Start-Tool $control.Tag
  })
 }
 $cards.Controls.Add($p)
}

function Show-ToolCard{
 [CmdletBinding()]
 param()
 $cards.SuspendLayout()
 $cards.Controls.Clear()
 $q=$search.Text.Trim()
 $items=@($script:ToolCatalog)
 if($script:View -eq 'Favorites'){$items=@($script:Favorites | ForEach-Object {Get-Tool $_} | Where-Object {$_})}
 elseif($script:View -eq 'Recent'){$items=@($script:Recent | ForEach-Object {Get-Tool $_} | Where-Object {$_})}
 elseif(-not $q -and $script:View -eq 'Tools' -and $script:Category -ne 'All Tools'){$items=@($items | Where-Object Category -eq $script:Category)}
 if($q){$items=@($items | Where-Object {(($_.Name+' '+$_.Description+' '+$_.Category) -like ('*'+$q+'*'))})}
 foreach($t in $items){Add-Card $t}
 if($items.Count -eq 0){
  $e=New-Object Windows.Forms.Label
  $e.Text=if($script:View -eq 'Favorites'){'No favorites yet. Use the star on a tool card to add one.'}else{'No matching tools.'}
  $e.AutoSize=$true
  $e.ForeColor=$sub
  $e.Font=New-Object Drawing.Font('Segoe UI',11)
  $e.Margin=New-Object Windows.Forms.Padding(10,18,0,0)
  $cards.Controls.Add($e)
 }
 $cards.ResumeLayout()
}

function Update-RunbookList{
 [CmdletBinding(SupportsShouldProcess=$true)]
 param()
 $rbList.Items.Clear()
 $helpRoot=Join-Path $root 'Windows\Help'
 if(Test-Path $helpRoot){Get-ChildItem $helpRoot -File -Filter '*.md' | Sort-Object Name | ForEach-Object {[void]$rbList.Items.Add($_)}}
 if(-not(Test-Path $runbookRoot)){return}
 Get-ChildItem $runbookRoot -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
  $p=$_.FullName
  -not ($script:ExcludedRunbook | Where-Object {$p -like ('*'+$_+'*')})
 } | Sort-Object FullName | ForEach-Object {[void]$rbList.Items.Add($_)}
}
function Show-ToolHelp([string]$Id){
 $script:View='Runbook';$rbSearch.Clear();Update-View
 $tool=Get-Tool $Id
 $fileName=$Id+' - '+($tool.Name -replace '[<>:"/\\|?*]','-')+'.md'
 foreach($item in $rbList.Items){if($item.Name -eq $fileName){$rbList.SelectedItem=$item;break}}
}
$rbList.DisplayMember='Name'
$rbList.Add_SelectedIndexChanged({
 $f=$rbList.SelectedItem
 if(-not$f){return}
 if($f.Extension.ToLowerInvariant() -in @('.txt','.md','.log','.csv','.json','.xml','.ps1')){
  try{$rbView.Text=Get-Content $f.FullName -Raw}catch{$rbView.Text=$_.Exception.Message}
 }else{$rbView.Text='Selected document: '+$f.Name+[Environment]::NewLine+[Environment]::NewLine+'Double-click to open it in the registered Windows application.'}
})
$rbList.Add_DoubleClick({$f=$rbList.SelectedItem;if($f){Start-Process $f.FullName}})
$rbSearch.Add_TextChanged({
 $term=$rbSearch.Text.Trim()
 Update-RunbookList
 if($term){
  $m=@($rbList.Items | Where-Object {$_.Name -like ('*'+$term+'*') -or $_.FullName -like ('*'+$term+'*')})
  $rbList.Items.Clear()
  foreach($i in $m){[void]$rbList.Items.Add($i)}
 }
})
$rbAdd.Add_Click({
 $d=New-Object Windows.Forms.OpenFileDialog
 $d.Multiselect=$true
 $d.Title='Add document to T3CHNRD Digital Field Kit Runbook'
 $d.Filter='Supported documents|*.pdf;*.doc;*.docx;*.txt;*.md;*.rtf;*.html;*.htm;*.csv;*.xlsx;*.pptx|All files|*.*'
 if($d.ShowDialog() -eq 'OK'){
  foreach($f in $d.FileNames){Copy-Item $f (Join-Path $runbookRoot ([IO.Path]::GetFileName($f))) -Force}
    Update-RunbookList
 }
})
$rbOpen.Add_Click({Start-Process explorer.exe $runbookRoot})
$rbRefresh.Add_Click({Update-RunbookList})

function Show-PlatformFallback{
 $d=New-Object Windows.Forms.Form
 $d.Text='T3CHNRD Digital Field Kit - Platform Failsafe'
 $d.StartPosition='CenterParent'
 $d.Size=New-Object Drawing.Size(560,325)
 $d.FormBorderStyle='FixedDialog'
 $d.MaximizeBox=$false
 $d.MinimizeBox=$false
 $h=New-Object Windows.Forms.Label
 $h.Text='Automatic detection is primary. Use this only as a failsafe.'
 $h.Font=New-Object Drawing.Font('Segoe UI',12,[Drawing.FontStyle]::Bold)
 $h.Size=New-Object Drawing.Size(500,40)
 $h.Location=New-Object Drawing.Point(24,22)
 $d.Controls.Add($h)
 $s=New-Object Windows.Forms.Label
 $s.Text='This Windows build can preview the macOS target profiles, but macOS Intel and Apple Silicon use their own native applications.'
 $s.Size=New-Object Drawing.Size(500,50)
 $s.Location=New-Object Drawing.Point(24,66)
 $d.Controls.Add($s)
 $choices=@(
  @('AUTO DETECT','WINDOWS | AUTO-DETECTED'),
  @('WINDOWS','WINDOWS | MANUAL FAILSAFE'),
  @('macOS INTEL','macOS INTEL | PROFILE PREVIEW'),
  @('macOS APPLE SILICON','macOS APPLE SILICON | PROFILE PREVIEW')
 )
 $i=0
 foreach($ch in $choices){
  $b=New-Object Windows.Forms.Button
  $b.Text=$ch[0]
  $b.Size=New-Object Drawing.Size(230,42)
  $col=$i%2
  $row=[Math]::Floor($i/2)
  $b.Location=New-Object Drawing.Point((24+262*$col),(145+54*$row))
  $b.Tag=$ch[1]
  $b.Add_Click({
    param($control)
     $platform.Text=[string]$control.Tag
   $d.Close()
  })
  $d.Controls.Add($b)
  $i++
 }
 [void]$d.ShowDialog($form)
}
$platformButton.Add_Click({Show-PlatformFallback})

. (Join-Path $appDirectory 'AIWorkspaceUI.ps1')

function Update-View{
 [CmdletBinding(SupportsShouldProcess=$true)]
 param()
 foreach($k in $tabs.Keys){$tabs[$k].BackColor=if($k -eq $script:View){[Drawing.Color]::FromArgb(104,149,17)}else{[Drawing.Color]::FromArgb(35,52,62)}}
 foreach($k in $cats.Keys){$cats[$k].BackColor=if($script:View -eq 'Tools' -and $k -eq $script:Category){[Drawing.Color]::FromArgb(67,104,47)}else{[Drawing.Color]::FromArgb(20,58,80)}}
 $cards.Visible=$false
 $runbook.Visible=$false
 $settings.Visible=$false
 $aiPanel.Visible=$false
 if($script:View -eq 'Runbook'){
  $pageTitle.Text='Help / Runbook'
  $pageSub.Text='Search tool instructions and your own runbook documents.'
  $info.Visible=$false
  $runbook.Visible=$true
    Update-RunbookList
 }elseif($script:View -eq 'AI Workspace'){
  $pageTitle.Text='AI Workspace'
  $pageSub.Text='Local drafts, diagnostic evidence and imported results. AI is not connected.'
  $info.Visible=$false;$aiPanel.Visible=$true
  Update-EvidenceList $logBrowser $reportRoot
  Update-EvidenceList $resultBrowser $aiResultsRoot
 }elseif($script:View -eq 'Settings'){
  $pageTitle.Text='Settings'
  $pageSub.Text='Open folders, adjust output display, and validate the app.'
  $info.Visible=$false
  $settings.Visible=$true
 }elseif($script:View -eq 'Favorites'){
  $pageTitle.Text='Favorites'
  $pageSub.Text='Your pinned field tools.'
  $info.Visible=$true
  $cards.Visible=$true
    Show-ToolCard
 }elseif($script:View -eq 'Recent'){
  $pageTitle.Text='Recent Tools'
  $pageSub.Text='Recently launched field tools.'
  $info.Visible=$true
  $cards.Visible=$true
    Show-ToolCard
 }else{
  if(-not [string]::IsNullOrWhiteSpace($search.Text)){
   $pageTitle.Text='Search Results'
   $pageSub.Text='Searching all Field Kit tools.'
  }else{
   $pageTitle.Text=$script:Category
   $pageSub.Text='Select a tool to diagnose, repair, optimize, secure or deploy Windows systems.'
  }
  $info.Visible=$true
  $cards.Visible=$true
  Show-ToolCard
 }
}

$form.Add_Resize({
 $brand.Location=New-Object Drawing.Point([Math]::Max(760,$header.ClientSize.Width-285),18)
 $search.Location=New-Object Drawing.Point([Math]::Max(700,$tabsPanel.ClientSize.Width-350),7)
 $info.Location=New-Object Drawing.Point([Math]::Max(520,$pageHead.ClientSize.Width-375),4)
 $platform.Location=New-Object Drawing.Point([Math]::Max(780,$footer.ClientSize.Width-245),20)
})

Update-View
$form.Add_Shown({
 if(-not [string]::IsNullOrWhiteSpace($AutoRunToolId)){
  $autoTool=Get-Tool $AutoRunToolId
  if($autoTool){
   $script:View='Tools'
   $script:Category=[string]$autoTool.Category
   Update-View
   Start-Tool $autoTool
  }
 }
})
[void]$form.ShowDialog()
