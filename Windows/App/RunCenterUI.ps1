function New-RunPane([int]$Number) {
 $page=New-Object Windows.Forms.TabPage
 $page.Text="Tool $Number - ready"
 $header=New-Object Windows.Forms.TableLayoutPanel
 $header.Dock='Top';$header.Height=70;$header.ColumnCount=3;$header.RowCount=1
 $header.BackColor=[Drawing.Color]::FromArgb(28,65,85)
 $header.Padding=New-Object Windows.Forms.Padding(12,8,12,8)
 [void]$header.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent',100)))
 [void]$header.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',140)))
 [void]$header.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',120)))
 $state=New-Object Windows.Forms.Label
 $state.Dock='Fill';$state.Text='Ready';$state.TextAlign='MiddleLeft';$state.ForeColor='White'
 $state.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
 $header.Controls.Add($state,0,0)
 $cancel=New-Object Windows.Forms.Button
 $hide=New-Object Windows.Forms.Button
 $send=New-Object Windows.Forms.Button
 foreach($button in @($cancel,$hide,$send)){
  $button.Dock='Fill';$button.FlatStyle='Flat';$button.BackColor=[Drawing.Color]::White
  $button.ForeColor=[Drawing.Color]::FromArgb(15,40,55);$button.UseVisualStyleBackColor=$false
  $button.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
  $button.Margin=New-Object Windows.Forms.Padding(6,3,6,3)
 }
 $cancel.Text='Cancel tool';$cancel.Enabled=$false;$hide.Text='Hide panel';$send.Text='Send input'
 $header.Controls.Add($cancel,1,0);$header.Controls.Add($hide,2,0)
 $output=New-Object Windows.Forms.RichTextBox
 $output.Dock='Fill';$output.ReadOnly=$true;$output.BackColor=[Drawing.Color]::FromArgb(3,13,18)
 $output.ForeColor=[Drawing.Color]::FromArgb(220,237,244);$output.Font=New-Object Drawing.Font('Consolas',10)
 $inputPanel=New-Object Windows.Forms.TableLayoutPanel
 $inputPanel.Dock='Bottom';$inputPanel.Height=44;$inputPanel.ColumnCount=2;$inputPanel.Visible=$false
 [void]$inputPanel.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Percent',100)))
 [void]$inputPanel.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle('Absolute',140)))
 $inputBox=New-Object Windows.Forms.TextBox;$inputBox.Dock='Fill';$inputBox.Font=$output.Font
 $inputBox.Margin=New-Object Windows.Forms.Padding(8)
 $inputPanel.Controls.Add($inputBox,0,0);$inputPanel.Controls.Add($send,1,0)
 $page.Controls.Add($output);$page.Controls.Add($inputPanel);$page.Controls.Add($header)
 $output.BringToFront();$inputPanel.BringToFront();$header.BringToFront()
 $pane=[pscustomobject]@{Page=$page;State=$state;Cancel=$cancel;Output=$output;Input=$inputBox;InputPanel=$inputPanel;Send=$send;Capture=$null;Process=$null;Log='';Cancelled=$false;Number=$Number}
 $page.Tag=$pane;$cancel.Tag=$pane;$send.Tag=$pane;$inputBox.Tag=$pane
 $send.Add_Click({param($control) $p=$control.Tag
  try{
   if($p.Process -and -not $p.Process.HasExited){
    $bytes=[Text.Encoding]::UTF8.GetBytes($p.Input.Text+"`r`n")
    $p.Process.StandardInput.BaseStream.Write($bytes,0,$bytes.Length)
    $p.Process.StandardInput.BaseStream.Flush()
    $p.Input.Clear()
   }
  }catch{Write-Run ('Input error: '+$_.Exception.Message) $p}
 })
 $inputBox.Add_KeyDown({param($control,$eventData) if($eventData.KeyCode -eq 'Enter'){$control.Tag.Send.PerformClick();$eventData.SuppressKeyPress=$true}})
 $cancel.Add_Click({param($control) Stop-RunPane $control.Tag})
 $hide.Add_Click({Hide-Runner})
 return $pane
}
function Stop-RunPane($Pane){
 if($Pane.Process -and -not $Pane.Process.HasExited){
  & taskkill.exe /PID $Pane.Process.Id /T /F | Out-Null
  if($LASTEXITCODE -eq 0){$Pane.Cancelled=$true;$Pane.State.Text='Cancelling...';$Pane.Cancel.Enabled=$false}
 }
}
function Get-FreeRunPane { $script:RunPanes | Where-Object {$null -eq $_.Capture} | Select-Object -First 1 }
function Update-RunPanes {
 foreach($pane in $script:RunPanes){
  if(-not $pane.Capture){continue}
  $chunk='';$drained=0
  while($drained -lt 100 -and $pane.Capture.Output.TryDequeue([ref]$chunk)){
   $pane.Output.AppendText($chunk);Add-Content -LiteralPath $pane.Log -Value $chunk -NoNewline;$drained++
  }
  if($pane.Capture.Finished -and $pane.Capture.Output.IsEmpty){
   $code=$pane.Process.ExitCode
   $label=if($pane.Cancelled){'Cancelled'}elseif($code -eq 0){'Completed'}else{'Failed'}
   $pane.State.Text=$label+[Environment]::NewLine+'Exit code: '+$code
   Write-Run ("`r`n----------------------------------------`r`n"+$label+"`r`nExit code: "+$code+"`r`n") $pane
   Add-Content -LiteralPath $pane.Log -Value ("`r`n"+$label+' | Exit code: '+$code)
   $pane.InputPanel.Visible=$false;$pane.Cancel.Enabled=$false
   $pane.Capture.Dispose();$pane.Capture=$null;$pane.Process=$null
  }
 }
 $count=@($script:RunPanes|Where-Object {$_.Capture}).Count
 $status.Text=if($count){"RUNNING $count OF 2 TOOLS"}else{'READY'}
}
