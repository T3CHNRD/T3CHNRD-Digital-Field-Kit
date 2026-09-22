#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Source,
    [string]$Destination,
    [switch]$Move,
    [switch]$Mirror
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Select-Folder {
    param([string]$Description)
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return $null
}

try {
    $robocopy = Join-Path $env:SystemRoot 'System32\robocopy.exe'
    if (-not (Test-Path -LiteralPath $robocopy)) { throw 'robocopy.exe is not available on this Windows installation.' }

    if ([string]::IsNullOrWhiteSpace($Source)) { $Source = Select-Folder 'Select the SOURCE folder to copy from' }
    if ([string]::IsNullOrWhiteSpace($Source)) { Write-Output 'Transfer cancelled: no source selected.'; exit 0 }
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Source folder does not exist: $Source" }

    if ([string]::IsNullOrWhiteSpace($Destination)) { $Destination = Select-Folder 'Select the DESTINATION folder to copy to' }
    if ([string]::IsNullOrWhiteSpace($Destination)) { Write-Output 'Transfer cancelled: no destination selected.'; exit 0 }

    $srcFull = [IO.Path]::GetFullPath($Source).TrimEnd('\\')
    $dstFull = [IO.Path]::GetFullPath($Destination).TrimEnd('\\')
    if ($srcFull -ieq $dstFull) { throw 'Source and destination cannot be the same folder.' }
    if ($dstFull.StartsWith($srcFull + '\\',[StringComparison]::OrdinalIgnoreCase)) {
        throw 'Destination cannot be inside the source folder.'
    }

    $logRoot = Join-Path $env:TEMP 'WindowsMasterDiagnosticToolkit'
    New-Item -Path $logRoot -ItemType Directory -Force | Out-Null
    $log = Join-Path $logRoot ("DataTransfer_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

    $args = @($srcFull,$dstFull,'/E','/COPY:DAT','/DCOPY:DAT','/R:2','/W:2','/XJ','/Z','/FFT','/NP',"/LOG:$log")
    if ($Move) { $args += '/MOVE' }
    if ($Mirror) {
        Write-Warning 'MIRROR mode can delete destination files that do not exist in the source.'
        $confirm = Read-Host 'Type MIRROR to continue'
        if ($confirm -cne 'MIRROR') { Write-Output 'Mirror cancelled.'; exit 0 }
        $args = @($srcFull,$dstFull,'/MIR','/COPY:DAT','/DCOPY:DAT','/R:2','/W:2','/XJ','/Z','/FFT','/NP',"/LOG:$log")
    }

    Write-Output "Source:      $srcFull"
    Write-Output "Destination: $dstFull"
    Write-Output "Log:         $log"
    & $robocopy @args
    $code = $LASTEXITCODE

    # Robocopy exit codes 0-7 are success/non-fatal states; 8+ indicates failure.
    if ($code -ge 8) { throw "Robocopy failed with exit code $code. Review: $log" }
    Write-Output "Transfer completed. Robocopy exit code: $code"
    Write-Output "Robocopy log: $log"
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
