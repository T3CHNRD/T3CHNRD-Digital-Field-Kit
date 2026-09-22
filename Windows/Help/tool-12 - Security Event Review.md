Security Event Review
=====================

WHAT IT DOES
Review recent security-relevant Windows event log entries.

LOCATION
Security > Security Event Review

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
The card runs this tool with its configured defaults. Wait for completion, review the output and exit code, and retain the relevant report before taking further action.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool is catalogued as read-only.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Security\Invoke-SecurityEventReview.ps1
Configured arguments: (defaults)
