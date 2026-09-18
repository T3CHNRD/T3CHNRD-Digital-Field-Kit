# T3CHNRD Digital Field Kit v12

Ground-up rebuild. The old HTA/VBScript/MSHTA/broker/marker-file architecture is intentionally absent from the active tree.

## Architecture

One shared Avalonia source tree publishes three native desktop builds:

- Windows x64: `win-x64`
- macOS Intel: `osx-x64`
- macOS Apple Silicon: `osx-arm64`

The application automatically detects the current OS/CPU. A visible manual selector remains available as a failsafe.

A single native executable cannot run unchanged on Windows and macOS. The supported end state is one external drive containing the three native builds plus clearly named platform launch entries.

## Required behavior carried forward

- Native minimize, maximize, resize and close behavior.
- Responsive desktop UI with Tools, output/run status and platform status.
- Smooth native scrolling rather than the old HTA page.
- Deployment **Install All** installs only Chrome, Firefox, Malwarebytes, AVG and CCleaner.
- Win11Debloat and every WinUtil workflow are excluded from Install All.
- Runbook **Add Document** uses the native file picker.
- Runbook hides prior development/temp paths listed in `docs/REQUIREMENTS.md`.
- Automatic Windows/macOS and Intel/Apple-Silicon detection is primary; manual selection is a failsafe.

## Build

GitHub Actions publishes all three platform builds. No local source compilation is required for a field technician using release artifacts.
