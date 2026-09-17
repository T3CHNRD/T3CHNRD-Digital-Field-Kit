Option Explicit
If WScript.Arguments.Count > 0 Then
  If LCase(WScript.Arguments(0)) = "/syntax-only" Then WScript.Quit 0
End If
Dim fso, sh, queue, root, readyPath, shutdownPath, heartbeatPath, warningPath, requestFolder, file, manifestPath
Dim powerShell, runnerPath, startupError, startupWarning, requestPath, cancelPath, reqName, ts
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
If WScript.Arguments.Count < 2 Then WScript.Quit 2
queue = WScript.Arguments(0)
root = WScript.Arguments(1)
If Not fso.FolderExists(queue) Then fso.CreateFolder queue
readyPath = fso.BuildPath(queue,"broker.ready")
shutdownPath = fso.BuildPath(queue,"shutdown.txt")
heartbeatPath = fso.BuildPath(queue,"heartbeat.txt")
warningPath = fso.BuildPath(queue,"broker.warning")
powerShell = ResolvePowerShell()
runnerPath = fso.BuildPath(root,"App\Invoke-ToolRunner.ps1")
If Not fso.FileExists(runnerPath) Then
  WriteUnicode fso.BuildPath(queue,"broker.error"), "Invoke-ToolRunner.ps1 is missing: " & runnerPath
  WScript.Quit 3
End If
startupError = ""
startupWarning = ""
If Not ProbePowerShellCommand(powerShell, queue, startupError) Then
  WriteUnicode fso.BuildPath(queue,"broker.error"), startupError
  WScript.Quit 4
End If
If Not ProbeLocalScriptCompatibility(powerShell, root, queue, startupWarning) Then
  WriteUnicode warningPath, startupWarning
End If
WriteAnsi readyPath, CStr(Now)
Do
  If fso.FileExists(shutdownPath) Then Exit Do
  If fso.FileExists(heartbeatPath) Then
    On Error Resume Next
    If DateDiff("s", fso.GetFile(heartbeatPath).DateLastModified, Now) > 120 Then Exit Do
    On Error GoTo 0
  End If
  Set requestFolder = fso.GetFolder(queue)
  For Each file In requestFolder.Files
    reqName = LCase(file.Name)
    If Left(reqName,8) = "request-" And Right(reqName,4) = ".txt" Then
      requestPath = file.Path
      manifestPath = ReadUnicodeOrAnsi(requestPath)
      If Len(Trim(manifestPath)) > 0 Then Call StartRequest(powerShell, runnerPath, manifestPath, queue)
      On Error Resume Next
      fso.DeleteFile requestPath, True
      On Error GoTo 0
    End If
  Next
  WScript.Sleep 100
Loop
WScript.Quit 0

Sub StartRequest(ByVal psExe, ByVal runner, ByVal manifest, ByVal queuePath)
  Dim encoded, cmd, shellCmd, rc, launchError, manifestEsc, runnerEsc, detail
  manifestEsc = Replace(manifest,"'","''")
  runnerEsc = Replace(runner,"'","''")
  shellCmd = "$ErrorActionPreference='Stop';try{$src=[IO.File]::ReadAllText('" & runnerEsc & "');$sb=[ScriptBlock]::Create($src);& $sb -ManifestPath '" & manifestEsc & "';exit $LASTEXITCODE}catch{($_ | Out-String -Width 4096) | Set-Content -LiteralPath '" & Replace(manifest & ".broker-error","'","''") & "' -Encoding Unicode;exit 1}"
  encoded = Base64Unicode(shellCmd)
  cmd = Q(psExe) & " -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -EncodedCommand " & encoded
  On Error Resume Next
  sh.Run cmd, 0, False
  If Err.Number <> 0 Then
    detail = "Broker could not launch the tool runner." & vbCrLf & "Manifest: " & manifest & vbCrLf & "Error: " & Err.Description & " (" & CStr(Err.Number) & ")"
    launchError = FindManifestValue(manifest,"LaunchErrorPath")
    If Len(launchError) > 0 Then WriteUnicode launchError, detail
    Err.Clear
  End If
  On Error GoTo 0
End Sub

Function ProbePowerShellCommand(ByVal psExe, ByVal qroot, ByRef detail)
  Dim marker, cmd, rc, code
  marker = fso.BuildPath(qroot,"powershell-command.ready")
  On Error Resume Next
  If fso.FileExists(marker) Then fso.DeleteFile marker,True
  On Error GoTo 0
  code = "[IO.File]::WriteAllText('" & Replace(marker,"'","''") & "','ready',[Text.Encoding]::ASCII);exit 0"
  cmd = Q(psExe) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q(code)
  On Error Resume Next
  rc = sh.Run(cmd,0,True)
  If Err.Number <> 0 Then
    detail = "Windows could not start PowerShell -Command: " & Err.Description & " (" & CStr(Err.Number) & ")"
    Err.Clear
    ProbePowerShellCommand = False
  ElseIf rc <> 0 Or Not fso.FileExists(marker) Then
    detail = "PowerShell -Command did not create its readiness marker. Exit code=" & CStr(rc)
    ProbePowerShellCommand = False
  Else
    ProbePowerShellCommand = True
  End If
  On Error GoTo 0
End Function

Function ProbeLocalScriptCompatibility(ByVal psExe, ByVal toolkitRoot, ByVal qroot, ByRef detail)
  Dim scriptPath, marker, errPath, cmdText, encoded, cmd, rc, i
  scriptPath = fso.BuildPath(toolkitRoot,"App\Broker-PowerShell-SelfTest.ps1")
  marker = fso.BuildPath(qroot,"powershell-file.ready")
  errPath = fso.BuildPath(qroot,"powershell-file-detail.txt")
  If Not fso.FileExists(scriptPath) Then
    detail = "Optional PowerShell local-script compatibility test is unavailable because Broker-PowerShell-SelfTest.ps1 is missing."
    ProbeLocalScriptCompatibility = False
    Exit Function
  End If
  cmdText = "$ErrorActionPreference='Stop';try{& '" & Replace(scriptPath,"'","''") & "' -ReadyPath '" & Replace(marker,"'","''") & "';exit 0}catch{($_ | Out-String -Width 4096)|Set-Content -LiteralPath '" & Replace(errPath,"'","''") & "' -Encoding Unicode;exit 1}"
  encoded = Base64Unicode(cmdText)
  cmd = Q(psExe) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand " & encoded
  On Error Resume Next
  rc = sh.Run(cmd,0,True)
  If Err.Number <> 0 Then
    detail = "Optional local PowerShell script compatibility test could not start: " & Err.Description
    Err.Clear
    ProbeLocalScriptCompatibility = False
  ElseIf rc <> 0 Or Not fso.FileExists(marker) Then
    detail = "Optional local PowerShell script compatibility test failed. This does not disable the runner. Exit code=" & CStr(rc)
    If fso.FileExists(errPath) Then detail = detail & vbCrLf & ReadUnicodeOrAnsi(errPath)
    ProbeLocalScriptCompatibility = False
  Else
    ProbeLocalScriptCompatibility = True
  End If
  On Error GoTo 0
End Function

Function FindManifestValue(ByVal manifestPath, ByVal keyName)
  Dim x, line, pos, k, v
  FindManifestValue = ""
  If Not fso.FileExists(manifestPath) Then Exit Function
  Set x = fso.OpenTextFile(manifestPath,1,False,-1)
  Do Until x.AtEndOfStream
    line = x.ReadLine
    pos = InStr(line,"=")
    If pos > 0 Then
      k = Left(line,pos-1)
      v = Mid(line,pos+1)
      If LCase(k)=LCase(keyName) Then FindManifestValue=v:Exit Do
    End If
  Loop
  x.Close
End Function

Function ReadUnicodeOrAnsi(ByVal path)
  Dim x,s
  ReadUnicodeOrAnsi=""
  On Error Resume Next
  Set x=fso.OpenTextFile(path,1,False,-1)
  If Err.Number=0 Then s=x.ReadAll:x.Close:ReadUnicodeOrAnsi=s:On Error GoTo 0:Exit Function
  Err.Clear
  Set x=fso.OpenTextFile(path,1,False,0)
  If Err.Number=0 Then s=x.ReadAll:x.Close:ReadUnicodeOrAnsi=s
  Err.Clear
  On Error GoTo 0
End Function
Sub WriteUnicode(ByVal path,ByVal text):Dim x:Set x=fso.CreateTextFile(path,True,True):x.Write text:x.Close:End Sub
Sub WriteAnsi(ByVal path,ByVal text):Dim x:Set x=fso.CreateTextFile(path,True,False):x.Write text:x.Close:End Sub
Function Base64Unicode(ByVal text)
  Dim dom,node,stm,bytes
  Set stm=CreateObject("ADODB.Stream"):stm.Type=2:stm.Charset="unicode":stm.Open:stm.WriteText text:stm.Position=0:stm.Type=1:bytes=stm.Read:stm.Close
  Set dom=CreateObject("Msxml2.DOMDocument.6.0"):Set node=dom.createElement("b64"):node.dataType="bin.base64":node.nodeTypedValue=bytes:Base64Unicode=Replace(Replace(node.text,vbCr,""),vbLf,"")
End Function
Function ResolvePowerShell()
  Dim p:p=sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe":If Not fso.FileExists(p) Then p="powershell.exe":ResolvePowerShell=p
End Function
Function Q(ByVal s):Q=Chr(34)&Replace(CStr(s),Chr(34),"")&Chr(34):End Function
