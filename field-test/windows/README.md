# v11 Windows field-test shell

This folder documents the temporary no-build field-test shell used while the private repository's GitHub-hosted Windows runner is unavailable.

It uses PowerShell WinForms directly and launches the existing scripts with PowerShell `-EncodedCommand`.

It does not use HTA, mshta.exe, VBScript, RunnerBroker, or marker-file IPC.

The production native .NET source is under `src/T3DFK.App`.
