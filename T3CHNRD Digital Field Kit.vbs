Option Explicit
Dim fso,sh,root,ui,ps,cmdText,args,rc
Set fso=CreateObject("Scripting.FileSystemObject"):Set sh=CreateObject("WScript.Shell")
root=fso.GetParentFolderName(WScript.ScriptFullName):ui=fso.BuildPath(root,"Windows\App\T3DFK-Windows.ps1")
If Not fso.FileExists(ui) Then MsgBox "Windows application source is missing:" & vbCrLf & ui,16,"T3CHNRD Digital Field Kit":WScript.Quit 2
ps=sh.ExpandEnvironmentStrings("%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"):If Not fso.FileExists(ps) Then ps="powershell.exe"
On Error Resume Next
sh.Run Q(ps) & " -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command " & Q("Get-ChildItem -LiteralPath " & PsLiteral(root) & " -Recurse -File -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue;exit 0"),0,True
Err.Clear:On Error GoTo 0
cmdText="$ErrorActionPreference='Stop';$code=[IO.File]::ReadAllText(" & PsLiteral(ui) & ");$sb=[ScriptBlock]::Create($code);& $sb -ToolkitRoot " & PsLiteral(root)
args="-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -Command " & Q(cmdText)
rc=sh.Run(Q(ps) & " " & args,0,False):WScript.Quit rc
Function PsLiteral(ByVal x):PsLiteral="'" & Replace(CStr(x),"'","''") & "'":End Function
Function Q(ByVal x):Q=Chr(34) & Replace(CStr(x),Chr(34),Chr(34)&Chr(34)) & Chr(34):End Function
