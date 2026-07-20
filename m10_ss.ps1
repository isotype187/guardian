. '.\core\Guardian_Loader.ps1'
Import-Guardian -Root (Resolve-Path '.')
Initialize-GuardianOperations | Out-Null
$r = Invoke-GuardianJob -Name 'STORAGE_SCAN'
Write-Host ('STORAGE_SCAN: ' + ($r | ConvertTo-Json -Depth 4 -Compress))
$j = Get-GuardianJob -Name 'STORAGE_SCAN'
Write-Host ('stored: ' + $j.lastStatus)
