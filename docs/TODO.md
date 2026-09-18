# T3CHNRD Digital Field Kit v11 TODO

## Phase 1 - Windows
- [x] Ground-up shell architecture
- [x] Remove v10 HTA/VBScript broker architecture from active main
- [x] Direct PowerShell invocation without the old broker/queue
- [x] Preserve original scripts and SHA-256 manifest
- [x] Native window controls and DPI-aware layout
- [x] In-app output, exit state, logs, and cancel control
- [x] Favorites, Recent, tool search, category navigation
- [x] Windows portable launcher
- [x] Windows field-test installer
- [ ] Complete Windows field validation on the technician workstation
- [ ] Restore/validate third-party deployment payloads only after the core runner passes

## Phase 2 - Runbook
- [ ] Wiki-style browsing/search
- [ ] Import documents
- [ ] Article editor
- [ ] Offline full-text index
- [ ] AI retrieval integration

## Phase 3 - macOS
- [ ] First-run OS detection
- [ ] Detect Intel x86_64 vs Apple Silicon arm64
- [ ] system_profiler
- [ ] Activity Monitor / memory pressure
- [ ] DiagnosticReports
- [ ] diskutil / APFS
- [ ] FileVault
- [ ] Gatekeeper / XProtect
- [ ] networksetup / scutil
- [ ] softwareupdate
- [ ] LaunchAgents / LaunchDaemons
- [ ] macOS portable launcher and installer

## Phase 4 - local AI/LLM
- [ ] Analyze Diagnostic-Reports offline
- [ ] Retrieve relevant Runbook articles
- [ ] Draft new Runbook procedures for technician review
