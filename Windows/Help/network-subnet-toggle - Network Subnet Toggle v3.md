Network Subnet Toggle v3
========================

WHAT IT DOES
Original site utility: normal IP 192.168.10.151/24, gateway 192.168.10.1, DNS 192.168.1.11 and 192.168.1.9. Alternate subnet input retains host .151. Review these fixed settings before use.

LOCATION
Network > Network Subnet Toggle v3

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Review the fixed IP, gateway and DNS values in the description before use. Changing adapter addressing can disconnect remote sessions; only use settings approved for the connected network.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Network\Network-Subnet-Toggle-v3.ps1
Configured arguments: (defaults)

ORIGINAL SCRIPT DOCUMENTATION
.SYNOPSIS
    Switches a laptop network adapter between:
      1. Normal network: 192.168.10.151/24
      2. Any alternate /24 subnet entered by the user

.NORMAL NETWORK
    IP address:      192.168.10.151
    Subnet mask:     255.255.255.0
    Default gateway: 192.168.10.1
    DNS servers:     192.168.1.11, 192.168.1.9

.ALTERNATE NETWORK
    The user enters a subnet such as 192.168.2.
    The script uses:
      IP address:      192.168.2.151
      Subnet mask:     255.255.255.0
      Default gateway: 192.168.2.1
      DNS servers:     192.168.1.11, 192.168.1.9
