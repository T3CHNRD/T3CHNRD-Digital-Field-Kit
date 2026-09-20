#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SourceRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$SourceRoot=[IO.Path]::GetFullPath($SourceRoot).TrimEnd('\')

function New-T3DFKShortcut {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)][string]$ShortcutPath,
        [Parameter(Mandatory=$true)][string]$InstallRoot
    )
    $wsh=New-Object -ComObject WScript.Shell
    $shortcut=$wsh.CreateShortcut($ShortcutPath)
    $exe=Join-Path $InstallRoot 'T3CHNRD Digital Field Kit.exe'
    if(Test-Path -LiteralPath $exe -PathType Leaf){
        $shortcut.TargetPath=$exe
        $shortcut.Arguments=''
        $shortcut.IconLocation="$exe,0"
    }else{
        $shortcut.TargetPath=Join-Path $env:SystemRoot 'System32\wscript.exe'
        $shortcut.Arguments='"'+(Join-Path $InstallRoot 'T3CHNRD Digital Field Kit.vbs')+'"'
    }
    $shortcut.WorkingDirectory=$InstallRoot
    $shortcut.Description='T3CHNRD Digital Field Kit'
    if($PSCmdlet.ShouldProcess($ShortcutPath,'Create shortcut')){$shortcut.Save()}
}

function Copy-VerifiedFile {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    $dir=Split-Path -Parent $Destination
    if(-not(Test-Path -LiteralPath $dir)){New-Item -ItemType Directory -Force -Path $dir|Out-Null}
    [IO.File]::Copy($Source,$Destination,$true)
    $sourceHash=(Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash
    $destHash=(Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash
    if($sourceHash -ne $destHash){throw "Verification failed after copying: $Source"}
}

$form=New-Object Windows.Forms.Form
$form.Text='Install T3CHNRD Digital Field Kit'
$form.StartPosition='CenterScreen'
$form.Size=New-Object Drawing.Size(850,560)
$form.MinimumSize=New-Object Drawing.Size(760,520)
$form.Font=New-Object Drawing.Font('Segoe UI',10)
$form.BackColor=[Drawing.Color]::FromArgb(219,232,241)

$header=New-Object Windows.Forms.Panel
$header.Dock='Top'
$header.Height=120
$header.BackColor=[Drawing.Color]::FromArgb(17,94,137)
$form.Controls.Add($header)

$title=New-Object Windows.Forms.Label
$title.Text='T3CHNRD Digital Field Kit'
$title.ForeColor='White'
$title.Font=New-Object Drawing.Font('Segoe UI',22,[Drawing.FontStyle]::Bold)
$title.AutoSize=$true
$title.Location=New-Object Drawing.Point(24,22)
$header.Controls.Add($title)

$subtitle=New-Object Windows.Forms.Label
$subtitle.Text='Windows installer - choose a destination, then install'
$subtitle.ForeColor='AliceBlue'
$subtitle.AutoSize=$true
$subtitle.Location=New-Object Drawing.Point(28,68)
$header.Controls.Add($subtitle)

$panel=New-Object Windows.Forms.Panel
$panel.Location=New-Object Drawing.Point(22,140)
$panel.Size=New-Object Drawing.Size(790,350)
$panel.Anchor='Top,Bottom,Left,Right'
$panel.BackColor='White'
$panel.BorderStyle='FixedSingle'
$form.Controls.Add($panel)

$label=New-Object Windows.Forms.Label
$label.Text='Install folder:'
$label.AutoSize=$true
$label.Location=New-Object Drawing.Point(22,28)
$panel.Controls.Add($label)

$destination=New-Object Windows.Forms.TextBox
$destination.Text=Join-Path $env:ProgramFiles 'T3DFK'
$destination.Location=New-Object Drawing.Point(22,55)
$destination.Size=New-Object Drawing.Size(610,28)
$destination.Anchor='Top,Left,Right'
$panel.Controls.Add($destination)

$browse=New-Object Windows.Forms.Button
$browse.Text='Browse...'
$browse.Location=New-Object Drawing.Point(648,53)
$browse.Size=New-Object Drawing.Size(110,32)
$browse.Anchor='Top,Right'
$panel.Controls.Add($browse)

$desktop=New-Object Windows.Forms.CheckBox
$desktop.Text='Create desktop shortcut'
$desktop.Checked=$true
$desktop.AutoSize=$true
$desktop.Location=New-Object Drawing.Point(24,105)
$panel.Controls.Add($desktop)

$launch=New-Object Windows.Forms.CheckBox
$launch.Text='Launch after installation'
$launch.Checked=$true
$launch.AutoSize=$true
$launch.Location=New-Object Drawing.Point(24,135)
$panel.Controls.Add($launch)

$note=New-Object Windows.Forms.Label
$note.Text='Portable use needs no installation: keep the extracted folder on a USB/SSD and double-click T3CHNRD Digital Field Kit.vbs. Installed mode keeps writable Runbook/report data under ProgramData.'
$note.ForeColor='DimGray'
$note.Location=New-Object Drawing.Point(24,175)
$note.Size=New-Object Drawing.Size(720,58)
$panel.Controls.Add($note)

$progress=New-Object Windows.Forms.ProgressBar
$progress.Location=New-Object Drawing.Point(24,248)
$progress.Size=New-Object Drawing.Size(650,24)
$progress.Anchor='Top,Left,Right'
$panel.Controls.Add($progress)

$status=New-Object Windows.Forms.Label
$status.Text='Ready.'
$status.Location=New-Object Drawing.Point(24,282)
$status.Size=New-Object Drawing.Size(720,28)
$panel.Controls.Add($status)

$install=New-Object Windows.Forms.Button
$install.Text='INSTALL'
$install.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
$install.Location=New-Object Drawing.Point(24,314)
$install.Size=New-Object Drawing.Size(140,40)
$install.BackColor='YellowGreen'
$panel.Controls.Add($install)

$cancel=New-Object Windows.Forms.Button
$cancel.Text='CANCEL'
$cancel.Location=New-Object Drawing.Point(176,314)
$cancel.Size=New-Object Drawing.Size(120,40)
$panel.Controls.Add($cancel)

$browse.Add_Click({
    $dialog=New-Object Windows.Forms.FolderBrowserDialog
    $dialog.Description='Choose installation parent folder'
    if($dialog.ShowDialog() -eq 'OK'){
        $destination.Text=Join-Path $dialog.SelectedPath 'T3DFK'
    }
})

$cancel.Add_Click({$form.Close()})

$install.Add_Click({
    try{
        $install.Enabled=$false
        $cancel.Enabled=$false
        $target=[IO.Path]::GetFullPath($destination.Text.Trim()).TrimEnd('\')
        if([string]::IsNullOrWhiteSpace($target)){throw 'Choose an installation folder.'}
        if($target -eq $SourceRoot -or $target.StartsWith($SourceRoot+'\',[StringComparison]::OrdinalIgnoreCase)){
            throw 'Install destination must be outside the portable source folder.'
        }

        $required=@(
            'T3CHNRD Digital Field Kit.vbs',
            'INSTALL T3CHNRD Digital Field Kit.vbs',
            'UNINSTALL T3CHNRD Digital Field Kit.vbs',
            'Windows\App\T3DFK-Windows.ps1',
            'Windows\Config\tools.json'
        )
        foreach($relative in $required){
            if(-not(Test-Path -LiteralPath (Join-Path $SourceRoot $relative) -PathType Leaf)){
                throw "Source package is incomplete. Missing: $relative"
            }
        }

        New-Item -ItemType Directory -Force -Path $target|Out-Null
        $files=@(
            Get-ChildItem -LiteralPath $SourceRoot -File -Recurse -Force |
            Where-Object {
                $_.FullName -notlike (Join-Path $SourceRoot 'Diagnostic-Reports\*') -and
                $_.FullName -notlike (Join-Path $SourceRoot '.git\*')
            }
        )

        $i=0
        foreach($file in $files){
            $i++
            $relative=$file.FullName.Substring($SourceRoot.Length).TrimStart('\')
            $output=Join-Path $target $relative
            Copy-VerifiedFile -Source $file.FullName -Destination $output
            $progress.Value=[Math]::Min(90,[int](90*$i/[Math]::Max(1,$files.Count)))
            $status.Text="Copying and verifying $i / $($files.Count)"
            [Windows.Forms.Application]::DoEvents()
        }

        $dataRoot=Join-Path $env:ProgramData 'T3DFK'
        New-Item -ItemType Directory -Force -Path (Join-Path $dataRoot 'Runbook'),(Join-Path $dataRoot 'Diagnostic-Reports')|Out-Null
        try{& icacls.exe $dataRoot /grant '*S-1-5-32-545:(OI)(CI)M' /T /C | Out-Null}catch{Write-Verbose ('Could not update report-folder permissions: '+$_.Exception.Message)}

        $startMenu=Join-Path ([Environment]::GetFolderPath('Programs')) 'T3CHNRD Digital Field Kit'
        New-Item -ItemType Directory -Force -Path $startMenu|Out-Null
        New-T3DFKShortcut -ShortcutPath (Join-Path $startMenu 'T3CHNRD Digital Field Kit.lnk') -InstallRoot $target
        if($desktop.Checked){
            New-T3DFKShortcut -ShortcutPath (Join-Path ([Environment]::GetFolderPath('Desktop')) 'T3CHNRD Digital Field Kit.lnk') -InstallRoot $target
        }

        $key='HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\T3CHNRDDigitalFieldKit'
        New-Item $key -Force|Out-Null
        Set-ItemProperty $key DisplayName 'T3CHNRD Digital Field Kit'
        Set-ItemProperty $key DisplayVersion '11.0-test'
        Set-ItemProperty $key Publisher 'T3CHNRD'
        Set-ItemProperty $key InstallLocation $target
        Set-ItemProperty $key UninstallString ('wscript.exe "'+(Join-Path $target 'UNINSTALL T3CHNRD Digital Field Kit.vbs')+'"')

        $progress.Value=100
        $status.Text='Installation complete.'
        [Windows.Forms.MessageBox]::Show('Installation completed and copied files were hash-verified.','T3CHNRD Digital Field Kit')|Out-Null
        if($launch.Checked){
            Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\wscript.exe') -ArgumentList ('"'+(Join-Path $target 'T3CHNRD Digital Field Kit.vbs')+'"') -WorkingDirectory $target
        }
        $form.Close()
    }catch{
        $status.Text='Installation failed.'
        [Windows.Forms.MessageBox]::Show($_.Exception.Message,'Installation failed','OK','Error')|Out-Null
        $install.Enabled=$true
        $cancel.Enabled=$true
    }
})

[void]$form.ShowDialog()
