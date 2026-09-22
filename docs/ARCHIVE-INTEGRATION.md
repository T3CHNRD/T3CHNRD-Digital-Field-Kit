# Uploaded archive integration â€” 2026-09-22

Starting main: `ae47d9eda40235ddadc64d579c64c6cce4c3e8f7`.

Packaging correction: WinUtil and Win11Debloat now live directly under
`Windows/Resources/WinUtil` and `Windows/Resources/Debloat`. The redundant upstream
archive folder names were removed without changing source bytes. The portable
download uses the short `FK.zip` filename and `FK/` root, with a checked maximum
archive path length of 160 characters. Extract to `C:\` to avoid Explorer's
long-path error; do not skip files during extraction.

The three uploaded archives are the source of truth. `ARCHIVE-INPUTS.json`
records their SHA-256 hashes. `ARCHIVE-RECONCILIATION.csv` lists every archive
file, its disposition, and matching repository paths. No replacement tools
were downloaded or invented.

## Source selection and preservation

The organized Windows Master Diagnostic Toolkit inside `personal_PS_scripts.zip`
is the canonical version for scripts already represented in the catalog.
The extracted `new_computer_setup` tree in `ections for the tools.zip` supplies
the deployment payloads. Its files match the equivalent setup resources in the
personal archive. The older `windows_script_toolkit.zip` supplies comparison
evidence; superseded launchers, modules, and distribution copies are not merged
over the current app.

`Windows/Config/ARCHIVE-SOURCES-SHA256.json` locks **778 files** directly to their
archive source paths: **48 scripts and 730 resource files**. Originals retain
their exact bytes, including BOMs, CRLFs, and original whitespace. Git attributes
prevent checkout conversion and exclude those unchanged originals from whitespace
lint. The vendored WinUtil `.gitattributes` is omitted because its newline rules
would override byte preservation on checkout. The existing Git-SHA1 manifest retains its historical LF-normalized format;
the application integrity check validates both manifests, and CI uses that check.

## Added tools and payloads

| Category | Addition | Location |
|---|---|---|
| Deployment | Complete supplied Win11Debloat project | `Windows/Resources/Debloat` |
| Deployment | Complete supplied WinUtil source project and licenses | `Windows/Resources/WinUtil` |
| Deployment | Chrome, Firefox, Malwarebytes, AVG, CCleaner installers | `Windows/Resources/NewComputerSetup` |
| Security | Multi-computer Secure Boot audit | `Windows/Scripts/Security/Check-SecureBootCert-MultiComputer.ps1` |
| Security | Production Secure Boot certificate audit | `Windows/Scripts/Security/Check-SecureBootCert_PRODUCTION_READY.ps1` |
| Network | Network Subnet Toggle v3 | `Windows/Scripts/Network/Network-Subnet-Toggle-v3.ps1` |
| System Management | Original 24-hour Sleep Hold, bundled but disabled | `Windows/Scripts/Maintenance/Disable-Sleep24.ps1` |
| System Management | Original Exchange OWA diagnostic, bundled but disabled | `Windows/Scripts/Server/Troubleshoot-Exchange-OWA.ps1` |

The two new audit cards use `Invoke-BundledSecureBootAudit.ps1` to select a local
report directory; they do not pass `ApplyUpdate`. Network Subnet Toggle retains
its original fixed IP/gateway/DNS defaults, which are disclosed in the card.

Nine existing deployment cards are enabled. `Install-BundledApp.ps1` routes the
five installers and Install All through Run Center, waits for each installer,
and reports its exit code. Install All no longer substitutes winget packages.
Installer GUI windows remain visible and bootstrap installers can require Internet.

WinUtil's previous launcher incorrectly executed only `scripts/start.ps1`.
It now copies build inputs to a unique writable `%LOCALAPPDATA%/T3DFK/WinUtil`
cache and runs the supplied compiler, then executes its generated script with
the requested `Offline` switch. No generated WinUtil script is committed.
Win11Debloat retains its original GUI and source; the wrapper declares elevation.
Open Setup Resources now points at a populated folder.

## Existing scripts reconciled

43 existing script files were restored byte-for-byte from the master archive.
Ten have substantive source differences; the other 33 differ only in original
encoding/line endings or were already identical:

| Script | Supplied source difference |
|---|---|
| `Invoke-BackupBitLockerKeys.ps1` | Creating a missing protector now requires the original `CreateMissingProtector` switch. |
| `Invoke-DebloatInventory.ps1` | Uses the app report directory and a writable fallback. |
| `Invoke-DeviceInformationReport.ps1` | Supplied error-handled device report with app report directory support. |
| `Invoke-DriveScanRepair.ps1` | Removable-drive repair requires the original `RepairRemovable` switch. |
| `Documentation/Invoke-MassDuplicateCleanup.ps1` | Saves the final session-log message before writing the log. |
| `Maintenance/Invoke-SecureBoot2023Update.ps1` | Supplied version 2026.05.14.2 includes battery eligibility checks and CSV reporting. |
| `Network/Invoke-KillerNetworkScan.ps1` | Supplied Windows PowerShell-compatible ping implementation and report handling. |
| `Optional/Invoke-DataTransferWizard.ps1` | Supplied self-contained folder-selection/robocopy implementation replaces a launcher for a missing StorageTools module. |
| `Security/Invoke-SecurityBaselineAudit.ps1` | Uses the app report directory and writable fallback. |
| `Updates/VendorUpdate.Common.ps1` | Uses the app report directory for update workspaces. |

Secure Boot remediation is called through `Invoke-BundledSecureBootRemediation.ps1`
only to set existing report-path parameters to the app's report folder instead of
the original P: company share. Eligibility and remediation logic are unchanged.
Its reports can contain recovery keys, as in the supplied original; those runtime
reports must not be committed.

## Run Center integration

All ready PowerShell cards use the same hidden, redirected, STA child process.
Interactive tools no longer escape into an untracked hidden PowerShell process.
`Invoke-RunCenterScript.ps1` adapts `Read-Host` to redirected line input and forwards
named arguments/switches and exit codes. `RunCenterProcess.cs` captures stdout and
stderr on .NET tasks; a Windows Forms timer updates the UI on its own thread.
This avoids PowerShell event callbacks on threads without a runspace and displays
prompts even without a trailing newline. A busy guard prevents a second tool from
overwriting the current process/log. Cancel still targets the child process tree.
Elevation relaunch now quotes spaced paths and preserves the selected tool ID.
Dependency inspection's over-escaped regex is corrected.

GUI utilities and installers may open their own application windows. This is a
portable source/payload package, not a promise that every operation works offline:
Windows updates, vendor packages, ps2exe installation, ORCA, and installer
bootstrappers retain their original network/product prerequisites. Console-only
APIs such as `Console.ReadKey` and `PromptForChoice` are not emulated; Win11Debloat
uses its GUI normally, but its console-only warning/error paths remain an upstream
runtime limitation.

## Files not enabled or imported

- Sleep Hold is bundled unchanged but disabled: mandatory ALBL share reporting,
  company-specific rollback paths, and scheduled shutdown-task changes require
  site review. Exchange OWA is bundled unchanged but disabled: fixed ALBL server,
  incident time, and Exchange Management Shell prerequisites. Cards explain these
  requirements instead of saying "needs migration".
- Other OneNote variants (`Fix_OneNote_Duplicates`, `Launch_OneNote`,
  `move_to_onenote*`, `sortdoc`, `how_to_guide`) use fixed notebooks, mapped drives,
  and/or deletion workflows. The catalog retains the authoritative master versions
  of the three existing OneNote tools; alternate destructive workflows are not
  exposed as additional cards.
- `Install-DotNet-Offline.ps1` and `ExecutionPolicy.ps1` require a fixed
  Administrator desktop and .NET installation media that are not supplied.
- The legacy Microsoft 365/media-creation integrations download additional payloads;
  the Microsoft 365 launcher removes its workflow folder and opens a separate
  PowerShell window. They require a separate integration rather than being enabled
  as self-contained tools. Their old host modules/build scripts and full diagnostic
  suite launchers target superseded applications, not this Run Center.
- Alternate `Check-SecureBootCert.ps1`/`bootcertchcker.ps1` copies and older task
  revisions are superseded by the canonical master sources. The PowerToys Configure
  module is a separate installed-product integration, not a runnable Field Kit tool.
- Compiled legacy executables, `KillerScan.exe`, shortcut files, prior distribution
  trees, nested duplicate ZIPs, old reports/logs, Win11Debloat registry backups and
  LastUsedSettings, Git databases, and unrelated legacy
  documentation are excluded. The supplied BitLocker recovery-key backup is excluded
  entirely. Its contents were neither printed nor copied into the repository.

For exact filenames, duplicate matches, and exclusions, consult every row of
`ARCHIVE-RECONCILIATION.csv`; the descriptions above group related files.

## Catalog and validation

| Category | Listed | Ready |
|---|---:|---:|
| Diagnostics | 7 | 7 |
| Repair | 5 | 5 |
| Optimization | 6 | 6 |
| Security | 18 | 18 |
| Network | 8 | 8 |
| Deployment | 10 | 10 |
| System Management | 10 | 8 |
| Total | 64 | 62 |

Validated on Windows PowerShell 5.1: PowerShell parsing, category mapping, unique
IDs, ready-tool paths, 778 byte-level archive hashes, and the original hash manifest.
The harmless transport test verifies live prompts/input, stdout, stderr, spaced
paths/arguments, switch forwarding, environment variables, exit codes, and child
process-tree cancellation. The
existing embedded runner self-test also succeeds through the new host wrapper.
The supplied WinUtil compiler produces its complete script successfully.

System-changing tools, installer execution, actual WinUtil/Win11Debloat GUI flows,
UAC interaction, and hardware-specific operations were not executed on the host.
Readiness means the source/payload and integration are present; it does not claim
all third-party workflows have been field-tested. CI repeats integrity and runner
transport checks before building the Windows package.
