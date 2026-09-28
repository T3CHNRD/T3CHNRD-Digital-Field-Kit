# OneNote Master Importer

## What this tool does

**OneNote Master Importer** is a generic bulk-import tool that imports documentation from a local or network folder into a selected OneNote notebook and section.

This version is portable and is **not tied to ABCo, specific drive letters, a fixed workbook, a fixed notebook, or a fixed file server**.

## When to use it

Use this tool when:

- migrating a folder of documentation into OneNote,
- building a new OneNote documentation section,
- bulk-loading files from a local disk, USB drive, or network share,
- or importing mixed document formats into one section.

## What it changes

The tool:

- opens a OneNote COM session,
- selects a target notebook,
- finds or creates the target section,
- scans the source folder recursively,
- imports TXT/MD/CSV content as text pages,
- imports other supported file types as OneNote file attachments,
- keeps original source files intact,
- writes an import report.

## What it does NOT do

It does **not**:

- delete the source files,
- delete existing sections,
- clear an existing notebook,
- move archive folders,
- rebuild an entire OneNote notebook,
- require Excel or Word COM just to attach documents,
- require any company-specific path,
- require a mapped drive,
- perform company-specific recovery logic.

## Safety / risk

**Risk level: Medium**

The tool creates pages and can create the requested target section, but it does not intentionally delete existing content.

## Requirements

- Windows PowerShell 5.1
- OneNote desktop installed
- OneNote desktop COM automation available
- target notebook open in OneNote desktop

## Defaults

Default source folder:

`Documents\T3DFK-OneNote-Import`

Default target section:

`Imported Documentation`

If no notebook is specified:

- first open OneNote notebook is selected.

Default report location:

- Field Kit report directory when run from the app
- otherwise `%TEMP%\T3DFK-OneNote`

## Supported file types

- TXT
- MD
- CSV
- RTF
- DOC
- DOCX
- PDF
- XLS
- XLSX
- JPG
- JPEG
- PNG
- ONE
- VSD
- VSDX

## Import behavior by file type

### TXT / MD / CSV

The file text is inserted directly into a OneNote page.

### Other supported files

The file is attached to a OneNote page.

This keeps the tool generic and avoids requiring Word/Excel conversion logic.

## Parameters

### -SourcePath

Folder to import recursively.

```powershell
.\Master-OneNote-Importer.ps1 -SourcePath "D:\Documentation"
```

The source can also be a network path:

```powershell
.\Master-OneNote-Importer.ps1 -SourcePath "\\server\share\IT Docs"
```

### -NotebookName

Optional exact notebook name.

```powershell
.\Master-OneNote-Importer.ps1 -NotebookName "IT Documentation"
```

### -SectionName

Target section name. The section is created if it does not already exist.

```powershell
.\Master-OneNote-Importer.ps1 -NotebookName "IT Documentation" -SectionName "Imported Procedures"
```

### -MaxFiles

Optional file limit for testing.

```powershell
.\Master-OneNote-Importer.ps1 -SourcePath "C:\Temp\Docs" -MaxFiles 10
```

A value of `0` means no limit.

## Recommended workflow

1. Open the target notebook in OneNote desktop.
2. Choose a small test source folder.
3. Run with `-MaxFiles 5` or `-MaxFiles 10`.
4. Verify page names and file attachments.
5. Review the report.
6. Run the full import after the test passes.

## Output

The report includes:

- selected notebook,
- target section,
- source folder,
- imported files,
- failed files,
- final imported/failed counts,
- report path.

## How to verify success

- confirm the requested section exists,
- confirm imported pages appear,
- confirm TXT/MD/CSV content is readable,
- confirm attached documents open correctly,
- confirm the original source files still exist,
- review the report for failures.
