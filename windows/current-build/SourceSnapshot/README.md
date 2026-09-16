# v9.1 Source Snapshot

This directory exists so the GitHub repository contains the complete **text/source code** shipped in the v9.1 test application even while the repository tree is being normalized.

- `SOURCE-SNAPSHOT-APP-PART-*.md` contains the application shell, installer, launcher, configuration, documentation, and supporting source files.
- `SOURCE-SNAPSHOT-SCRIPTS-PART-*.md` contains the diagnostic/workflow PowerShell source.
- Each source file is introduced by its original runtime path.
- `../SOURCE-MANIFEST.md` is the exact path inventory.

The original working diagnostic scripts are preserved in the test package. The v9 stabilization work changes the app/runner/installer wiring around them rather than rewriting their behavior.

Large third-party application installers and optional redistributable runtime payloads are not duplicated into Git as source code. They remain part of the downloadable test package where appropriate and are tracked separately for licensing/repository-size reasons.
