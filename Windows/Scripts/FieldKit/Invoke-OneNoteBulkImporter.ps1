#Requires -Version 5.1
<#
.SYNOPSIS
Generic OneNote bulk importer for local or network folders.

.DESCRIPTION
Portable Field Kit tool. It is not tied to a company, mapped drive, workbook,
notebook, section, archive location, or file server.

Defaults:
- Source folder: Documents\T3DFK-OneNote-Import
- Target notebook: first open OneNote notebook if -NotebookName is omitted
- Target section: Imported Documentation
- Reports: TTK_REPORT_DIR when launched from the Field Kit, otherwise TEMP

The importer creates the target section when needed and imports supported files.
Text/Markdown/CSV files are inserted as text. Other supported file types are attached
as files so the source remains intact.

It does not delete source files, move archive folders, rebuild notebooks, or perform
company-specific recovery actions.

.PARAMETER SourcePath
Folder to import recursively.

.PARAMETER NotebookName
Optional exact open OneNote notebook name.

.PARAMETER SectionName
Target section name. Created when missing.

.PARAMETER MaxFiles
Optional limit for testing. 0 means no limit.
#>
[CmdletBinding()]
param(
 [string]$SourcePath=(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'T3DFK-OneNote-Import'),
 [string]$NotebookName,
 [string]$SectionName='Imported Documentation',
 [ValidateRange(0,100000)][int]$MaxFiles=0
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$ReportRoot=if($env:TTK_REPORT_DIR){$env:TTK_REPORT_DIR}else{Join-Path $env:TEMP 'T3DFK-OneNote'}
New-Item -ItemType Directory -Path $ReportRoot,$SourcePath -Force | Out-Null
$LogFile=Join-Path $ReportRoot ("OneNote-MasterImporter_{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss'))

function Log([string]$Text){
 $Text | Tee-Object -FilePath $LogFile -Append
}

function Get-OneNoteApplication {
 try{return New-Object -ComObject OneNote.Application}
 catch{throw 'OneNote desktop COM automation is unavailable. Install/open OneNote desktop and try again.'}
}

function Get-Notebook {
 param([object]$OneNote)
 [xml]$xml='';$OneNote.GetHierarchy('',2,[ref]$xml)
 $ns=New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
 $ns.AddNamespace('one',$xml.DocumentElement.NamespaceURI)
 $nb=if($NotebookName){
  $xml.SelectSingleNode("//one:Notebook[@name="+[char]34+$NotebookName+[char]34+"]",$ns)
 }else{
  $xml.SelectSingleNode('//one:Notebook',$ns)
 }
 if(-not $nb){throw 'No matching open OneNote notebook was found. Open the notebook in OneNote desktop and try again.'}
 return $nb
}

function Get-OrCreateSection {
 param([object]$OneNote,[string]$NotebookId)
 [xml]$xml='';$OneNote.GetHierarchy($NotebookId,1,[ref]$xml)
 $ns=New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
 $ns.AddNamespace('one',$xml.DocumentElement.NamespaceURI)
 $sec=$xml.SelectSingleNode("//one:Section[@name="+[char]34+$SectionName+[char]34+"]",$ns)
 if($sec){return [string]$sec.ID}
 $newId=''
 $OneNote.CreateNewSection($NotebookId,$SectionName,[ref]$newId)
 if([string]::IsNullOrWhiteSpace($newId)){throw "Could not create section '$SectionName'."}
 return $newId
}

function Add-TextPage {
 param([object]$OneNote,[string]$SectionId,[IO.FileInfo]$File)
 $pageId='';$OneNote.CreateNewPage($SectionId,[ref]$pageId)
 [xml]$page='';$OneNote.GetPageContent($pageId,[ref]$page,0)
 $ns=$page.DocumentElement.NamespaceURI
 $title=[System.Security.SecurityElement]::Escape($File.BaseName)
 $body=[System.Security.SecurityElement]::Escape((Get-Content -LiteralPath $File.FullName -Raw -ErrorAction Stop))
 $xml="<?xml version='1.0'?><one:Page xmlns:one='$ns' ID='$pageId'><one:Title><one:OE><one:T><![CDATA[$title]]></one:T></one:OE></one:Title><one:Outline><one:OEChildren><one:OE><one:T><![CDATA[$body]]></one:T></one:OE></one:OEChildren></one:Outline></one:Page>"
 $OneNote.UpdatePageContent($xml)
}

function Add-AttachmentPage {
 param([object]$OneNote,[string]$SectionId,[IO.FileInfo]$File)
 $pageId='';$OneNote.CreateNewPage($SectionId,[ref]$pageId)
 [xml]$page='';$OneNote.GetPageContent($pageId,[ref]$page,0)
 $ns=$page.DocumentElement.NamespaceURI
 $title=[System.Security.SecurityElement]::Escape($File.BaseName)
 $path=[System.Security.SecurityElement]::Escape($File.FullName)
 $name=[System.Security.SecurityElement]::Escape($File.Name)
 $xml="<?xml version='1.0'?><one:Page xmlns:one='$ns' ID='$pageId'><one:Title><one:OE><one:T><![CDATA[$title]]></one:T></one:OE></one:Title><one:Outline><one:OEChildren><one:OE><one:InsertedFile pathSource='$path' preferredName='$name'/></one:OE></one:OEChildren></one:Outline></one:Page>"
 $OneNote.UpdatePageContent($xml)
}

$one=Get-OneNoteApplication
$nb=Get-Notebook $one
$sectionId=Get-OrCreateSection $one $nb.ID

Log "Notebook: $($nb.name)"
Log "Section: $SectionName"
Log "Source: $SourcePath"

$supported=@('.txt','.md','.csv','.rtf','.doc','.docx','.pdf','.xls','.xlsx','.jpg','.jpeg','.png','.one','.vsd','.vsdx')
$files=@(Get-ChildItem -LiteralPath $SourcePath -File -Recurse -ErrorAction SilentlyContinue |
 Where-Object {$supported -contains $_.Extension.ToLowerInvariant()})
if($MaxFiles -gt 0){$files=@($files | Select-Object -First $MaxFiles)}

$imported=0;$failed=0
foreach($file in $files){
 try{
  if($file.Extension.ToLowerInvariant() -in @('.txt','.md','.csv')){
   Add-TextPage $one $sectionId $file
  }else{
   Add-AttachmentPage $one $sectionId $file
  }
  $imported++
  Log "IMPORTED: $($file.FullName)"
 }catch{
  $failed++
  Log "ERROR: $($file.FullName) :: $($_.Exception.Message)"
 }
}

Log "Imported: $imported"
Log "Failed: $failed"
Log "Report: $LogFile"
Write-Host '[PASS] OneNote bulk import completed.' -ForegroundColor Green
Write-Host "Imported=$imported Failed=$failed" -ForegroundColor Cyan
Write-Host "Report: $LogFile" -ForegroundColor Cyan
