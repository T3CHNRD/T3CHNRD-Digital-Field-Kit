Option Explicit

Dim fso, sh, root, reportPath, tempDir, ps, cmdExe, marker1, marker2, marker3, marker4, rc
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

If WScript.Arguments.Count < 2 Then WScript.Quit 2
root = WScript.Arguments(0)
reportPath = WScript.Arguments(1)
tempDir = fso.GetParentFolderName(reportPath)
If Not fso.FolderExists(tempDir) Then fso.CreateFolder tempDir

WriteReport "T3CHNRD Digital Field Kit - Runner Diagnostics v10.2.3"
AppendReport "Generated: " & CStr(Now)
AppendReport "Root: " & root
AppendReport "WScript: " & WScript.FullName
AppendReport "Windows: " & sh.ExpandEnvironmentStrings("%OS%")
AppendReport "PROCESSOR_ARCHITECTURE: " & sh.ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%")
AppendReport "PROCESSOR_ARCHITEW6432: " & sh.ExpandEnvironmentStrings("%PROCESSOR_ARCHITEW6432%")
AppendReport ""

cmdExe = sh.ExpandEnvironmentStrings("%ComSpec%")
If Not fso.FileExists(cmdExe) Then cmdExe = "cmd.exe"
AppendReport "cmd.exe: " & cmdExe

ps = sh.ExpandEnvironmentStrings("%WINDIR%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
If Not fso.FileExists(ps) Then ps = "powershell.exe"
AppendReport "powershell.exe: " & ps
AppendReport "powershell exists: " & CStr(fso.FileExists(ps))
AppendReport ""

marker1 = fso.BuildPath(tempDir, "diag-cmd.ready")
marker2 = fso.BuildPath(tempDir, "diag-ps-command.ready")
marker3 = fso.BuildPath(tempDir, "diag-ps-file.ready")
marker4 = fso.BuildPath(tempDir, "diag-ps-invoke.ready")
DeleteIfExists marker1
DeleteIfExists marker2
DeleteIfExists marker3
DeleteIfExists marker4

On Error Resume Next
rc = sh.Run(Q(cmdExe) & " /d /c echo cmd-ok>" & Q(marker1), 0, True)
If Err.Number <> 0 Then
  AppendReport "CMD launch error: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
Else
  AppendReport "CMD exit code: " & CStr(rc)
  AppendReport "CMD marker created: " & CStr(fso.FileExists(marker1))
End If
On Error GoTo 0
AppendReport ""

Dim psCommand
psCommand = Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q("[IO.File]::WriteAllText(" & PsLiteral(marker2) & ",'powershell-command-ok',[Text.Encoding]::ASCII)")
On Error Resume Next
rc = sh.Run(psCommand, 0, True)
If Err.Number <> 0 Then
  AppendReport "PowerShell -Command launch error: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
Else
  AppendReport "PowerShell -Command exit code: " & CStr(rc)
  AppendReport "PowerShell -Command marker created: " & CStr(fso.FileExists(marker2))
End If
On Error GoTo 0
AppendReport ""

Dim envReport, envCommand
envReport = fso.BuildPath(tempDir, "diag-powershell-environment.txt")
DeleteIfExists envReport
envCommand = "$p=" & PsLiteral(fso.BuildPath(root, "App\Broker-PowerShell-SelfTest.ps1")) & ";" & _
  "$o=@();$o+='PSVersion: '+$PSVersionTable.PSVersion.ToString();$o+='Edition: '+$PSVersionTable.PSEdition;$o+='LanguageMode: '+$ExecutionContext.SessionState.LanguageMode;" & _
  "$o+='ExecutionPolicy:';$o+=(Get-ExecutionPolicy -List | Out-String);" & _
  "$z=Get-Content -LiteralPath $p -Stream Zone.Identifier -ErrorAction SilentlyContinue;$o+='Zone.Identifier: '+$(if($z){($z -join ' | ')}else{'none'});" & _
  "$sig=Get-AuthenticodeSignature -LiteralPath $p;$o+='SignatureStatus: '+$sig.Status;$o | Set-Content -LiteralPath " & PsLiteral(envReport) & " -Encoding Unicode"
On Error Resume Next
rc = sh.Run(Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q(envCommand), 0, True)
If Err.Number <> 0 Then
  AppendReport "PowerShell environment query launch error: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
ElseIf fso.FileExists(envReport) Then
  AppendReport "PowerShell environment:"
  AppendReport ReadTextAuto(envReport)
Else
  AppendReport "PowerShell environment query exit code: " & CStr(rc) & " (no report file created)"
End If
On Error GoTo 0
AppendReport ""

Dim selfTest
selfTest = fso.BuildPath(root, "App\Broker-PowerShell-SelfTest.ps1")
AppendReport "Self-test script: " & selfTest
AppendReport "Self-test script exists: " & CStr(fso.FileExists(selfTest))
If fso.FileExists(selfTest) Then
  On Error Resume Next
  rc = sh.Run(Q(ps) & " -NoLogo -NoProfile -NonInteractive -STA -ExecutionPolicy Bypass -File " & Q(selfTest) & " -ReadyPath " & Q(marker3), 0, True)
  If Err.Number <> 0 Then
    AppendReport "PowerShell -File launch error: " & CStr(Err.Number) & " - " & Err.Description
    Err.Clear
  Else
    AppendReport "PowerShell -File exit code: " & CStr(rc)
    AppendReport "PowerShell -File marker created: " & CStr(fso.FileExists(marker3))
  End If
  On Error GoTo 0
End If
AppendReport ""

Dim invokeDetail, invokeCommand
invokeDetail = fso.BuildPath(tempDir, "diag-ps-invoke-error.txt")
DeleteIfExists invokeDetail
invokeCommand = "$ErrorActionPreference='Stop';try{& " & PsLiteral(selfTest) & " -ReadyPath " & PsLiteral(marker4) & ";if(-not $?) {throw 'Script invocation returned failure.'};exit 0}catch{($_ | Format-List * -Force | Out-String -Width 4096) | Set-Content -LiteralPath " & PsLiteral(invokeDetail) & " -Encoding Unicode;exit 1}"
On Error Resume Next
rc = sh.Run(Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q(invokeCommand), 0, True)
If Err.Number <> 0 Then
  AppendReport "PowerShell script-invocation launch error: " & CStr(Err.Number) & " - " & Err.Description
  Err.Clear
Else
  AppendReport "PowerShell script-invocation exit code: " & CStr(rc)
  AppendReport "PowerShell script-invocation marker created: " & CStr(fso.FileExists(marker4))
  If fso.FileExists(invokeDetail) Then
    AppendReport "PowerShell script-invocation detail:"
    AppendReport ReadTextAuto(invokeDetail)
  End If
End If
On Error GoTo 0
AppendReport ""

AppendReport "Interpretation:"
AppendReport "- CMD=false: Windows child-process launch is failing before PowerShell."
AppendReport "- PowerShell -Command=false: PowerShell itself is blocked or unavailable."
AppendReport "- -File=false but script-invocation=true: use command-based script invocation; powershell.exe -File is the failing boundary."
AppendReport "- Both script tests=false: use the captured execution-policy/Zone.Identifier/error detail to identify the block."
AppendReport "- If a PowerShell exception is present below, that exception is the root diagnostic signal; do not infer policy/EDR without it."
AppendReport "- Script-invocation=true: the broker can use the v10.2.3 command-based runner path."

WScript.Quit 0

Sub DeleteIfExists(ByVal path)
  On Error Resume Next
  If fso.FileExists(path) Then fso.DeleteFile path, True
  On Error GoTo 0
End Sub

Sub WriteReport(ByVal text)
  Dim ts
  Set ts = fso.CreateTextFile(reportPath, True, True)
  ts.WriteLine text
  ts.Close
End Sub

Sub AppendReport(ByVal text)
  Dim ts
  Set ts = fso.OpenTextFile(reportPath, 8, True, -1)
  ts.WriteLine text
  ts.Close
End Sub

Function ReadTextAuto(ByVal path)
  Dim ts
  ReadTextAuto = ""
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
  ReadTextAuto = ts.ReadAll
  ts.Close
End Function

Function PsLiteral(ByVal s)
  PsLiteral = "'" & Replace(CStr(s), "'", "''") & "'"
End Function

Function Q(ByVal s)
  Q = Chr(34) & Replace(CStr(s), Chr(34), "") & Chr(34)
End Function
