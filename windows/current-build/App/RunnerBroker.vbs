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

Dim brokerTest, psReady, psCommandReady, psError, psDetail, ps, commandCmd, scriptCmd, rc
brokerTest = fso.BuildPath(root, "App\Broker-PowerShell-SelfTest.ps1")
psReady = fso.BuildPath(queue, "powershell-script.ready")
psCommandReady = fso.BuildPath(queue, "powershell-command.ready")
psError = fso.BuildPath(queue, "broker.error")
psDetail = fso.BuildPath(queue, "broker-powershell-detail.txt")

If Not fso.FileExists(brokerTest) Then
  WriteUnicodeText psError, "Broker PowerShell self-test is missing: " & brokerTest
  WScript.Quit 3
End If

ps = ResolvePowerShell()

' Stage 1: prove powershell.exe can execute an inline command.
Dim commandLiteral
commandLiteral = PsLiteral(psCommandReady)
commandCmd = Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q("[IO.File]::WriteAllText(" & commandLiteral & ",'ok',[Text.Encoding]::ASCII)")
On Error Resume Next
rc = sh.Run(commandCmd, 0, True)
If Err.Number <> 0 Then
  WriteUnicodeText psError, "Unable to launch Windows PowerShell from the broker: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
  On Error GoTo 0
  WScript.Quit 4
End If
On Error GoTo 0
If rc <> 0 Or Not fso.FileExists(psCommandReady) Then
  WriteUnicodeText psError, "Windows PowerShell failed the inline -Command startup test. Exit code: " & CStr(rc)
  WScript.Quit 5
End If

' Stage 2: invoke a real local .ps1 from a PowerShell command and capture the exact exception.
' This avoids depending on powershell.exe -File parsing for the broker bootstrap while still
' exercising normal PowerShell script invocation and execution-policy enforcement.
DeleteIfExists psReady
DeleteIfExists psDetail
scriptCmd = BuildScriptInvocationCommand(ps, brokerTest, psReady, psDetail)
On Error Resume Next
rc = sh.Run(scriptCmd, 0, True)
If Err.Number <> 0 Then
  WriteUnicodeText psError, "PowerShell launched, but the broker could not start the script invocation self-test: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
  On Error GoTo 0
  WScript.Quit 6
End If
On Error GoTo 0

If rc <> 0 Or Not fso.FileExists(psReady) Then
  Dim detail
  detail = "PowerShell -Command works, but invoking a local .ps1 failed. Exit code: " & CStr(rc)
  If fso.FileExists(psDetail) Then detail = detail & vbCrLf & vbCrLf & ReadTextAnsiOrUnicode(psDetail)
  WriteUnicodeText psError, detail
  WScript.Quit 7
End If

WriteAnsiText readyPath, CStr(Now)

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
      manifest = ReadTextAnsiOrUnicode(file.Path)
      On Error Resume Next
      fso.DeleteFile file.Path, True
      On Error GoTo 0
      manifest = Trim(manifest)
      If Len(manifest) > 0 Then LaunchManifest manifest, toolkitRoot
    End If
  Next
End Sub

Sub LaunchManifest(ByVal manifestPath, ByVal toolkitRoot)
  Dim runner, psLocal, cmd, startedPath, launchErrorPath, cancelPath, donePath, launchErr, runnerDetail
  runner = fso.BuildPath(toolkitRoot, "App\Invoke-ToolRunner.ps1")
  startedPath = ManifestValue(manifestPath, "StartedPath")
  launchErrorPath = ManifestValue(manifestPath, "LaunchErrorPath")
  cancelPath = ManifestValue(manifestPath, "CancelPath")
  donePath = ManifestValue(manifestPath, "DonePath")

  If Len(cancelPath) > 0 Then
    If fso.FileExists(cancelPath) Then
      If Len(donePath) > 0 Then WriteAnsiText donePath, "1223"
      Exit Sub
    End If
  End If

  If Not fso.FileExists(runner) Then
    If Len(launchErrorPath) > 0 Then WriteUnicodeText launchErrorPath, "Runner script missing: " & runner
    If Len(donePath) > 0 Then WriteAnsiText donePath, "1"
    Exit Sub
  End If

  psLocal = ResolvePowerShell()
  runnerDetail = launchErrorPath
  cmd = BuildRunnerInvocationCommand(psLocal, runner, manifestPath, runnerDetail)

  On Error Resume Next
  sh.Run cmd, 0, False
  If Err.Number <> 0 Then
    launchErr = Err.Description
    Err.Clear
    On Error GoTo 0
    If Len(launchErrorPath) > 0 Then WriteUnicodeText launchErrorPath, "Unable to start PowerShell runner from broker: " & launchErr
    If Len(donePath) > 0 Then WriteAnsiText donePath, "1"
    Exit Sub
  End If
  On Error GoTo 0
End Sub

Function BuildScriptInvocationCommand(ByVal psExe, ByVal scriptPath, ByVal markerPath, ByVal detailPath)
  Dim commandText
  commandText = "$ErrorActionPreference='Stop';try{& " & PsLiteral(scriptPath) & " -ReadyPath " & PsLiteral(markerPath) & ";if(-not $?) { throw 'Self-test script returned failure.' };exit 0}catch{($_ | Format-List * -Force | Out-String -Width 4096) | Set-Content -LiteralPath " & PsLiteral(detailPath) & " -Encoding Unicode;exit 1}"
  BuildScriptInvocationCommand = Q(psExe) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q(commandText)
End Function

Function BuildRunnerInvocationCommand(ByVal psExe, ByVal runnerPath, ByVal manifestPath, ByVal detailPath)
  Dim commandText
  commandText = "$ErrorActionPreference='Stop';try{& " & PsLiteral(runnerPath) & " -ManifestPath " & PsLiteral(manifestPath) & ";exit $LASTEXITCODE}catch{($_ | Format-List * -Force | Out-String -Width 4096) | Set-Content -LiteralPath " & PsLiteral(detailPath) & " -Encoding Unicode;exit 1}"
  BuildRunnerInvocationCommand = Q(psExe) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q(commandText)
End Function

Function ResolvePowerShell()
  Dim p
  p = sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
  If Not fso.FileExists(p) Then p = "powershell.exe"
  ResolvePowerShell = p
End Function

Function ManifestValue(ByVal path, ByVal wantedKey)
  Dim ts, line, pos, k, v
  ManifestValue = ""
  On Error Resume Next
  Set ts = fso.OpenTextFile(path, 1, False, -1)
  If Err.Number <> 0 Then
    Err.Clear
    Set ts = fso.OpenTextFile(path, 1, False, 0)
  End If
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

Function ReadTextAnsiOrUnicode(ByVal path)
  Dim ts
  ReadTextAnsiOrUnicode = ""
  On Error Resume Next
  Set ts = fso.OpenTextFile(path, 1, False, -1)
  If Err.Number <> 0 Then
    Err.Clear
    Set ts = fso.OpenTextFile(path, 1, False, 0)
  End If
  If Err.Number <> 0 Then
    Err.Clear
    Exit Function
  End If
  On Error GoTo 0
  ReadTextAnsiOrUnicode = ts.ReadAll
  ts.Close
End Function

Sub WriteAnsiText(ByVal path, ByVal text)
  Dim ts
  Set ts = fso.CreateTextFile(path, True, False)
  ts.Write CStr(text)
  ts.Close
End Sub

Sub WriteUnicodeText(ByVal path, ByVal text)
  Dim ts
  Set ts = fso.CreateTextFile(path, True, True)
  ts.Write CStr(text)
  ts.Close
End Sub

Sub DeleteIfExists(ByVal path)
  On Error Resume Next
  If fso.FileExists(path) Then fso.DeleteFile path, True
  On Error GoTo 0
End Sub

Function PsLiteral(ByVal s)
  PsLiteral = "'" & Replace(CStr(s), "'", "''") & "'"
End Function

Function Q(ByVal s)
  Q = Chr(34) & Replace(CStr(s), Chr(34), "") & Chr(34)
End Function
