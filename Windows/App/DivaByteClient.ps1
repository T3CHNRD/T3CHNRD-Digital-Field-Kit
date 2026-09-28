#Requires -Version 5.1
# Thin Windows client for the standalone cross-platform DivaByte core.

$script:DivaByteCoreProcess=$null
$script:DivaByteConnection=$null

function Get-DivaByteCoreExecutable {
    param([Parameter(Mandatory=$true)][string]$ToolkitRoot)
    return (Join-Path $ToolkitRoot 'DivaByte\Runtime\windows-x64\divabyte-core.exe')
}

function Get-DivaByteConnectionFile {
    param([Parameter(Mandatory=$true)][string]$DataRoot)
    return (Join-Path $DataRoot 'core-connection.json')
}

function Test-DivaByteCoreConnection {
    param([Parameter(Mandatory=$true)]$Connection)
    try{
        $uri='http://127.0.0.1:{0}/v1/health' -f [int]$Connection.port
        $result=Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 2 -ErrorAction Stop
        return [bool]($result.ok -and $result.name -eq 'DivaByte')
    }catch{return $false}
}

function Start-DivaByteCore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ToolkitRoot,
        [Parameter(Mandatory=$true)][string]$DataRoot,
        [Parameter(Mandatory=$true)][string]$RunbookRoot,
        [Parameter(Mandatory=$true)][string]$ReportRoot
    )

    $exe=Get-DivaByteCoreExecutable -ToolkitRoot $ToolkitRoot
    if(-not(Test-Path -LiteralPath $exe -PathType Leaf)){
        $script:DivaByteConnection=$null
        return $false
    }

    New-Item -ItemType Directory -Force -Path $DataRoot,$RunbookRoot,$ReportRoot | Out-Null
    $connectionFile=Get-DivaByteConnectionFile -DataRoot $DataRoot

    if(Test-Path -LiteralPath $connectionFile){
        try{
            $existing=Get-Content -LiteralPath $connectionFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if(Test-DivaByteCoreConnection -Connection $existing){
                $script:DivaByteConnection=$existing
                return $true
            }
        }catch{}
        Remove-Item -LiteralPath $connectionFile -Force -ErrorAction SilentlyContinue
    }

    function Quote-DivaByteArgument([string]$Value){
        return '"'+$Value.Replace('"','\"')+'"'
    }

    $argumentString=@(
        '--data-root', (Quote-DivaByteArgument $DataRoot),
        '--runbook-root', (Quote-DivaByteArgument $RunbookRoot),
        '--report-root', (Quote-DivaByteArgument $ReportRoot),
        '--connection-file', (Quote-DivaByteArgument $connectionFile),
        '--port', '0'
    ) -join ' '

    try{
        $script:DivaByteCoreProcess=Start-Process -FilePath $exe -ArgumentList $argumentString -WindowStyle Hidden -PassThru -ErrorAction Stop
    }catch{
        $script:DivaByteCoreProcess=$null
        $script:DivaByteConnection=$null
        return $false
    }

    for($i=0;$i -lt 80;$i++){
        Start-Sleep -Milliseconds 100
        if(Test-Path -LiteralPath $connectionFile){
            try{
                $connection=Get-Content -LiteralPath $connectionFile -Raw -Encoding UTF8 | ConvertFrom-Json
                if(Test-DivaByteCoreConnection -Connection $connection){
                    $script:DivaByteConnection=$connection
                    return $true
                }
            }catch{}
        }
        if($script:DivaByteCoreProcess -and $script:DivaByteCoreProcess.HasExited){break}
    }

    if($script:DivaByteCoreProcess -and -not $script:DivaByteCoreProcess.HasExited){
        try{$script:DivaByteCoreProcess.Kill()}catch{}
    }
    $script:DivaByteCoreProcess=$null
    $script:DivaByteConnection=$null
    return $false
}

function Invoke-DivaByteApi {
    [CmdletBinding()]
    param(
        [ValidateSet('GET','POST','PUT')][string]$Method='GET',
        [Parameter(Mandatory=$true)][string]$Path,
        $Body
    )

    if(-not $script:DivaByteConnection){
        throw 'DivaByte core is not connected.'
    }
    if(-not $Path.StartsWith('/')){$Path='/'+$Path}
    $uri='http://127.0.0.1:{0}{1}' -f [int]$script:DivaByteConnection.port,$Path
    $headers=@{Authorization=('Bearer '+[string]$script:DivaByteConnection.token)}

    if($PSBoundParameters.ContainsKey('Body') -and $null -ne $Body){
        $json=$Body | ConvertTo-Json -Depth 20 -Compress
        return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -ContentType 'application/json' -Body $json -TimeoutSec 60 -ErrorAction Stop
    }
    return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -TimeoutSec 60 -ErrorAction Stop
}

function Get-DivaByteCoreStatus {
    if(-not $script:DivaByteConnection){return $null}
    try{return Invoke-DivaByteApi -Method GET -Path '/v1/status'}catch{return $null}
}

function Stop-DivaByteCore {
    if($script:DivaByteConnection){
        try{Invoke-DivaByteApi -Method POST -Path '/v1/shutdown' -Body @{} | Out-Null}catch{}
    }
    if($script:DivaByteCoreProcess){
        try{
            if(-not $script:DivaByteCoreProcess.WaitForExit(2500)){
                $script:DivaByteCoreProcess.Kill()
            }
        }catch{}
    }
    $script:DivaByteCoreProcess=$null
    $script:DivaByteConnection=$null
}
