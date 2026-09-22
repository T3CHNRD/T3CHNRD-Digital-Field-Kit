OneNote Master Importer
=======================

WHAT IT DOES
Site-specific full OneNote documentation import/rebuild.

LOCATION
System Management > OneNote Master Importer

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Review the site-specific notebook/import configuration and back up the notebook before import or rebuild.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Documentation\Master-OneNote-Importer.ps1
Configured arguments: (defaults)

ORIGINAL SCRIPT DOCUMENTATION
-------------------------------------------------------------------------
ABCO OneNote Documentation Rebuild (Excel TOC version) - SAFE CLEAR + PROGRESS

Key behavior:
- DOES NOT delete/move any notebook folders on disk for clearing.
- Clears ONLY by deleting sections/pages INSIDE the target notebook via OneNote COM.

This version also:
- $ClearOnlyOurSectionName = $true (only clears section named $SectionName)
- VOIP recovery helper (non-destructive report; optional copy restore)
- Moves any leftover *-ARCHIVE-* folders under V:\ABCo Systems Documentation
  to the local Documents folder (requested)

Requires:
- Windows PowerShell 5.1
- OneNote desktop (COM: OneNote.Application)
- Microsoft Excel + Word desktop installed
---------------------------------------------------------------------------
