#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'

$root=$env:TTK_TOOLKIT_ROOT
if([string]::IsNullOrWhiteSpace($root)){
    $root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$pass=0;$warn=0;$fail=0
function Result {
    param([string]$Status,[string]$Message)
    Write-Output ("[{0}] {1}" -f $Status,$Message)
    switch($Status){'PASS'{$script:pass++}'WARN'{$script:warn++}'FAIL'{$script:fail++}}
}

Result PASS "Toolkit root: $root"
$required=@(
    'T3CHNRD Digital Field Kit.vbs',
    'INSTALL T3CHNRD Digital Field Kit.vbs',
    'UNINSTALL T3CHNRD Digital Field Kit.vbs',
    'Windows\App\T3DFK-Windows.ps1',
    'Windows\Config\tools.json',
    'Windows\Config\ORIGINAL-SCRIPTS-GIT-SHA1.txt'
)
foreach($relative in $required){
    $path=Join-Path $root $relative
    if(Test-Path -LiteralPath $path -PathType Leaf){Result PASS "Present: $relative"}else{Result FAIL "Missing: $relative"}
}

$manifestPath=Join-Path $root 'Windows\Config\tools.json'
try{
    $parsed=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8|ConvertFrom-Json
    $tools=@()
    foreach($entry in $parsed){$tools+=$entry}
    Result PASS ("Tool manifest parsed: {0} entries" -f $tools.Count)

    $allowedCategories=@('Diagnostics','Repair','Optimization','Security','Network','Deployment','System Management')
    $categoryMap=@{
        Diagnostics='Diagnostics'
        Security='Security'
        BitLocker='Security'
        Network='Network'
        Storage='Repair'
        Updates='Optimization'
        Setup='Deployment'
        Advanced='System Management'
    }

    $duplicateIds=@($tools|Group-Object id|Where-Object Count -gt 1)
    if($duplicateIds.Count){Result FAIL ("Duplicate tool IDs: "+(($duplicateIds.Name)-join ', '))}
    else{Result PASS 'Tool IDs are unique.'}

    foreach($tool in $tools){
        if($allowedCategories -notcontains [string]$tool.category){
            Result FAIL ("Invalid category: {0} -> {1}" -f $tool.name,$tool.category)
            continue
        }

        if($categoryMap.ContainsKey([string]$tool.originalCategory)){
            $expected=$categoryMap[[string]$tool.originalCategory]
            if([string]$tool.category -eq $expected){
                Result PASS ("Category mapping: {0} -> {1}" -f $tool.name,$tool.category)
            }else{
                Result FAIL ("Category mismatch: {0}; original={1}; expected={2}; actual={3}" -f $tool.name,$tool.originalCategory,$expected,$tool.category)
            }
        }

        if($tool.ready -and $tool.path -and $tool.path -ne 'INSTALLALL'){
            $toolPath=Join-Path $root ([string]$tool.path)
            if(Test-Path -LiteralPath $toolPath -PathType Leaf){Result PASS ("Mapped tool exists: "+$tool.name)}
            else{Result FAIL ("Mapped tool missing: {0} -> {1}" -f $tool.name,$tool.path)}

            if(([string]$tool.path -match '\.ps1

$parseFiles=Get-ChildItem -LiteralPath (Join-Path $root 'Windows') -Recurse -File -Filter *.ps1 -ErrorAction SilentlyContinue
foreach($file in $parseFiles){
    $tokens=$null;$errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){Result FAIL ("Parse error: {0} :: {1}" -f $file.FullName,(($errors|ForEach-Object Message)-join ' | '))}
    else{Result PASS ("Parsed: "+$file.FullName.Substring($root.Length+1))}
}

$hashManifest=Join-Path $root 'Windows\Config\ORIGINAL-SCRIPTS-GIT-SHA1.txt'
if(Test-Path -LiteralPath $hashManifest){
    foreach($line in Get-Content -LiteralPath $hashManifest){
        if([string]::IsNullOrWhiteSpace($line)){continue}
        if($line -notmatch '^([0-9a-fA-F]{40})\s+\*(.+)$'){Result FAIL ("Invalid hash-manifest line: $line");continue}
        $expected=$matches[1].ToLowerInvariant();$relative=$matches[2];$path=Join-Path $root $relative
        if(-not(Test-Path -LiteralPath $path -PathType Leaf)){Result FAIL ("Immutable source missing: $relative");continue}
        $bytes=[IO.File]::ReadAllBytes($path)
        $prefix=[Text.Encoding]::UTF8.GetBytes(("blob {0}{1}" -f $bytes.Length,[char]0))
        $all=New-Object byte[] ($prefix.Length+$bytes.Length)
        [Array]::Copy($prefix,0,$all,0,$prefix.Length)
        [Array]::Copy($bytes,0,$all,$prefix.Length,$bytes.Length)
        $sha=[Security.Cryptography.SHA1]::Create()
        try{$actual=(-join ($sha.ComputeHash($all)|ForEach-Object {$_.ToString('x2')}))}finally{$sha.Dispose()}
        if($actual -eq $expected){Result PASS ("Immutable source hash: $relative")}else{Result FAIL ("Immutable source changed: $relative")}
    }
}else{Result FAIL 'Immutable original-script manifest is missing.'}

Write-Output ''
Write-Output ("SUMMARY: PASS={0} WARN={1} FAIL={2}" -f $pass,$warn,$fail)
if($fail){exit 1}else{exit 0}
) -and [string]$tool.executionMode -ne 'InApp'){
                Result FAIL ("PowerShell tool is not marked for in-app execution: "+$tool.name)
            }elseif([string]$tool.path -match '\.ps1

$parseFiles=Get-ChildItem -LiteralPath (Join-Path $root 'Windows') -Recurse -File -Filter *.ps1 -ErrorAction SilentlyContinue
foreach($file in $parseFiles){
    $tokens=$null;$errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){Result FAIL ("Parse error: {0} :: {1}" -f $file.FullName,(($errors|ForEach-Object Message)-join ' | '))}
    else{Result PASS ("Parsed: "+$file.FullName.Substring($root.Length+1))}
}

$hashManifest=Join-Path $root 'Windows\Config\ORIGINAL-SCRIPTS-GIT-SHA1.txt'
if(Test-Path -LiteralPath $hashManifest){
    foreach($line in Get-Content -LiteralPath $hashManifest){
        if([string]::IsNullOrWhiteSpace($line)){continue}
        if($line -notmatch '^([0-9a-fA-F]{40})\s+\*(.+)$'){Result FAIL ("Invalid hash-manifest line: $line");continue}
        $expected=$matches[1].ToLowerInvariant();$relative=$matches[2];$path=Join-Path $root $relative
        if(-not(Test-Path -LiteralPath $path -PathType Leaf)){Result FAIL ("Immutable source missing: $relative");continue}
        $bytes=[IO.File]::ReadAllBytes($path)
        $prefix=[Text.Encoding]::UTF8.GetBytes(("blob {0}{1}" -f $bytes.Length,[char]0))
        $all=New-Object byte[] ($prefix.Length+$bytes.Length)
        [Array]::Copy($prefix,0,$all,0,$prefix.Length)
        [Array]::Copy($bytes,0,$all,$prefix.Length,$bytes.Length)
        $sha=[Security.Cryptography.SHA1]::Create()
        try{$actual=(-join ($sha.ComputeHash($all)|ForEach-Object {$_.ToString('x2')}))}finally{$sha.Dispose()}
        if($actual -eq $expected){Result PASS ("Immutable source hash: $relative")}else{Result FAIL ("Immutable source changed: $relative")}
    }
}else{Result FAIL 'Immutable original-script manifest is missing.'}

Write-Output ''
Write-Output ("SUMMARY: PASS={0} WARN={1} FAIL={2}" -f $pass,$warn,$fail)
if($fail){exit 1}else{exit 0}
){
                Result PASS ("In-app execution mode: "+$tool.name)
            }
        }
    }
}catch{Result FAIL ("Tool manifest error: "+$_.Exception.Message)}

$parseFiles=Get-ChildItem -LiteralPath (Join-Path $root 'Windows') -Recurse -File -Filter *.ps1 -ErrorAction SilentlyContinue
foreach($file in $parseFiles){
    $tokens=$null;$errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName,[ref]$tokens,[ref]$errors)
    if($errors.Count){Result FAIL ("Parse error: {0} :: {1}" -f $file.FullName,(($errors|ForEach-Object Message)-join ' | '))}
    else{Result PASS ("Parsed: "+$file.FullName.Substring($root.Length+1))}
}

$hashManifest=Join-Path $root 'Windows\Config\ORIGINAL-SCRIPTS-GIT-SHA1.txt'
if(Test-Path -LiteralPath $hashManifest){
    foreach($line in Get-Content -LiteralPath $hashManifest){
        if([string]::IsNullOrWhiteSpace($line)){continue}
        if($line -notmatch '^([0-9a-fA-F]{40})\s+\*(.+)$'){Result FAIL ("Invalid hash-manifest line: $line");continue}
        $expected=$matches[1].ToLowerInvariant();$relative=$matches[2];$path=Join-Path $root $relative
        if(-not(Test-Path -LiteralPath $path -PathType Leaf)){Result FAIL ("Immutable source missing: $relative");continue}
        $bytes=[IO.File]::ReadAllBytes($path)
        $prefix=[Text.Encoding]::UTF8.GetBytes(("blob {0}{1}" -f $bytes.Length,[char]0))
        $all=New-Object byte[] ($prefix.Length+$bytes.Length)
        [Array]::Copy($prefix,0,$all,0,$prefix.Length)
        [Array]::Copy($bytes,0,$all,$prefix.Length,$bytes.Length)
        $sha=[Security.Cryptography.SHA1]::Create()
        try{$actual=(-join ($sha.ComputeHash($all)|ForEach-Object {$_.ToString('x2')}))}finally{$sha.Dispose()}
        if($actual -eq $expected){Result PASS ("Immutable source hash: $relative")}else{Result FAIL ("Immutable source changed: $relative")}
    }
}else{Result FAIL 'Immutable original-script manifest is missing.'}

Write-Output ''
Write-Output ("SUMMARY: PASS={0} WARN={1} FAIL={2}" -f $pass,$warn,$fail)
if($fail){exit 1}else{exit 0}
