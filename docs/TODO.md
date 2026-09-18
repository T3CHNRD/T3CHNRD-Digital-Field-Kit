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
