# Microsoft Windows Malicious Software Removal Tool (MRT)

## Purpose

Opens the Microsoft-signed Malicious Software Removal Tool included with supported Windows installations. MRT is an on-demand scanner; it does not replace Microsoft Defender or another antivirus product.

## How to run

1. Select the MRT tool in the Security category.
2. Confirm the Field Kit warning. The launcher verifies the system executable's Microsoft signature.
3. Choose a scan type in the MRT window and review its findings.
4. Approve or decline any removal in MRT itself. The Field Kit does not silently remove detected software.

The tool may be unavailable on some Windows Server or managed images. The launcher reports a missing or invalidly signed system executable instead of downloading or running a substitute.