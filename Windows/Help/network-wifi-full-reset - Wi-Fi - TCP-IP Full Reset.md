Wi-Fi / TCP-IP Full Reset

Resets Winsock and TCP/IP, attempts to release and renew the selected Wi-Fi adapter's DHCP lease, flushes DNS, restarts WLAN AutoConfig, and captures before/after network evidence. The Wi-Fi adapter restart can be skipped by the script, but the normal guided launch uses the defaults.

## HOW TO RUN

1. Use this only when less disruptive network troubleshooting has not resolved the issue. The tool requires Administrator access and temporarily interrupts Wi-Fi.
2. Select **Wi-Fi / TCP-IP Full Reset** and choose **Run**. Confirm the action when prompted.
3. Allow the reset and evidence capture to finish. The report is saved under Diagnostic-Reports.
4. Restart Windows afterward so the Winsock/TCP-IP reset is fully applied, then reconnect to Wi-Fi and review the report.

The reset does not delete saved Wi-Fi profiles. Avoid running it during remote sessions that depend on the affected network.
