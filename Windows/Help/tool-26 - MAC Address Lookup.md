MAC Address Lookup
==================

WHAT IT DOES
Lookup or review MAC address information.

LOCATION
Network > MAC Address Lookup

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Enter the MAC address in the input dialog. This tool sends that address to api.macvendors.com for an online vendor lookup; Internet access is required.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool is catalogued as read-only.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Network\Invoke-MacAddressLookup.ps1
Configured arguments: (defaults)
