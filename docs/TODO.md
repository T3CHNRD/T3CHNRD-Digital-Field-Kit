# T3CHNRD Digital Field Kit - Master TODO

This is the single source of truth for project tracking. There is only one active TODO file for the repository.

Status: PASS = runtime-tested; STATIC PASS = source/package verified; NEEDS FIELD TEST = implemented but not runtime-proven; FAIL = known broken.

## ACTIVE GATE - WINDOWS APP
- [x] STATIC PASS - Top-level portable Windows launcher.
- [x] STATIC PASS - Top-level graphical Windows installer and uninstall source.
- [x] STATIC PASS - Original Field Kit UI/UX restored.
- [x] STATIC PASS - Original 59-entry GUI tool catalog restored.
- [x] STATIC PASS - 39 tool entries have exact original PowerShell source restored from authoritative GitHub source.
- [ ] 15 tool entries still lack an authoritative original script/payload body; they remain visible but disabled and must not be recreated.
- [x] STATIC PASS - Create and enforce immutable Git blob SHA-1 manifest for restored original scripts.
- [x] STATIC PASS - Embedded stdout/stderr capture and exit-code display for compatible noninteractive tools.
- [x] STATIC PASS - Cancel uses taskkill /T /F on the child process tree.
- [x] STATIC PASS - Interactive tools launch externally rather than blocking the embedded runner.
- [x] STATIC PASS - Scripts declaring #Requires -RunAsAdministrator are elevated only when that declaration is detected.
- [x] STATIC PASS - Default execution policy for the app now launches tools elevated by default in the embedded runner flow.
- [x] STATIC PASS - Install All includes Chrome, Firefox, Malwarebytes, AVG, CCleaner and excludes Win11Debloat/WinUtil.
- [ ] NEEDS FIELD TEST - Launch without PowerShell security prompt.
- [ ] NEEDS FIELD TEST - Minimize/maximize/restore/resize/close.
- [ ] NEEDS FIELD TEST - Favorites/Recent/categories/search/Run Center/Runbook.
- [ ] NEEDS FIELD TEST - All Tools smooth scrolling.
- [ ] NEEDS FIELD TEST - 100/125/150/200% display scaling.
- [ ] NEEDS FIELD TEST - portable local disk / USB / external SSD.
- [ ] NEEDS FIELD TEST - Windows install / shortcuts / installed launch / uninstall.
- [ ] NEEDS FIELD TEST - every restored Windows diagnostic category.
- [ ] Proper branded Windows EXE/taskbar icon remains open; current field-test launcher is WSH-based.

## 2026-09-20 WINDOWS FIELD-TEST CHECKLIST
This checklist is the current live hardware gate for the Windows app. Static validation is complete, but final acceptance requires a real Windows machine.

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
- [ ] Finish Runbook wiki/search/index/editor.
- [ ] Build macOS Intel native app + installer.
- [ ] Build macOS Apple Silicon native app + installer.
- [ ] Add automatic multi-platform startup routing and manual Windows/macOS Intel/macOS Apple Silicon failsafe.
- [ ] Add offline/local AI only after diagnostic foundations are stable.


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
- [ ] NEEDS FIELD TEST - Windows launcher/UI startup on actual Windows hardware.
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
- [ ] IN PROGRESS - Reconcile the remaining exact user-supplied Windows Master Diagnostic Toolkit scripts/resources with the current Field Kit catalog.
- [ ] IN PROGRESS - Restore original deployment resources/workflows from the supplied toolkit without changing Win11Debloat/WinUtil exclusion from Install All.
- [ ] NEEDS FIELD TEST - Verify tool cards now populate under Diagnostics, Repair, Optimization, Security, Network, Deployment, and System Management.


## 2026-09-18 PowerShell 5.1 JSON catalog enumeration fix
- [x] PASS FROM FIELD REPRODUCTION - App displayed "Loaded 1 tools (1 ready)" and one card containing concatenated names/descriptions from the entire catalog.
- [x] ROOT CAUSE - Windows PowerShell 5.1 returned the JSON array as one array object; the UI treated that object as a single tool.
- [x] STATIC PASS - Catalog loader now explicitly enumerates every JSON entry into $script:ToolCatalog.
- [ ] NEEDS FIELD TEST - Confirm startup now reports 61 tools and individual cards populate all categories/search.


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
- [ ] NEEDS FIELD TEST - Confirm Device Information Report runs and displays output in Run Center.
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
- [ ] IN PROGRESS - Bundle exact original Win11Debloat/WinUtil projects and local application installers from the user-supplied toolkit into the technician package.
- [ ] IN PROGRESS - Bundle exact original 24-Hour Sleep Hold and Exchange OWA Diagnostic scripts from the user-supplied toolkit.
- [ ] NEEDS FIELD TEST - Re-test an enabled diagnostic tool after admin-regex fix and confirm output appears only in Run Center.
- [ ] RELEASE GATE - Do not call Windows self-contained until the remaining 11 disabled payload-backed cards are bundled or intentionally removed.
