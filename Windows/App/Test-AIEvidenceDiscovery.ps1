#Requires -Version 5.1
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
$source=Join-Path $PSScriptRoot 'AIWorkspaceUI.ps1'
$tokens=$null;$errors=$null
$ast=[Management.Automation.Language.Parser]::ParseFile($source,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'AI workspace source has PowerShell parse errors.'}
$functions=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -in @('Show-EvidencePreview','Update-EvidenceList')},$true))
foreach($name in @('Show-EvidencePreview','Update-EvidenceList')){
    $function=$functions|Where-Object Name -eq $name|Select-Object -First 1
    if(-not $function){throw "Missing evidence helper: $name"}
    . ([scriptblock]::Create($function.Extent.Text))
}
$script:EvidenceTextExtensions=@('.txt','.log','.json','.csv','.md','.xml','.html','.htm','.ps1','.psd1','.ini','.cfg','.yaml','.yml')
$script:EvidencePreviewLimitBytes=1048576
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('T3DFK-evidence-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture|Out-Null
$browser=[pscustomobject]@{List=(New-Object Windows.Forms.ListBox);Preview=(New-Object Windows.Forms.RichTextBox)}
try{
    $textPath=Join-Path $fixture 'security.log'
    $binaryPath=Join-Path $fixture 'event.evtx'
    $largePath=Join-Path $fixture 'oversized.txt'
    [IO.File]::WriteAllText($textPath,'Security event evidence',[Text.Encoding]::UTF8)
    [IO.File]::WriteAllBytes($binaryPath,[byte[]](0,1,2,3))
    [IO.File]::WriteAllBytes($largePath,(New-Object byte[] 1048577))
    Update-EvidenceList $browser $fixture
    if($browser.List.Items.Count -ne 3){throw 'The evidence browser did not list every artifact.'}
    $textEntry=$browser.List.Items|Where-Object Path -eq $textPath|Select-Object -First 1
    Show-EvidencePreview $browser.Preview $textEntry
    if($browser.Preview.Text -notmatch 'Security event evidence'){throw 'Text evidence preview failed.'}
    $binaryEntry=$browser.List.Items|Where-Object Path -eq $binaryPath|Select-Object -First 1
    Show-EvidencePreview $browser.Preview $binaryEntry
    if($browser.Preview.Text -notmatch 'Preview unavailable'){throw 'Binary evidence was read as text.'}
    $largeEntry=$browser.List.Items|Where-Object Path -eq $largePath|Select-Object -First 1
    Show-EvidencePreview $browser.Preview $largeEntry
    if($browser.Preview.Text -notmatch 'Preview limited'){throw 'Oversized text file was read into the preview.'}
    Write-Output 'PASS: all evidence files listed; supported text previewed; binary and oversized artifacts were not read.'
}finally{
    $browser.List.Dispose();$browser.Preview.Dispose()
    $resolved=[IO.Path]::GetFullPath($fixture)
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
    if(-not $resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Unexpected fixture cleanup path.'}
    Remove-Item -LiteralPath $resolved -Recurse -Force
}