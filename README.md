# T3CHNRD Digital Field Kit

**T3CHNRD Digital Field Kit** is a portable and installable technician toolkit for Windows diagnostics, troubleshooting, evidence collection, security review, repair workflows, deployment/setup tasks, documentation, and future offline AI-assisted diagnosis.

## End state

The goal is **one T3CHNRD Digital Field Kit on one external drive**, with platform-aware launchers and one shared experience across:

- Windows
- Intel macOS
- Apple Silicon macOS

with shared:

- UI concepts
- Runbook/wiki
- diagnostic report structure
- future offline AI/LLM analysis

and platform-specific diagnostic engines underneath.

The drive will contain one product, while the launcher/runtime selects the correct Windows, Intel macOS, or Apple Silicon macOS engine after launch. Windows and macOS may require separate native launchers/installers, but they remain parts of the same toolkit and share documentation, reports, evidence concepts, and future AI features.

## Required work order

1. **Finish/stabilize the Windows app**
2. **Runbook integration**
3. **macOS support**
   - `system_profiler`
   - Activity Monitor / memory pressure
   - DiagnosticReports
   - `diskutil` / APFS
   - FileVault
   - Gatekeeper/XProtect
   - `networksetup` / `scutil`
   - `softwareupdate`
   - LaunchAgents / LaunchDaemons
4. **Local AI/LLM integration**

A fresh downloadable test build is produced after completed code/debug changes so field testing does not depend on a local development environment.

## What the Windows app does

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

## Current Windows stabilization line

The current test line is **v10.1 Windows stabilization**. This pass focuses on the application shell and does **not** rewrite the existing diagnostic scripts.

Current v10.1 work includes:

- normal resizable window behavior with minimize, maximize, close, and sizing controls
- revised embedded runner completion/status protocol with child PID tracking and cancel support
- direct hidden Windows PowerShell child-process execution while preserving the existing diagnostic scripts
- an **Embedded Runner Self-Test** under System Management
- a Deployment **Install All Apps** action that installs Chrome, Firefox, Malwarebytes, AVG, and CCleaner while deliberately excluding Win11Debloat and WinUtil
- lighter All Tools card rendering, compact cards, DocumentFragment rendering, and debounced search for smoother scrolling
- Runbook filtering that removes development/runtime content from the technician document list, including `.venv312`, `ai_cowork`, `apps`, `General`, `deps.txt`, `static`, `templates`, `tmp-lo-test2`, `tmp_backend.html`, and `tmp_backend_v.txt`
- a native Windows **Add Document** picker for importing Markdown, text, HTML, PDF, Word, and RTF documentation into the Runbook
- less crowded header/platform/search layout
- installer verification for the runner, deployment helper, self-test, and Runbook document picker

## User interface

The GUI combines Windows Vista-style glass/chrome, Android 5/Lollipop-inspired navigation, and classic Windows XP-style utility icons.

The application is designed to run without leaving a PowerShell console open behind the main window. Most compatible scripts execute through the hidden runner and feed status/output into the in-app **Run Center**. Scripts that genuinely require `Read-Host` or other direct technician input remain interactive so their original behavior is preserved.

## Safety model

Read-only diagnostics are separated from actions that can modify a machine. Repair, cleanup, network reset, encryption changes, updates, firmware/BIOS workflows, installers, and other higher-impact actions require explicit technician selection/confirmation.

The stabilization work intentionally avoids rewriting working diagnostic scripts. The application shell, runner, installer, path handling, and script wiring are fixed around those scripts instead.

## Portable use

Extract the complete application package to a USB drive, external SSD, or local folder and launch:

```text
OPEN-ME-GUI.vbs
```

## Installed use

The graphical Windows installer entry point is:

```text
INSTALL-T3DFK.vbs
```

The installer asks for the destination, offers shortcut options, copies with visible progress, verifies GUI tool targets and required app helpers, creates shortcuts, and registers uninstall support.

## Source layout

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

Large third-party redistributables and optional setup payloads are intentionally kept separate from the normal first-party source tree when redistribution or repository size would be inappropriate. The downloadable field-test package can therefore contain runtime payloads that are not all duplicated as normal source files in Git.

## Runbook direction

The Runbook is intended to become a portable local company troubleshooting wiki for recurring problems and commonly broken systems.

Planned capabilities include:

- browse/search all technician documentation
- add/import documents
- standardized article format
- platform metadata such as Windows, macOS, or Any
- link diagnostic findings to relevant Runbook procedures
- allow the future local AI to search the Runbook for supporting information
- allow future AI to create a **Draft** Runbook article after a newly solved issue, with technician review required before the article becomes **Verified**

## macOS direction

The macOS engine will be implemented after Windows stabilization and Runbook integration, in this order:

1. System Information / `system_profiler`
2. Activity Monitor and memory pressure
3. macOS crash / DiagnosticReports
4. `diskutil` / APFS
5. FileVault
6. Gatekeeper / XProtect
7. `networksetup` / `scutil`
8. `softwareupdate`
9. LaunchAgents / LaunchDaemons

The Windows and macOS engines should eventually normalize evidence into a shared diagnostic schema so the Runbook and AI layers can reason over either platform consistently.

## Offline AI / LLM direction

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

## Related earlier project

The older **`T3CHNRD/windows-tool-kit-`** project is closely related. It includes a PowerShell/WinForms launcher, background execution, modules, build scripts, legacy scripts, and overlapping maintenance/security/network functions.

For now it is treated as a reference source rather than blindly merged. Useful components can be migrated deliberately after the active Windows app passes runtime testing.

## Project name

**T3CHNRD Digital Field Kit**
