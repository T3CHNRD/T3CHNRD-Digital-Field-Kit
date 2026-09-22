#requires -RunAsAdministrator
#requires -Version 5.1

<#
.SYNOPSIS
    Switches a laptop network adapter between:
      1. Normal network: 192.168.10.151/24
      2. Any alternate /24 subnet entered by the user

.NORMAL NETWORK
    IP address:      192.168.10.151
    Subnet mask:     255.255.255.0
    Default gateway: 192.168.10.1
    DNS servers:     192.168.1.11, 192.168.1.9

.ALTERNATE NETWORK
    The user enters a subnet such as 192.168.2.
    The script uses:
      IP address:      192.168.2.151
      Subnet mask:     255.255.255.0
      Default gateway: 192.168.2.1
      DNS servers:     192.168.1.11, 192.168.1.9
#>

$NormalIPAddress = '192.168.10.151'
$NormalGateway   = '192.168.10.1'
$SubnetMask      = '255.255.255.0'
$PrefixLength    = 24

$DnsServers = @(
    '192.168.1.11',
    '192.168.1.9'
)

function Get-ActiveNetworkAdapter {
    $Adapters = @(
        Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Status -eq 'Up' -and
                $_.Name -notmatch 'Bluetooth|vEthernet|VPN|VMware|VirtualBox'
            } |
            Sort-Object Name
    )

    if ($Adapters.Count -eq 0) {
        throw 'No active physical Ethernet or Wi-Fi adapter was found.'
    }

    if ($Adapters.Count -eq 1) {
        return $Adapters[0]
    }

    Write-Host ''
    Write-Host 'Available active network adapters:' -ForegroundColor Cyan

    for ($Index = 0; $Index -lt $Adapters.Count; $Index++) {
        Write-Host "$($Index + 1). $($Adapters[$Index].Name) - $($Adapters[$Index].InterfaceDescription)"
    }

    $SelectedNumber = 0
    $ValidSelection = $false

    do {
        $Selection = Read-Host 'Select the network adapter number'

        $ValidSelection =
            [int]::TryParse($Selection, [ref]$SelectedNumber) -and
            $SelectedNumber -ge 1 -and
            $SelectedNumber -le $Adapters.Count

        if (-not $ValidSelection) {
            Write-Warning "Enter a number between 1 and $($Adapters.Count)."
        }
    }
    until ($ValidSelection)

    return $Adapters[$SelectedNumber - 1]
}

function Get-AlternateNetworkConfiguration {
    Write-Host ''
    Write-Host 'Enter an alternate /24 subnet using one of these formats:' -ForegroundColor Cyan
    Write-Host '  192.168.2'
    Write-Host '  192.168.2.0'
    Write-Host '  192.168.2.0/24'
    Write-Host ''

    do {
        $SubnetInput = (Read-Host 'Alternate subnet').Trim()

        $SubnetInput = $SubnetInput -replace '/24$', ''
        $SubnetInput = $SubnetInput -replace '\.0$', ''

        $Parts = @($SubnetInput -split '\.')
        $ValidSubnet = $Parts.Count -eq 3

        if ($ValidSubnet) {
            foreach ($Part in $Parts) {
                $Octet = 0

                if (
                    -not [int]::TryParse($Part, [ref]$Octet) -or
                    $Octet -lt 0 -or
                    $Octet -gt 255
                ) {
                    $ValidSubnet = $false
                    break
                }
            }
        }

        if (-not $ValidSubnet) {
            Write-Warning 'Enter a valid /24 subnet, such as 192.168.2.'
        }
    }
    until ($ValidSubnet)

    $NetworkBase = $Parts -join '.'

    [pscustomobject]@{
        Network        = "$NetworkBase.0/24"
        IPAddress      = "$NetworkBase.151"
        DefaultGateway = "$NetworkBase.1"
    }
}

function Set-StaticNetworkConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$InterfaceAlias,

        [Parameter(Mandatory)]
        [string]$IPAddress,

        [Parameter(Mandatory)]
        [string]$DefaultGateway
    )

    Write-Host ''
    Write-Host "Configuring adapter: $InterfaceAlias" -ForegroundColor Cyan
    Write-Host "IP address:      $IPAddress/$PrefixLength"
    Write-Host "Default gateway: $DefaultGateway"
    Write-Host "DNS servers:     $($DnsServers -join ', ')"
    Write-Host ''

    # netsh "set address" replaces the existing IPv4 address and gateway.
    # This prevents the "Instance DefaultGateway already exists" error.
    $AddressArguments = @(
        'interface',
        'ipv4',
        'set',
        'address',
        "name=$InterfaceAlias",
        'source=static',
        "address=$IPAddress",
        "mask=$SubnetMask",
        "gateway=$DefaultGateway",
        'gwmetric=1'
    )

    $AddressProcess = Start-Process `
        -FilePath 'netsh.exe' `
        -ArgumentList $AddressArguments `
        -Wait `
        -PassThru `
        -NoNewWindow

    if ($AddressProcess.ExitCode -ne 0) {
        throw "netsh could not apply the IPv4 address. Exit code: $($AddressProcess.ExitCode)"
    }

    Set-DnsClientServerAddress `
        -InterfaceAlias $InterfaceAlias `
        -ServerAddresses $DnsServers `
        -ErrorAction Stop

    Clear-DnsClientCache

    Start-Sleep -Seconds 2

    Write-Host ''
    Write-Host 'Network configuration updated successfully.' -ForegroundColor Green
}

function Show-CurrentConfiguration {
    param(
        [Parameter(Mandatory)]
        [string]$InterfaceAlias
    )

    Write-Host ''
    Write-Host 'Current IPv4 configuration:' -ForegroundColor Cyan
    Write-Host ''

    $Configuration = Get-NetIPConfiguration `
        -InterfaceAlias $InterfaceAlias `
        -ErrorAction Stop

    $IPv4Addresses = @(
        $Configuration.IPv4Address |
            ForEach-Object {
                "$($_.IPAddress)/$($_.PrefixLength)"
            }
    )

    $IPv4DnsServers = @(
        $Configuration.DNSServer |
            Where-Object AddressFamily -eq 2 |
            Select-Object -ExpandProperty ServerAddresses
    )

    [pscustomobject]@{
        Adapter        = $Configuration.InterfaceAlias
        IPv4Address    = $IPv4Addresses -join ', '
        DefaultGateway = $Configuration.IPv4DefaultGateway.NextHop -join ', '
        DNSServers     = $IPv4DnsServers -join ', '
    } |
        Format-List
}

try {
    $Adapter = Get-ActiveNetworkAdapter
    $InterfaceAlias = $Adapter.Name
    $ExitRequested = $false

    while (-not $ExitRequested) {
        Clear-Host

        Write-Host 'Laptop Network Toggle' -ForegroundColor Cyan
        Write-Host '---------------------'
        Write-Host "Adapter: $InterfaceAlias"
        Write-Host ''
        Write-Host '1. Switch to normal 192.168.10.x network'
        Write-Host '   IP:      192.168.10.151/24'
        Write-Host '   Gateway: 192.168.10.1'
        Write-Host ''
        Write-Host '2. Switch to an alternate /24 subnet'
        Write-Host '   You enter the subnet; the script uses .151 and gateway .1'
        Write-Host ''
        Write-Host '3. Show current configuration'
        Write-Host '4. Exit'
        Write-Host ''

        $Choice = Read-Host 'Enter your selection'

        switch ($Choice) {
            '1' {
                Write-Host ''
                Write-Host 'Normal network configuration:' -ForegroundColor Yellow
                Write-Host "IP address:      $NormalIPAddress/$PrefixLength"
                Write-Host "Default gateway: $NormalGateway"
                Write-Host "DNS servers:     $($DnsServers -join ', ')"
                Write-Host ''

                $Confirmation = Read-Host 'Type Y to apply the normal configuration'

                if ($Confirmation -match '^[Yy]$') {
                    Set-StaticNetworkConfiguration `
                        -InterfaceAlias $InterfaceAlias `
                        -IPAddress $NormalIPAddress `
                        -DefaultGateway $NormalGateway

                    Show-CurrentConfiguration -InterfaceAlias $InterfaceAlias
                }
                else {
                    Write-Host 'No changes were made.' -ForegroundColor Yellow
                }

                Read-Host 'Press Enter to return to the menu'
            }

            '2' {
                $Alternate = Get-AlternateNetworkConfiguration

                Write-Host ''
                Write-Host 'Alternate network configuration:' -ForegroundColor Yellow
                Write-Host "Network:         $($Alternate.Network)"
                Write-Host "IP address:      $($Alternate.IPAddress)/$PrefixLength"
                Write-Host "Default gateway: $($Alternate.DefaultGateway)"
                Write-Host "DNS servers:     $($DnsServers -join ', ')"
                Write-Host ''

                $Confirmation = Read-Host 'Type Y to apply the alternate configuration'

                if ($Confirmation -match '^[Yy]$') {
                    Set-StaticNetworkConfiguration `
                        -InterfaceAlias $InterfaceAlias `
                        -IPAddress $Alternate.IPAddress `
                        -DefaultGateway $Alternate.DefaultGateway

                    Show-CurrentConfiguration -InterfaceAlias $InterfaceAlias
                }
                else {
                    Write-Host 'No changes were made.' -ForegroundColor Yellow
                }

                Read-Host 'Press Enter to return to the menu'
            }

            '3' {
                Show-CurrentConfiguration -InterfaceAlias $InterfaceAlias
                Read-Host 'Press Enter to return to the menu'
            }

            '4' {
                $ExitRequested = $true
            }

            default {
                Write-Warning 'Invalid selection. Enter 1, 2, 3, or 4.'
                Start-Sleep -Seconds 2
            }
        }
    }
}
catch {
    Write-Host ''
    Write-Error "The network configuration could not be changed: $($_.Exception.Message)"
    Write-Host ''
    Read-Host 'Press Enter to close'
    exit 1
}
