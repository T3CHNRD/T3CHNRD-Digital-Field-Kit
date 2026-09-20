Option Explicit
Dim fso, sh, root, ui, ps, cmdText, args, rc, logDir, logPath, details
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

root = fso.GetParentFolderName(WScript.ScriptFullName)
ui = fso.BuildPath(root, "Windows\App\T3DFK-Windows.ps1")

If Not fso.FileExists(ui) Then
  MsgBox "Windows application source is missing:" & vbCrLf & ui, 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 2
End If

Dim exe
exe = fso.BuildPath(root, "T3CHNRD Digital Field Kit.exe")
If fso.FileExists(exe) Then
  rc = sh.Run(Q(exe), 0, True)
  WScript.Quit rc
End If

ps = sh.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
If Not fso.FileExists(ps) Then ps = "powershell.exe"

logDir = fso.BuildPath(sh.ExpandEnvironmentStrings("%LOCALAPPDATA%"), "T3DFK\StartupLogs")
If Not fso.FolderExists(fso.BuildPath(sh.ExpandEnvironmentStrings("%LOCALAPPDATA%"), "T3DFK")) Then
  fso.CreateFolder fso.BuildPath(sh.ExpandEnvironmentStrings("%LOCALAPPDATA%"), "T3DFK")
End If
If Not fso.FolderExists(logDir) Then fso.CreateFolder logDir
logPath = fso.BuildPath(logDir, "last-startup-error.txt")
If fso.FileExists(logPath) Then fso.DeleteFile logPath, True

On Error Resume Next
sh.Run Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & _
  Q("Get-ChildItem -LiteralPath " & PsLiteral(root) & " -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue; exit 0"), 0, True
On Error GoTo 0

cmdText = "$ErrorActionPreference='Stop';try{$code=[IO.File]::ReadAllText(" & PsLiteral(ui) & ");$sb=[ScriptBlock]::Create($code);. $sb -ToolkitRoot " & PsLiteral(root) & ";exit 0}catch{($_ | Out-String) | Set-Content -LiteralPath " & PsLiteral(logPath) & " -Encoding UTF8;exit 1}"
args = "-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & Q(cmdText)

rc = sh.Run(Q(ps) & " " & args, 0, True)

If rc <> 0 Then
  details = "The Field Kit could not start."
  If fso.FileExists(logPath) Then
    On Error Resume Next
    details = details & vbCrLf & vbCrLf & fso.OpenTextFile(logPath, 1, False).ReadAll
    On Error GoTo 0
  End If
  details = details & vbCrLf & vbCrLf & "Startup log:" & vbCrLf & logPath
  MsgBox details, 16, "T3CHNRD Digital Field Kit"
End If

WScript.Quit rc

Function PsLiteral(ByVal value)
  PsLiteral = "'" & Replace(CStr(value), "'", "''") & "'"
End Function

Function Q(ByVal value)
  Q = Chr(34) & Replace(CStr(value), Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Function
