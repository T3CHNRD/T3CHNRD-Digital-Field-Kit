var TOOLS = [
  {
    "category": "Diagnostics",
    "name": "Launch Diagnostic Consoles",
    "description": "Reliability Monitor, Resource Monitor, Task Manager, Event Viewer, System Information, Performance Monitor, Device Manager, Disk Management.",
    "path": "Scripts\\Core\\Launch-DiagnosticConsoles.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "monitor"
  },
  {
    "category": "Diagnostics",
    "name": "BSOD / Crash Report",
    "description": "Collect recent BugCheck, Kernel-Power, WHEA, storage, application crash, and Windows Error Reporting evidence.",
    "path": "Scripts\\Core\\Collect-BSODCrashReport.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Diagnostics",
    "name": "Performance / Slowness Report",
    "description": "Collect CPU, memory, disks, startup programs, drivers, and live performance counters.",
    "path": "Scripts\\Core\\Collect-SlownessReport.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "chart"
  },
  {
    "category": "Diagnostics",
    "name": "Copy BSOD Minidumps",
    "description": "Copy Windows minidump files into the current diagnostic session.",
    "path": "Scripts\\Core\\Copy-Minidumps.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Diagnostics",
    "name": "Device Information Report",
    "description": "Collect hardware, operating-system, BIOS, CPU, disk, and network information.",
    "path": "Scripts\\Invoke-DeviceInformationReport.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Diagnostics",
    "name": "Disk Space Monitor",
    "description": "Review local disk free space and capacity.",
    "path": "Scripts\\Invoke-DiskSpaceMonitor.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "disk"
  },
  {
    "category": "Diagnostics",
    "name": "Software / Debloat Inventory",
    "description": "Inventory installed and provisioned applications without automatically removing them.",
    "path": "Scripts\\Invoke-DebloatInventory.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Security",
    "name": "Defender Audit",
    "description": "Review Microsoft Defender configuration and security status.",
    "path": "Scripts\\Invoke-DefendAudit.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Security",
    "name": "Defender Quick Scan",
    "description": "Start a Microsoft Defender quick malware scan.",
    "path": "Scripts\\Invoke-DefenderQuickScan.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Security",
    "name": "Security Baseline Audit",
    "description": "Review workstation security baseline settings and posture.",
    "path": "Scripts\\Security\\Invoke-SecurityBaselineAudit.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Security",
    "name": "Local Account Security",
    "description": "Audit local accounts and account security settings.",
    "path": "Scripts\\Security\\Invoke-LocalAccountSecurityAudit.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Security",
    "name": "Security Event Review",
    "description": "Review recent security-relevant Windows event log entries.",
    "path": "Scripts\\Security\\Invoke-SecurityEventReview.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Security",
    "name": "Open Ports Audit",
    "description": "Review locally listening TCP/UDP ports and associated processes.",
    "path": "Scripts\\Security\\Invoke-OpenPortsAudit.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Security",
    "name": "PowerShell Risk Scan",
    "description": "Scan PowerShell scripts for potentially risky constructs.",
    "path": "Scripts\\Security\\Invoke-PowerShellRiskScan.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Security",
    "name": "Startup Items Review",
    "description": "Review common startup and persistence locations.",
    "path": "Scripts\\Security\\Invoke-StartupItemsReview.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Security",
    "name": "Persistence Review",
    "description": "Inspect additional persistence and autorun locations.",
    "path": "Scripts\\Invoke-AmortPersistenceReview.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Security",
    "name": "Browser Review",
    "description": "Review browser-related configuration and extensions.",
    "path": "Scripts\\Invoke-BeretBrowserReview.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Security",
    "name": "Privacy Audit",
    "description": "Review Windows privacy-related configuration.",
    "path": "Scripts\\Security\\Invoke-ShadePrivacyAudit.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Security",
    "name": "Secure Boot Quick Check",
    "description": "Check Secure Boot status and Windows UEFI CA 2023 presence.",
    "path": "Scripts\\Security\\Check-SecureBootCert-Quick.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Security",
    "name": "ORCA Security Report",
    "description": "Generate the included ORCA security report.",
    "path": "Scripts\\Security\\Invoke-OrcaSecurityReport.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Network",
    "name": "DHCP Renew",
    "description": "Release/renew DHCP and refresh addressing.",
    "path": "Scripts\\Invoke-DhcpRenew.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "globe"
  },
  {
    "category": "Network",
    "name": "Domain / DNS Lookup",
    "description": "Run the domain/DNS lookup utility.",
    "path": "Scripts\\Invoke-DomainLookup.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "globe"
  },
  {
    "category": "Network",
    "name": "Network Maintenance",
    "description": "Run guided network maintenance checks/actions.",
    "path": "Scripts\\Network\\Invoke-NetworkMaintenance.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "globe"
  },
  {
    "category": "Network",
    "name": "Reset Network Stack",
    "description": "Reset Winsock/IP stack. May require a reboot.",
    "path": "Scripts\\Network\\Invoke-ResetNetworkStack.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "globe"
  },
  {
    "category": "Network",
    "name": "Local Network Scan",
    "description": "Authorized local-subnet discovery and limited port checks.",
    "path": "Scripts\\Network\\Invoke-KillerNetworkScan.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "globe"
  },
  {
    "category": "Network",
    "name": "MAC Address Lookup",
    "description": "Lookup or review MAC address information.",
    "path": "Scripts\\Network\\Invoke-MacAddressLookup.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "globe"
  },
  {
    "category": "Network",
    "name": "Open Remote C$ Share",
    "description": "Open a remote workstation administrative share.",
    "path": "Scripts\\Network\\Open-RemoteAdminShare.ps1",
    "risk": "SystemChange",
    "interactive": true,
    "args": [],
    "icon": "globe"
  },
  {
    "category": "Storage",
    "name": "Drive Scan / Repair",
    "description": "Scan drives and optionally perform repair actions.",
    "path": "Scripts\\Invoke-DriveScanRepair.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "disk"
  },
  {
    "category": "Storage",
    "name": "Free C: Drive Space",
    "description": "Guided space-recovery utility.",
    "path": "Scripts\\Invoke-FreeCDriveSpace.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "disk"
  },
  {
    "category": "Storage",
    "name": "Clear Temp Junk",
    "description": "Remove selected temporary/cache data.",
    "path": "Scripts\\Invoke-ClearTempJunk.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "disk"
  },
  {
    "category": "Storage",
    "name": "MACE Cleanup",
    "description": "Run the included cleanup workflow.",
    "path": "Scripts\\Maintenance\\Invoke-MaceCleanup.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "disk"
  },
  {
    "category": "Storage",
    "name": "Data Transfer Wizard",
    "description": "Portable robocopy-based copy, move, or mirror utility.",
    "path": "Scripts\\Optional\\Invoke-DataTransferWizard.ps1",
    "risk": "HighRisk",
    "interactive": true,
    "args": [],
    "icon": "disk"
  },
  {
    "category": "BitLocker",
    "name": "Backup BitLocker Keys",
    "description": "Back up existing BitLocker recovery information.",
    "path": "Scripts\\Invoke-BackupBitLockerKeys.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "lock"
  },
  {
    "category": "BitLocker",
    "name": "Disable BitLocker",
    "description": "Decrypt/disable BitLocker on a selected volume.",
    "path": "Scripts\\Invoke-DisableBitLocker.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "lock"
  },
  {
    "category": "BitLocker",
    "name": "Encryption Helper",
    "description": "Run the included encryption/decryption/hash helper.",
    "path": "Scripts\\Utilities\\Invoke-KillerEncryptionHelper.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "lock"
  },
  {
    "category": "Updates",
    "name": "Windows Update Tool",
    "description": "Run the guided Windows Update workflow.",
    "path": "Scripts\\Updates\\Invoke-WindowsUpdateTool.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "update"
  },
  {
    "category": "Updates",
    "name": "Update Installed Apps",
    "description": "Use the included application-update workflow.",
    "path": "Scripts\\Updates\\Invoke-UpdateAllApps.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "update"
  },
  {
    "category": "Updates",
    "name": "Driver Update",
    "description": "Vendor-aware driver update workflow.",
    "path": "Scripts\\Updates\\Invoke-DriverUpdate.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "disk"
  },
  {
    "category": "Updates",
    "name": "BIOS Update",
    "description": "Vendor-aware BIOS update workflow. AC power and recovery planning recommended.",
    "path": "Scripts\\Updates\\Invoke-BiosUpdate.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "update"
  },
  {
    "category": "Updates",
    "name": "Firmware Update",
    "description": "Vendor-aware firmware update workflow.",
    "path": "Scripts\\Updates\\Invoke-FirmwareUpdate.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "update"
  },
  {
    "category": "Updates",
    "name": "Secure Boot 2023 Remediation",
    "description": "Apply the included Secure Boot 2023 remediation workflow.",
    "path": "Scripts\\Maintenance\\Invoke-SecureBoot2023Update.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "shield"
  },
  {
    "category": "Setup",
    "name": "Win11Debloat",
    "description": "Launch the complete locally embedded Win11Debloat GUI/project from the toolkit.",
    "path": "Scripts\\Setup\\Launch-Win11Debloat.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "WinUtil (Local Project)",
    "description": "Build if needed, then launch the locally embedded Chris Titus Tech WinUtil project.",
    "path": "Scripts\\Setup\\Launch-WinUtil.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "WinUtil Offline Mode",
    "description": "Launch the embedded WinUtil project with its Offline switch.",
    "path": "Scripts\\Setup\\Launch-WinUtil.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": ["-Offline"],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "Install Google Chrome",
    "description": "Launch the bundled Chrome installer supplied in the new-computer setup package.",
    "path": "R\\Setup\\Apps\\Chrome.exe",
    "risk": "SystemChange",
    "interactive": true,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "Install Mozilla Firefox",
    "description": "Launch the bundled Firefox installer supplied in the new-computer setup package.",
    "path": "R\\Setup\\Apps\\Firefox.exe",
    "risk": "SystemChange",
    "interactive": true,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "Install Malwarebytes",
    "description": "Launch the bundled Malwarebytes installer supplied in the new-computer setup package.",
    "path": "R\\Setup\\Apps\\Malwarebytes.exe",
    "risk": "SystemChange",
    "interactive": true,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "Install AVG Antivirus",
    "description": "Launch the bundled AVG Antivirus installer supplied in the new-computer setup package.",
    "path": "R\\Setup\\Apps\\AVG.exe",
    "risk": "SystemChange",
    "interactive": true,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "Install CCleaner",
    "description": "Launch the bundled CCleaner installer supplied in the new-computer setup package.",
    "path": "R\\Setup\\Apps\\CCleaner.exe",
    "risk": "SystemChange",
    "interactive": true,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Setup",
    "name": "Open Setup Resources",
    "description": "Open the complete embedded new-computer setup resource folder in Explorer.",
    "path": "Scripts\\Setup\\Open-NewComputerSetupResources.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "package"
  },
  {
    "category": "Advanced",
    "name": "Windows Repair Checks",
    "description": "Guided SFC/DISM repair checks.",
    "path": "Scripts\\Maintenance\\Invoke-WindowsRepairChecks.ps1",
    "risk": "SystemChange",
    "interactive": false,
    "args": [],
    "icon": "wrench"
  },
  {
    "category": "Advanced",
    "name": "24-Hour Sleep Hold",
    "description": "Site-specific power/scheduled-task hold utility.",
    "path": "Scripts\\Maintenance\\Disable-Sleep24.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "wrench"
  },
  {
    "category": "Advanced",
    "name": "Exchange OWA Diagnostic",
    "description": "Site-specific Exchange/OWA troubleshooting utility.",
    "path": "Scripts\\Server\\Troubleshoot-Exchange-OWA.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "gear"
  },
  {
    "category": "Advanced",
    "name": "OneNote Duplicate Cleanup",
    "description": "Site-specific OneNote staging/import cleanup.",
    "path": "Scripts\\Documentation\\Invoke-MassDuplicateCleanup.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "wrench"
  },
  {
    "category": "Advanced",
    "name": "OneNote Smart-Skip Audit",
    "description": "Site-specific OneNote audit/import workflow.",
    "path": "Scripts\\Documentation\\Master-Audit-Smart-Skip.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "document"
  },
  {
    "category": "Advanced",
    "name": "OneNote Master Importer",
    "description": "Site-specific full OneNote documentation import/rebuild.",
    "path": "Scripts\\Documentation\\Master-OneNote-Importer.ps1",
    "risk": "HighRisk",
    "interactive": false,
    "args": [],
    "icon": "gear"
  },
  {
    "category": "Advanced",
    "name": "PS1 to EXE Builder",
    "description": "Portable ps2exe front end. May offer to install the ps2exe module.",
    "path": "Scripts\\Utilities\\Invoke-ps2exe-Portable.ps1",
    "risk": "SystemChange",
    "interactive": true,
    "args": [],
    "icon": "terminal"
  },
  {
    "category": "Advanced",
    "name": "Toolkit Integrity Self-Test",
    "description": "Parse every PowerShell script and verify required toolkit files and Windows commands.",
    "path": "Scripts\\Core\\Test-ToolkitIntegrity.ps1",
    "risk": "ReadOnly",
    "interactive": false,
    "args": [],
    "icon": "terminal"
  }
];
