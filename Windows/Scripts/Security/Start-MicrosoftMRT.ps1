#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
$systemDirectory=if([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess){
    Join-Path $env:SystemRoot 'Sysnative'
}else{
    Join-Path $env:SystemRoot 'System32'
}
$mrtPath=Join-Path $systemDirectory 'MRT.exe'
if(-not(Test-Path -LiteralPath $mrtPath -PathType Leaf)){
    throw "Microsoft Malicious Software Removal Tool was not found at $mrtPath."
}

$signature=Get-AuthenticodeSignature -FilePath $mrtPath
$signerSubject=if($signature.SignerCertificate){[string]$signature.SignerCertificate.Subject}else{''}
if($signature.Status -ne 'Valid' -or $signerSubject -notmatch 'Microsoft'){
    throw 'The system MRT.exe does not have a valid Microsoft Authenticode signature; it was not started.'
}

Start-Process -FilePath $mrtPath -ErrorAction Stop | Out-Null
Write-Output 'Microsoft MRT opened in its own window. Choose the scan type and review any proposed removal there.'