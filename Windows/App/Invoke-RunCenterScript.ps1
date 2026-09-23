#Requires -Version 5.1
param(
    [Parameter(Mandatory=$true)][string]$TargetScript,
    [string]$ArgumentsBase64 = 'W10='
)
$ErrorActionPreference='Stop'

# ConsoleHost's Read-Host bypasses redirected stdout when no console exists.
# Keep original tools unchanged and provide the same line-input contract here.
function global:Read-Host {
    param([object]$Prompt, [switch]$AsSecureString)
    [Console]::Out.WriteLine(([string]$Prompt + ':'))
    [Console]::Out.Flush()
    $answer=[Console]::In.ReadLine()
    if($null -eq $answer){throw 'Run Center input stream was closed.'}
    $answer=$answer.TrimStart([char]0xFEFF,[char]0x200B,[char]0x00EF,[char]0x00BB,[char]0x00BF)
    if($AsSecureString){
        $secure=New-Object Security.SecureString
        foreach($character in $answer.ToCharArray()){$secure.AppendChar($character)}
        return $secure
    }
    return $answer
}

try {
    $arguments=ConvertFrom-Json -InputObject ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($ArgumentsBase64)))

    # Build a PowerShell invocation string so named parameters remain named parameters.
    # Switch names and literal PowerShell booleans are emitted unquoted; ordinary values
    # are single-quoted and escaped.
    $tokens=@($arguments | ForEach-Object {
        $value=[string]$_
        if($value -match '^-[A-Za-z][A-Za-z0-9-]*$'){
            $value
        }
        elseif($value -match '^\$(?:true|false|null)$'){
            $value
        }
        else{
            "'" + $value.Replace("'","''") + "'"
        }
    })

    $command="& '" + $TargetScript.Replace("'","''") + "' " + ($tokens -join ' ')
    $global:LASTEXITCODE=0
    & ([scriptblock]::Create($command))
    exit $LASTEXITCODE
}
catch{
    [Console]::Error.WriteLine($_.ToString())
    exit 1
}
