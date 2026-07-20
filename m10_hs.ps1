. '.\core\Guardian_Loader.ps1'
Import-Guardian -Root (Resolve-Path '.')
Initialize-GuardianOperations | Out-Null
$r = Invoke-GuardianJob -Name 'HEALTH_SCAN'
Write-Host ('HEALTH_SCAN: ' + ($r | ConvertTo-Json -Depth 4 -Compress))
$j = Get-GuardianJob -Name 'HEALTH_SCAN'
Write-Host ('stored status: ' + $j.lastStatus + ' lastRun=' + $j.lastRun)
