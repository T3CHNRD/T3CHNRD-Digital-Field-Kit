24-Hour Sleep Hold
==================

WHAT IT DOES
Site-specific power/scheduled-task hold utility.

LOCATION
System Management > 24-Hour Sleep Hold

HOW TO RUN
This card is disabled: configuration and validation are required before use.
Disabled in the app until adapted and validated for the target site. The original script requires a report share on alblnetapp02 and stores state under C:\ProgramData\ALBL\SleepHold. It changes sleep settings and scheduled tasks and provides a Rollback switch. Have the maintainer configure reporting/state paths and validate restoration before enabling its catalog entry.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool can change system settings or data; review its purpose and target before running.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Maintenance\Disable-Sleep24.ps1
Configured arguments: (defaults)

ORIGINAL SCRIPT DOCUMENTATION
.SYNOPSIS
Temporarily prevents Windows 11 machines from sleeping for 24 hours,
temporarily disables scheduled shutdown/restart/logoff tasks,
then restores previous settings automatically.

.DESCRIPTION
Designed for Lansweeper deployment.

This script:
- Runs silently with no prompts or popups.
- Disables system sleep timeout on AC and DC power.
- Disables hibernate timeout on AC and DC power where supported.
- Disables hard disk timeout on AC and DC power.
- Does NOT change display/screen timeout.
- Attempts to abort a pending shutdown timer, if one exists.
- Temporarily disables enabled scheduled tasks that appear to shut down, restart, or log off the machine.
- Saves previous power settings locally for rollback.
- Saves only the scheduled shutdown tasks that this script disabled locally for rollback.
- Creates or replaces a scheduled rollback task.
- Restores original power settings and re-enables only the scheduled tasks it disabled.
- Checks Cisco AnyConnect / Cisco Secure Client VPN status.
- Writes ALL result logs to ONE required CSV only.

.REQUIRED CSV
\\alblnetapp02\public\IT Tracking - Requests_Projects\bootcheck_results\updated_machines\SleepHold_Results.csv

.NOTES
Run as Administrator.
Designed for Lansweeper deployment.
