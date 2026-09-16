# GitHub Source Synchronization

The GitHub repository is the authoritative development home for **T3CHNRD Digital Field Kit**.

## Current policy

- First-party application source, installer source, runner code, configuration, documentation, and diagnostic/workflow scripts should be represented in GitHub.
- The downloadable test ZIP remains the runtime test artifact.
- Large third-party installers, optional redistributables, and vendor payloads are not automatically committed as normal source code. They are kept separate when licensing or repository size makes that safer.
- `windows/current-build/SOURCE-MANIFEST.md` records the first-party/text source paths included with the current v9.1 synchronization.
- `windows/current-build/SourceSnapshot/` is used as a complete source snapshot while the tree is normalized into individual paths.

## Related repository

`T3CHNRD/windows-tool-kit-` was reviewed as a related earlier toolkit. It contains overlapping Windows maintenance, security, network, build, and deployment code.

It is intentionally **not being blindly merged during main-app stabilization**. The active Digital Field Kit has a different HTA/Run Center runtime architecture. Pulling in the older WinForms/background-worker architecture now would increase regression risk while the current app is being runtime-tested.

After the main Windows app is accepted, useful components from `windows-tool-kit-` can be migrated deliberately and tested one at a time.

## Required work order

1. Main Windows app stabilization
2. Runbook integration
3. macOS collectors/scripts in the agreed order
4. Local AI/LLM integration
