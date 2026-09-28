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
