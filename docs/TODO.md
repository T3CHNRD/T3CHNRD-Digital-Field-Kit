# T3CHNRD Digital Field Kit - TODO

## Active / Next

- [ ] Complete Windows runtime field testing for every tool category on Windows 10 and Windows 11.
- [ ] Add structured local AI diagnostic assistant using normalized evidence + deterministic rules + local LLM.
- [ ] Add Runbook retrieval to AI diagnosis so AI recommendations cite relevant Runbook articles.
- [ ] Add AI-assisted Runbook draft generation for newly solved issues. AI-created articles must remain **Draft** until a technician reviews and promotes them.
- [ ] Build macOS collectors and native scripts for System Information, performance, crash logs, storage, FileVault, Gatekeeper/XProtect, networking, updates and persistence.
- [ ] Define shared Windows/macOS diagnostic evidence schema.
- [ ] Add Runbook article editor with richer formatting and screenshots.
- [ ] Add Runbook full-text index suitable for offline AI retrieval.

## Runbook rules

- Runbook content is operational documentation, not application source code.
- New articles use the standard template in `docs/RUNBOOK_STANDARD.md`.
- AI may suggest or create drafts, but may not silently publish verified procedures.
- Verified procedures should include symptoms, scope, cause, resolution, verification and rollback/recovery where applicable.
