# Runbook

This folder is the operational documentation layer for the T3CHNRD Digital Field Kit.

It is intentionally not a duplicate UI layer or a second project root. It is the technician-facing reference set for troubleshooting, launch paths, repair steps, and documented procedures.

## Scope

- technician quick-start guidance
- troubleshooting playbooks and decision paths
- repair and remediation procedures
- operational notes and escalation references
- documentation templates and reusable report patterns

## Canonical role

- The root README.md remains the canonical project overview.
- The master TODO remains in [../docs/TODO.md](../docs/TODO.md).
- This Runbook exists to support field execution and support continuity.

## Index

- [00-INDEX.md](00-INDEX.md) — runbook index and navigation
- [01-Quick-Start.md](01-Quick-Start.md) — quick-start and launch guidance
- [02-Troubleshooting-Playbook.md](02-Troubleshooting-Playbook.md) — structured field troubleshooting flows
- [03-Documentation-Template.md](03-Documentation-Template.md) — templates for service notes and reports
- [04-Security-Review.md](04-Security-Review.md) — defensive endpoint and account review
- [05-Network-Troubleshooting.md](05-Network-Troubleshooting.md) — connectivity and DNS workflow
- [06-Repair-and-Maintenance.md](06-Repair-and-Maintenance.md) — controlled repair and maintenance
- [07-Deployment-and-Setup.md](07-Deployment-and-Setup.md) — workstation setup and handoff
- [08-Evidence-and-Escalation.md](08-Evidence-and-Escalation.md) — evidence handling and escalation packet

## Platform posture

The active Windows phase remains the project gate. The Runbook is structured to support the current release while keeping future macOS work separated as planned platform expansion rather than competing activity in the current root.
