Exchange OWA Diagnostic
=======================

WHAT IT DOES
Site-specific Exchange/OWA troubleshooting utility.

LOCATION
System Management > Exchange OWA Diagnostic

HOW TO RUN
This card is disabled: configuration and validation are required before use.
Disabled in the app until adapted and validated for the target Exchange environment. The original expects elevated Exchange Management Shell on ALBL-EXCH2019. Configure server name, webmail host/URLs, monitor IP, request ID, incident time and IIS/Exchange log paths. It diagnoses availability without restarting services or recycling pools.

BEFORE YOU START
The Windows app requests administrator elevation at startup. This tool is catalogued as read-only.

RESULTS AND CONTROLS
Select the tool tab in Run Center to read output and its exit code. Drag the bar above the tabs to resize the panel. Hide panel keeps the tool running. Cancel tool stops its process tree and does not undo completed changes. Up to two tools can run; avoid concurrent tools that change the same settings. Run Center logs are saved under Diagnostic-Reports (ProgramData\T3DFK for an installed copy); individual tools can report additional output locations.

BUNDLED SCRIPT
Windows\Scripts\Server\Troubleshoot-Exchange-OWA.ps1
Configured arguments: (defaults)

ORIGINAL SCRIPT DOCUMENTATION
.SYNOPSIS
    Troubleshoots Exchange OWA/webmail availability flapping.

.DESCRIPTION
    This script checks:
    - IIS app pool state for OWA/ECP/Exchange services
    - Core IIS and Exchange services
    - Exchange Server health
    - Server component state
    - OWA/ECP virtual directory configuration
    - DNS resolution for webmail hostname
    - Local and external OWA HTTP response behavior
    - IIS W3SVC logs for monitor IP, HTTP 440, OWA path, and request ID
    - Exchange HttpProxy\Owa logs for monitor IP, HTTP 440, and request ID
    - Basic notes about possible false-positive monitoring if HTTP 440 is treated as down

.NOTES
    Run from elevated Exchange Management Shell on ALBL-EXCH2019.

    This script is read-only/diagnostic.
    It does not restart services, recycle app pools, or change Exchange/IIS configuration.
