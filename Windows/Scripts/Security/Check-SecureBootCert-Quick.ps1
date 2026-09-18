#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$result = [ordered]@{
    ComputerName       = $env:COMPUTERNAME
    SecureBootStatus   = 'Unknown'
    SecureBootEnabled  = $null
    WindowsUEFICA2023  = $null
    Notes              = ''
}

try {
    $enabled = Confirm-SecureBootUEFI
    $result.SecureBootEnabled = [bool]$enabled
    $result.SecureBootStatus = if ($enabled) { 'Enabled' } else { 'Disabled' }
}
catch {
    $result.SecureBootStatus = 'UnsupportedOrUnavailable'
    $result.Notes = $_.Exception.Message
}

try {
    $db = (Get-SecureBootUEFI -Name db).Bytes
    $text = [System.Text.Encoding]::ASCII.GetString($db)
    $result.WindowsUEFICA2023 = [bool]($text -match 'Windows UEFI CA 2023')
}
catch {
    if ([string]::IsNullOrWhiteSpace($result.Notes)) {
        $result.Notes = $_.Exception.Message
    } else {
        $result.Notes += ' | ' + $_.Exception.Message
    }
}

[pscustomobject]$result | Format-List
