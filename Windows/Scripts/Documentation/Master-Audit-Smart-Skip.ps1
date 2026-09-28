#Requires -Version 5.1
<#
.SYNOPSIS
Generic OneNote smart-skip staging importer.

.DESCRIPTION
Portable Field Kit tool. It is not tied to a company, mapped drive, notebook name,
section name, or file server.

Defaults:
- Uses the first open OneNote notebook when -NotebookName is omitted.
- Uses the first section in that notebook when -TargetSectionName is omitted.
- Uses Documents\T3DFK-OneNote-Staging as the staging folder.
- Writes its audit log to TTK_REPORT_DIR when launched from the Field Kit.

The tool inventories existing OneNote page titles, skips staged files whose base names
already exist, and imports new files. It does not delete source files unless
-RemoveProcessedFiles is specified.

.PARAMETER NotebookName
Optional exact notebook name.

.PARAMETER TargetSectionName
Optional exact section name.

.PARAMETER StagingPath
Folder containing files to import.

.PARAMETER RemoveProcessedFiles
Delete staged files only after successful import or confirmed skip.
#>
[CmdletBinding()]
param(
 [string]$NotebookName,
 [string]$TargetSectionName,
 [string]$StagingPath=(Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'T3DFK-OneNote-Staging'),
 [switch]$RemoveProcessedFiles
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

$ReportRoot=if($env:TTK_REPORT_DIR){$env:TTK_REPORT_DIR}else{Join-Path $env:TEMP 'T3DFK-OneNote'}
New-Item -ItemType Directory -Path $ReportRoot,$StagingPath -Force | Out-Null
$LogFile=Join-Path $ReportRoot ("OneNote-SmartSkip_{0}.txt" -f (Get-Date -Format 'yyyy-MM-dd_HHmmss'))

function Log([string]$Text){
 $Text | Tee-Object -FilePath $LogFile -Append
}

function Get-Context {
 $one=New-Object -ComObject OneNote.Application
 [xml]$xml='';$one.GetHierarchy('',2,[ref]$xml)
 $ns=New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
 $ns.AddNamespace('one',$xml.DocumentElement.NamespaceURI)
 $nb=if($NotebookName){
  $xml.SelectSingleNode("//one:Notebook[@name="+[char]34+$NotebookName+[char]34+"]",$ns)
 }else{
  $xml.SelectSingleNode('//one:Notebook',$ns)
 }
 if(-not $nb){throw 'No matching open OneNote notebook was found.'}

 [xml]$sections='';$one.GetHierarchy($nb.ID,1,[ref]$sections)
 $ns2=New-Object System.Xml.XmlNamespaceManager($sections.NameTable)
 $ns2.AddNamespace('one',$sections.DocumentElement.NamespaceURI)
 $sec=if($TargetSectionName){
  $sections.SelectSingleNode("//one:Section[@name="+[char]34+$TargetSectionName+[char]34+"]",$ns2)
 }else{
  $sections.SelectSingleNode('//one:Section',$ns2)
 }
 if(-not $sec){throw 'No matching OneNote section was found.'}

 [pscustomobject]@{OneNote=$one;Notebook=$nb;Section=$sec}
}

$ctx=Get-Context
Log "Notebook: $($ctx.Notebook.name)"
Log "Section: $($ctx.Section.name)"
Log "Staging: $StagingPath"
Log "RemoveProcessedFiles: $RemoveProcessedFiles"

[xml]$pages='';$ctx.OneNote.GetHierarchy($ctx.Section.ID,4,[ref]$pages)
$ns=New-Object System.Xml.XmlNamespaceManager($pages.NameTable)
$ns.AddNamespace('one',$pages.DocumentElement.NamespaceURI)
$inventory=@{}
foreach($page in @($pages.SelectNodes('//one:Page',$ns))){
 $title=[string]$page.name
 if(-not [string]::IsNullOrWhiteSpace($title)){
  $inventory[$title.Trim().ToLowerInvariant()]=$true
 }
}

$extensions='txt|doc|docx|md|rtf|pdf|xls|xlsx|csv|one|jpg|png|jpeg|vsd|vsdx'
$files=@(Get-ChildItem -LiteralPath $StagingPath -File -Recurse -ErrorAction SilentlyContinue |
 Where-Object {$_.Extension.TrimStart('.') -match ("^(?i)("+$extensions+")$")})

$imported=0;$skipped=0;$failed=0
foreach($file in $files){
 $title=$file.BaseName
 $key=$title.ToLowerInvariant()
 if($inventory.ContainsKey($key)){
  $skipped++
  Log "SKIP existing page: $title"
  if($RemoveProcessedFiles){Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue}
  continue
 }

 try{
  $pageId=''
  $ctx.OneNote.CreateNewPage($ctx.Section.ID,[ref]$pageId)
  [xml]$pageXml='';$ctx.OneNote.GetPageContent($pageId,[ref]$pageXml,0)
  $schema=$pageXml.DocumentElement.NamespaceURI
  $escapedPath=[System.Security.SecurityElement]::Escape($file.FullName)
  $escapedName=[System.Security.SecurityElement]::Escape($file.Name)
  $escapedTitle=[System.Security.SecurityElement]::Escape($title)
  $xmlText="<?xml version='1.0'?><one:Page xmlns:one='$schema' ID='$pageId'><one:Title><one:OE><one:T><![CDATA[$escapedTitle]]></one:T></one:OE></one:Title><one:Outline><one:OEChildren><one:OE><one:InsertedFile pathSource='$escapedPath' preferredName='$escapedName'/></one:OE></one:OEChildren></one:Outline></one:Page>"
  $ctx.OneNote.UpdatePageContent($xmlText)
  $inventory[$key]=$true
  $imported++
  Log "IMPORTED: $($file.FullName)"
  if($RemoveProcessedFiles){Remove-Item -LiteralPath $file.FullName -Force}
 }catch{
  $failed++
  Log "ERROR: $($file.FullName) :: $($_.Exception.Message)"
 }
}

Log "Imported: $imported"
Log "Skipped: $skipped"
Log "Failed: $failed"
Log "Report: $LogFile"
Write-Host "[PASS] OneNote smart-skip import completed." -ForegroundColor Green
Write-Host "Imported=$imported Skipped=$skipped Failed=$failed" -ForegroundColor Cyan
Write-Host "Report: $LogFile" -ForegroundColor Cyan
