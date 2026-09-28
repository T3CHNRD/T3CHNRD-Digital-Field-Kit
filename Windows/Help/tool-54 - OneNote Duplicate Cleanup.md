# OneNote Duplicate Cleanup

## What this tool does

**OneNote Duplicate Cleanup** is a generic OneNote maintenance tool for cleaning duplicate or untitled pages from a selected OneNote section. It can also optionally import files from a staging folder into that section.

This version is portable and is **not tied to ABCo, a mapped drive, a fixed notebook, or a fixed section name**.

## When to use it

Use this tool when:

- a OneNote section has multiple pages with the same title,
- a OneNote section has many untitled pages,
- you want to clean up a section before importing new documentation,
- or you want to import staged files into OneNote while avoiding duplicate page titles.

## What it changes

By default, the tool can:

- inspect all pages in the selected section,
- identify duplicate page titles,
- identify blank or "Untitled Page" entries,
- delete duplicate or untitled pages,
- import files from the staging folder as OneNote attachments,
- create a page title from the source file name,
- skip staged files whose page title already exists.

## What it does NOT do

It does **not**:

- delete or move an entire notebook,
- delete other sections,
- require a company file share,
- require a mapped drive,
- require a specific notebook name,
- require a specific section name,
- change Windows, Office, or OneNote settings,
- delete staged source files automatically.

## Safety / risk

**Risk level: High**

This tool can delete pages from OneNote. If you only want to inspect what would be removed, use **Audit Only** mode first.

## Requirements

- Windows PowerShell 5.1
- OneNote desktop installed
- OneNote desktop COM automation available
- target notebook open in OneNote desktop

## Defaults

If you do not specify a notebook:

- the first open OneNote notebook is selected.

If you do not specify a section:

- the first section in the selected notebook is used.

Default staging folder:

`Documents\T3DFK-OneNote-Staging`

Default report location:

- Field Kit report folder when run from the app
- otherwise `%TEMP%\T3DFK-OneNote`

## Parameters

### -NotebookName

Optional exact notebook name.

Example:

```powershell
.\Invoke-MassDuplicateCleanup.ps1 -NotebookName "IT Notes"
```

### -TargetSectionName

Optional exact section name.

Example:

```powershell
.\Invoke-MassDuplicateCleanup.ps1 -NotebookName "IT Notes" -TargetSectionName "Network"
```

### -StagingPath

Optional folder containing files to import.

Example:

```powershell
.\Invoke-MassDuplicateCleanup.ps1 -StagingPath "C:\Temp\OneNote-Staging"
```

### -AuditOnly

Reports duplicate and untitled pages without deleting or importing anything.

Recommended first run:

```powershell
.\Invoke-MassDuplicateCleanup.ps1 -AuditOnly
```

## HOW TO RUN

From the app, open **Misc -> OneNote Duplicate Cleanup** and click the tool card. For the safest first pass, use the standalone parameter `-AuditOnly` when running the script directly so no pages are removed or imported.

## Recommended workflow

1. Open the target notebook in OneNote desktop.
2. Run the tool with `-AuditOnly`.
3. Review the report.
4. Confirm that the duplicate and untitled pages are safe to remove.
5. Run again without `-AuditOnly` if cleanup is desired.
6. Review the OneNote section and the generated report.

## Output

The tool writes a report named similar to:

`OneNote-DuplicateCleanup_YYYY-MM-DD_HHMMSS.txt`

The report includes:

- notebook name,
- section name,
- staging path,
- audit mode state,
- duplicate candidates,
- untitled candidates,
- pages removed,
- files imported,
- skipped files,
- errors.

## How to verify success

After the tool finishes:

- reopen or refresh the target section,
- confirm duplicate/untitled pages are gone,
- confirm expected staging files were imported,
- confirm unrelated pages and sections were untouched,
- review the generated report for warnings or errors.
