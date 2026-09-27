BIOS Update
===========

WHAT IT DOES
Vendor-aware BIOS update workflow. AC power and recovery planning recommended.

LOCATION
Optimization > BIOS Update

HOW TO RUN
Open Tools, choose the category above, and click the tool card.
Verify the detected manufacturer/model and select its vendor workflow. Dell requires Dell Command | Update with `dcu-cli.exe` installed; HP requires HP Image Assistant or HPCMSL; Lenovo requires Lenovo System Update. Framework opens its official support page instead of running a silent BIOS installer. If a vendor utility is missing, the workflow stops and reports the vendor's support page without attempting an update. Use AC power, have recovery keys available, and do not interrupt an update.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Updates\Invoke-BiosUpdate.ps1
Configured arguments: (defaults)
