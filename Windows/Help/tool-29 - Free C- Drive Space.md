Free C: Drive Space
===================

WHAT IT DOES
Guided space-recovery utility.

LOCATION
Repair > Free C: Drive Space

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Starts DISM component cleanup and Windows Disk Cleanup. This changes the machine; close work and review the output before deciding further cleanup is needed.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Invoke-FreeCDriveSpace.ps1
Configured arguments: (defaults)
