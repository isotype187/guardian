. '.\core\Guardian_Loader.ps1'
Import-Guardian -Root (Resolve-Path '.')
$cmds = @('Initialize-GuardianOperations','Register-GuardianJob','Invoke-GuardianJob','Invoke-GuardianSchedulerCycle','Invoke-GuardianHeartbeat','Get-GuardianHeartbeatStatus','Invoke-GuardianNexus98ConsumerCycle','Add-GuardianAck','Get-GuardianAcks','Invoke-GuardianRiskAnalysis','Get-GuardianOperationalState','Get-GuardianRuntimeConfig','Set-GuardianRuntimeConfig','Start-GuardianOperations','Stop-GuardianOperations','Get-GuardianOperationsStatus')
foreach ($c in $cmds) { if (Get-Command $c -EA SilentlyContinue) { Write-Host ('OK ' + $c) } else { Write-Host ('MISS ' + $c) } }
