#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$tools=@(
    [pscustomobject]@{File='perfmon.exe';Args='/rel';Name='Reliability Monitor'},
    [pscustomobject]@{File='resmon.exe';Args='';Name='Resource Monitor'},
    [pscustomobject]@{File='taskmgr.exe';Args='';Name='Task Manager'},
    [pscustomobject]@{File='eventvwr.msc';Args='/c:Application';Name='Event Viewer - Application'},
    [pscustomobject]@{File='eventvwr.msc';Args='/c:System';Name='Event Viewer - System'},
    [pscustomobject]@{File='msinfo32.exe';Args='';Name='System Information'},
    [pscustomobject]@{File='perfmon.exe';Args='';Name='Performance Monitor'},
    [pscustomobject]@{File='devmgmt.msc';Args='';Name='Device Manager'},
    [pscustomobject]@{File='diskmgmt.msc';Args='';Name='Disk Management'}
)

$form=New-Object Windows.Forms.Form
$form.Text='T3CHNRD Diagnostic Consoles'
$form.StartPosition='CenterScreen'
$form.Size=New-Object Drawing.Size(520,470)
$form.MinimumSize=New-Object Drawing.Size(500,430)
$form.FormBorderStyle='FixedDialog'
$form.MaximizeBox=$false
$form.MinimizeBox=$false
$form.Font=New-Object Drawing.Font('Segoe UI',10)

$title=New-Object Windows.Forms.Label
$title.Text='Choose diagnostic consoles to open'
$title.Font=New-Object Drawing.Font('Segoe UI',14,[Drawing.FontStyle]::Bold)
$title.AutoSize=$true
$title.Location=New-Object Drawing.Point(22,18)
$form.Controls.Add($title)

$note=New-Object Windows.Forms.Label
$note.Text='Select one or more tools. The Field Kit app will remain open.'
$note.AutoSize=$true
$note.ForeColor='DimGray'
$note.Location=New-Object Drawing.Point(24,50)
$form.Controls.Add($note)

$list=New-Object Windows.Forms.CheckedListBox
$list.CheckOnClick=$true
$list.Location=New-Object Drawing.Point(22,82)
$list.Size=New-Object Drawing.Size(458,275)
foreach($tool in $tools){[void]$list.Items.Add($tool.Name,$true)}
$form.Controls.Add($list)

$selectAll=New-Object Windows.Forms.Button
$selectAll.Text='SELECT ALL'
$selectAll.Size=New-Object Drawing.Size(120,36)
$selectAll.Location=New-Object Drawing.Point(22,375)
$selectAll.Add_Click({for($i=0;$i -lt $list.Items.Count;$i++){$list.SetItemChecked($i,$true)}})
$form.Controls.Add($selectAll)

$launch=New-Object Windows.Forms.Button
$launch.Text='OPEN SELECTED'
$launch.Size=New-Object Drawing.Size(145,36)
$launch.Location=New-Object Drawing.Point(210,375)
$launch.BackColor=[Drawing.Color]::FromArgb(181,225,55)
$launch.Add_Click({$form.DialogResult=[Windows.Forms.DialogResult]::OK;$form.Close()})
$form.Controls.Add($launch)

$cancel=New-Object Windows.Forms.Button
$cancel.Text='CANCEL'
$cancel.Size=New-Object Drawing.Size(100,36)
$cancel.Location=New-Object Drawing.Point(380,375)
$cancel.Add_Click({$form.DialogResult=[Windows.Forms.DialogResult]::Cancel;$form.Close()})
$form.Controls.Add($cancel)
$form.AcceptButton=$launch
$form.CancelButton=$cancel

if($form.ShowDialog() -eq [Windows.Forms.DialogResult]::OK){
    for($i=0;$i -lt $list.CheckedItems.Count;$i++){
        $name=[string]$list.CheckedItems[$i]
        $tool=$tools|Where-Object Name -eq $name|Select-Object -First 1
        if($tool){
            try{
                if([string]::IsNullOrWhiteSpace($tool.Args)){Start-Process -FilePath $tool.File}
                else{Start-Process -FilePath $tool.File -ArgumentList $tool.Args}
            }catch{Write-Error ("Could not open {0}: {1}" -f $tool.Name,$_.Exception.Message)}
        }
    }
}
