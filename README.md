# T3CHNRD Digital Field Kit

**T3CHNRD Digital Field Kit** is a portable and installable technician toolkit for Windows diagnostics, troubleshooting, evidence collection, security review, repair workflows, deployment/setup tasks, documentation, and future offline AI-assisted diagnosis.

> Current development priority: stabilize the Windows application shell and installer first. Runbook integration comes next, followed by the macOS collectors, then the local AI/LLM subsystem.

## What the app does

The Windows edition provides one graphical interface for a growing set of IT support and field-service tools. The goal is to carry the toolkit on a USB drive or external SSD, launch it on a problem computer, collect evidence, run technician-selected diagnostics, and keep the resulting reports together in one session.

Current capabilities include:

- Reliability Monitor, Resource Monitor, Task Manager, Event Viewer, System Information, Performance Monitor, Device Manager, and Disk Management launchers
- BSOD/crash report collection and minidump collection
- Performance/slowness reporting
- Hardware and software inventory
- Microsoft Defender audit and quick scan
- Windows security baseline review
- Local account, startup/persistence, browser, privacy, security-event, open-port, and PowerShell-risk audits
- BitLocker and Secure Boot utilities
- DNS/domain lookup, DHCP renewal, network maintenance, network reset, MAC lookup, and local-network scan workflows
- Disk-space, drive-scan, cleanup, and data-transfer workflows
- Windows repair checks
- Windows Update and application/vendor update workflows
- Exchange/OWA and OneNote environment-specific support tools
- Setup/deployment launchers and technician utilities
- Portable and installed execution modes
- In-app Run Center for scripts that do not require direct console input
- Per-session diagnostic reports

## User interface

The GUI combines Windows Vista-style glass/chrome, Android 5/Lollipop-inspired navigation, and classic Windows XP-style utility icons.

The application is designed to run without leaving a PowerShell console open behind the main window. Most compatible scripts execute through the hidden runner and feed output into the in-app **Run Center**. Scripts that genuinely require `Read-Host` or other direct technician input remain interactive so their original behavior is preserved.

## Safety model

Read-only diagnostics are separated from actions that can modify a machine. Repair, cleanup, network reset, encryption changes, updates, firmware/BIOS workflows, and other higher-impact actions require explicit technician selection/confirmation.

The current stabilization work intentionally avoids rewriting working diagnostic scripts. The application shell, runner, installer, path handling, and script wiring are being fixed around those scripts instead.

## Portable use

Extract the complete application package to a USB drive, external SSD, or local folder and launch:

```text
OPEN-ME-GUI.vbs
```

## Installed use

The graphical installer entry point is:

```text
INSTALL-T3DFK.vbs
```

The installer is intended to ask for the destination, offer shortcut options, copy with visible progress, verify GUI tool targets, create shortcuts, and register uninstall support.

## Source layout

The GitHub repository now mirrors the first-party source used by the downloadable Windows test build rather than containing only a few shell files.

```text
windows/current-build/
├── Toolkit.hta
├── App/
├── Assets/
├── Config/
├── Installer/
├── Scripts/
├── Docs/
└── launch/install helpers
```

Large third-party redistributables and optional setup payloads are intentionally kept separate from the normal first-party source tree. The downloadable test build may contain runtime payloads that are not duplicated in Git when redistribution or repository size would be inappropriate.

## Related earlier project

The older **`T3CHNRD/windows-tool-kit-`** project is closely related. It includes a PowerShell/WinForms launcher, background execution, modules, build scripts, legacy scripts, and overlapping maintenance/security/network functions.

For now it is being treated as a **reference source**, not blindly merged. The active Digital Field Kit has a different GUI/runtime architecture and the immediate priority is stabilizing the current Windows app without introducing unrelated regressions. Useful pieces can be migrated deliberately after the current app passes runtime testing.

## Roadmap / required work order

### 1. Windows main application — current

- stabilize embedded script execution
- stabilize portable launcher/elevation
- stabilize installer/uninstaller
- verify every GUI tool mapping
- preserve working script behavior

### 2. Runbook integration

Build the Runbook into a local wiki-style documentation system for commonly broken systems and recurring support procedures.

Planned capabilities:

- browse/search all Runbook articles
- add/import documentation
- standardized article format
- link diagnostic findings to relevant Runbook procedures
- allow future AI to search the Runbook as supporting evidence
- future AI-generated **Draft** Runbook articles for newly solved issues, requiring technician review before becoming **Verified**

### 3. macOS edition

Planned collector order:

1. System Information / `system_profiler`
2. Activity Monitor and memory pressure
3. macOS crash / DiagnosticReports
4. `diskutil` / APFS
5. FileVault
6. Gatekeeper / XProtect
7. `networksetup` / `scutil`
8. `softwareupdate`
9. LaunchAgents / LaunchDaemons

### 4. Offline AI / LLM assistant

Planned AI goals:

- run locally from USB/external storage with no cloud requirement
- analyze the active session's `Diagnostic-Reports`
- use deterministic diagnostic rules before the LLM
- explain likely causes and cite the evidence used
- search the local Runbook for relevant procedures
- suggest next checks and existing toolkit actions
- remain read-only by default; destructive/remediation actions still require technician approval
- eventually draft new Runbook articles after novel issues are solved

A likely runtime direction is `llama.cpp` plus a quantized GGUF model with a rules-only fallback for low-memory machines.

## Current status

The current Windows test line is **v9 main-app stabilization**. Source synchronization is being expanded so GitHub tracks the same first-party application code shipped in the downloadable test package.

## Project name

**T3CHNRD Digital Field Kit**
