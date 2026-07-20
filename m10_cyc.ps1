. '.\core\Guardian_Loader.ps1'
Import-Guardian -Root (Resolve-Path '.')
Remove-Item data/ops -Recurse -Force -ErrorAction SilentlyContinue
Initialize-GuardianOperations | Out-Null
$r = Invoke-GuardianSchedulerCycle
Write-Host ('cycle ran: ' + $r.jobsRun)
Get-GuardianJob | ForEach-Object { Write-Host ('  ' + $_.name + '=' + $_.lastStatus + ' lastRun=' + $_.lastRun) }
