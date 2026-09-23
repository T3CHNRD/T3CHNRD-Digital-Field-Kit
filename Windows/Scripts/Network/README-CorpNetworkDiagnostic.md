# Corp Network Diagnostic — README

## Script

`Invoke-CorpNetworkDiagnostic.ps1`

## Purpose

This script is designed to help troubleshoot Windows network issues, especially cases where:

- A laptop can connect to a guest Wi-Fi network but cannot connect properly to the corporate Wi-Fi network.
- Corporate Wi-Fi should provide access to Active Directory, internal resources, or shared drives.
- You need to compare LAN and Wi-Fi network configuration.
- You need to capture `ipconfig /all` and related Windows network evidence.
- You need to perform a controlled LAN DHCP refresh.
- You want the results saved into a report folder for review.

The script is intended to work both:

- Standalone from PowerShell.
- Inside the T3CHNRD Digital Field Kit Run Center.

---

# Administrator Rights

Run the script from an elevated PowerShell session.

Example:

1. Right-click **Windows PowerShell**.
2. Select **Run as administrator**.
3. Change to the folder containing the script.

Example:

```powershell
cd "C:\Path\To\Script"
```

---

# Main Commands

## 1. Full Network Diagnostic

Use this first for most troubleshooting.

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action All
```

This collects the overall network state, including:

- Network Discovery status.
- Network Discovery service state.
- Network Discovery firewall rules.
- `ipconfig /all`.
- Network adapter information.
- IP configuration.
- Network connection profiles.
- IPv4 routes.
- DNS server configuration.
- Domain / workgroup membership.
- Domain controller discovery when applicable.
- Computer Group Policy summary.
- Wi-Fi interface information.
- Wi-Fi driver information.
- Saved Wi-Fi profiles.
- Visible Wi-Fi networks and BSSIDs.
- Recent WLAN AutoConfig warnings/errors.
- Windows WLAN report.
- Wired LAN adapter information.

This mode does **not** release and renew the LAN address unless `-RenewLAN` is also specified.

---

## 2. LAN Cable Connected — Flush DNS / Release / Renew

Use this after connecting the Ethernet/LAN cable.

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action RenewLAN
```

The script will automatically attempt to detect the wired network adapter and then perform:

```text
ipconfig /flushdns
ipconfig /release "<detected LAN adapter>"
ipconfig /renew "<detected LAN adapter>"
ipconfig /all
```

You do **not** need to manually run those commands yourself.

The script also records the results in the diagnostic report.

---

## 3. Force a Specific LAN Adapter

If auto-detection chooses the wrong adapter, specify the adapter name.

Example:

```powershell
.\Invoke-CorpNetworkDiagostic.ps1 -Action RenewLAN -LanAlias "Ethernet"
```

Replace `Ethernet` with the actual Windows adapter name if different.

To see adapter names:

```powershell
Get-NetAdapter
```

---

## 4. Wi-Fi Diagnostic Only

To focus primarily on the wireless adapter:

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action WiFi
```

Optional: specify the Wi-Fi adapter name manually.

```powershell
.\Invoke-CorpNetworkDiagostic.ps1 -Action WiFi -WifiAlias "Wi-Fi"
```

---

## 5. LAN Diagnostic Only

To focus on the wired connection without performing DHCP release/renew:

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action LAN
```

Optional:

```powershell
.\Invoke-CorpNetworkDiagostic.ps1 -Action LAN -LanAlias "Ethernet"
```

---

## 6. Current-State Snapshot

To collect the current network state without intentionally performing the LAN DHCP reset sequence:

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action Snapshot
```

---

## 7. Full Diagnostic Plus LAN Renew

If you want the full diagnostic collection and also want the wired DHCP renew sequence:

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action All -RenewLAN
```

Connect the LAN cable before using this option.

---

# Recommended Troubleshooting Workflow

## Step 1 — Corporate Wi-Fi Test

Connect to the corporate Wi-Fi network, or attempt to connect to it.

Run:

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action All
```

Review the generated report for:

- Wi-Fi adapter status.
- Current SSID.
- IP address.
- Default gateway.
- DNS servers.
- Network category.
- Domain membership.
- WLAN AutoConfig errors.
- BSSID / signal information.
- Wi-Fi driver information.

---

## Step 2 — Wired LAN Test

Disconnect from Wi-Fi if appropriate and connect the Ethernet/LAN cable.

Run:

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action RenewLAN
```

This performs:

```text
ipconfig /flushdns
ipconfig /release "<LAN adapter>"
ipconfig /renew "<LAN adapter>"
ipconfig /all
```

Compare the resulting configuration to the Wi-Fi results.

Pay particular attention to:

- IPv4 address.
- Subnet mask / prefix.
- Default gateway.
- DNS servers.
- DNS suffix.
- DHCP server.
- Domain connectivity.
- Network profile.

---

## Step 3 — Compare Guest Wi-Fi vs Corporate Wi-Fi

If guest Wi-Fi works but corporate Wi-Fi does not, compare:

- SSID.
- IPv4 address.
- DNS servers.
- Default gateway.
- DNS suffix.
- Network category.
- Domain controller discovery.
- WLAN AutoConfig events.
- Authentication failures.

A laptop that can use guest Wi-Fi but not corporate Wi-Fi may have a problem involving:

- Corporate Wi-Fi profile.
- 802.1X / EAP authentication.
- User or computer certificate.
- RADIUS / NPS authentication.
- Group Policy wireless profile.
- Domain authentication.
- Wi-Fi driver.
- DHCP or DNS configuration.

The diagnostic report is intended to help distinguish those problems from a simple TCP/IP issue.

---

# Network Discovery

By default, the script checks Network Discovery and attempts to enable the services and firewall rules normally required for it.

It enables Network Discovery firewall rules for:

- Domain profiles.
- Private profiles.

It intentionally does **not** enable Network Discovery for Public profiles.

This is important because guest Wi-Fi networks are commonly classified as Public.

To skip the Network Discovery change:

```powershell
.\Invoke-CorpNetworkDiagnostic.ps1 -Action All -EnableNetworkDiscovery $false
```

---

# MultiAP / AP / Client Isolation

The script does **not** change:

- MultiAP Isolation.
- AP Isolation.
- Client Isolation.
- Wireless controller isolation policies.

Those settings are normally configured on the wireless access point or wireless controller, not on the Windows laptop.

If someone recommends:

> Un-check Enable MultiAP Isolation

verify that setting on the correct AP/controller and confirm that changing it is appropriate for the corporate WLAN design.

Do not assume it should be disabled globally.

---

# Reports

When run inside the T3CHNRD Digital Field Kit, the script uses the Field Kit report directory.

When run standalone, it creates a `Diagnostic-Reports` folder beside the script.

A typical report folder looks like:

```text
Diagnostic-Reports\
    Network-Diagnostic_COMPUTERNAME_YYYY-MM-DD_HHMMSS\
        Network-Diagnostic.txt
```

The report contains the collected command output and troubleshooting evidence.

---

# Useful Manual Commands

These commands are already used by the script where applicable, but they can also be useful manually.

## Show All IP Configuration

```powershell
ipconfig /all
```

## Flush DNS

```powershell
ipconfig /flushdns
```

## Release DHCP Address

```powershell
ipconfig /release
```

## Renew DHCP Address

```powershell
ipconfig /renew
```

## Show Network Adapters

```powershell
Get-NetAdapter
```

## Show Windows Network Profiles

```powershell
Get-NetConnectionProfile
```

## Show Wi-Fi Interface

```powershell
netsh wlan show interfaces
```

## Show Wi-Fi Drivers

```powershell
netsh wlan show drivers
```

## Show Saved Wi-Fi Profiles

```powershell
netsh wlan show profiles
```

## Show Visible Wi-Fi Networks / BSSIDs

```powershell
netsh wlan show networks mode=bssid
```

## Generate Windows WLAN Report

```powershell
netsh wlan show wlanreport
```

---

# Separate Repair Script

The Corp Network Diagnostic script is primarily intended for diagnosis and controlled LAN renewal.

For a more disruptive Windows Wi-Fi/TCP-IP repair, use:

```text
Reset-WiFiNetworkStack.ps1
```

That script performs:

```text
netsh winsock reset
netsh int ip reset
ipconfig /release
ipconfig /renew
ipconfig /flushdns
Wi-Fi adapter disable
Wi-Fi adapter enable
WLAN AutoConfig restart
```

A Windows reboot is recommended afterward.

Do not use the full reset as the first troubleshooting step unless the evidence suggests the local Windows networking stack may be damaged.

---

# Quick Reference

| Goal | Command |
|---|---|
| Full diagnostic | `.\Invoke-CorpNetworkDiagnostic.ps1 -Action All` |
| LAN flush/release/renew | `.\Invoke-CorpNetworkDiagnostic.ps1 -Action RenewLAN` |
| Force LAN adapter | `.\Invoke-CorpNetworkDiagnostic.ps1 -Action RenewLAN -LanAlias "Ethernet"` |
| Wi-Fi diagnostic | `.\Invoke-CorpNetworkDiagostic.ps1 -Action WiFi` |
| Force Wi-Fi adapter | `.\Invoke-CorpNetworkDiagostic.ps1 -Action WiFi -WifiAlias "Wi-Fi"` |
| LAN diagnostic only | `.\Invoke-CorpNetworkDiagnostic.ps1 -Action LAN` |
| Current-state snapshot | `.\Invoke-CorpNetworkDiagnostic.ps1 -Action Snapshot` |
| Full diagnostic + LAN renew | `.\Invoke-CorpNetworkDiagnostic.ps1 -Action All -RenewLAN` |
| Skip Network Discovery changes | `.\Invoke-CorpNetworkDiagnostic.ps1 -Action All -EnableNetworkDiscovery $false` }

---

# Safety Notes

- Run as Administrator.
- The `RenewLAN` mode can temporarily interrupt the wired network connection.
- Do not run `RenewLAN` while actively connected to a critical remote session through that same Ethernet adapter.
- Network Discovery is not enabled on Public profiles by this script.
- The script does not delete saved Wi-Fi profiles.
- The script does not modify AP/controller configuration.
- The script does not change MultiAP/AP/Client Isolation.
- Review WLAN/802.1X evidence before performing a full Wi-Fi stack reset.
