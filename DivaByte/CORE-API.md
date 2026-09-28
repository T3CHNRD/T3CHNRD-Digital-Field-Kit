# DivaByte Core API

This document defines the platform-neutral boundary between the Field Kit applications and the standalone DivaByte core.

## Goal

Windows and macOS must not contain separate DivaByte implementations.

Each platform UI launches the native DivaByte core binary compiled from the same source tree and communicates with it through the same versioned local JSON API.

## Transport

- HTTP/JSON on loopback only.
- Bind to `127.0.0.1` and/or `::1`.
- Never expose the service to the LAN.
- The launcher selects an available local port.
- The core prints/writes its chosen port and a random session token.
- Every request except `/v1/health` requires that token.
- The platform app terminates the core when the Field Kit session ends unless a future persistent mode is explicitly enabled.

## Versioning

All routes are under `/v1`.

Breaking changes require a new API version.

## Initial endpoints

### GET /v1/health

Returns process health and API version.

### GET /v1/status

Returns:
- local model availability,
- model loaded state,
- research mode,
- memory/index state,
- Runbook index state,
- offline/online capability state.

### POST /v1/cases

Creates a diagnostic case.

### GET /v1/cases/{id}

Returns case metadata, evidence references, hypotheses, technician observations, and current status.

### POST /v1/cases/{id}/evidence

Adds local evidence by path/reference and records provenance/hash metadata.

### POST /v1/cases/{id}/analyze

Runs or continues root-cause analysis using current evidence, local memory, Runbook knowledge, and permitted research.

### POST /v1/cases/{id}/message

Adds a technician question or observation.

### POST /v1/cases/{id}/correction

Records a technician challenge/correction and forces re-evaluation instead of defending the previous answer.

### GET /v1/cases/{id}/hypotheses

Returns each active hypothesis with:
- confidence band,
- supporting evidence,
- contradicting evidence,
- unknowns,
- what would disprove it,
- recommended next diagnostic.

### GET /v1/memory/search

Searches prior local diagnostic memory.

### POST /v1/memory

Creates a technician-approved memory record.

### GET /v1/runbook/search

Searches the local Runbook.

### POST /v1/runbook/proposals

Creates a proposed Runbook add/update operation.

This does not modify the Runbook.

### POST /v1/runbook/proposals/{id}/approve

Applies a technician-approved Runbook proposal.

### GET /v1/research/mode

Returns:
- Offline
- Local + Research
- Ask Before Researching

### PUT /v1/research/mode

Changes and persists the research policy.

### POST /v1/research

Runs research only when allowed by the active policy.

In Ask Before Researching mode, the core must return an approval-required response before making any Internet request.

## Structured result rules

The API returns structured JSON validated against the shared schemas in `DivaByte/Schemas`.

The UI should never need to parse free-form model text to determine:
- facts,
- evidence,
- hypotheses,
- confidence,
- contradictions,
- next diagnostics,
- research sources,
- Runbook proposals.

## Cross-platform parity

The same request fixture sent to Windows, macOS Intel, and macOS Apple Silicon builds of DivaByte core should return semantically equivalent JSON, allowing for OS-specific evidence paths and diagnostics.
