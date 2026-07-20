. '.\core\Guardian_Loader.ps1'
Import-Guardian -Root (Resolve-Path '.')
Initialize-GuardianOperations | Out-Null
$cyc = Invoke-GuardianSchedulerCycle
Write-Host ('cycle ran jobs: ' + $cyc.jobsRun)
Get-GuardianJob | ForEach-Object { Write-Host ('  ' + $_.name + '=' + $_.lastStatus) }
