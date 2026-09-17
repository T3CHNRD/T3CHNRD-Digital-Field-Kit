# T3CHNRD Digital Field Kit - TODO

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

See `PROJECT-VISION.md` for the shared Windows / Intel macOS / Apple Silicon product goal.

## Cross-platform launch/install requirements

- [ ] Add **first-run OS/platform detection** so the field kit determines Windows vs macOS automatically before selecting the platform engine.
- [ ] On macOS, detect **Intel (`x86_64`) vs Apple Silicon (`arm64`)** automatically and select the correct runtime without requiring the technician to know the CPU architecture.
- [ ] Keep one portable external-drive product with clearly identified Windows and macOS launchers while presenting one shared product/UX.
- [ ] Provide a real **portable launch entry point** that is easy to identify on a USB/external SSD and does not depend on the technician building anything locally.
- [ ] Provide a validated Windows installer/uninstaller and a validated macOS installer/portable launch path. Do not mark the cross-platform installer requirement complete until both platforms have been built and tested on their native OS.
- [ ] Preserve one shared Runbook/wiki and normalized diagnostic-report structure across Windows, Intel macOS, and Apple Silicon macOS.

## Active - Windows stabilization

- [ ] Complete Windows runtime field testing for every tool category on Windows 10 and Windows 11.
- [ ] Prove the **v10.2.6** startup broker / embedded runner on a real Windows machine with **Embedded Runner Self-Test**, Device Information Report, BSOD / Crash Report, Launch Diagnostic Consoles, Defender Audit, and Security Baseline Audit.
- [x] Preserve field evidence that `cmd.exe` and Windows PowerShell `-Command` work while the older `powershell.exe -File` self-test returns exit code 1 on the affected workstation.
- [x] Stop treating the old `-File` compatibility self-test as the broker readiness gate; it is diagnostic-only and cannot falsely take the entire runner offline when `-Command` is healthy.
- [x] Correct the v10.2.2 VBScript `800A0005` error-reporting/encoding failure; broker and diagnostic error detail use Unicode-safe paths.
- [x] Change the primary installer bootstrap so it no longer depends on `powershell.exe -File` on the affected field PC.
- [x] Correct the v10.2.5 Windows Script Host compile failure: generated infrastructure files contained `CRCRLF` (`0D 0D 0A`) line endings. Because the launchers/broker use VBScript underscore continuations, the extra carriage return created a blank physical line and caused WSH error `800A03EA`. v10.2.6 canonicalizes infrastructure text to exact CRLF; VBS/CMD files are ASCII with no UTF-8 BOM; diagnostic scripts remain byte-for-byte unchanged.
- [ ] Field-test the v10.2.6 graphical installer destination selection, progress, verification, shortcuts, installed launch, and uninstall entry.
- [ ] Field-test the native taskbar/window icon host and confirm `Toolkit.ico` appears for the running app and installed shortcuts.
- [ ] Field-test the responsive header at normal width and narrower windows, including Windows display scaling where practical.
- [ ] Prove portable window minimize / maximize / resize / close behavior.
- [ ] Prove Deployment **Install All Apps** behavior; it must install Chrome, Firefox, Malwarebytes, AVG and CCleaner while excluding Win11Debloat and all WinUtil workflows.
- [ ] Confirm All Tools scrolling/search performance is acceptable on the field machine.
- [ ] Finish synchronizing the full first-party Windows application source tree to GitHub so it mirrors the downloadable field-test package, excluding intentionally ignored third-party/runtime payloads.

## Runbook - after Windows stabilization

- [ ] Finish local wiki-style Runbook browsing/search.
- [ ] Prove native document import / Add Document behavior on Windows.
- [ ] Keep development/runtime directories and temporary files excluded from the technician Runbook view.
- [ ] Add Runbook article editor with richer formatting and screenshots.
- [ ] Add Runbook full-text index suitable for offline AI retrieval.

## macOS - after Runbook

- [ ] System Information / `system_profiler`.
- [ ] Activity Monitor and memory pressure.
- [ ] macOS crash / DiagnosticReports.
- [ ] `diskutil` / APFS.
- [ ] FileVault.
- [ ] Gatekeeper / XProtect.
- [ ] `networksetup` / `scutil`.
- [ ] `softwareupdate`.
- [ ] LaunchAgents / LaunchDaemons.
- [ ] Define shared Windows/macOS diagnostic evidence schema.
- [ ] Build/test the macOS portable launcher and installer on both Intel macOS and Apple Silicon macOS.

## AI / LLM - after macOS base collectors

- [ ] Add structured local AI diagnostic assistant using normalized evidence + deterministic rules + local LLM.
- [ ] Add Runbook retrieval to AI diagnosis so AI recommendations cite relevant Runbook articles.
- [ ] Add AI-assisted Runbook draft generation for newly solved issues. AI-created articles must remain **Draft** until a technician reviews and promotes them.

## Runbook rules

- Runbook content is operational documentation, not application source code.
- New articles use the standard template in `docs/RUNBOOK_STANDARD.md`.
- AI may suggest or create drafts, but may not silently publish verified procedures.
- Verified procedures should include symptoms, scope, cause, resolution, verification and rollback/recovery where applicable.
