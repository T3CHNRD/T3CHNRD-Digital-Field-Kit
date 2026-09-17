Option Explicit

If WScript.Arguments.Count > 0 Then
  If LCase(WScript.Arguments(0)) = "/syntax-only" Then WScript.Quit 0
End If

Dim fso, sh, app, root, hta, broker, elevated, queue, token, readyPath, errorPath, warningPath, i
Dim mshta, diagScript, diagReport, ps, iconPath, detail, ts, degraded, dts, brokerCmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
Set app = CreateObject("Shell.Application")

root = fso.GetParentFolderName(WScript.ScriptFullName)
hta = fso.BuildPath(root, "Toolkit.hta")
broker = fso.BuildPath(root, "App\RunnerBroker.vbs")
diagScript = fso.BuildPath(root, "App\Runner-Diagnostics.vbs")
iconPath = fso.BuildPath(root, "Toolkit.ico")

If Not fso.FileExists(hta) Then
  MsgBox "Toolkit.hta is missing. Extract the complete toolkit package.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If
If Not fso.FileExists(broker) Then
  MsgBox "RunnerBroker.vbs is missing. Extract the complete toolkit package.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If

' Keep the existing elevated field-test mode for v10.2.7 while the Windows runner
' is being stabilized. Per-tool elevation remains a later cleanup once the shared
' runner path is proven.
elevated = False
If WScript.Arguments.Count > 0 Then
  If LCase(WScript.Arguments(0)) = "/elevated" Then elevated = True
End If
If Not elevated Then
  app.ShellExecute "wscript.exe", Q(WScript.ScriptFullName) & " /elevated", root, "runas", 1
  WScript.Quit 0
End If

ps = ResolvePowerShell()
Call UnblockToolkit(ps, root)

Randomize
token = Replace(Replace(Replace(CStr(Now), "/", ""), ":", ""), " ", "-") & "-" & CStr(Int(Rnd * 1000000))
queue = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Broker-" & token)
EnsureFolder queue
sh.Environment("PROCESS")("T3DFK_BROKER_QUEUE") = queue

brokerCmd = Q(sh.ExpandEnvironmentStrings("%SystemRoot%\System32\wscript.exe")) & " " & Q(broker) & " " & Q(queue) & " " & Q(root)
On Error Resume Next
sh.Run brokerCmd, 0, False
If Err.Number <> 0 Then
  MsgBox "Windows could not start the T3CHNRD runner broker." & vbCrLf & vbCrLf & Err.Description, 16, "T3CHNRD Digital Field Kit"
  Err.Clear
End If
On Error GoTo 0

readyPath = fso.BuildPath(queue, "broker.ready")
errorPath = fso.BuildPath(queue, "broker.error")
warningPath = fso.BuildPath(queue, "broker.warning")
For i = 1 To 240
  If fso.FileExists(readyPath) Then Exit For
  If fso.FileExists(errorPath) Then Exit For
  WScript.Sleep 100
Next

If Not fso.FileExists(readyPath) Then
  detail = "The background runner broker did not become ready. T3CHNRD will open in diagnostic mode so the application can still be used while the runner problem is investigated."
  If fso.FileExists(errorPath) Then detail = detail & vbCrLf & vbCrLf & "Broker detail:" & vbCrLf & ReadUnicodeOrAnsi(errorPath)
  diagReport = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Runner-Diagnostics-" & token & ".txt")
  If fso.FileExists(diagScript) Then
    On Error Resume Next
    sh.Run Q(sh.ExpandEnvironmentStrings("%SystemRoot%\System32\wscript.exe")) & " " & Q(diagScript) & " " & Q(root) & " " & Q(diagReport), 0, True
    Err.Clear
    On Error GoTo 0
  End If
  If fso.FileExists(diagReport) Then detail = detail & vbCrLf & vbCrLf & "Runner diagnostics:" & vbCrLf & ReadUnicodeOrAnsi(diagReport)
  detail = detail & vbCrLf & vbCrLf & "Diagnostic report: " & diagReport
  sh.Environment("PROCESS")("T3DFK_BROKER_DIAG_REPORT") = diagReport
  degraded = fso.BuildPath(queue, "broker.degraded")
  On Error Resume Next
  Set dts = fso.CreateTextFile(degraded, True, True)
  dts.WriteLine detail
  dts.Close
  On Error GoTo 0
  MsgBox detail, 48, "T3CHNRD Digital Field Kit - Runner Diagnostic Mode"
Else
  sh.Environment("PROCESS")("T3DFK_BROKER_DIAG_REPORT") = ""
  If fso.FileExists(warningPath) Then
    sh.Environment("PROCESS")("T3DFK_BROKER_WARNING") = ReadUnicodeOrAnsi(warningPath)
  Else
    sh.Environment("PROCESS")("T3DFK_BROKER_WARNING") = ""
  End If
End If

Call LaunchToolkitWindow(root, hta, iconPath)
WScript.Quit 0

Sub UnblockToolkit(ByVal psExe, ByVal toolkitRoot)
  Dim cmd, rc, logPath, logText
  logPath = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Unblock.log")
  cmd = Q(psExe) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & _
        Q("$ErrorActionPreference='SilentlyContinue';Get-ChildItem -LiteralPath " & PsLiteral(toolkitRoot) & " -Recurse -File | Unblock-File -ErrorAction SilentlyContinue;exit 0")
  On Error Resume Next
  rc = sh.Run(cmd, 0, True)
  If Err.Number <> 0 Then
    logText = CStr(Now) & " Unblock attempt could not start: " & Err.Description
    Err.Clear
  Else
    logText = CStr(Now) & " Toolkit Zone.Identifier cleanup completed. Exit code=" & CStr(rc)
  End If
  On Error GoTo 0
  WriteAnsiBestEffort logPath, logText
End Sub

Sub LaunchToolkitWindow(ByVal toolkitRoot, ByVal htaPath, ByVal icoPath)
  Dim hostSource, runtimeRoot, hostExe, csc, compileCmd, rc, useHost
  hostSource = fso.BuildPath(toolkitRoot, "App\WindowHost.cs")
  runtimeRoot = fso.BuildPath(sh.ExpandEnvironmentStrings("%LOCALAPPDATA%"), "T3DFK\Runtime")
  EnsureFolder runtimeRoot
  hostExe = fso.BuildPath(runtimeRoot, "T3DFK-WindowHost.exe")
  useHost = False
  If fso.FileExists(hostSource) And fso.FileExists(icoPath) Then
    If (Not fso.FileExists(hostExe)) Or (fso.GetFile(hostSource).DateLastModified > fso.GetFile(hostExe).DateLastModified) Then
      csc = FindCsc()
      If Len(csc) > 0 Then
        compileCmd = Q(csc) & " /nologo /target:winexe /r:System.Windows.Forms.dll /win32icon:" & Q(icoPath) & " /out:" & Q(hostExe) & " " & Q(hostSource)
        On Error Resume Next
        rc = sh.Run(compileCmd, 0, True)
        If Err.Number <> 0 Or rc <> 0 Then
          Err.Clear
          If fso.FileExists(hostExe) Then fso.DeleteFile hostExe, True
        End If
        On Error GoTo 0
      End If
    End If
    If fso.FileExists(hostExe) Then useHost = True
  End If
  If useHost Then
    sh.Run Q(hostExe) & " " & Q(htaPath) & " " & Q(icoPath), 1, False
  Else
    mshta = sh.ExpandEnvironmentStrings("%SystemRoot%\System32\mshta.exe")
    If Not fso.FileExists(mshta) Then mshta = "mshta.exe"
    sh.Run Q(mshta) & " " & Q(htaPath), 1, False
  End If
End Sub

Function FindCsc()
  Dim p
  p = sh.ExpandEnvironmentStrings("%WINDIR%") & "\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
  If fso.FileExists(p) Then FindCsc = p : Exit Function
  p = sh.ExpandEnvironmentStrings("%WINDIR%") & "\Microsoft.NET\Framework\v4.0.30319\csc.exe"
  If fso.FileExists(p) Then FindCsc = p : Exit Function
  FindCsc = ""
End Function

Function ResolvePowerShell()
  Dim p
  p = sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
  If Not fso.FileExists(p) Then p = "powershell.exe"
  ResolvePowerShell = p
End Function

Function ReadUnicodeOrAnsi(ByVal path)
  Dim s, x
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

Sub EnsureFolder(ByVal path)
  Dim parent
  If fso.FolderExists(path) Then Exit Sub
  parent = fso.GetParentFolderName(path)
  If Len(parent) > 0 And Not fso.FolderExists(parent) Then EnsureFolder parent
  On Error Resume Next
  fso.CreateFolder path
  On Error GoTo 0
End Sub

Sub WriteAnsiBestEffort(ByVal path, ByVal text)
  Dim x
  On Error Resume Next
  Set x = fso.OpenTextFile(path, 8, True, 0)
  x.WriteLine text
  x.Close
  On Error GoTo 0
End Sub

Function PsLiteral(ByVal s)
  PsLiteral = "'" & Replace(CStr(s), "'", "''") & "'"
End Function

Function Q(ByVal s)
  Q = Chr(34) & Replace(CStr(s), Chr(34), "") & Chr(34)
End Function
