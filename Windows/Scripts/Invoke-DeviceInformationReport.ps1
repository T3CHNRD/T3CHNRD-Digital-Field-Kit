#Requires -Version 5.1
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$toolkitRoot = Split-Path -Parent $PSScriptRoot
$preferredLogDir = if ($env:TTK_REPORT_DIR) { $env:TTK_REPORT_DIR } else { Join-Path $toolkitRoot 'Logs' }
try { New-Item -Path $preferredLogDir -ItemType Directory -Force -ErrorAction Stop | Out-Null; $logDir=$preferredLogDir }
catch { $logDir=Join-Path $env:TEMP 'Windows-Master-Diagnostic-Toolkit-Reports'; New-Item $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null }
$report=Join-Path $logDir ("DeviceInformation-{0:yyyyMMdd-HHmmss}.txt" -f (Get-Date))
Write-Output 'Collecting Windows hardware/software report.'
$lines=New-Object System.Collections.Generic.List[string]
$lines.Add("Device Information Report - $(Get-Date)");$lines.Add("Computer: $env:COMPUTERNAME")
try { $cs=Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; $lines.Add("Manufacturer/Model: $($cs.Manufacturer) $($cs.Model)"); $lines.Add("RAM GB: $([math]::Round($cs.TotalPhysicalMemory/1GB,2))") } catch { $lines.Add("Computer system query failed: $($_.Exception.Message)") }
try { $bios=Get-CimInstance Win32_BIOS -ErrorAction Stop; $lines.Add("BIOS: $($bios.SMBIOSBIOSVersion) $($bios.ReleaseDate)") } catch { $lines.Add("BIOS query failed: $($_.Exception.Message)") }
try { $os=Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; $lines.Add("OS: $($os.Caption) build $($os.BuildNumber)") } catch { $lines.Add("OS query failed: $($_.Exception.Message)") }
try { $cpu=Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1; $lines.Add("CPU: $($cpu.Name)") } catch { $lines.Add("CPU query failed: $($_.Exception.Message)") }
$lines.Add('');$lines.Add('Disks:');try { $lines.Add((Get-Disk -ErrorAction Stop | Select-Object Number,FriendlyName,BusType,OperationalStatus,@{n='SizeGB';e={[math]::Round($_.Size/1GB,2)}} | Format-Table -AutoSize | Out-String)) } catch { $lines.Add("Disk query failed: $($_.Exception.Message)") }
$lines.Add('');$lines.Add('Network adapters:');try { $lines.Add((Get-NetAdapter -ErrorAction Stop | Select-Object Name,Status,MacAddress,LinkSpeed | Format-Table -AutoSize | Out-String)) } catch { $lines.Add("Network adapter query failed: $($_.Exception.Message)") }
$lines | Set-Content -LiteralPath $report -Encoding UTF8;$lines | ForEach-Object { Write-Output $_ };Write-Output "Report saved: $report";exit 0
