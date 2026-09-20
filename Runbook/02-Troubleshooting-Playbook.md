# Troubleshooting Playbook

## Overview

This playbook is intended for repeatable investigation and escalation across technician sessions.

## Standard triage flow

1. Confirm the issue and business impact
2. Verify the device and operating context
3. Check for account, admin, or policy constraints
4. Run low-risk diagnostics first
5. Move to targeted repair or network actions only as needed
6. Capture output and confirm the result
7. Escalate only when the issue is outside the current toolkit scope

## Common categories

### Diagnostics

Use diagnostics when the root cause is still unclear or when a broad system review is needed.

Examples:

- hardware and system summary
- disk and performance checks
- crash and event review
- startup and persistence review

### Security

Use security checks when the issue suggests malware, persistence, account risk, suspicious activity, or configuration drift.

### Network

Use network checks when the issue involves connectivity, DNS, routing, DHCP, or local network behavior.

### Repair

Use repair actions when a device has a known or likely configuration issue that can be safely remediated.

### Deployment

Use deployment workflows when the task is installation, provisioning, software setup, or fresh-environment preparation.

## Escalation triggers

Escalate when:

- the problem involves vendor-specific hardware or firmware issues
- a service is failing outside the local toolkit scope
- the tool output is inconclusive or contradictory
- a repair action is high-impact and requires documented approval
- the issue requires an external support workflow or a known-good rebuild path

## Evidence to save

Capture and save:

- timestamps
- command or tool name
- output summary
- screenshots or log path
- impacted user, device, and service
- decision made and follow-up action

## Best practice

Keep the investigation narrow, evidence-based, and reversible where possible. Avoid broad changes before the root cause is understood.
