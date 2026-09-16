# T3CHNRD Digital Field Kit - Product Vision and Work Order

**One T3CHNRD Digital Field Kit on one external drive**, with platform-aware launchers and one shared experience across:

- Windows
- Intel macOS
- Apple Silicon macOS

with shared:

- UI concepts
- Runbook/wiki
- diagnostic report structure
- future offline AI/LLM analysis

and platform-specific diagnostic engines underneath.

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

Every completed code/debug change should produce a fresh downloadable test build so field testing does not depend on a local development environment.
