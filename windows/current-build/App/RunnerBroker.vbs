Option Explicit

If WScript.Arguments.Count > 0 Then
  If LCase(WScript.Arguments(0)) = "/syntax-only" Then WScript.Quit 0
End If


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

Dim ps, psCommandReady, psError, psWarning, rc, commandCmd, warnText
ps = ResolvePowerShell()
psCommandReady = fso.BuildPath(queue, "powershell-command.ready")
psError = fso.BuildPath(queue, "broker.error")
psWarning = fso.BuildPath(queue, "broker.warning")
DeleteIfExists psCommandReady
DeleteIfExists psError
DeleteIfExists psWarning

' Broker readiness proves the exact primitive the current pipeline depends on:
' Windows PowerShell can execute an inline command. The previous -File self-test
' was not representative of the v10.2.7 pipeline and incorrectly forced the
' entire application into diagnostic mode on systems where -Command worked.
Dim commandLiteral
commandLiteral = PsLiteral(psCommandReady)
commandCmd = Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & _
  Q("[IO.File]::WriteAllText(" & commandLiteral & ",'ok',[Text.Encoding]::ASCII);exit 0")

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
  WriteUnicodeText psError, "Windows PowerShell failed the inline startup test. Exit code: " & CStr(rc)
  WScript.Quit 5
End If

' Optional compatibility diagnostic only. A failure here no longer disables the
' broker because the actual runner is loaded as an in-memory ScriptBlock and tool
' execution reports its own real error/output through the Run Center.
Dim brokerTest, psReady, psDetail, scriptCmd
brokerTest = fso.BuildPath(root, "App\Broker-PowerShell-SelfTest.ps1")
psReady = fso.BuildPath(queue, "powershell-script.ready")
psDetail = fso.BuildPath(queue, "broker-powershell-detail.txt")
DeleteIfExists psReady
DeleteIfExists psDetail
If fso.FileExists(brokerTest) Then
  scriptCmd = BuildScriptInvocationCommand(ps, brokerTest, psReady, psDetail)
  On Error Resume Next
  rc = sh.Run(scriptCmd, 0, True)
  If Err.Number <> 0 Then
    WriteUnicodeText psWarning, "Local script compatibility test could not be launched: " & CStr(Err.Number) & " - " & Err.Description
    Err.Clear
  ElseIf rc <> 0 Or Not fso.FileExists(psReady) Then
    warnText = "Local script compatibility test failed. Exit code: " & CStr(rc)
    If fso.FileExists(psDetail) Then warnText = warnText & vbCrLf & vbCrLf & ReadTextUnicodeFirst(psDetail)
    WriteUnicodeText psWarning, warnText
  End If
  On Error GoTo 0
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
      manifest = ReadTextUnicodeFirst(file.Path)
      On Error Resume Next
      fso.DeleteFile file.Path, True
      On Error GoTo 0
      manifest = Trim(manifest)
      If Len(manifest) > 0 Then LaunchManifest manifest, toolkitRoot
    End If
  Next
End Sub

Sub LaunchManifest(ByVal manifestPath, ByVal toolkitRoot)
  Dim runner, psLocal, cmd, launchErrorPath, cancelPath, donePath, launchErr
  runner = fso.BuildPath(toolkitRoot, "App\Invoke-ToolRunner.ps1")
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
  cmd = BuildRunnerInvocationCommand(psLocal, runner, manifestPath, launchErrorPath)

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
  commandText = "$ErrorActionPreference='Stop';try{$code=[IO.File]::ReadAllText(" & PsLiteral(runnerPath) & ");$sb=[ScriptBlock]::Create($code);& $sb -ManifestPath " & PsLiteral(manifestPath) & ";if($LASTEXITCODE -ne $null){exit [int]$LASTEXITCODE}else{exit 0}}catch{($_ | Format-List * -Force | Out-String -Width 4096) | Set-Content -LiteralPath " & PsLiteral(detailPath) & " -Encoding Unicode;exit 1}"
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

Function ReadTextUnicodeFirst(ByVal path)
  Dim ts
  ReadTextUnicodeFirst = ""
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
  ReadTextUnicodeFirst = ts.ReadAll
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
