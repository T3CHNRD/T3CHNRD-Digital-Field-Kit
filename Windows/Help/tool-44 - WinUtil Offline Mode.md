WinUtil Offline Mode
====================

WHAT IT DOES
Launch the embedded WinUtil project with its Offline switch.

LOCATION
Deployment > WinUtil Offline Mode

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Uses the included WinUtil Offline switch. Offline mode does not guarantee every WinUtil operation has its downloads or dependencies available.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Setup\Launch-WinUtil.ps1
Configured arguments: -Offline
