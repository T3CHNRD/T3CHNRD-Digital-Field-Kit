Option Explicit
Dim fso, sh, root, diag, report, token, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
root = fso.GetParentFolderName(WScript.ScriptFullName)
diag = fso.BuildPath(root, "App\Runner-Diagnostics.vbs")
If Not fso.FileExists(diag) Then
  MsgBox "Runner-Diagnostics.vbs is missing. Extract the complete toolkit package.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If
Randomize
token = Replace(Replace(Replace(CStr(Now), "/", ""), ":", ""), " ", "-") & "-" & CStr(Int(Rnd * 1000000))
report = fso.BuildPath(sh.ExpandEnvironmentStrings("%TEMP%"), "T3DFK-Runner-Diagnostics-" & token & ".txt")
cmd = Chr(34) & sh.ExpandEnvironmentStrings("%SystemRoot%\System32\wscript.exe") & Chr(34) & " " & Chr(34) & diag & Chr(34) & " " & Chr(34) & root & Chr(34) & " " & Chr(34) & report & Chr(34)
sh.Run cmd, 0, True
If fso.FileExists(report) Then
  sh.Run "notepad.exe " & Chr(34) & report & Chr(34), 1, False
Else
  MsgBox "Runner diagnostics did not create a report.", 16, "T3CHNRD Digital Field Kit"
End If
