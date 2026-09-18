Option Explicit
Dim fso,app,sh,root,ps1,ps,cmdText,args
Set fso=CreateObject("Scripting.FileSystemObject"):Set app=CreateObject("Shell.Application"):Set sh=CreateObject("WScript.Shell")
root=fso.GetParentFolderName(WScript.ScriptFullName):ps1=fso.BuildPath(root,"Windows\Installer\Install-Windows.ps1")
If Not fso.FileExists(ps1) Then MsgBox "Installer source is missing.",16,"T3CHNRD Digital Field Kit":WScript.Quit 2
ps=sh.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
cmdText="$ErrorActionPreference='Stop';$code=[IO.File]::ReadAllText(" & PsLiteral(ps1) & ");& ([ScriptBlock]::Create($code)) -SourceRoot " & PsLiteral(root)
args="-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & Q(cmdText)
On Error Resume Next:app.ShellExecute ps,args,root,"runas",1
If Err.Number<>0 Then MsgBox "Windows could not start the installer: " & Err.Description,16,"T3CHNRD Digital Field Kit"
On Error GoTo 0
Function PsLiteral(ByVal x):PsLiteral="'" & Replace(CStr(x),"'","''") & "'":End Function
Function Q(ByVal x):Q=Chr(34) & Replace(CStr(x),Chr(34),Chr(34)&Chr(34)) & Chr(34):End Function
