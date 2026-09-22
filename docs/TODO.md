# T3CHNRD Digital Field Kit - Master TODO

This is the single source of truth for project tracking. There is only one active TODO file for the repository.

Status: PASS = runtime-tested; STATIC PASS = source/package verified; NEEDS FIELD TEST = implemented but not runtime-proven; FAIL = known broken.

## CURRENT STATUS SNAPSHOT - 2026-09-22
- Windows-first source tree is clean and synchronized with `origin/main`.
- Catalog contains 64 entries: 62 ready and 2 disabled pending site configuration (24-Hour Sleep Hold and Exchange OWA Diagnostic). Their original scripts are bundled.
- All ready catalog file mappings resolve. Install All uses the bundled installer wrapper; normal PowerShell tools run through the two-slot Run Center.
- Runbook contains the index, quick start, troubleshooting, security, networking, repair, deployment, evidence, escalation, and documentation procedures.
- Branded EXE build, generated icon, startup elevation, diagnostic-console selector, and Run Center lifecycle changes are implemented but still need real Windows field testing.
- No final release claim is made until Windows field testing and the unresolved Defender detection of the full GitHub ZIP are addressed. Local repository, individual launcher, and script-only test ZIP scans reported no threats; that does not establish a false positive.

## ACTIVE GATE - WINDOWS APP
- [x] STATIC PASS - Top-level portable Windows launcher.
- [x] STATIC PASS - Top-level graphical Windows installer and uninstall source.
- [x] STATIC PASS - Original Field Kit UI/UX restored.
- [x] STATIC PASS - Current 64-entry GUI tool catalog restored and validated (62 ready).
- [x] STATIC PASS - 778 archive-source files (48 scripts and 730 resources) are SHA-256 locked; the original Git blob manifest is also retained.
- [x] STATIC PASS - Reconcile authoritative archives and bundle the missing original scripts/payloads; record exclusions and file provenance in docs/ARCHIVE-INTEGRATION.md and docs/ARCHIVE-RECONCILIATION.csv.
- [ ] CONFIGURATION REQUIRED - Adapt and validate Sleep Hold and Exchange OWA for the target site before enabling their cards.
- [x] STATIC PASS - Create and enforce immutable Git blob SHA-1 manifest for restored original scripts.
- [x] STATIC PASS - Embedded stdout/stderr capture and exit-code display for compatible noninteractive tools.
- [x] STATIC PASS - Cancel uses taskkill /T /F on the child process tree.
- [x] STATIC PASS - Interactive console input is handled in Run Center; native GUI selectors/tools can open their own windows.
- [x] STATIC PASS - Application startup requests Administrator elevation; child tools inherit the elevated process by default.
- [x] STATIC PASS - Compatible tool output remains in the embedded Run Center; interactive selector workflows launch separately without closing the main app.
- [x] STATIC PASS - Install All includes Chrome, Firefox, Malwarebytes, AVG, CCleaner and excludes Win11Debloat/WinUtil.
- [ ] NEEDS FIELD TEST - Launch without PowerShell security prompt.
- [ ] NEEDS FIELD TEST - Minimize/maximize/restore/resize/close.
- [ ] NEEDS FIELD TEST - Favorites/Recent/categories/search/Run Center/Runbook.
- [ ] NEEDS FIELD TEST - All Tools smooth scrolling.
- [ ] NEEDS FIELD TEST - 100/125/150/200% display scaling.
- [ ] NEEDS FIELD TEST - portable local disk / USB / external SSD.
- [ ] NEEDS FIELD TEST - Windows install / shortcuts / installed launch / uninstall.
- [ ] NEEDS FIELD TEST - every restored Windows diagnostic category.
- [x] STATIC PASS - Added repeatable branded Windows EXE build with generated T3CHNRD icon; VBS remains the source-only fallback.
- [ ] NEEDS FIELD TEST - Validate packaged EXE startup, taskbar icon, portable root detection, installer shortcuts, and fallback behavior.
- [ ] INVESTIGATE - Determine why the main Field Kit window may still close after a tool or script completes; reproduce with the latest elevated packaged EXE and inspect process exit, form lifecycle, and child-process callbacks.

## 2026-09-20 WINDOWS FIELD-TEST CHECKLIST
This checklist tracks remaining live hardware acceptance. Automated Windows UI/runner tests and user screenshots provide partial evidence; they do not close the full device, installer or scaling matrix.

- [ ] Windows UI runtime validation
  - [ ] startup without PowerShell security prompt
  - [ ] minimize / maximize / restore / resize / close
  - [ ] favorites / recent / categories / search
  - [ ] Run Center flow
  - [ ] Runbook flow
- [ ] Installer and portability checks
  - [ ] installed launch
  - [ ] uninstall path
  - [ ] USB / external SSD run behavior
  - [ ] display scaling behavior
- [ ] Packaging and release checks
  - [ ] shortcut/launcher behavior
  - [ ] installed vs portable mode expectations
  - [ ] final Windows field-test checklist
- [ ] Documentation cleanup
  - [ ] keep roadmap and milestone tracking tied to the active branch/phase
  - [ ] keep macOS and local AI items separated from the current Windows phase

## AFTER WINDOWS PASS
- [x] STATIC PASS - Expand Runbook with quick start, troubleshooting, security, networking, repair, deployment, evidence, escalation, and documentation procedures.
- [ ] NEEDS FIELD TEST - Validate the in-app Runbook browser, search, refresh, add-document, open-folder, and document preview flows.
- [ ] Improve Runbook wiki/search/index/editor after Windows field validation.
- [ ] Build macOS Intel native app + installer.
- [ ] Build macOS Apple Silicon native app + installer.
- [ ] Add automatic multi-platform startup routing and manual Windows/macOS Intel/macOS Apple Silicon failsafe.
- [ ] Add offline/local AI only after diagnostic foundations are stable.


## 2026-09-22 COMPLETED WORK AND REMAINING VALIDATION
Evidence: implementation commits d691d35 through fffd892; automated Windows tests, source integrity checks, and user screenshots. PASS below specifies the tested scope and does not imply every bundled tool has been run.

- [x] STATIC PASS - Integrated authoritative archives, category mappings, local setup payloads, source hashes and reconciliation records without inventing replacements.
- [x] PASS (launcher-path test) - Fixed empty PSScriptRoot startup failure by loading the UI from its actual script path; tested VBS path handling with spaces/apostrophes.
- [x] STATIC PASS - Included PS2EXE launcher and T3DFK icon on main; shortened resource/package paths and produced script-only test packages.
- [x] PASS (automated runner tests) - Two simultaneous tool slots with separate input/output/logs, independent cancellation/completion and a third-tool limit.
- [x] PASS (UI tests/render review) - Readable Cancel/Hide controls and spaced completion/exit-code display; draggable Run Center height with retained session height and bounds.
- [x] PASS (UI click/persistence tests) - Fixed favorites add/remove, reload and final-favorite removal; search respects the Favorites subset.
- [x] PASS (chooser test) - Diagnostic consoles start with none selected and open only the selected console; test launches were mocked.
- [x] PASS (mocked antivirus tests) - Identify registered antivirus, skip unavailable/inactive Defender, retain text/JSON evidence, and invoke active Defender once. No protection disabled; live scan coverage is not claimed.
- [x] PASS (UI tests) - Added searchable help for all 64 tools and card Help buttons, including requirements for disabled site tools.
- [x] PASS (UI tests) - Restored Log Files shortcut; added functional Settings folder actions, integrity-check action and persisted Run Center word wrapping. Folder/external-launch actions still need technician acceptance.
- [x] PASS (UI tests) - Added local AI workspace navigation, chat-draft saving and log preview; analysis-document import/results viewer implemented. No AI provider is connected and no messages/logs are uploaded.
- [x] PASS (integrity suite) - 1,345 checks passed with zero failures; fixed the false missing-EXE failure for intentional script-launcher packages.
- [x] PASS (Defender custom scans) - Latest local script-only test ZIP reported no threats. This is scan evidence, not a guarantee of safety.
- [ ] INVESTIGATE / RELEASE GATE - Full GitHub ZIP reproducibly detected as Trojan:Script/Wacatac.B!ml. Exact offending component and false-positive status remain unconfirmed; do not bypass protection.
- [ ] NEEDS FIELD TEST - Latest resize/help, favorites persistence, two real simultaneous tools, Settings actions, local drafts after restart and analysis-document import/results preview.
- [ ] NEEDS FIELD TEST - Real active/passive Defender scenarios and technician review of retained evidence.
- [ ] NOT CONNECTED - Implement actual AI chat and log analysis after diagnostic foundations are stable. Current workspace is local preparation only.

## HISTORICAL ENTRIES
Earlier dated sections retain original findings/counts as history. The September 22 snapshot and completion section supersede stale counts and execution details; unchecked field-test items remain open unless explicitly closed with evidence.

## 2026-09-18 static bug sweep

- [x] STATIC PASS - Root portable launcher, installer launcher, uninstaller launcher, Windows app, config, and integrity-test files are present.
- [x] STATIC PASS - All enabled manifest tool paths resolve to files; 0 enabled mappings are missing.
- [x] STATIC PASS - All 40 immutable restored-script Git blob hashes match.
- [x] STATIC PASS - Launcher now records startup failures and displays the actual startup error instead of failing silently.
- [x] STATIC PASS - Embedded runner now supplies TTK_TOOLKIT_ROOT, TTK_REPORT_DIR, and TTK_RUNBOOK_DIR.
- [x] STATIC PASS - Runner now detects administrator requirements declared inside sourced dependency scripts as well as the wrapper.
- [x] STATIC PASS - Runner now detects GUI/interactive dependencies and launches them externally rather than hidden.
- [x] STATIC PASS - Manifest arguments are now passed to both embedded and external tool launches.
- [x] STATIC PASS - Installed mode uses writable ProgramData Runbook/report storage; portable mode keeps them with the external-drive toolkit.
- [x] STATIC PASS - Windows installer rewritten to remove malformed function-call syntax and hash-verify copied files.
- [x] STATIC PASS - Historical HTA integrity test disabled; current Application Integrity Self-Test added.
- [x] STATIC PASS - Vendor update Toolkit.Settings.psd1 restored.
- [x] PASS FROM USER SCREENSHOTS (2026-09-22) - Windows UI opens and runs reports. Packaged EXE, installation and portability acceptance remain separate open checks.
- [ ] NEEDS FIELD TEST - Installer/UAC/shortcut/uninstall runtime behavior.
- [ ] NEEDS FIELD TEST - Individual enabled diagnostic tools.
- [ ] BLOCKED - GitHub Actions job is failing before step/log details are exposed; do not count CI as PASS.


## 2026-09-18 startup failure fix
- [x] PASS FROM FIELD ERROR REPRODUCTION - Startup failure identified from user screenshot: PowerShell automatic read-only variable $Host was being overwritten by the UI panel variable $host.
- [x] STATIC PASS - Renamed the UI panel variable to $viewHost everywhere in Windows/App/T3DFK-Windows.ps1.
- [x] STATIC PASS - Re-scanned main app, installer, uninstaller, and application integrity test for collisions with common PowerShell automatic/read-only variables; none remain.
- [x] STATIC PASS - Re-checked bracket/quote structural balance on those startup-critical scripts; no structural errors found.
- [ ] NEEDS FIELD TEST - Re-test top-level T3CHNRD Digital Field Kit.vbs startup on Windows.


## 2026-09-18 WinForms callback scope fix
- [x] PASS FROM FIELD REPRODUCTION - Windows UI now opens successfully.
- [x] FAIL IDENTIFIED - Clicking navigation raised CommandNotFoundException because Update-View was not visible to the WinForms event callback.
- [x] STATIC PASS - Root launcher now dot-sources the dynamically loaded UI script so helper functions remain in the callback-visible PowerShell scope.
- [x] STATIC PASS - Installer and uninstaller launchers use the same persistent-scope loading model.
- [ ] NEEDS FIELD TEST - Re-test top tabs, left navigation, Runbook buttons, Settings/platform fallback, Favorites star, Recent, and Run Center controls.


## macOS testing/install clarification

- [x] PROJECT DECISION - Do not ask for macOS testing during the Windows stabilization phase.
- [ ] NOT STARTED - Build macOS Intel diagnostic scripts.
- [ ] NOT STARTED - Build macOS Apple Silicon diagnostic scripts.
- [ ] NOT STARTED - Build macOS Intel native application/package.
- [ ] NOT STARTED - Build macOS Apple Silicon native application/package.
- [ ] NOT STARTED - Build macOS installer/package workflow.
- [ ] NOT STARTED - Define macOS portable launch from the external drive.
- [ ] NOT STARTED - Define signed/notarized macOS distribution requirements.
- [ ] NOT STARTED - Test macOS Intel on native Intel hardware.
- [ ] NOT STARTED - Test macOS Apple Silicon on native Apple Silicon hardware.
- [ ] BLOCKED BY WINDOWS PHASE - No macOS install/test instructions are expected yet.

Planned macOS order remains:
1. system_profiler / System Information
2. Activity Monitor / memory pressure
3. DiagnosticReports / crash collection
4. diskutil / APFS
5. FileVault
6. Gatekeeper / XProtect
7. networksetup / scutil
8. softwareupdate
9. LaunchAgents / LaunchDaemons


## 2026-09-18 original Windows tool source recovered
- [x] PASS - User supplied the original Windows script/toolkit archives used by the working application.
- [x] STATIC PASS - Current UI tool catalog moved to script-scoped state so category/search callbacks can access it reliably.
- [x] STATIC PASS - Catalog startup validation now shows loaded/ready tool counts and fails visibly if zero tools load.
- [x] STATIC PASS - Secure Boot Quick Check restored unchanged from the uploaded Windows Master Diagnostic Toolkit and hash-locked.
- [x] STATIC PASS - Network remote-share utility restored unchanged from the uploaded Windows Master Diagnostic Toolkit and hash-locked.
- [x] STATIC PASS - PS1-to-EXE utility restored unchanged from the uploaded Windows Master Diagnostic Toolkit and hash-locked.
- [x] STATIC PASS (2026-09-22) - Reconciled supplied scripts/resources; provenance and excluded inputs documented in the archive reconciliation records.
- [x] STATIC PASS (2026-09-22) - Restored original deployment resources and wrappers; Install All still excludes Win11Debloat/WinUtil.
- [ ] NEEDS FIELD TEST - Verify tool cards now populate under Diagnostics, Repair, Optimization, Security, Network, Deployment, and System Management.


## 2026-09-18 PowerShell 5.1 JSON catalog enumeration fix
- [x] PASS FROM FIELD REPRODUCTION - App displayed "Loaded 1 tools (1 ready)" and one card containing concatenated names/descriptions from the entire catalog.
- [x] ROOT CAUSE - Windows PowerShell 5.1 returned the JSON array as one array object; the UI treated that object as a single tool.
- [x] STATIC PASS - Catalog loader now explicitly enumerates every JSON entry into $script:ToolCatalog.
- [ ] NEEDS FIELD TEST - Confirm startup now reports 64 tools (62 ready) and individual cards populate all categories/search.


## 2026-09-18 category and in-app execution audit
- [x] STATIC PASS - Verified every tool category against the original Field Kit manifest.
- [x] STATIC PASS - Original Diagnostics map to Diagnostics.
- [x] STATIC PASS - Original Security + BitLocker map to Security.
- [x] STATIC PASS - Original Network maps to Network.
- [x] STATIC PASS - Original Storage maps to Repair.
- [x] STATIC PASS - Original Updates map to Optimization.
- [x] STATIC PASS - Original Setup maps to Deployment.
- [x] STATIC PASS - Original Advanced maps to System Management.
- [x] STATIC PASS - 0 category mismatches found across all 61 catalog entries.
- [x] STATIC PASS - Every ready PowerShell tool is marked executionMode=InApp.
- [x] STATIC PASS - Normal PowerShell tools run hidden with stdout/stderr/exit code in Run Center.
- [x] STATIC PASS - Interactive PowerShell tools use Run Center input instead of opening a PowerShell console.
- [x] STATIC PASS - Administrator-required tools reopen the Field Kit itself elevated via UAC and auto-run inside the elevated Run Center; no visible PowerShell console is intended.
- [x] STATIC PASS - Tool-native GUI windows may still appear where the script itself is a GUI tool; this is not a PowerShell console.
- [x] STATIC PASS - Application Integrity Self-Test now validates category mapping and in-app execution metadata.
- [x] PASS FROM USER SCREENSHOT (2026-09-22) - Machine Specs / Device Information displayed CPU, RAM, BIOS, Windows and disks in Run Center with exit code 0.
- [ ] NEEDS FIELD TEST - Confirm one Security tool, one Network tool, one Repair tool, and one Optimization tool run in Run Center.
- [ ] NEEDS FIELD TEST - Confirm UAC-required tool reopens elevated Field Kit and auto-runs without a visible PowerShell console.
- [ ] NEEDS FIELD TEST - Confirm in-app input works for Open Remote C$ Share / PS1 to EXE Builder.


## 2026-09-18 self-contained tool restoration / admin regex fix
- [x] PASS FROM FIELD REPRODUCTION - JIT exception identified as an invalid administrator-detection regular expression.
- [x] STATIC PASS - Replaced the single fragile administrator regex with separate valid checks; the previous broken expression is no longer present.
- [x] STATIC PASS - Restored Launch Diagnostic Consoles from the original master diagnostic toolkit and enabled it.
- [x] STATIC PASS - Restored BSOD / Crash Report from the original master diagnostic toolkit and enabled it.
- [x] STATIC PASS - Restored Performance / Slowness Report from the original master diagnostic toolkit and enabled it.
- [x] STATIC PASS - Restored Copy BSOD Minidumps from the original master diagnostic toolkit and enabled it.
- [x] STATIC PASS - Restored OneNote Smart-Skip Audit and OneNote Master Importer from original toolkit source and enabled them.
- [x] STATIC PASS - Retargeted the obsolete HTA-era Toolkit Integrity card to the current Application Integrity Self-Test.
- [x] STATIC PASS - Added self-contained launch wrappers for Win11Debloat, WinUtil, and Open Setup Resources; wrappers expect bundled local resources and do not fetch replacements.
- [x] STATIC PASS - Current manifest has 61 tools / 50 ready, 0 category mismatches, and 0 ready PowerShell mappings pointing to missing files.
- [x] STATIC PASS - Current runner has no separate-PowerShell-window branch; it uses hidden PowerShell with stdout/stderr/stdin redirected into Run Center.
- [x] STATIC PASS (2026-09-22) - Bundled original Win11Debloat/WinUtil projects and five supplied vendor installers; bootstrap downloads may still require Internet access.
- [x] STATIC PASS (2026-09-22) - Bundled exact Sleep Hold and Exchange OWA scripts. Both remain disabled pending site configuration; tool help documents the requirements.
- [x] PASS FROM USER SCREENSHOT (2026-09-22) - Machine Specs / Device Information completed in Run Center; separate broader category tests remain open.
- [x] STATIC PASS (2026-09-22) - Original missing payload bundling gate completed. Two site-configured tools remain disabled; fully offline operation and final release acceptance are not claimed.
