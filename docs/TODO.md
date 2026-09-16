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

## Active - Windows stabilization

- [ ] Complete Windows runtime field testing for every tool category on Windows 10 and Windows 11.
- [ ] Prove the v10.1 embedded runner on a real Windows machine with **Embedded Runner Self-Test**, Device Information Report, Defender Audit and Security Baseline Audit.
- [ ] Prove portable window minimize / maximize / resize / close behavior.
- [ ] Prove Windows installer / uninstaller behavior.
- [ ] Prove Deployment **Install All Apps** behavior; it must install Chrome, Firefox, Malwarebytes, AVG and CCleaner while excluding Win11Debloat and all WinUtil workflows.
- [ ] Confirm All Tools scrolling/search performance is acceptable on the field machine.

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

## AI / LLM - after macOS base collectors

- [ ] Add structured local AI diagnostic assistant using normalized evidence + deterministic rules + local LLM.
- [ ] Add Runbook retrieval to AI diagnosis so AI recommendations cite relevant Runbook articles.
- [ ] Add AI-assisted Runbook draft generation for newly solved issues. AI-created articles must remain **Draft** until a technician reviews and promotes them.

## Runbook rules

- Runbook content is operational documentation, not application source code.
- New articles use the standard template in `docs/RUNBOOK_STANDARD.md`.
- AI may suggest or create drafts, but may not silently publish verified procedures.
- Verified procedures should include symptoms, scope, cause, resolution, verification and rollback/recovery where applicable.
