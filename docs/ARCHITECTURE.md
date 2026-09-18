# v12 architecture

## Decision

The application is rebuilt as a cross-platform Avalonia desktop app instead of extending the prior Windows-only WinForms/HTA launch stack.

The same source is published for Windows, Intel macOS and Apple-Silicon macOS. Platform-specific diagnostics live under `scripts/windows` and `scripts/macos`.

## Why there are multiple native binaries

Windows PE executables and macOS Mach-O/application bundles are different native formats. A single native binary cannot be directly launched by both operating systems. The Field Kit therefore remains one product/drive while carrying separate native builds.

## Failsafe startup behavior

The app detects OS/architecture automatically. The top navigation also exposes Windows, macOS Intel and macOS Apple Silicon manual target buttons so a technician can confirm or override the selected profile when troubleshooting packaging/detection.

The manual selector does not make an incompatible native binary executable on the wrong OS; it controls the app profile after a compatible platform build has already launched.
