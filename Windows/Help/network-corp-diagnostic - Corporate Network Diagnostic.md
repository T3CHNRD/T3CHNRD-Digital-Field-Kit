Corporate Network Diagnostic

Guided collection of corporate LAN and Wi-Fi configuration, connectivity, adapter, DNS, route, domain, WLAN, and event evidence. Reports are saved to the Field Kit diagnostic report folder.

## HOW TO RUN

1. Select **Corporate Network Diagnostic** and choose **Run**. The Field Kit requests Administrator access for this tool.
2. Choose a run mode in the options dialog. Start with **Full Network Diagnostic** to collect evidence without renewing the LAN address.
3. Choose LAN-only, Wi-Fi-only, current-state snapshot, or full diagnostic plus LAN renew when appropriate. Specify an adapter alias only for a force-specific-adapter mode.
4. Select **Run Diagnostic**. Review the output and saved report in the Run Center.

LAN renew and Network Discovery options can change system/network state. Use them only when appropriate for the device and site; consult `Windows/Scripts/Network/README-CorpNetworkDiagnostic.md` for mode details and expected effects.
