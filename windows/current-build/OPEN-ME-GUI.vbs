Option Explicit
Dim fso, sh, root, hta
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("Shell.Application")
root = fso.GetParentFolderName(WScript.ScriptFullName)
hta = fso.BuildPath(root, "Toolkit.hta")
If Not fso.FileExists(hta) Then
  MsgBox "Toolkit.hta is missing. Extract the complete toolkit package.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If
sh.ShellExecute "mshta.exe", Chr(34) & hta & Chr(34), root, "runas", 1
