#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'
$root=Split-Path -Parent $PSScriptRoot
$apps=@(
    @{Name='Google Chrome';Path='R\Setup\Apps\Chrome.exe'},
    @{Name='Mozilla Firefox';Path='R\Setup\Apps\Firefox.exe'},
    @{Name='Malwarebytes';Path='R\Setup\Apps\Malwarebytes.exe'},
    @{Name='AVG Antivirus';Path='R\Setup\Apps\AVG.exe'},
    @{Name='CCleaner';Path='R\Setup\Apps\CCleaner.exe'}
)
Write-Output 'T3CHNRD Digital Field Kit - Install All Deployment Apps'
Write-Output 'Excluded by design: Win11Debloat and all WinUtil tools.'
$missing=0;$failed=0
foreach($app in $apps){
    $path=Join-Path $root $app.Path
    if(-not (Test-Path -LiteralPath $path -PathType Leaf)){Write-Warning ("Missing installer: {0} ({1})" -f $app.Name,$path);$missing++;continue}
    Write-Output ("Starting installer: {0}" -f $app.Name)
    try{
        $p=Start-Process -FilePath $path -WorkingDirectory (Split-Path -Parent $path) -PassThru -Wait -ErrorAction Stop
        Write-Output ("Installer finished: {0} (exit code {1})" -f $app.Name,$p.ExitCode)
        if($p.ExitCode -notin @(0,1641,3010)){$failed++}
    }catch{Write-Warning ("Installer failed to launch or complete: {0} - {1}" -f $app.Name,$_.Exception.Message);$failed++}
}
Write-Output ("Install-all sequence finished. Missing={0}; Failed/nonstandard exit={1}" -f $missing,$failed)
if($failed -gt 0){exit 1}
exit 0
