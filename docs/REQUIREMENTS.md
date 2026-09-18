# Rebuild requirements

## Product shape

One Field Kit on one external drive, with separate native Windows and macOS applications built from one shared codebase.

Automatic platform selection is primary:
- Windows -> Windows x64 build
- macOS x86_64 -> macOS Intel build
- macOS arm64 -> macOS Apple Silicon build

Manual platform selection remains visible as a failsafe.

## Windows UI

- Native window chrome: minimize, maximize, resize, close.
- App/taskbar identity provided by the native packaged executable.
- Tools view must use native scrolling.
- Output must remain visible without freezing the UI.

## Deployment

Install All includes exactly:
- Google Chrome
- Mozilla Firefox
- Malwarebytes
- AVG
- CCleaner

Install All excludes:
- Win11Debloat
- all WinUtil apps/workflows

## Runbook

Add Document must open a native file picker.

Exclude these prior development/runtime items from the technician Runbook view:
- `.venv312`
- `ai_cowork`
- `apps`
- `deps.txt`
- `static`
- `static\\robots.txt`
- `templates`
- `tmp-lo-test2`
- `tmp-lo-test2\\AB_Cluster.pdf`
- `tmp_backend.html`
- `tmp_backend_v.txt`
- generic duplicate `General` entries
