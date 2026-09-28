# DivaByte

DivaByte is the local-first diagnostic partner for the T3CHNRD Digital Field Kit.

The name combines Diva and Tarabyte and keeps both dogs permanently connected to the project.

## Mission

DivaByte is being built to help a technician get to root cause faster without replacing technician judgment.

It must:

- work completely offline,
- analyze Field Kit diagnostic evidence locally,
- use the Runbook as local knowledge,
- remember confirmed recurring problems, successful fixes, failed fixes, disproven hypotheses, and technician corrections,
- optionally research the Internet when the selected policy allows it,
- clearly separate facts, inference, remembered experience, Runbook guidance, and external research,
- actively look for evidence that contradicts its current hypothesis,
- accept questions and corrections from the technician,
- recommend the next best diagnostic instead of assuming its first answer is correct,
- never execute a repair solely because the model suggested it.

## Research modes

### Offline

Uses only the local model, current logs/evidence, local Runbook, and remembered incidents.

Offline mode also supports local Runbook additions and updates. Human approval remains required for Runbook writes.

### Local + Research

Reasons locally first. Internet research may be used when useful. Research results must be saved with their source and retrieval date and must remain labeled separately from current evidence.

### Ask Before Researching

Reasons locally first. When outside research would materially help, DivaByte must ask the technician before making an Internet request.

This is the default mode.

## Current implementation state

The Windows UI now contains the local DivaByte foundation:

- case-note storage,
- diagnostic evidence browser,
- persistent research-mode preference,
- technician-curated memory store,
- Runbook article editor,
- local research cache,
- analysis-results browser.

The actual local LLM and live Internet-research engine are intentionally not connected yet. The foundation is designed so those components can be added without making Internet access mandatory.
