Open Remote C$ Share
====================

WHAT IT DOES
Open a remote workstation administrative share.

LOCATION
Network > Open Remote C$ Share

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Enter the remote computer name when prompted in Run Center. The administrative share requires network reachability and suitable credentials.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Network\Open-RemoteAdminShare.ps1
Configured arguments: (defaults)
