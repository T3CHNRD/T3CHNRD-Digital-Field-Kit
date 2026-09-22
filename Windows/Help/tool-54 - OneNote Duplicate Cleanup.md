OneNote Duplicate Cleanup
=========================

WHAT IT DOES
Site-specific OneNote staging/import cleanup.

LOCATION
System Management > OneNote Duplicate Cleanup

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Review the source configuration for the intended OneNote staging/import locations. Back up the notebook and staging data before cleanup.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Documentation\Invoke-MassDuplicateCleanup.ps1
Configured arguments: (defaults)

ORIGINAL SCRIPT DOCUMENTATION
.SYNOPSIS
    ABCo Master Tool - Hardened Version
    Location: V:\ABCo Systems Documentation\IT Master Documentation
    Target Section: ABCO Documentation
