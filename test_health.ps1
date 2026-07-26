$root = 'D:\Nexus98_Guardian'
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

# Test 4: Communication health score
Write-Host "=== Test 4: Communication health score ==="
$h = Get-GuardianCommunicationHealth
$h