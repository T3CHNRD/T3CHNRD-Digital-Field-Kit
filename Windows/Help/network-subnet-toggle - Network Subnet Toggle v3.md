Network Subnet Toggle v3

WHAT IT DOES
Configures the selected physical adapter using your settings. No preset IP, gateway or DNS values are used. The archived original remains unchanged for provenance and is no longer launched by the card.

HOW TO RUN
Open Network > Network Subnet Toggle v3. Select the adapter number in Run Center and use Send input. Choose STATIC or DHCP. For STATIC, enter the full IPv4 address, prefix length (1-32), optional gateway, and comma-separated DNS addresses. Blank gateway means none; blank DNS clears static DNS. DHCP restores automatic address and DNS assignment.
Review the summary, then type APPLY exactly. Any other confirmation cancels. This replaces static addressing and may disconnect remote access. Obtain valid network settings from the network administrator; input validation cannot prove an address is available or routable.

RESULTS
Before applying, saves Network-Before-<timestamp>.json in Diagnostic-Reports on the toolkit device in portable mode. This is a reference snapshot, not automatic rollback. Run Center retains the transcript in Diagnostic-Reports/AppLogs. If a command fails, settings may be partially applied: inspect the adapter and use DHCP or the recorded original configuration to recover.

SCRIPT
Windows/Scripts/Network/Set-InteractiveNetworkConfiguration.ps1
