Option Explicit
If WScript.Arguments.Count > 0 Then
  If LCase(WScript.Arguments(0)) = "/syntax-only" Then WScript.Quit 0
End If
Dim fso, sh, root, target
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
root = fso.GetParentFolderName(WScript.ScriptFullName)
target = fso.BuildPath(root, "OPEN-ME-GUI.vbs")
If Not fso.FileExists(target) Then
  MsgBox "OPEN-ME-GUI.vbs is missing. Extract the complete toolkit package.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If
sh.Run Chr(34) & sh.ExpandEnvironmentStrings("%SystemRoot%\System32\wscript.exe") & Chr(34) & " " & Chr(34) & target & Chr(34), 1, False
