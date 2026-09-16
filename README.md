# T3CHNRD Digital Field Kit

**T3CHNRD Digital Field Kit** is a portable, installable field-service toolkit for diagnosing, troubleshooting, repairing, documenting, and eventually AI-assisting common computer problems.

## End goal

The goal is **one T3CHNRD Digital Field Kit on one external drive** with platform-aware launchers and one shared experience across:

- Windows
- Intel macOS
- Apple Silicon macOS

The product should share the same overall UI concepts, Runbook/wiki, diagnostic-report structure, and future offline AI/LLM analysis while using platform-specific diagnostic engines underneath.

Windows and macOS may require separate native launchers/installers, but they remain one product on one drive.

## Required work order

1. **Finish/stabilize the Windows app**
2. **Runbook integration**
3. **macOS support**
   - `system_profiler`
   - Activity Monitor / memory pressure
   - DiagnosticReports
   - `diskutil` / APFS
   - FileVault
   - Gatekeeper / XProtect
   - `networksetup` / `scutil`
   - `softwareupdate`
   - LaunchAgents / LaunchDaemons
4. **Local AI/LLM integration**

A fresh downloadable test build is produced after completed code/debug changes so field testing does not depend on a local development environment.

## What the Windows app does

The Windows edition provides a single GUI for technician diagnostics and support workflows. Current areas include:

- reliability and event diagnostics
- BSOD/crash collection and minidumps
- hardware, BIOS, CPU, memory, disk, network, and software inventory
- performance/slowness collection
- Microsoft Defender review and quick scan
- Windows security baseline review
- local account, startup/persistence, browser, privacy, security-event, open-port, and PowerShell-risk audits
- BitLocker and Secure Boot workflows
- DNS, DHCP, network reset/maintenance, MAC lookup, and local-network scanning
- disk-space, drive-scan, cleanup, and transfer workflows
- Windows repair checks
- Windows Update, driver, firmware, and vendor-update workflows
- deployment/setup utilities
- portable and installed modes
- in-app Run Center for compatible PowerShell tools
- per-session diagnostic reports

The existing diagnostic PowerShell scripts are treated as working source and are not rewritten merely to fit the GUI. The application shell, runner, installer, path handling, and tool mappings are built around them.

## Current stabilization line: v10.2.1

The current Windows test build focuses on the runner/startup problem seen during field testing.

Key v10.2.1 changes:

- fixes an ANSI/Unicode mismatch that made broker error text appear as Chinese/CJK-looking gibberish even though the original message was English
- adds a two-stage runner startup test:
  1. verify `powershell.exe -Command`
  2. verify `powershell.exe -File`
- adds standalone runner diagnostics that independently test `cmd.exe`, PowerShell command execution, and PowerShell script-file execution
- opens the main GUI in **diagnostic mode** if the PowerShell broker cannot become ready instead of refusing to open the toolkit entirely
- preserves the existing PowerShell diagnostic script tree byte-for-byte relative to the v10.2 package
- keeps the current cancel/process-tree handling and in-app Run Center architecture

The startup diagnostics report is written under `%TEMP%` as `T3DFK-Runner-Diagnostics-*.txt`.

## Portable Windows use

Extract the complete package and run:

```text
OPEN-ME-GUI.vbs
```

If the PowerShell runner cannot initialize, the app opens in diagnostic mode and reports which process-launch stage failed.

A standalone test is also available:

```text
RUN-RUNNER-DIAGNOSTICS.vbs
```

## Installed Windows use

The primary installer launcher is:

```text
INSTALL-T3DFK.vbs
```

The installer is intended to choose the install destination, create shortcuts, copy/verify the application, register uninstall support, and use the T3CHNRD application icon.

## Safety model

Read-only diagnostics are separated from actions that modify the machine. Repair, cleanup, network reset, encryption changes, updates, firmware/BIOS workflows, installers, and other higher-impact actions require deliberate technician selection/confirmation.

## Source layout

```text
windows/current-build/
├── Toolkit.hta
├── App/
│   ├── RunnerBroker.vbs
│   ├── Runner-Diagnostics.vbs
│   ├── Broker-PowerShell-SelfTest.ps1
│   └── Invoke-ToolRunner.ps1
├── Assets/
├── Config/
├── Installer/
├── Scripts/
├── Docs/
├── OPEN-ME-GUI.vbs
├── RUN-RUNNER-DIAGNOSTICS.vbs
└── install/launch helpers
```

The repository contains a `.gitignore` that deliberately excludes diagnostic reports, logs, local/company Runbook content, AI model files, build output, secrets, generated archives, and large third-party redistributable binaries.

## Runbook direction

After Windows stabilization, the Runbook becomes a portable local company troubleshooting wiki. Planned capabilities include browsing/searching all technician documentation, importing documents, standardized articles, screenshots, platform metadata, full-text retrieval, and future AI-assisted draft creation.

AI-created documentation must remain **Draft** until a technician reviews and promotes it.

## macOS direction

The macOS engine will be implemented after the Runbook phase in this exact order:

1. System Information / `system_profiler`
2. Activity Monitor and memory pressure
3. macOS crash / DiagnosticReports
4. `diskutil` / APFS
5. FileVault
6. Gatekeeper / XProtect
7. `networksetup` / `scutil`
8. `softwareupdate`
9. LaunchAgents / LaunchDaemons

Windows and macOS evidence should eventually normalize into a shared schema so Runbook search and AI diagnosis can work consistently across both platforms.

## Offline AI / LLM direction

Planned AI goals include local/offline analysis of `Diagnostic-Reports`, deterministic diagnostic rules before the LLM, evidence-backed likely causes, Runbook retrieval, recommended next checks, guarded toolkit actions, and future technician-reviewed Runbook draft generation.

A likely runtime direction is `llama.cpp` plus a quantized GGUF model with a rules-only fallback for low-memory systems.

## Related project

The older [`T3CHNRD/windows-tool-kit-`](https://github.com/T3CHNRD/windows-tool-kit-) repository contains related PowerShell/WinForms, module, task, and build work. It is treated as a useful reference/upstream source and can be selectively merged where doing so improves the Digital Field Kit without destabilizing the active Windows build.

## Project name

**T3CHNRD Digital Field Kit**
