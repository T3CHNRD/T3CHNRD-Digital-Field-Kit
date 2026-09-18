Option Explicit
Dim fso,app,sh,root,ps1,ps,cmdText,args
Set fso=CreateObject("Scripting.FileSystemObject"):Set app=CreateObject("Shell.Application"):Set sh=CreateObject("WScript.Shell")
root=fso.GetParentFolderName(WScript.ScriptFullName):ps1=fso.BuildPath(root,"Windows\Installer\Uninstall-Windows.ps1"):ps=sh.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe")
cmdText="$code=[IO.File]::ReadAllText(" & PsLiteral(ps1) & ");& ([ScriptBlock]::Create($code)) -InstallRoot " & PsLiteral(root):args="-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & Q(cmdText):app.ShellExecute ps,args,root,"runas",0
Function PsLiteral(ByVal x):PsLiteral="'" & Replace(CStr(x),"'","''") & "'":End Function
Function Q(ByVal x):Q=Chr(34) & Replace(CStr(x),Chr(34),Chr(34)&Chr(34)) & Chr(34):End Function
