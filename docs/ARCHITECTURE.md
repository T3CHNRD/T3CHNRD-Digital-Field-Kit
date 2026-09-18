# v11 architecture

v11 is a ground-up rebuild.

## Windows execution path

Production target:

```
T3DFK.exe -> native process runner -> Windows PowerShell -> original .ps1
```

Field-test fallback while the private GitHub hosted runner is unavailable:

```
RUN-T3DFK.cmd -> T3DFK.ps1 WinForms shell -> Windows PowerShell -EncodedCommand -> original .ps1
```

The active v11 design intentionally removes HTA, mshta.exe, VBScript brokers, marker-file IPC queues, and runtime-compiled window hosts.

The PowerShell diagnostic scripts are treated as immutable payloads. A SHA-256 manifest is checked before the field-test shell opens.

## Cross-platform direction

The external drive remains one T3CHNRD Digital Field Kit. First-run platform detection is required:
- Windows -> Windows engine
- macOS x86_64 -> Intel macOS engine
- macOS arm64 -> Apple Silicon engine

Work order remains Windows -> Runbook -> macOS -> local AI/LLM.
