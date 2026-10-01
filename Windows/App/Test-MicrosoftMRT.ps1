#Requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$manifest=Get-Content -LiteralPath (Join-Path $root 'Windows\Config\tools.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$tool=@($manifest | Where-Object id -eq 'microsoft-mrt')
if($tool.Count -ne 1){throw 'Microsoft MRT catalog entry is missing or duplicated.'}
if($tool[0].category -ne 'Security' -or -not $tool[0].requiresAdmin -or $tool[0].risk -ne 'SystemChange'){
    throw 'Microsoft MRT catalog safety metadata is incorrect.'
}

$systemDirectory=if([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess){
    Join-Path $env:SystemRoot 'Sysnative'
}else{
    Join-Path $env:SystemRoot 'System32'
}
$global:ExpectedMrtPath=Join-Path $systemDirectory 'MRT.exe'
$global:MrtLaunches=@()
$global:MockMrtSignatureStatus='Valid'

function Test-Path {
    param([string]$LiteralPath,[string]$PathType)
    return [string]::Equals($LiteralPath,$global:ExpectedMrtPath,[StringComparison]::OrdinalIgnoreCase)
}
function Get-AuthenticodeSignature {
    param([string]$FilePath)
    if(-not [string]::Equals($FilePath,$global:ExpectedMrtPath,[StringComparison]::OrdinalIgnoreCase)){
        throw "Unexpected signature check path: $FilePath"
    }
    return [pscustomobject]@{Status=$global:MockMrtSignatureStatus;SignerCertificate=[pscustomobject]@{Subject='CN=Microsoft Windows'}}
}
function Start-Process {
    param([string]$FilePath)
    $global:MrtLaunches+= $FilePath
}

& (Join-Path $root $tool[0].path)
if($global:MrtLaunches.Count -ne 1 -or -not [string]::Equals($global:MrtLaunches[0],$global:ExpectedMrtPath,[StringComparison]::OrdinalIgnoreCase)){
    throw 'The MRT launcher did not start the expected native Windows system executable.'
}
$global:MockMrtSignatureStatus='NotSigned'
try{
    & (Join-Path $root $tool[0].path)
    throw 'The MRT launcher accepted an invalid signature.'
}catch{
    if($_.Exception.Message -notmatch 'valid Microsoft Authenticode signature'){throw}
}
if($global:MrtLaunches.Count -ne 1){throw 'The MRT launcher started an executable with an invalid signature.'}

Write-Output 'PASS: MRT catalog metadata, native path, valid-signature launch, invalid-signature rejection. No scan was started.'