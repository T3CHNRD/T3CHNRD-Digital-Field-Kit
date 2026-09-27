[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateScript({
        $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
        [IO.Path]::GetFullPath($_).StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)
    })]
    [string[]]$CleanupTarget,
    [switch]$SkipRecycleBin
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Write-Output 'MACE-inspired cleanup: safe cache cleanup pass with detailed completed/skipped/failed summary.'
$completed=New-Object System.Collections.Generic.List[string]
$skipped=New-Object System.Collections.Generic.List[string]
$failed=New-Object System.Collections.Generic.List[string]
$targets=if($CleanupTarget){@($CleanupTarget)}else{@($env:TEMP,"$env:LOCALAPPDATA\Temp",'C:\Windows\Temp')}
$targets=@($targets|Where-Object{$_ -and (Test-Path -LiteralPath $_ -PathType Container)}|Select-Object -Unique)

foreach($target in $targets){
    Write-Output "Cleaning target: $target"
    try{
        $items=Get-ChildItem -LiteralPath $target -Force -ErrorAction Stop
        foreach($item in $items){
            $itemPath=$item.FullName
            try{
                if($PSCmdlet.ShouldProcess($itemPath,'Remove temporary item')){
                    Remove-Item -LiteralPath $itemPath -Recurse -Force -ErrorAction Stop
                    $completed.Add($itemPath)
                }else{
                    $skipped.Add("Not removed: $itemPath")
                }
            }catch{
                $skipped.Add("$itemPath :: $($_.Exception.Message)")
            }
        }
    }catch{
        $failed.Add("$target :: $($_.Exception.Message)")
    }
}

if(-not $SkipRecycleBin){
    try{
        if($PSCmdlet.ShouldProcess('Recycle Bin','Clear')){
            Clear-RecycleBin -Force -ErrorAction Stop
            $completed.Add('Recycle Bin')
        }else{
            $skipped.Add('Recycle Bin: WhatIf or confirmation declined')
        }
    }catch{
        $skipped.Add('Recycle Bin: '+$_.Exception.Message)
    }
}

Write-Output "Cleanup summary: Completed=$($completed.Count); Skipped=$($skipped.Count); Failed=$($failed.Count)"
if($skipped.Count){Write-Output 'Skipped examples:';$skipped|Select-Object -First 20|ForEach-Object{Write-Output "  $_"}}
if($failed.Count){Write-Output 'Failed:';$failed|ForEach-Object{Write-Output "  $_"};exit 1}
exit 0