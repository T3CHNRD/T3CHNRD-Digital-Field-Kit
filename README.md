# T3CHNRD Digital Field Kit

The [uploaded archive integration report](docs/ARCHIVE-INTEGRATION.md) documents
the current 64-tool catalog, original-source hashes, bundled deployment payloads,
Run Center validation, and remaining site-specific requirements.

For Windows Explorer extraction, use the portable **FK.zip** package and extract
to a short location such as `C:\`. Launch `C:\FK\T3CHNRD Digital Field Kit.exe`.
The PS2EXE-built launcher is tracked on main and included in source downloads.
Extract the entire ZIP first and keep the `Windows` folder beside the EXE;
the EXE launches the bundled app and is not a standalone copy of every tool.

Run Center supports two simultaneous tools in separate tabs, each with its own
output, input, log, and Cancel button. Click the footer status to reopen a hidden
Run Center. Completion and exit code appear on separate lines. The app window and
EXE use the same T3DFK icon.
GitHub's automatic source ZIP adds a long repository/SHA folder name; extracting
that archive to its default nested destination can exceed Windows path limits.
Maintainers can create the short package from a committed checkout with
`Windows\Build\Build-PortableZip.ps1 -OutputFile C:\Temp\FK.zip`.

T3CHNRD Digital Field Kit is a technician-first Windows diagnostic and repair toolkit designed for portable field use, local workstation support, and structured troubleshooting workflows. It brings together a restored Windows interface, a curated tool catalog, captured output in a Run Center, operational Runbook access, and a strict policy of not inventing missing original scripts.

## Why this exists

This project exists to give a technician a reliable, field-friendly toolkit that can be carried on a USB drive or installed locally without depending on a fragile or inconsistent collection of scripts.

The goal is simple: provide a single operational workspace for diagnosis, repair, optimization, security review, and deployment tasks while keeping the experience transparent and auditable.

In practical terms, this project helps a technician:

- launch a portable or installed Windows toolkit from a single entry point
- run recovered Windows diagnostics, maintenance, security, repair, and deployment workflows
- review output in an embedded Run Center instead of a hidden or disconnected console
- classify tools by category and risk
- keep reports and technician notes in a structured Runbook and Diagnostic-Reports workflow
- keep the current Windows release work separate from future macOS and AI phases

## Current status

This repository is currently in the Windows-first stabilization phase.

### Active milestone

- Windows app is the active production milestone
- The toolkit is intended to run from a portable USB/external drive or an installed workstation location
- Future platform work remains intentionally separated from the active Windows release gate

### Current project maturity

- core launcher and package structure are in place
- Windows UI and catalog flow are active
- restored scripts are being validated and tracked
- missing or unverifiable original payloads remain intentionally disabled instead of being recreated
- field validation is still required for live Windows runtime behavior

## Main project goals

- restore the original field kit UX and catalog structure
- keep tool execution traceable, visible, and easy to audit
- avoid rewriting or inventing missing original scripts
- preserve immutable script integrity using the project manifest and source-hash validation
- provide a technician-friendly workflow for diagnostics, repair, optimization, deployment, and security review

## Core functionality

### Windows UI and launcher

The project includes a Windows desktop launcher and a portable entry model. The top-level launchers handle the normal user path, while the app itself uses a structured PowerShell UI with:

- tool cards and categories
- recent/favorites tracking
- search/filter behavior
- Run Center output capture
- Runbook viewing and browsing
- administrator-aware execution behavior

### Diagnostic workflows

The tool catalog covers diagnostics, security review, network checks, repair tasks, optimization, deployment, and system management. Many restored tools are exact recovered originals, while missing, unverifiable originals remain disabled instead of being replaced with untrusted rewrites.

### Embedded execution model

The Windows app runs tools in a controlled embedded flow with:

- stdout and stderr capture
- exit-code reporting
- interactive input support for the appropriate tools
- cancellation support for active child processes
- elevated relaunch when required by the target script

### Runbook and reporting

The repo includes:

- a Runbook folder for SOPs, repair guides, technician resources, and operational reference material
- a Diagnostic-Reports directory for live output and generated reports
- a centralized state location for favorites/recent activity and tool-session metadata

## Repository layout

- Windows/App — Windows application launcher and UI logic
- Windows/Config — catalog manifest and toolkit settings
- Windows/Installer — install/uninstall workflow
- Windows/Scripts — restored tool scripts and support utilities
- Runbook — operator documents and support references
- Diagnostic-Reports — runtime-generated logs and diagnostic reports
- macOS Intel — placeholder for the future Intel native build
- macOS Apple Silicon — placeholder for the future Apple Silicon native build

## Canonical repository conventions

This repository uses a single canonical project root and a single canonical source of truth for public-facing documentation.

- The repository root is the only authoritative project root for the active build.
- The root README.md is the canonical project overview and public entry point.
- The master TODO in [docs/TODO.md](docs/TODO.md) is the canonical task tracker.
- The Runbook is a true operational layer for technician procedures, not a duplicate of the app or another UI entry point.
- Platform-specific folders such as macOS Intel and macOS Apple Silicon remain explicit placeholders, not competing production paths.

This keeps the repo simple, auditable, and aligned with best-practice monorepo or single-project hygiene without introducing duplicate user-facing documentation layers.

## Startup and usage

### Portable Windows launch

Double-click:

- T3CHNRD Digital Field Kit.vbs

When the packaged Windows EXE is present, this launcher automatically delegates to `T3CHNRD Digital Field Kit.exe`, which provides the branded taskbar and shortcut icon. The VBS path remains the portable fallback for source-only checkouts.

### Installed Windows launch

Double-click:

- INSTALL T3CHNRD Digital Field Kit.vbs

### Important usage note

Do not launch the PowerShell source directly from the Windows/App folder unless intentionally debugging or testing internals. The supported entry points are the root portable installer/uninstaller and the project root launcher.

The branded EXE is generated during Windows packaging from [Windows/App/Build-T3DFKWindowsExe.ps1](Windows/App/Build-T3DFKWindowsExe.ps1). It is not committed as a binary; release artifacts are generated from source so the package remains auditable.

## Roadmap and branch plan

All future work continues on `main` in this order:

1. Windows app
2. macOS Intel app
3. macOS Apple Silicon app
4. One shared UI/UX shell on the portable drive
5. Auto-detect OS at startup
6. Local offline AI + runbook-aware log analysis
7. Runbook folder for SOPs, repair guides, and technician files

## Future phases (not active yet)

### macOS Intel and Apple Silicon
The macOS Intel and Apple Silicon directories are placeholders for future native builds. They are intentionally not treated as completed or production-ready while the Windows phase remains the active gate.

### Local offline AI
Local offline AI is intentionally deferred until the Windows diagnostic foundation is stable and field-tested. The planned AI phase is a local-only assistant that can read runbooks and logs to help summarize findings without cloud dependence.

### Runbook expansion
The Runbook remains the technician operational reference layer and is expected to expand alongside future platform work.

## Project policy

This project follows a strict rule:

- if an original script body is not recoverable and authoritative, it remains disabled
- it is not recreated or rewritten from memory
- the project keeps a clear record of which tools are restored, which are missing, and which are intentionally blocked

This keeps the toolkit honest, auditable, and aligned with real field recovery practices.

## Licensing / legal

This project is currently a personal project and is being developed as a personal technical toolkit and internal field utility. At this stage, no formal commercial or team-distribution license has been adopted.

### Current posture

- maintained under a personal-development model
- not yet a formal public commercial product with a signed commercial licensing structure
- not yet a finalized team-distribution model

Before broader team sharing, resale, customer delivery, or public commercial distribution, the project should be reviewed for:

- ownership and contribution assignment
- third-party script and payload licensing status
- vendor or OEM rights for any bundled software
- export, distribution, and support obligations
- legal review for enterprise or customer use

### Third-party and restored-script review

This project includes restored scripts, bundled installer references, and operational workflows that may be derived from original community, vendor, or technician-source materials. Some included items may carry their own licensing, copyright, or usage restrictions even when the project architecture is original.

Before any team collaboration, public release, or commercial sale, the project should confirm:

- which assets are original code authored for this repository
- which assets are restored from prior working materials
- which assets are vendor-provided or third-party payloads
- which assets are explicitly excluded from redistribution or reuse
- which commercial packaging and support boundaries apply

## Future team / commercial path

The project is structured to support future growth, but the legal status is intentionally conservative today. If this toolkit is later used by a team or sold commercially, the following should be handled before release:

- define contributor ownership and intellectual-property assignment
- select an explicit OSS or commercial license
- document third-party dependencies and restrictions
- create a distribution policy for bundled tools, installers, and artifacts
- confirm whether any bundled materials are for internal support use only
- review support boundaries and technical warranty language

### Important notice

This project is not currently presented as legally finalized for public commercial deployment or broad team use. It remains a working personal toolkit and operational project archive until formal legal review and licensing decisions are completed.

## Documentation status

The repository’s single source of truth for task tracking is the master TODO in [docs/TODO.md](docs/TODO.md). The README is the public project summary; the TODO is the working execution list.

The project intentionally keeps one canonical project entry point, one root overview, and one operational Runbook so the field toolkit remains easy to navigate without redundant UI duplication.
