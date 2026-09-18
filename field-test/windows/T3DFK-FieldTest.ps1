Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$form = New-Object Windows.Forms.Form
$form.Text = 'T3CHNRD Digital Field Kit v12 - Windows Field Test'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object Drawing.Size(1280,800)
$form.MinimumSize = New-Object Drawing.Size(900,620)
$form.BackColor = [Drawing.Color]::FromArgb(239,245,249)
$form.Font = New-Object Drawing.Font('Segoe UI',10)

$header = New-Object Windows.Forms.Panel
$header.Dock='Top'; $header.Height=88; $header.BackColor=[Drawing.Color]::FromArgb(11,92,122)
$title = New-Object Windows.Forms.Label
$title.Text='T3CHNRD Digital Field Kit'; $title.ForeColor='White'; $title.Font=New-Object Drawing.Font('Segoe UI',22,[Drawing.FontStyle]::Bold); $title.AutoSize=$true; $title.Location=New-Object Drawing.Point(18,12)
$sub = New-Object Windows.Forms.Label
$sub.Text='Diagnose  |  Repair  |  Optimize  |  Deploy'; $sub.ForeColor='WhiteSmoke'; $sub.AutoSize=$true; $sub.Location=New-Object Drawing.Point(22,55)
$badge = New-Object Windows.Forms.Label
$badge.Text='WINDOWS | Auto-detected'; $badge.ForeColor='Black'; $badge.BackColor=[Drawing.Color]::FromArgb(154,220,37); $badge.Size=New-Object Drawing.Size(190,30); $badge.TextAlign='MiddleCenter'; $badge.Anchor='Top,Right'; $badge.Location=New-Object Drawing.Point(1060,20)
$header.Controls.AddRange(@($title,$sub,$badge)); $form.Controls.Add($header)

$nav = New-Object Windows.Forms.FlowLayoutPanel
$nav.Dock='Top'; $nav.Height=54; $nav.Padding=New-Object Windows.Forms.Padding(10,7,10,5); $nav.WrapContents=$false; $nav.BackColor=[Drawing.Color]::FromArgb(3,23,32)
$form.Controls.Add($nav)

$split = New-Object Windows.Forms.SplitContainer
$split.Dock='Fill'; $split.SplitterDistance=500; $split.FixedPanel='None'; $form.Controls.Add($split); $split.BringToFront()

$tools = New-Object Windows.Forms.FlowLayoutPanel
$tools.Dock='Fill'; $tools.AutoScroll=$true; $tools.FlowDirection='TopDown'; $tools.WrapContents=$false; $tools.Padding=New-Object Windows.Forms.Padding(12)
$split.Panel1.Controls.Add($tools)
$output = New-Object Windows.Forms.RichTextBox
$output.Dock='Fill'; $output.ReadOnly=$true; $output.Font=New-Object Drawing.Font('Consolas',9.5); $output.BackColor=[Drawing.Color]::FromArgb(1,17,23); $output.ForeColor='WhiteSmoke'
$split.Panel2.Controls.Add($output)

function Write-UI([string]$Text){ $output.AppendText($Text + [Environment]::NewLine); $output.SelectionStart=$output.TextLength; $output.ScrollToCaret() }
function Add-Nav([string]$Text,[scriptblock]$Action){ $b=New-Object Windows.Forms.Button; $b.Text=$Text; $b.AutoSize=$true; $b.Height=36; $b.Add_Click($Action); $nav.Controls.Add($b) }
function Add-Tool([string]$Name,[string]$Description,[string]$Script){
  $b=New-Object Windows.Forms.Button; $b.Width=445; $b.Height=76; $b.TextAlign='MiddleLeft'; $b.Text="$Name`r`n$Description"; $b.Margin=New-Object Windows.Forms.Padding(3,3,3,8)
  $b.Add_Click({ param($s,$e) Write-UI "Starting $($s.Tag.Name)..."; $p=$s.Tag.Path; if(!(Test-Path $p)){Write-UI "ERROR: Missing $p"; return}; $text=& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $p 2>&1 | Out-String; Write-UI $text }.GetNewClosure())
  $b.Tag=[pscustomobject]@{Name=$Name;Path=$Script}; $tools.Controls.Add($b)
}

Add-Nav 'AUTO DETECT' { $badge.Text='WINDOWS | Auto-detected'; Write-UI 'Automatic detection selected: Windows.' }
Add-Nav 'WINDOWS' { $badge.Text='WINDOWS | Manual failsafe'; Write-UI 'Manual platform profile: Windows.' }
Add-Nav 'MAC INTEL' { $badge.Text='macOS Intel | Profile preview'; Write-UI 'This Windows field-test executable cannot run macOS binaries. The production macOS Intel build uses the same UI/source.' }
Add-Nav 'MAC APPLE SILICON' { $badge.Text='macOS Apple Silicon | Profile preview'; Write-UI 'This Windows field-test executable cannot run macOS binaries. The production Apple-Silicon build uses the same UI/source.' }
Add-Nav 'INSTALL ALL APPS' {
  $ids=@('Google.Chrome','Mozilla.Firefox','Malwarebytes.Malwarebytes','AVG.Antivirus.Free','Piriform.CCleaner')
  Write-UI 'Install All allow-list: Chrome, Firefox, Malwarebytes, AVG, CCleaner. Win11Debloat and WinUtil are excluded.'
  $answer=[Windows.Forms.MessageBox]::Show('Install the 5 approved apps now with winget?','Install All Apps','YesNo','Question')
  if($answer -ne 'Yes'){Write-UI 'Install All cancelled.'; return}
  foreach($id in $ids){ Write-UI "Installing $id ..."; & winget.exe install --id $id --exact --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object { Write-UI $_ } }
}
Add-Nav 'ADD RUNBOOK DOCUMENT' {
  $dlg=New-Object Windows.Forms.OpenFileDialog; $dlg.Multiselect=$true; $dlg.Title='Add document to Runbook'; $dlg.Filter='Documents|*.pdf;*.doc;*.docx;*.txt;*.md;*.html;*.htm|All files|*.*'
  if($dlg.ShowDialog() -eq 'OK'){ $dest=Join-Path $root 'Runbook'; New-Item -ItemType Directory -Force -Path $dest | Out-Null; foreach($f in $dlg.FileNames){Copy-Item -LiteralPath $f -Destination (Join-Path $dest ([IO.Path]::GetFileName($f))) -Force; Write-UI "Imported: $([IO.Path]::GetFileName($f))"} }
}

Add-Tool 'System Information' 'Hardware and Windows inventory.' (Join-Path $root 'scripts\windows\System-Info.ps1')
Add-Tool 'Network Summary' 'Adapters, DNS and routing.' (Join-Path $root 'scripts\windows\Network-Summary.ps1')
Add-Tool 'Disk Summary' 'Local drive capacity and free space.' (Join-Path $root 'scripts\windows\Disk-Summary.ps1')

Write-UI 'v12 Windows field-test shell loaded.'
Write-UI 'This package validates the rebuilt UI/runner/platform selector. The full production diagnostic catalog still requires one-by-one migration and field validation.'
[void]$form.ShowDialog()
