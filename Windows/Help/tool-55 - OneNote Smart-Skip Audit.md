# OneNote Smart-Skip Audit / Import

## What this tool does

**OneNote Smart-Skip Audit / Import** is a generic staging importer for OneNote that first inventories existing page titles and then imports only files that do not already have matching page titles.

This version is portable and is **not tied to ABCo, a mapped drive, or a fixed notebook/section**.

## When to use it

Use this tool when:

- you have a folder of documentation waiting to be imported into OneNote,
- you do not want to create duplicate pages,
- you want to preserve staged source files by default,
- or you need a repeatable import workflow where already-existing titles are skipped.

## What it changes

The tool can:

- connect to an open OneNote notebook,
- select a notebook and section,
- inventory existing page titles,
- scan a staging folder recursively,
- skip staged files whose base file name already exists as a page title,
- import new files as OneNote attachments,
- optionally remove staged files after successful import or confirmed skip.

## What it does NOT do

It does **not**:

- delete existing OneNote pages,
- delete existing OneNote sections,
- rebuild an entire notebook,
- require a mapped drive or file server,
- delete staged files unless `-RemoveProcessedFiles` is explicitly used,
- modify Windows or Office configuration.

## Safety / risk

**Risk level: Medium to High**

The default mode preserves the staging files. Risk increases if `-RemoveProcessedFiles` is enabled.

## Requirements

- Windows PowerShell 5.1
- OneNote desktop installed
- OneNote desktop COM automation available
- target notebook open in OneNote desktop

## Defaults

Default staging folder:

`Documents\T3DFK-OneNote-Staging`

If no notebook is specified:

- first open notebook is selected.

If no section is specified:

- first section in that notebook is selected.

Default report location:

- Field Kit report directory when run in the app
- otherwise `%TEMP%\T3DFK-OneNote`

## Supported staged file types

The tool scans for:

- TXT
- DOC
- DOCX
- MD
- RTF
- PDF
- XLS
- XLSX
- CSV
- ONE
- JPG
- JPEG
- PNG
- VSD
- VSDX

## Parameters

### -NotebookName

Optional exact notebook name.

```powershell
.\Master-Audit-Smart-Skip.ps1 -NotebookName "IT Notes"
```

### -TargetSectionName

Optional exact section.

```powershell
.\Master-Audit-Smart-Skip.ps1 -NotebookName "IT Notes" -TargetSectionName "Procedures"
```

### -StagingPath

Optional staging folder.

```powershell
.\Master-Audit-Smart-Skip.ps1 -StagingPath "C:\Temp\OneNote-Staging"
```

### -RemoveProcessedFiles

Deletes staged files after a successful import or confirmed duplicate skip.

Use only when you are sure the staging folder is disposable.

```powershell
.\Master-Audit-Smart-Skip.ps1 -RemoveProcessedFiles
```

## Recommended workflow

1. Open the destination notebook in OneNote desktop.
2. Put files to import into the staging folder.
3. Run the tool **without** `-RemoveProcessedFiles`.
4. Review the imported pages.
5. Review the report for skipped and failed items.
6. Only enable `-RemoveProcessedFiles` if you intentionally want the staging folder cleaned after processing.

## Output

The report includes:

- selected notebook,
- selected section,
- staging path,
- number imported,
- number skipped,
- number failed,
- each imported file,
- each skipped duplicate,
- each error.

## How to verify success

- confirm new files appear as pages in the target section,
- confirm existing page titles were not duplicated,
- confirm source files remain in staging unless removal was requested,
- review the report for errors.
