Option Explicit
Dim fso, shApp, root, installer
Set fso = CreateObject("Scripting.FileSystemObject")
Set shApp = CreateObject("Shell.Application")
root = fso.GetParentFolderName(WScript.ScriptFullName)
installer = fso.BuildPath(root, "Installer\Install-Wizard.hta")
If Not fso.FileExists(installer) Then
  MsgBox "Installer files are missing. Extract the complete T3DFK folder first.", 16, "T3CHNRD Digital Field Kit"
  WScript.Quit 1
End If
shApp.ShellExecute "mshta.exe", Chr(34) & installer & Chr(34), root, "runas", 1
