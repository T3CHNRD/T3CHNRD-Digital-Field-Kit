# Network Troubleshooting SOP

Use this procedure for loss of connectivity, DNS failures, DHCP problems, slow access, or suspected local routing issues.

## Establish scope

- Identify whether the failure affects one device, one user, one network segment, or multiple services.
- Record the connected interface, network name, IP address, gateway, DNS servers, and approximate start time.
- Confirm whether wired, wireless, VPN, proxy, or remote access is involved.

## Review order

1. Confirm link or wireless association.
2. Check local address, gateway, and DNS configuration.
3. Test the local gateway, then a known external address, then a known hostname.
4. Compare name resolution with direct connectivity.
5. Renew DHCP or reset the network stack only after capturing the original state.
6. Re-test the affected business service and document the result.

## Guardrails

- Do not reset a remote user's network stack without a recovery path.
- Do not change DNS, proxy, VPN, or firewall settings without recording the original values.
- Coordinate changes with the network owner when multiple devices are affected.

## Escalate when

- gateway or upstream service failure is suspected
- the issue affects multiple users or locations
- authentication, VPN, firewall, or managed DNS policy is involved
- the result is intermittent and requires packet capture or provider investigation

## Closeout

Record tests performed, original and changed settings, tool output locations, service validation, and any remaining monitoring requirement.
