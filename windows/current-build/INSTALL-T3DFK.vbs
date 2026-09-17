Option Explicit

Dim fso, app, sh, root, ps1, ps, args, readyPath, token, i, cmdText, rc, detail, errFile
Set fso = CreateObject("Scripting.FileSystemObject")
Set app = CreateObject("Shell.Application")
Set sh = CreateObject("WScript.Shell")

root = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = fso.BuildPath(root, "Installer\Install-Wizard.ps1")
If Not fso.FileExists(ps1) Then
  MsgBox "Installer script is missing. Extract the complete T3DFK folder first.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If

ps = sh.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
If Not fso.FileExists(ps) Then ps = "powershell.exe"

' Remove downloaded-file Zone.Identifier metadata only from this extracted toolkit.
' The affected field PC has already proven powershell.exe -Command works while
' powershell.exe -File returns exit code 1, so the installer uses the same proven
' command-based invocation path as the application bootstrap.
On Error Resume Next
rc = sh.Run(Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q("Get-ChildItem -LiteralPath " & PsLiteral(root) & " -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue;exit 0"), 0, True)
Err.Clear
On Error GoTo 0

Randomize
token = Replace(Replace(Replace(CStr(Now), "/", ""), ":", ""), " ", "-") & "-" & CStr(Int(Rnd * 1000000))
readyPath = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Installer-" & token & ".ready")
If fso.FileExists(readyPath) Then fso.DeleteFile readyPath, True

cmdText = "$ErrorActionPreference='Stop';try{$code=[IO.File]::ReadAllText(" & PsLiteral(ps1) & ");$sb=[ScriptBlock]::Create($code);& $sb -SourceRoot " & PsLiteral(root) & " -ReadyPath " & PsLiteral(readyPath) & ";exit 0}catch{($_ | Out-String -Width 4096) | Set-Content -LiteralPath (Join-Path $env:TEMP 'T3DFK-Install-Launcher-Error.txt') -Encoding Unicode;exit 1}"
args = "-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & Q(cmdText)

On Error Resume Next
app.ShellExecute ps, args, root, "runas", 1
If Err.Number <> 0 Then
  MsgBox "Windows could not start the installer: " & Err.Description, 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 2
End If
On Error GoTo 0

' Wait only for the installer UI handshake. The installer remains independent after this launcher exits.
For i = 1 To 120
  If fso.FileExists(readyPath) Then Exit For
  WScript.Sleep 100
Next
If Not fso.FileExists(readyPath) Then
  errFile = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Install-Launcher-Error.txt")
  detail = "The installer did not initialize within 12 seconds."
  If fso.FileExists(errFile) Then detail = detail & vbCrLf & vbCrLf & ReadUnicodeOrAnsi(errFile)
  detail = detail & vbCrLf & vbCrLf & "Installer log: " & sh.ExpandEnvironmentStrings("%TEMP%\T3DFK-Install.log")
  MsgBox detail, 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 3
End If

On Error Resume Next
fso.DeleteFile readyPath, True
On Error GoTo 0
WScript.Quit 0

Function ReadUnicodeOrAnsi(ByVal path)
  Dim x, s
  ReadUnicodeOrAnsi = ""
  On Error Resume Next
  Set x = fso.OpenTextFile(path, 1, False, -1)
  If Err.Number = 0 Then
    s = x.ReadAll
    x.Close
    ReadUnicodeOrAnsi = s
    On Error GoTo 0
    Exit Function
  End If
  Err.Clear
  Set x = fso.OpenTextFile(path, 1, False, 0)
  If Err.Number = 0 Then
    s = x.ReadAll
    x.Close
    ReadUnicodeOrAnsi = s
  End If
  Err.Clear
  On Error GoTo 0
End Function

Function PsLiteral(ByVal s)
  PsLiteral = "'" & Replace(CStr(s), "'", "''") & "'"
End Function

Function Q(ByVal s)
  Q = Chr(34) & Replace(CStr(s), Chr(34), "") & Chr(34)
End Function
