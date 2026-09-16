Option Explicit

Dim fso, sh, queue, root, readyPath, shutdownPath, heartbeatPath
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

If WScript.Arguments.Count < 2 Then WScript.Quit 2
queue = WScript.Arguments(0)
root = WScript.Arguments(1)
readyPath = fso.BuildPath(queue, "broker.ready")
shutdownPath = fso.BuildPath(queue, "shutdown.txt")
heartbeatPath = fso.BuildPath(queue, "heartbeat.txt")

If Not fso.FolderExists(queue) Then fso.CreateFolder queue

' Prove the process chain in two stages before the GUI relies on it.
Dim brokerTest, psReady, psCommandReady, psError, ps, testCmd, commandCmd, waitIndex
brokerTest = fso.BuildPath(root, "App\Broker-PowerShell-SelfTest.ps1")
psReady = fso.BuildPath(queue, "powershell-file.ready")
psCommandReady = fso.BuildPath(queue, "powershell-command.ready")
psError = fso.BuildPath(queue, "broker.error")
If Not fso.FileExists(brokerTest) Then
  WriteText psError, "Broker PowerShell self-test is missing: " & brokerTest
  WScript.Quit 3
End If
ps = sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
If Not fso.FileExists(ps) Then ps = "powershell.exe"

' Stage 1: prove powershell.exe can execute a simple command.
Dim commandLiteral
commandLiteral = Replace(psCommandReady, "'", "''")
commandCmd = Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q("[IO.File]::WriteAllText('" & commandLiteral & "','ok',[Text.Encoding]::ASCII)")
On Error Resume Next
sh.Run commandCmd, 0, False
If Err.Number <> 0 Then
  WriteText psError, "Unable to launch Windows PowerShell from the broker: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
  On Error GoTo 0
  WScript.Quit 4
End If
On Error GoTo 0
For waitIndex = 1 To 100
  If fso.FileExists(psCommandReady) Then Exit For
  WScript.Sleep 100
Next
If Not fso.FileExists(psCommandReady) Then
  WriteText psError, "Windows PowerShell did not complete a simple -Command startup test within 10 seconds. PowerShell may be blocked by Windows security, application control, antivirus/EDR, or system policy."
  WScript.Quit 5
End If

' Stage 2: prove a local .ps1 can execute with -File.
testCmd = Q(ps) & " -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass -File " & Q(brokerTest) & " -ReadyPath " & Q(psReady)
On Error Resume Next
sh.Run testCmd, 0, False
If Err.Number <> 0 Then
  WriteText psError, "PowerShell started, but the broker could not launch the script-file self-test: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
  On Error GoTo 0
  WScript.Quit 6
End If
On Error GoTo 0
For waitIndex = 1 To 100
  If fso.FileExists(psReady) Then Exit For
  WScript.Sleep 100
Next
If Not fso.FileExists(psReady) Then
  WriteText psError, "PowerShell -Command works, but PowerShell -File did not complete the local script self-test within 10 seconds. Script execution may be blocked, or the extracted files may be carrying downloaded-file security metadata."
  WScript.Quit 7
End If
WriteText readyPath, CStr(Now)

Dim idleSeconds
idleSeconds = 0

Do
  If fso.FileExists(shutdownPath) Then Exit Do

  If fso.FileExists(heartbeatPath) Then
    On Error Resume Next
    idleSeconds = DateDiff("s", fso.GetFile(heartbeatPath).DateLastModified, Now)
    If Err.Number <> 0 Then
      Err.Clear
      idleSeconds = 0
    End If
    On Error GoTo 0
    If idleSeconds > 45 Then Exit Do
  Else
    idleSeconds = idleSeconds + 1
    If idleSeconds > 300 Then Exit Do
  End If

  ProcessRequests queue, root
  WScript.Sleep 150
Loop

On Error Resume Next
If fso.FileExists(readyPath) Then fso.DeleteFile readyPath, True
On Error GoTo 0
WScript.Quit 0

Sub ProcessRequests(ByVal q, ByVal toolkitRoot)
  Dim folder, file, name, manifest
  On Error Resume Next
  Set folder = fso.GetFolder(q)
  If Err.Number <> 0 Then
    Err.Clear
    Exit Sub
  End If
  On Error GoTo 0

  For Each file In folder.Files
    name = LCase(file.Name)
    If Left(name, 8) = "request-" And Right(name, 4) = ".txt" Then
      manifest = ReadText(file.Path)
      On Error Resume Next
      fso.DeleteFile file.Path, True
      On Error GoTo 0
      manifest = Trim(manifest)
      If Len(manifest) > 0 Then LaunchManifest manifest, toolkitRoot
    End If
  Next
End Sub

Sub LaunchManifest(ByVal manifestPath, ByVal toolkitRoot)
  Dim runner, ps, cmd, startedPath, launchErrorPath, cancelPath, donePath, launchErr
  runner = fso.BuildPath(toolkitRoot, "App\Invoke-ToolRunner.ps1")
  startedPath = ManifestValue(manifestPath, "StartedPath")
  launchErrorPath = ManifestValue(manifestPath, "LaunchErrorPath")
  cancelPath = ManifestValue(manifestPath, "CancelPath")
  donePath = ManifestValue(manifestPath, "DonePath")

  If Len(cancelPath) > 0 Then
    If fso.FileExists(cancelPath) Then
      If Len(donePath) > 0 Then WriteText donePath, "1223"
      Exit Sub
    End If
  End If

  If Not fso.FileExists(runner) Then
    If Len(launchErrorPath) > 0 Then WriteText launchErrorPath, "Runner script missing: " & runner
    If Len(donePath) > 0 Then WriteText donePath, "1"
    Exit Sub
  End If

  ps = sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
  If Not fso.FileExists(ps) Then ps = "powershell.exe"
  cmd = Q(ps) & " -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File " & Q(runner) & " -ManifestPath " & Q(manifestPath)

  On Error Resume Next
  sh.Run cmd, 0, False
  If Err.Number <> 0 Then
    launchErr = Err.Description
    Err.Clear
    On Error GoTo 0
    If Len(launchErrorPath) > 0 Then WriteText launchErrorPath, "Unable to start PowerShell runner from broker: " & launchErr
    If Len(donePath) > 0 Then WriteText donePath, "1"
    Exit Sub
  End If
  On Error GoTo 0
End Sub

Function ManifestValue(ByVal path, ByVal wantedKey)
  Dim ts, line, pos, k, v
  ManifestValue = ""
  On Error Resume Next
  Set ts = fso.OpenTextFile(path, 1, False, -1)
  If Err.Number <> 0 Then
    Err.Clear
    Exit Function
  End If
  On Error GoTo 0
  Do Until ts.AtEndOfStream
    line = ts.ReadLine
    pos = InStr(line, "=")
    If pos > 1 Then
      k = Left(line, pos - 1)
      v = Mid(line, pos + 1)
      If StrComp(k, wantedKey, vbTextCompare) = 0 Then
        ManifestValue = v
        Exit Do
      End If
    End If
  Loop
  ts.Close
End Function

Function ReadText(ByVal path)
  Dim ts
  ReadText = ""
  On Error Resume Next
  Set ts = fso.OpenTextFile(path, 1, False, -1)
  If Err.Number <> 0 Then
    Err.Clear
    Exit Function
  End If
  On Error GoTo 0
  ReadText = ts.ReadAll
  ts.Close
End Function

Sub WriteText(ByVal path, ByVal text)
  Dim ts
  Set ts = fso.CreateTextFile(path, True, False)
  ts.Write text
  ts.Close
End Sub

Function Q(ByVal s)
  Q = Chr(34) & Replace(CStr(s), Chr(34), "") & Chr(34)
End Function
