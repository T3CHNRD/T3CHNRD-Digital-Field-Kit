Domain / DNS Lookup
===================

WHAT IT DOES
Run the domain/DNS lookup utility.

LOCATION
Network > Domain / DNS Lookup

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Enter a domain in the separate input dialog, such as example.com. Review A, AAAA, MX, NS, TXT and SOA results. DNS access is required.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool is catalogued as read-only.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Invoke-DomainLookup.ps1
Configured arguments: (defaults)
