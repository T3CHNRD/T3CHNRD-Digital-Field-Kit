Option Explicit

Dim fso, sh, root, reportPath, tempDir, ps, cmdExe, marker1, marker2, marker3, rc
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")

If WScript.Arguments.Count < 2 Then WScript.Quit 2
root = WScript.Arguments(0)
reportPath = WScript.Arguments(1)
tempDir = fso.GetParentFolderName(reportPath)
If Not fso.FolderExists(tempDir) Then fso.CreateFolder tempDir

WriteReport "T3CHNRD Digital Field Kit - Runner Diagnostics"
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
DeleteIfExists marker1
DeleteIfExists marker2
DeleteIfExists marker3

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

Dim psCommand, psLiteral
psLiteral = Replace(marker2, "'", "''")
psCommand = Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q("[IO.File]::WriteAllText('" & psLiteral & "','powershell-command-ok',[Text.Encoding]::ASCII)")
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
AppendReport "Interpretation:"
AppendReport "- CMD=false: Windows child-process launch is failing before PowerShell."
AppendReport "- CMD=true, PowerShell -Command=false: PowerShell itself is blocked or unavailable."
AppendReport "- PowerShell -Command=true, PowerShell -File=false: script-file execution is being blocked or failing."
AppendReport "- All three=true: the PowerShell engine is healthy; investigate broker/request wiring next."

WScript.Quit 0

Sub DeleteIfExists(ByVal path)
  On Error Resume Next
  If fso.FileExists(path) Then fso.DeleteFile path, True
  On Error GoTo 0
End Sub

Sub WriteReport(ByVal text)
  Dim ts
  Set ts = fso.CreateTextFile(reportPath, True, False)
  ts.WriteLine text
  ts.Close
End Sub

Sub AppendReport(ByVal text)
  Dim ts
  Set ts = fso.OpenTextFile(reportPath, 8, True, 0)
  ts.WriteLine text
  ts.Close
End Sub

Function Q(ByVal s)
  Q = Chr(34) & Replace(CStr(s), Chr(34), "") & Chr(34)
End Function
