# T3CHNRD Digital Field Kit

**T3CHNRD Digital Field Kit** is a portable and installable field-service toolkit for diagnosing, troubleshooting, repairing, documenting, and eventually AI-assisting common computer problems.

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

## Current stabilization line: v10.2.4

The v10.2.4 Windows field-test build specifically targets the shared failures observed on the real workstation.

Verified field evidence showed that `cmd.exe` and `powershell.exe -Command` work on the affected computer, while the older `powershell.exe -File` script self-test returns exit code 1. The application therefore no longer treats the failing legacy `-File` self-test as proof that the entire runner is unavailable.

Key v10.2.4 changes:

- broker readiness is based on the PowerShell inline-command primitive that is proven to work on the affected Windows machine
- the older local-script compatibility check is retained as a diagnostic warning instead of globally forcing the application into Runner Diagnostic Mode
- `Invoke-ToolRunner.ps1` is loaded into the broker PowerShell process from source using a ScriptBlock, while the actual diagnostic scripts under `Scripts\` remain unchanged
- normal tool scripts are launched through an encoded command that invokes the original `.ps1` by path, preserving script paths and normal tool behavior
- the launcher removes only `Zone.Identifier` / Mark-of-the-Web metadata from files inside the extracted toolkit tree before startup; it does not change machine execution policy or security configuration
- the graphical installer bootstrap no longer depends on `powershell.exe -File`; it loads the installer source through the command path and reports startup errors to `%TEMP%\T3DFK-Install-Launcher-Error.txt`
- the graphical installer copies the complete toolkit with real progress, verifies application files and GUI tool targets, creates Start Menu/optional desktop shortcuts, and registers uninstall information
- `App\WindowHost.cs` provides a native Windows helper that applies `Toolkit.ico` to the actual HTA window/taskbar entry when the local .NET Framework compiler is available
- the header layout separates platform selection from search/navigation, removes the redundant in-app Close control, and includes narrower-window breakpoints
- runner diagnostics retain the original `-File` test for troubleshooting, but explicitly distinguish it from the broker readiness requirement
- all 56 files under the diagnostic `Scripts\` tree remain unchanged in this stabilization line

The current build is package/static tested here, but Windows-only behavior such as HTA hosting, UAC, taskbar icon assignment, Defender/WMI/CIM calls, and the installer still requires field testing on Windows before being called proven.

## Portable Windows use

Extract the complete package into a fresh folder and run:

```text
OPEN-ME-GUI.vbs
```

The portable launcher starts the background broker, establishes the per-session queue, and then opens the GUI. A standalone runner diagnostic remains available:

```text
RUN-RUNNER-DIAGNOSTICS.vbs
```

## Installed Windows use

The primary installer launcher is:

```text
INSTALL-T3DFK.vbs
```

The installer asks for the destination, shows copy/verification progress, can create a desktop shortcut, creates a Start Menu shortcut, registers uninstall support, and uses the T3CHNRD application icon.

## Safety model

Read-only diagnostics are separated from actions that modify the machine. Repair, cleanup, network reset, encryption changes, updates, firmware/BIOS workflows, installers, and other higher-impact actions require deliberate technician selection/confirmation.

The current stabilization work does not change PowerShell execution policy, registry security policy, Windows services, scheduled tasks, or unrelated system files merely to make the runner appear healthy.

## Source layout

```text
windows/current-build/
├── Toolkit.hta
├── App/
│   ├── RunnerBroker.vbs
│   ├── Runner-Diagnostics.vbs
│   ├── Broker-PowerShell-SelfTest.ps1
│   ├── Invoke-ToolRunner.ps1
│   ├── WindowHost.cs
│   └── other app integration helpers
├── Assets/
├── Config/
├── Installer/
│   └── Install-Wizard.ps1
├── Scripts/
├── Docs/
├── OPEN-ME-GUI.vbs
├── RUN-PORTABLE.vbs
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
