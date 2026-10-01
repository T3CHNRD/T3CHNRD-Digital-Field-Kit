#Requires -Version 5.1
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$temp=Join-Path $env:TEMP ('DivaByte-Core-Test-'+[guid]::NewGuid().ToString('N'))
$data=Join-Path $temp 'Data'
$runbook=Join-Path $temp 'Runbook'
$reports=Join-Path $temp 'Reports'
New-Item -ItemType Directory -Force -Path $data,$runbook,$reports | Out-Null

. (Join-Path $PSScriptRoot 'DivaByteClient.ps1')

try{
    $exe=Get-DivaByteCoreExecutable -ToolkitRoot $root
    if(-not(Test-Path -LiteralPath $exe -PathType Leaf)){throw "DivaByte core binary missing: $exe"}

    if(-not(Start-DivaByteCore -ToolkitRoot $root -DataRoot $data -RunbookRoot $runbook -ReportRoot $reports)){
        throw 'DivaByte core did not start.'
    }

    $status=Get-DivaByteCoreStatus
    if(-not $status -or -not $status.ok -or $status.apiVersion -ne 'v1'){throw 'DivaByte status endpoint failed.'}
    if($status.platform -ne 'windows'){throw "Unexpected core platform: $($status.platform)"}
    Write-Output 'PASS: DivaByte standalone Windows core started and answered the v1 API.'

    $case=Invoke-DivaByteApi -Method POST -Path '/v1/cases' -Body @{title='CI Network Timeout Case'}
    if(-not $case.id){throw 'Case creation did not return an ID.'}

    $sample=Join-Path $reports 'sample-network.log'
    @'
2026-09-28 12:00:00 INFO client connected successfully
2026-09-28 12:04:00 ERROR TNS-12170 connection timed out
2026-09-28 12:04:01 WARN DNS server unreachable during lookup
2026-09-28 12:04:02 ERROR TNS-12535 operation timed out
'@ | Set-Content -LiteralPath $sample -Encoding UTF8

    $evidence=Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$case.id+'/evidence') -Body @{path=$sample}
    if(-not $evidence.evidence.sha256){throw 'Evidence ingestion did not return a SHA-256.'}

    [void](Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$case.id+'/message') -Body @{text='DNS is reachable from the client.'})

    $analysis=Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$case.id+'/analyze') -Body @{}
    if(@($analysis.facts).Count -lt 2){throw 'DivaByte did not extract diagnostic facts.'}
    $network=@($analysis.hypotheses | Where-Object {$_.cause -match 'Network|DNS|connectivity'})
    if(-not $network.Count){throw 'DivaByte did not create the expected network hypothesis.'}
    if(-not @($network[0].supportingEvidence).Count){throw 'Network hypothesis has no supporting evidence.'}
    if(-not @($network[0].contradictingEvidence).Count){throw 'Healthy status evidence was not surfaced as a contradiction.'}
    if(-not @($analysis.facts | Where-Object {$_.source -eq 'Technician Message'}).Count){throw 'Technician observations were omitted from analysis facts.'}
    Write-Output 'PASS: evidence and technician observations produce attributed, contradictable facts and hypotheses.'

    $corrected=Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$case.id+'/correction') -Body @{text='Do not assume the database server failed; verify the client/network path.'}
    if($corrected.case.status -ne 'Needs Re-evaluation'){throw 'Technician correction did not reopen the analysis.'}
    $reanalyzed=Invoke-DivaByteApi -Method POST -Path ('/v1/cases/'+$case.id+'/analyze') -Body @{}
    if(-not @($reanalyzed.facts | Where-Object {$_.source -eq 'Technician Correction'}).Count){throw 'Technician correction was omitted from re-analysis.'}
    Write-Output 'PASS: technician corrections are retained and force re-evaluation.'

    $memory=Invoke-DivaByteApi -Method POST -Path '/v1/memory' -Body @{
        type='Confirmed Root Cause'
        trust='Confirmed Local Knowledge'
        title='TNS timeout caused by client network interruption'
        body='A prior verified case had TNS-12170 after the client network path dropped.'
        source='CI Test'
    }
    if(-not $memory.memory.id){throw 'Memory creation failed.'}
    $memorySearch=Invoke-DivaByteApi -Method GET -Path '/v1/memory/search?q=TNS-12170'
    if(@($memorySearch.results).Count -lt 1){throw 'Memory search did not find the saved incident.'}
    Write-Output 'PASS: persistent local diagnostic memory can be created and searched.'

    @'
# Oracle Client Timeout
If TNS-12170 occurs after a successful connection, correlate the client network path and listener timestamps before assuming database failure.
'@ | Set-Content -LiteralPath (Join-Path $runbook 'Oracle-Timeout.md') -Encoding UTF8
    $runbookSearch=Invoke-DivaByteApi -Method GET -Path '/v1/runbook/search?q=TNS-12170'
    if(@($runbookSearch.results).Count -lt 1){throw 'Runbook search did not find the local article.'}

    $proposalContent=@'
# DivaByte CI Article
Technician-approved local Runbook proposal test.
'@
    $proposal=Invoke-DivaByteApi -Method POST -Path '/v1/runbook/proposals' -Body @{
        relativePath='Network\DivaByte-CI-Article.md'
        title='DivaByte CI Article'
        content=$proposalContent
    }
    if($proposal.runbookModified){throw 'Creating a Runbook proposal modified the Runbook before approval.'}
    [void](Invoke-DivaByteApi -Method POST -Path ('/v1/runbook/proposals/'+$proposal.proposal.id+'/approve') -Body @{})
    if(-not(Test-Path -LiteralPath (Join-Path $runbook 'Network\DivaByte-CI-Article.md'))){throw 'Approved Runbook proposal was not applied.'}
    Write-Output 'PASS: local Runbook search and explicit technician-approval write path.'

    [void](Invoke-DivaByteApi -Method PUT -Path '/v1/research/mode' -Body @{mode='Offline'})
    $mode=Invoke-DivaByteApi -Method GET -Path '/v1/research/mode'
    if($mode.mode -ne 'Offline'){throw 'Research mode did not persist through the core API.'}
    if((Get-Content -LiteralPath (Join-Path $data 'Research-Mode.txt') -Raw).Trim() -ne 'Offline'){throw 'Research mode was not persisted to local storage.'}
    Write-Output 'PASS: research mode is local, persistent, and controlled through the shared core.'

    Stop-DivaByteCore
    Start-Sleep -Milliseconds 300
    if(Test-Path -LiteralPath (Join-Path $data 'core-connection.json')){throw 'Core connection file remained after shutdown.'}
    Write-Output 'PASS: DivaByte core shuts down cleanly.'
}finally{
    try{Stop-DivaByteCore}catch{}
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
