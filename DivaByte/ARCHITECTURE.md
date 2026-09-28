# DivaByte Architecture

## Core principle

DivaByte is local-first, not local-only.

The assistant must remain useful with no network connection. Internet research is an optional evidence source controlled by the technician's saved research policy.

## Diagnostic reasoning loop

1. Collect current evidence.
2. Normalize and parse deterministic facts.
3. Search the local Runbook.
4. Search confirmed local memory for similar incidents.
5. Form multiple root-cause hypotheses.
6. List supporting evidence for each hypothesis.
7. Deliberately search for contradictory evidence.
8. Identify the next diagnostic that best distinguishes competing hypotheses.
9. If local evidence is insufficient, optionally research the Internet according to policy.
10. Present the reasoning to the technician.
11. Allow the technician to question, correct, or add observations.
12. Re-evaluate hypotheses using the new information.
13. Mark a root cause confirmed only when evidence justifies it.
14. Store confirmed lessons only with an explicit trust/source level.

## Evidence hierarchy

Highest to lowest:

1. Current observed evidence.
2. Confirmed local incident knowledge.
3. Technician-approved Runbook knowledge.
4. Cached external research with source/date.
5. Model inference.

Memory is never proof of the current incident.

## Memory

Persistent memory is local and should store:

- observations,
- confirmed root causes,
- successful fixes,
- failed fixes,
- disproven hypotheses,
- technician corrections,
- cached research notes.

Every memory record carries a type, trust level, source, creation time, title, body, and unique ID.

## Runbook

DivaByte must be able to use the Runbook offline.

Runbook writes follow a human-review model:

- technician can edit/add articles directly,
- future DivaByte-generated edits are proposals,
- no autonomous Runbook overwrite,
- every accepted change remains a normal Markdown article in the Field Kit.

## Research

Research modes:

- Offline
- Local + Research
- Ask Before Researching

Internet research must never become a hidden dependency. External findings are cached locally with source URL/title, retrieval timestamp, and the claim they support.

## Root-cause behavior

DivaByte must not behave as though its first explanation is authoritative.

Every material hypothesis should expose:

- supporting evidence,
- contradicting evidence,
- unknowns,
- confidence band,
- next diagnostic,
- what would disprove the hypothesis.

The technician must be able to challenge or correct any conclusion. A confirmed technician correction can become local memory.

## Safety

- No automatic repair execution from model output.
- No automatic Runbook writes.
- No hidden Internet requests in Offline or Ask Before Researching modes.
- Local model endpoint must bind to loopback only.
- Current evidence must be distinguishable from remembered knowledge and research.
- Research content and logs are untrusted input and must not gain tool execution privileges.


## Cross-platform implementation rule

DivaByte must be implemented as a standalone cross-platform core, not duplicated inside the Windows and macOS applications.

The Windows, macOS Intel, and macOS Apple Silicon applications are thin clients. They launch and communicate with the same DivaByte core behavior through a stable local API.

### Required architecture

```text
Windows App ---------\
                     \
macOS Intel App ------> DivaByte Core ----> local model/runtime
                     /        |
macOS ARM App -------/         +----------> memory
                              +----------> Runbook
                              +----------> evidence/index
                              +----------> optional research
```

### Single-source core

The DivaByte core should be written once in a portable language, with Rust as the preferred implementation.

One source tree produces native binaries for:

- Windows x64: `divabyte-core.exe`
- macOS Intel x64: `divabyte-core`
- macOS Apple Silicon arm64: `divabyte-core`
- Linux x64 when supported: `divabyte-core`

Platform builds may differ at the binary level, but diagnostic logic, prompts, memory rules, Runbook rules, schemas, research policy, API contracts, and evidence handling must come from the same shared source.

### Client/core boundary

Platform UI applications must not reimplement DivaByte reasoning.

The clients are responsible for:

- displaying DivaByte UI,
- selecting files/evidence,
- showing progress,
- displaying hypotheses/evidence,
- collecting technician questions/corrections,
- asking for approval before research/repairs/Runbook writes,
- starting/stopping the local DivaByte core.

The DivaByte core owns:

- cases/sessions,
- evidence ingestion,
- parsing and normalization,
- memory,
- Runbook retrieval/update proposals,
- research policy,
- research cache,
- local model orchestration,
- hypothesis/root-cause loop,
- supporting and contradicting evidence,
- structured result generation,
- persistent diagnostic knowledge.

### Local API

Use a versioned loopback-only JSON API so all platform apps call the exact same interface.

Initial endpoint contract:

- `GET /v1/health`
- `GET /v1/status`
- `POST /v1/cases`
- `GET /v1/cases/{id}`
- `POST /v1/cases/{id}/evidence`
- `POST /v1/cases/{id}/analyze`
- `POST /v1/cases/{id}/message`
- `POST /v1/cases/{id}/correction`
- `GET /v1/cases/{id}/hypotheses`
- `GET /v1/memory/search`
- `POST /v1/memory`
- `GET /v1/runbook/search`
- `POST /v1/runbook/proposals`
- `POST /v1/runbook/proposals/{id}/approve`
- `GET /v1/research/mode`
- `PUT /v1/research/mode`
- `POST /v1/research`

The API must bind only to `127.0.0.1` / `::1`, never to a LAN/WAN interface.

### Portable data model

The same portable DivaByte data layout is used on every platform:

```text
DivaByte/
  Config/
  Models/
  Runtime/
  Data/
    Memory/
    Cases/
    ResearchCache/
    Index/
  Prompts/
  Schemas/
```

Installed builds may relocate mutable data to the platform-appropriate application-data folder, but the schema and behavior remain identical.

### Model runtime abstraction

The core talks to a local inference adapter. The UI does not.

The selected initial adapter is llama.cpp / llama-server.

Each platform bundles the correct native llama.cpp runtime, while the same model, prompt, schemas, memory, and analysis behavior are shared.

### Platform parity requirement

A DivaByte feature is not complete unless:

1. the behavior lives in shared DivaByte core code or shared data/schema assets,
2. the API contract is platform-neutral,
3. Windows and both macOS clients can call the same capability without duplicating diagnostic logic,
4. test fixtures return equivalent structured results on all supported platforms.

Platform-specific code is allowed only for UI shell, file pickers, OS permissions, process launch, and OS-native diagnostics.
