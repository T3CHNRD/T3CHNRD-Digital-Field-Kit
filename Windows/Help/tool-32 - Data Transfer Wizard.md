Data Transfer Wizard
====================

WHAT IT DOES
Portable robocopy-based copy, move, or mirror utility.

LOCATION
Repair > Data Transfer Wizard

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Choose source, destination and operation in the wizard. Verify both paths. Move removes source data; mirror can remove destination files absent from the source.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Optional\Invoke-DataTransferWizard.ps1
Configured arguments: (defaults)
