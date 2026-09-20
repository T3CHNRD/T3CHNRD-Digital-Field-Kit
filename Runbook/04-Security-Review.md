# Security Review SOP

Use this procedure for suspected malware, account risk, persistence, security drift, or unusual endpoint behavior.

## Before running tools

- Confirm the device owner and business impact.
- Record the current time, logged-in user, device name, and network state.
- Ask whether the device must remain online for business, containment, or evidence reasons.
- Do not delete files, disable security controls, or reset accounts before documenting the reason and obtaining approval.

## Review order

1. Run a read-only device and security baseline review.
2. Review security events, startup items, local accounts, open ports, and PowerShell risk indicators.
3. Run the approved Defender quick scan when the user impact is acceptable.
4. Review the generated output for unknown services, unsigned startup entries, unexpected accounts, and policy drift.
5. Apply only an approved remediation and record the before and after state.

## Escalate immediately when

- ransomware, credential theft, or active unauthorized access is suspected
- a privileged account may be compromised
- evidence must be preserved for legal, insurance, or incident response use
- the device is business-critical and containment could interrupt operations

## Closeout

Save the report path, tool names, exit codes, findings, remediation approval, and validation result in the documentation template. Treat suspicious files as evidence; do not upload them to unapproved services.
