# T3CHNRD Digital Field Kit v11

Ground-up rebuild of the field diagnostic application. v11 deliberately removes the v10 HTA/VBScript/MSHTA broker architecture and returns to the original goal: a dependable native desktop application that launches the known-working diagnostic scripts without rewriting them.

## Current v11 foundation

- **Desktop UI:** .NET 8 + Avalonia.
- **Windows execution:** `T3DFK.exe -> powershell.exe -> original .ps1`.
- **Script preservation:** the 56 supplied Windows PowerShell scripts are stored byte-for-byte in an immutable payload archive and verified against `scripts/windows-manifest.json` before every build and again at app startup.
- **Output:** stdout/stderr are captured into the in-app Run Center and session log files.
- **Interactive tools:** stdin can be sent from the Run Center.
- **Cancel:** terminates the child process tree.
- **Platform detection:** automatic Windows / macOS Intel / macOS Apple Silicon detection. The platform badge is informational; users do not select the engine manually.
- **Portable Windows build:** self-contained `T3DFK.exe`; no HTA, VBS, MSHTA, broker, or local compile step.
- **Windows installer:** built from the tested portable output with Inno Setup.

## Deliberately not carried forward

The v10 HTA UI, VBScript launchers, VBScript runner broker, temporary file command queue, PowerShell installer bootstrap, generated WindowHost launcher, and patch-era validation files are not part of the v11 current source tree.

Historical v10 commits remain in Git history for auditability. They are not present in the current branch tree.

## Script payload policy

The original scripts are treated as immutable operational payloads, not application source to be refactored. The exact bytes are stored in:

`payload/immutable-windows-scripts.tar.xz`

Their relative paths and SHA-256 hashes are recorded in:

`scripts/windows-manifest.json`

`build/Restore-ScriptPayload.ps1` extracts and verifies all 56 scripts. Any missing or changed script fails the build.

## Status language

- **PASS** — executed successfully on the target operating system.
- **STATIC PASS** — source/package validation only.
- **NEEDS FIELD TEST** — requires target OS/field hardware verification.
- **FAIL** — known broken.

## Work order

1. Windows v11 foundation and Windows tools.
2. Runbook/wiki integration.
3. macOS Intel + Apple Silicon diagnostics.
4. Local AI/LLM analysis and Runbook retrieval.
