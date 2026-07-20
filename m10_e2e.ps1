. '.\core\Guardian_Loader.ps1'
Import-Guardian -Root (Resolve-Path '.')
Initialize-GuardianOperations | Out-Null
$start = Start-GuardianOperations -MaxCycles 1
Write-Host ('start: ' + ($start | ConvertTo-Json -Compress))
$hb = Get-GuardianHeartbeatStatus
Write-Host ('heartbeat: ' + ($hb | ConvertTo-Json -Compress))
$jobs = Get-GuardianJob
Write-Host ('jobs: ' + ($jobs | ForEach-Object { $_.name + '=' + $_.lastStatus }) -join ', ')
$risk = Invoke-GuardianRiskAnalysis
Write-Host ('risk: score=' + $risk.riskScore + ' level=' + $risk.riskLevel + ' factors=' + ($risk.factors -join '; '))
$st = Get-GuardianOperationalState
Write-Host ('ops state health=' + $st.guardianHealth.overallPct + ' jobs=' + $st.schedulerStatus.jobCount)
$acks = Get-GuardianAcks
Write-Host ('acks seen: ' + $acks.Count)
Stop-GuardianOperations | Out-Null
Write-Host 'stopped'
