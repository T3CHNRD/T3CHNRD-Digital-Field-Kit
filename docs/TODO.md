# T3CHNRD Digital Field Kit - Master TODO

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
