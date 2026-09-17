#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$SourceRoot,[string]$ReadyPath='', [switch]$ShortcutSelfTest)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$SourceRoot = [IO.Path]::GetFullPath($SourceRoot).TrimEnd('\')
$logDir = Join-Path $env:LOCALAPPDATA 'T3DFK\Logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$logPath = Join-Path $logDir 'T3DFK-Install.log'
$script:installSucceeded = $false
$script:launchAfter = $true
$script:installRoot = Join-Path $env:ProgramFiles 'T3DFK'

function Write-InstallLog([string]$Message) {
    try {
        if(-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
        $line = '[{0}] {1}{2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message, [Environment]::NewLine
        [IO.File]::AppendAllText($logPath, $line, (New-Object Text.UTF8Encoding($true)))
    } catch { }
}
function Update-Ui {
    [System.Windows.Forms.Application]::DoEvents()
}
function Set-Status([int]$Percent,[string]$Message) {
    $progress.Value = [Math]::Max(0,[Math]::Min(100,$Percent))
    $lblPercent.Text = '{0}%' -f $progress.Value
    $lblStatus.Text = $Message
    Update-Ui
}
function New-Shortcut([string]$Path,[string]$InstallRoot) {
    try {
        $parent = Split-Path -Parent $Path
        if($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        $ws = New-Object -ComObject WScript.Shell
        $shortcut = $ws.CreateShortcut($Path)
        $shortcut.TargetPath = Join-Path $env:SystemRoot 'System32\wscript.exe'
        $shortcut.Arguments = '"{0}"' -f (Join-Path $InstallRoot 'OPEN-ME-GUI.vbs')
        $shortcut.WorkingDirectory = $InstallRoot
        $shortcut.Description = 'T3CHNRD Digital Field Kit'
        $icon = Join-Path $InstallRoot 'Toolkit.ico'
        if(Test-Path -LiteralPath $icon) { $shortcut.IconLocation = '{0},0' -f $icon }
        $shortcut.Save()
        if(-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Shortcut Save() returned but the .lnk file was not created.' }
        Write-InstallLog ("Shortcut created: $Path")
        return $true
    } catch {
        Write-InstallLog ("Shortcut failed: $Path :: $($_.Exception.GetType().FullName) :: $($_.Exception.Message)")
        return $false
    }
}
function Get-CopyFiles([string]$Root) {
    $excludedTop = @('Diagnostic-Reports','Archive','Source-Archive')
    Get-ChildItem -LiteralPath $Root -File -Recurse -Force | Where-Object {
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
        $top = ($rel -split '\\',2)[0]
        $excludedTop -notcontains $top
    }
}
function Test-SourcePackage {
    $required = @(
        'Toolkit.hta','Toolkit.ico','OPEN-ME-GUI.vbs','App\RunnerBroker.vbs',
        'App\Broker-PowerShell-SelfTest.ps1','App\Invoke-ToolRunner.ps1','App\Invoke-ExternalTool.ps1',
        'App\Select-RunbookDocument.ps1','App\Install-All-Deployment.ps1','App\ToolkitLauncher.cs','App\WindowHost.cs','Assets\tools.js','App\tool-targets.txt',
        'Installer\Install-Wizard.ps1','UNINSTALL-T3DFK.vbs'
    )
    foreach($rel in $required) {
        $p = Join-Path $SourceRoot $rel
        if(-not (Test-Path -LiteralPath $p -PathType Leaf)) { throw "Source package is incomplete. Missing: $rel" }
    }
    if(-not (Test-Path -LiteralPath (Join-Path $SourceRoot 'Scripts') -PathType Container)) {
        throw 'Source package is incomplete. Scripts folder is missing.'
    }
}
function Test-InstalledPackage([string]$Root) {
    $required = @('Toolkit.hta','Toolkit.ico','OPEN-ME-GUI.vbs','App\RunnerBroker.vbs','App\Broker-PowerShell-SelfTest.ps1','App\Invoke-ToolRunner.ps1','App\Invoke-ExternalTool.ps1','App\Select-RunbookDocument.ps1','App\Install-All-Deployment.ps1','App\ToolkitLauncher.cs','App\WindowHost.cs','Assets\tools.js','App\tool-targets.txt')
    foreach($rel in $required) {
        if(-not (Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)) { throw "Installed verification failed. Missing: $rel" }
    }
    $missing = New-Object System.Collections.Generic.List[string]
    foreach($rel in Get-Content -LiteralPath (Join-Path $Root 'App\tool-targets.txt')) {
        if([string]::IsNullOrWhiteSpace($rel)) { continue }
        if(-not (Test-Path -LiteralPath (Join-Path $Root $rel) -PathType Leaf)) { $missing.Add($rel) }
    }
    if($missing.Count -gt 0) { throw "Installed tool verification failed. Missing $($missing.Count) target(s). First: $($missing[0])" }
}
function Register-Uninstall([string]$Root) {
    $key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\T3CHNRDDigitalFieldKit'
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name DisplayName -Value 'T3CHNRD Digital Field Kit'
    Set-ItemProperty -Path $key -Name DisplayVersion -Value '10.2.8'
    Set-ItemProperty -Path $key -Name Publisher -Value 'T3CHNRD'
    Set-ItemProperty -Path $key -Name InstallLocation -Value $Root
    Set-ItemProperty -Path $key -Name DisplayIcon -Value (Join-Path $Root 'Toolkit.ico')
    Set-ItemProperty -Path $key -Name UninstallString -Value ('wscript.exe "{0}"' -f (Join-Path $Root 'UNINSTALL-T3DFK.vbs'))
    Set-ItemProperty -Path $key -Name NoModify -Type DWord -Value 1
    Set-ItemProperty -Path $key -Name NoRepair -Type DWord -Value 1
}

try { Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue } catch {}
Write-InstallLog "Installer opened. Source=$SourceRoot"

if($ShortcutSelfTest) {
    Write-InstallLog 'Installer shortcut/log self-test started.'
    if(-not (Test-Path -LiteralPath $logPath -PathType Leaf) -or (Get-Item -LiteralPath $logPath).Length -le 0) { throw 'Installer log self-test failed: log file is empty.' }
    $testDir = Join-Path $env:TEMP ('T3DFK-ShortcutSelfTest-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    $testLink = Join-Path $testDir 'T3CHNRD Digital Field Kit.lnk'
    if(-not (New-Shortcut -Path $testLink -InstallRoot $SourceRoot)) { throw 'Shortcut self-test failed.' }
    if(-not (Test-Path -LiteralPath $testLink -PathType Leaf)) { throw 'Shortcut self-test did not create a .lnk file.' }
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-InstallLog 'Installer shortcut/log self-test passed.'
    exit 0
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Install T3CHNRD Digital Field Kit'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(870,610)
$form.MinimumSize = New-Object System.Drawing.Size(760,560)
$form.Font = New-Object System.Drawing.Font('Segoe UI',10)
$form.BackColor = [Drawing.Color]::FromArgb(219,232,241)
try { $form.Icon = New-Object System.Drawing.Icon((Join-Path $SourceRoot 'Toolkit.ico')) } catch { Write-InstallLog ('Icon load warning: '+$_.Exception.Message) }

$header = New-Object System.Windows.Forms.Panel
$header.Dock='Top'; $header.Height=130; $header.BackColor=[Drawing.Color]::FromArgb(31,105,178)
$form.Controls.Add($header)
$title = New-Object System.Windows.Forms.Label
$title.Text='T3CHNRD Digital Field Kit';$title.ForeColor=[Drawing.Color]::White;$title.Font=New-Object Drawing.Font('Segoe UI',22,[Drawing.FontStyle]::Bold);$title.AutoSize=$true;$title.Location=New-Object Drawing.Point(24,24)
$header.Controls.Add($title)
$sub = New-Object System.Windows.Forms.Label
$sub.Text='v10.2.8 Windows installer - choose a location, options, then install';$sub.ForeColor=[Drawing.Color]::AliceBlue;$sub.AutoSize=$true;$sub.Location=New-Object Drawing.Point(28,70)
$header.Controls.Add($sub)

$panel = New-Object System.Windows.Forms.Panel
$panel.Location=New-Object Drawing.Point(22,150);$panel.Size=New-Object Drawing.Size(810,390);$panel.Anchor='Top,Bottom,Left,Right';$panel.BackColor=[Drawing.Color]::White;$panel.BorderStyle='FixedSingle'
$form.Controls.Add($panel)

$lblStep = New-Object System.Windows.Forms.Label
$lblStep.Text='INSTALLATION OPTIONS';$lblStep.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold);$lblStep.ForeColor=[Drawing.Color]::SlateGray;$lblStep.AutoSize=$true;$lblStep.Location=New-Object Drawing.Point(22,20)
$panel.Controls.Add($lblStep)
$lblDest = New-Object System.Windows.Forms.Label
$lblDest.Text='Install folder:';$lblDest.AutoSize=$true;$lblDest.Location=New-Object Drawing.Point(22,58)
$panel.Controls.Add($lblDest)
$txtDest = New-Object System.Windows.Forms.TextBox
$txtDest.Text=$script:installRoot;$txtDest.Location=New-Object Drawing.Point(22,84);$txtDest.Size=New-Object Drawing.Size(620,28);$txtDest.Anchor='Top,Left,Right'
$panel.Controls.Add($txtDest)
$btnBrowse=New-Object System.Windows.Forms.Button
$btnBrowse.Text='Browse...';$btnBrowse.Location=New-Object Drawing.Point(658,82);$btnBrowse.Size=New-Object Drawing.Size(110,32);$btnBrowse.Anchor='Top,Right'
$panel.Controls.Add($btnBrowse)
$chkDesktop=New-Object System.Windows.Forms.CheckBox
$chkDesktop.Text='Create desktop shortcut';$chkDesktop.Checked=$true;$chkDesktop.AutoSize=$true;$chkDesktop.Location=New-Object Drawing.Point(24,132)
$panel.Controls.Add($chkDesktop)
$chkLaunch=New-Object System.Windows.Forms.CheckBox
$chkLaunch.Text='Launch T3CHNRD Digital Field Kit when setup finishes';$chkLaunch.Checked=$true;$chkLaunch.AutoSize=$true;$chkLaunch.Location=New-Object Drawing.Point(24,162)
$panel.Controls.Add($chkLaunch)
$note=New-Object System.Windows.Forms.Label
$note.Text='Setup copies the complete portable toolkit, verifies every GUI tool target, creates Start Menu/optional desktop shortcuts, and registers uninstall support.';$note.ForeColor=[Drawing.Color]::DimGray;$note.Location=New-Object Drawing.Point(24,202);$note.Size=New-Object Drawing.Size(735,48)
$panel.Controls.Add($note)
$progress=New-Object System.Windows.Forms.ProgressBar
$progress.Location=New-Object Drawing.Point(24,265);$progress.Size=New-Object Drawing.Size(690,24);$progress.Anchor='Top,Left,Right';$progress.Minimum=0;$progress.Maximum=100
$panel.Controls.Add($progress)
$lblPercent=New-Object System.Windows.Forms.Label
$lblPercent.Text='0%';$lblPercent.AutoSize=$true;$lblPercent.Location=New-Object Drawing.Point(724,267);$lblPercent.Anchor='Top,Right'
$panel.Controls.Add($lblPercent)
$lblStatus=New-Object System.Windows.Forms.Label
$lblStatus.Text='Ready.';$lblStatus.Location=New-Object Drawing.Point(24,302);$lblStatus.Size=New-Object Drawing.Size(740,44);$lblStatus.ForeColor=[Drawing.Color]::DarkSlateGray
$panel.Controls.Add($lblStatus)
$btnInstall=New-Object System.Windows.Forms.Button
$btnInstall.Text='INSTALL';$btnInstall.Font=New-Object Drawing.Font('Segoe UI',12,[Drawing.FontStyle]::Bold);$btnInstall.Location=New-Object Drawing.Point(24,345);$btnInstall.Size=New-Object Drawing.Size(140,42);$btnInstall.BackColor=[Drawing.Color]::YellowGreen
$panel.Controls.Add($btnInstall)
$btnCancel=New-Object System.Windows.Forms.Button
$btnCancel.Text='CANCEL';$btnCancel.Location=New-Object Drawing.Point(178,345);$btnCancel.Size=New-Object Drawing.Size(120,42)
$panel.Controls.Add($btnCancel)

$btnBrowse.Add_Click({
    $dlg=New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description='Choose the parent folder for T3CHNRD Digital Field Kit'
    try { $dlg.SelectedPath = Split-Path -Parent $txtDest.Text } catch { $dlg.SelectedPath = $env:ProgramFiles }
    if($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        $candidate=$dlg.SelectedPath
        if((Split-Path -Leaf $candidate) -ine 'T3DFK'){ $candidate=Join-Path $candidate 'T3DFK' }
        $txtDest.Text=$candidate
    }
})
$btnCancel.Add_Click({ $form.Close() })

$btnInstall.Add_Click({
    try {
        $btnInstall.Enabled=$false;$btnCancel.Enabled=$false;$txtDest.Enabled=$false;$btnBrowse.Enabled=$false;$chkDesktop.Enabled=$false;$chkLaunch.Enabled=$false
        $script:installRoot=[IO.Path]::GetFullPath($txtDest.Text.Trim()).TrimEnd('\')
        $script:launchAfter=$chkLaunch.Checked
        if([string]::IsNullOrWhiteSpace($script:installRoot)){throw 'Choose a valid installation folder.'}
        if($script:installRoot -ieq $SourceRoot){throw 'The installed folder must be different from the portable/source folder.'}
        if($script:installRoot.StartsWith($SourceRoot+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'The installed folder cannot be inside the portable/source folder.'}
        Test-SourcePackage
        Write-InstallLog "Install started. Destination=$script:installRoot"
        Set-Status 3 'Validating source package...'
        New-Item -Path $script:installRoot -ItemType Directory -Force | Out-Null
        $files=@(Get-CopyFiles -Root $SourceRoot)
        if($files.Count -eq 0){throw 'No source files were found to install.'}
        $i=0
        foreach($file in $files){
            $i++
            $rel=$file.FullName.Substring($SourceRoot.Length).TrimStart('\')
            $dest=Join-Path $script:installRoot $rel
            $destDir=Split-Path -Parent $dest
            if(-not(Test-Path -LiteralPath $destDir -PathType Container)){New-Item -Path $destDir -ItemType Directory -Force | Out-Null}
            [IO.File]::Copy($file.FullName,$dest,$true)
            if(($i % 15)-eq 0 -or $i -eq $files.Count){
                $pct=5+[int](65*($i/[double]$files.Count))
                Set-Status $pct ("Copying files... {0}/{1}" -f $i,$files.Count)
            }
        }
        Set-Status 74 'Verifying installed application...'
        Test-InstalledPackage -Root $script:installRoot
        Set-Status 82 'Creating Start Menu shortcut...'
        $commonPrograms = [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonPrograms)
        $userPrograms = [Environment]::GetFolderPath([Environment+SpecialFolder]::Programs)
        $shortcutMade = $false
        if($commonPrograms) {
            $startDir = Join-Path $commonPrograms 'T3CHNRD Digital Field Kit'
            $shortcutMade = New-Shortcut -Path (Join-Path $startDir 'T3CHNRD Digital Field Kit.lnk') -InstallRoot $script:installRoot
        }
        if(-not $shortcutMade -and $userPrograms) {
            Write-InstallLog 'Common Start Menu shortcut failed; trying current-user Start Menu.'
            $startDir = Join-Path $userPrograms 'T3CHNRD Digital Field Kit'
            $shortcutMade = New-Shortcut -Path (Join-Path $startDir 'T3CHNRD Digital Field Kit.lnk') -InstallRoot $script:installRoot
        }
        if(-not $shortcutMade) { Write-InstallLog 'WARNING: Start Menu shortcut could not be created. Installation will continue.' }
        if($chkDesktop.Checked){
            Set-Status 88 'Creating desktop shortcut...'
            $desktopMade = $false
            $commonDesktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::CommonDesktopDirectory)
            if($commonDesktop) { $desktopMade = New-Shortcut -Path (Join-Path $commonDesktop 'T3CHNRD Digital Field Kit.lnk') -InstallRoot $script:installRoot }
            if(-not $desktopMade) {
                $userDesktop = [Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory)
                if($userDesktop) { $desktopMade = New-Shortcut -Path (Join-Path $userDesktop 'T3CHNRD Digital Field Kit.lnk') -InstallRoot $script:installRoot }
            }
            if(-not $desktopMade) { Write-InstallLog 'WARNING: Desktop shortcut could not be created. Installation will continue.' }
        }
        Set-Status 94 'Registering uninstall information...'
        Register-Uninstall -Root $script:installRoot
        @('T3CHNRD Digital Field Kit v10.2.8','Installed: '+(Get-Date),'Source: '+$SourceRoot) | Set-Content -LiteralPath (Join-Path $script:installRoot 'Installed-Version.txt') -Encoding utf8
        Set-Status 100 'Installation complete and verified.'
        Write-InstallLog 'Installation completed successfully.'
        $script:installSucceeded=$true
        $btnInstall.Text='FINISH';$btnInstall.Enabled=$true;$btnCancel.Text='CLOSE';$btnCancel.Enabled=$true
        $txtDest.Enabled=$false;$btnBrowse.Enabled=$false
        [Windows.Forms.MessageBox]::Show('T3CHNRD Digital Field Kit was installed and verified successfully.','Installation complete',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    }
    catch {
        $message=$_.Exception.Message
        Write-InstallLog ('ERROR: '+($_ | Out-String -Width 4096))
        Set-Status 0 ('Installation failed: '+$message)
        [Windows.Forms.MessageBox]::Show($message+"`r`n`r`nInstaller log: $logPath",'Installation failed',[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        $btnInstall.Enabled=$true;$btnCancel.Enabled=$true;$txtDest.Enabled=$true;$btnBrowse.Enabled=$true;$chkDesktop.Enabled=$true;$chkLaunch.Enabled=$true
    }
})

$form.Add_FormClosing({
    if($script:installSucceeded -and $script:launchAfter){
        try { Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\wscript.exe') -ArgumentList ('"{0}"' -f (Join-Path $script:installRoot 'OPEN-ME-GUI.vbs')) -WorkingDirectory $script:installRoot } catch {}
    }
})

if($ReadyPath){ try { [IO.File]::WriteAllText($ReadyPath,'Installer UI ready',[Text.Encoding]::ASCII) } catch {} }
[void]$form.ShowDialog()
