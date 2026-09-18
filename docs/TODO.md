# v12 TODO

## Complete in source
- [x] Ground-up cross-platform application structure
- [x] Remove old HTA/VBScript/MSHTA/broker architecture from active repository tree
- [x] Automatic Windows/macOS + CPU architecture detection
- [x] Manual platform selector failsafe
- [x] Native desktop window controls through Avalonia
- [x] Native Runbook file picker
- [x] Windows Install All allow-list and explicit Win11Debloat/WinUtil exclusion
- [x] Three GitHub Actions publish targets

## Needs target-machine validation
- [ ] Windows 10 field test
- [ ] Windows 11 field test
- [ ] macOS Intel field test
- [ ] macOS Apple Silicon field test
- [ ] Validate signing/notarization strategy before public macOS deployment
- [ ] Migrate/revalidate the complete production diagnostic-script catalog one tool at a time
- [ ] Rebuild full Runbook search/index/editor after base launcher passes
