Option Explicit
Dim fso, sh, app, root, hta, broker, elevated, queue, token, readyPath, errorPath, i, mshta, diagScript, diagReport
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
Set app = CreateObject("Shell.Application")
root = fso.GetParentFolderName(WScript.ScriptFullName)
hta = fso.BuildPath(root, "Toolkit.hta")
broker = fso.BuildPath(root, "App\RunnerBroker.vbs")
diagScript = fso.BuildPath(root, "App\Runner-Diagnostics.vbs")

If Not fso.FileExists(hta) Then
  MsgBox "Toolkit.hta is missing. Extract the complete toolkit package.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If
If Not fso.FileExists(broker) Then
  MsgBox "RunnerBroker.vbs is missing. Extract the complete toolkit package.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If

elevated = False
If WScript.Arguments.Count > 0 Then
  If LCase(WScript.Arguments(0)) = "/elevated" Then elevated = True
End If

If Not elevated Then
  app.ShellExecute "wscript.exe", Chr(34) & WScript.ScriptFullName & Chr(34) & " /elevated", root, "runas", 1
  WScript.Quit 0
End If

Randomize
token = Replace(Replace(Replace(CStr(Now), "/", ""), ":", ""), " ", "-") & "-" & CStr(Int(Rnd * 1000000))
queue = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Broker-" & token)
If Not fso.FolderExists(queue) Then fso.CreateFolder queue
sh.Environment("PROCESS")("T3DFK_BROKER_QUEUE") = queue

sh.Run Chr(34) & sh.ExpandEnvironmentStrings("%SystemRoot%\System32\wscript.exe") & Chr(34) & " " & Chr(34) & broker & Chr(34) & " " & Chr(34) & queue & Chr(34) & " " & Chr(34) & root & Chr(34), 0, False
readyPath = fso.BuildPath(queue, "broker.ready")
errorPath = fso.BuildPath(queue, "broker.error")
For i = 1 To 240
  If fso.FileExists(readyPath) Then Exit For
  If fso.FileExists(errorPath) Then Exit For
  WScript.Sleep 100
Next
If Not fso.FileExists(readyPath) Then
  Dim detail, ts
  detail = "The background runner broker did not become ready. T3CHNRD will open in diagnostic mode so the application can still be used while the runner problem is investigated."
  If fso.FileExists(errorPath) Then
    On Error Resume Next
    Set ts = fso.OpenTextFile(errorPath, 1, False, 0)
    If Err.Number = 0 Then detail = detail & vbCrLf & vbCrLf & "Broker detail:" & vbCrLf & ts.ReadAll
    If Not ts Is Nothing Then ts.Close
    Err.Clear
    On Error GoTo 0
  End If

  diagReport = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Runner-Diagnostics-" & token & ".txt")
  If fso.FileExists(diagScript) Then
    On Error Resume Next
    sh.Run Chr(34) & sh.ExpandEnvironmentStrings("%SystemRoot%\System32\wscript.exe") & Chr(34) & " " & Chr(34) & diagScript & Chr(34) & " " & Chr(34) & root & Chr(34) & " " & Chr(34) & diagReport & Chr(34), 0, True
    Err.Clear
    On Error GoTo 0
  End If
  If fso.FileExists(diagReport) Then
    On Error Resume Next
    Set ts = fso.OpenTextFile(diagReport, 1, False, 0)
    If Err.Number = 0 Then detail = detail & vbCrLf & vbCrLf & "Runner diagnostics:" & vbCrLf & ts.ReadAll
    If Not ts Is Nothing Then ts.Close
    Err.Clear
    On Error GoTo 0
  End If
  detail = detail & vbCrLf & vbCrLf & "Diagnostic report: " & diagReport
  sh.Environment("PROCESS")("T3DFK_BROKER_DIAG_REPORT") = diagReport
  On Error Resume Next
  Dim degraded, dts
  degraded = fso.BuildPath(queue, "broker.degraded")
  Set dts = fso.CreateTextFile(degraded, True, False)
  dts.WriteLine detail
  dts.Close
  On Error GoTo 0
  MsgBox detail, 48, "T3CHNRD Digital Field Kit - Runner Diagnostic Mode"
End If

mshta = sh.ExpandEnvironmentStrings("%SystemRoot%\System32\mshta.exe")
If Not fso.FileExists(mshta) Then mshta = "mshta.exe"
sh.Run Chr(34) & mshta & Chr(34) & " " & Chr(34) & hta & Chr(34), 1, False
