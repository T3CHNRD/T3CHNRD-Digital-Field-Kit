#Requires -Version 5.1
[CmdletBinding()]
param()
$ErrorActionPreference='Continue'
$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fail=0;$warn=0;$pass=0
function Result($Status,$Message){Write-Output ('[{0}] {1}' -f $Status,$Message);switch($Status){'PASS'{$script:pass++}'WARN'{$script:warn++}'FAIL'{$script:fail++}}}
Result PASS "Toolkit root: $root"
$required=@('Toolkit.hta','Assets\tools.js','Scripts','Toolkit.ico')
foreach($r in $required){$p=Join-Path $root $r;if(Test-Path -LiteralPath $p){Result PASS "Present: $r"}else{Result FAIL "Missing: $r"}}
$parseFiles=Get-ChildItem -LiteralPath (Join-Path $root 'Scripts') -Recurse -File -Filter *.ps1 -ErrorAction SilentlyContinue
foreach($f in $parseFiles){$tokens=$null;$errors=$null;[void][System.Management.Automation.Language.Parser]::ParseFile($f.FullName,[ref]$tokens,[ref]$errors);if($errors.Count){Result FAIL ("Parse error: {0} :: {1}" -f $f.FullName,($errors|ForEach-Object Message -join ' | '))}else{Result PASS ("Parsed: "+$f.FullName.Substring($root.Length+1))}}
$cmds=@('powershell.exe','cmd.exe','robocopy.exe','sfc.exe','dism.exe','chkdsk.exe','ipconfig.exe','route.exe','driverquery.exe')
foreach($c in $cmds){if(Get-Command $c -ErrorAction SilentlyContinue){Result PASS "Command: $c"}else{Result WARN "Command unavailable: $c"}}
Write-Output ''
Write-Output ("SUMMARY: PASS={0} WARN={1} FAIL={2}" -f $pass,$warn,$fail)
if($fail){exit 1}else{exit 0}
