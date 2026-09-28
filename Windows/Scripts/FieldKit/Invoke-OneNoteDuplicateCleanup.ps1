#Requires -Version 5.1
<#
.SYNOPSIS
Generic OneNote duplicate/untitled page cleanup and staging importer.

.DESCRIPTION
Portable Field Kit tool. It is not tied to a company, mapped drive, notebook name,
section name, or file server.

Defaults:
- Uses the first open OneNote notebook when -NotebookName is omitted.
- Uses the first section in that notebook when -TargetSectionName is omitted.
- Uses Documents\T3DFK-OneNote-Staging as the optional staging/import folder.
- Writes logs to TTK_REPORT_DIR when launched from the Field Kit, otherwise to TEMP.

The cleanup removes duplicate page titles and untitled pages from the selected section.
Files in the staging folder are imported as file attachments when their base name is not
already present in the section.

.PARAMETER NotebookName
Optional exact OneNote notebook name.

.PARAMETER TargetSectionName
Optional exact OneNote section name.

.PARAMETER StagingPath
Optional staging/import folder.

.PARAMETER AuditOnly
Report duplicates and untitled pages without deleting or importing anything.
#>
[CmdletBinding()]
param(
 [string]$NotebookName,
 [string]$TargetSectionName,
 [string]$StagingPath=(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'T3DFK-OneNote-Staging'),
 [switch]$AuditOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$ReportRoot=if($env:TTK_REPORT_DIR){$env:TTK_REPORT_DIR}else{Join-Path $env:TEMP 'T3DFK-OneNote'}
New-Item -ItemType Directory -Path $ReportRoot,$StagingPath -Force | Out-Null
$LogPath=Join-Path $ReportRoot ("OneNote-DuplicateCleanup_{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss'))

function Log([string]$Message){
 $Message | Tee-Object -FilePath $LogPath -Append
}
function Get-OneNoteContext {
 $one=New-Object -ComObject OneNote.Application
 [xml]$xml='';$one.GetHierarchy('',2,[ref]$xml)
 $ns=New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
 $ns.AddNamespace('one',$xml.DocumentElement.NamespaceURI)

 $nb=if($NotebookName){
  $xml.SelectSingleNode("//one:Notebook[@name="+[char]34+$NotebookName+[char]34+"]",$ns)
 }else{
  $xml.SelectSingleNode('//one:Notebook',$ns)
 }
 if(-not $nb){throw 'No matching open OneNote notebook was found. Open the notebook in OneNote desktop and try again.'}

 [xml]$sections='';$one.GetHierarchy($nb.ID,1,[ref]$sections)
 $ns2=New-Object System.Xml.XmlNamespaceManager($sections.NameTable)
 $ns2.AddNamespace('one',$sections.DocumentElement.NamespaceURI)
 $sec=if($TargetSectionName){
  $sections.SelectSingleNode("//one:Section[@name="+[char]34+$TargetSectionName+[char]34+"]",$ns2)
 }else{
  $sections.SelectSingleNode('//one:Section',$ns2)
 }
 if(-not $sec){throw 'No matching OneNote section was found.'}

 [pscustomobject]@{OneNote=$one;Notebook=$nb;Section=$sec;Namespace=$ns2}
}

$ctx=Get-OneNoteContext
Log "Notebook: $($ctx.Notebook.name)"
Log "Section: $($ctx.Section.name)"
Log "Staging: $StagingPath"
Log "AuditOnly: $AuditOnly"

[xml]$pages='';$ctx.OneNote.GetHierarchy($ctx.Section.ID,4,[ref]$pages)
$ns=New-Object System.Xml.XmlNamespaceManager($pages.NameTable)
$ns.AddNamespace('one',$pages.DocumentElement.NamespaceURI)
$all=@($pages.SelectNodes('//one:Page',$ns))

$seen=@{}
$duplicates=0
$untitled=0
foreach($page in $all){
 $title=[string]$page.name
 $key=$title.Trim().ToLowerInvariant()
 $isUntitled=[string]::IsNullOrWhiteSpace($title) -or $title -match '^(?i)untitled page$'
 $isDuplicate=(-not $isUntitled) -and $seen.ContainsKey($key)
 if($isUntitled){$untitled++}
 elseif($isDuplicate){$duplicates++}
 else{$seen[$key]=$true}

 if($isUntitled -or $isDuplicate){
  Log ("Candidate: "+$title+" | "+$(if($isUntitled){'Untitled'}else{'Duplicate'}))
  if(-not $AuditOnly){
   try{$ctx.OneNote.DeleteHierarchy($page.ID);Log '  Removed.'}
   catch{Log ("  WARN: "+$_.Exception.Message)}
  }
 }
}

if(-not $AuditOnly){
 $files=@(Get-ChildItem -LiteralPath $StagingPath -File -Recurse -ErrorAction SilentlyContinue)
 foreach($file in $files){
  $title=$file.BaseName
  if($seen.ContainsKey($title.ToLowerInvariant())){
   Log "SKIP existing page: $title"
   continue
  }
  try{
   $pageId=''
   $ctx.OneNote.CreateNewPage($ctx.Section.ID,[ref]$pageId)
   $schema=$pages.DocumentElement.NamespaceURI
   $escapedPath=[System.Security.SecurityElement]::Escape($file.FullName)
   $escapedName=[System.Security.SecurityElement]::Escape($file.Name)
   $escapedTitle=[System.Security.SecurityElement]::Escape($title)
   $pageXml="<?xml version='1.0'?><one:Page xmlns:one='$schema' ID='$pageId'><one:Title><one:OE><one:T><![CDATA[$escapedTitle]]></one:T></one:OE></one:Title><one:Outline><one:OEChildren><one:OE><one:InsertedFile pathSource='$escapedPath' preferredName='$escapedName'/></one:OE></one:OEChildren></one:Outline></one:Page>"
   $ctx.OneNote.UpdatePageContent($pageXml)
   $seen[$title.ToLowerInvariant()]=$true
   Log "IMPORTED: $($file.FullName)"
  }catch{Log "ERROR importing $($file.FullName): $($_.Exception.Message)"}
 }
}

Log "Duplicate candidates: $duplicates"
Log "Untitled candidates: $untitled"
Log "Report: $LogPath"
Write-Host "[PASS] OneNote duplicate cleanup/audit completed." -ForegroundColor Green
Write-Host "Report: $LogPath" -ForegroundColor Cyan
