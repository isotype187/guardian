Clear-Host

Write-Host "================================="
Write-Host " Nexus98 Guardian v3.0.0"
Write-Host "================================="


$Root="D:\Nexus98_Guardian"


. "$Root\core\snapshot_engine.ps1"
. "$Root\core\verification_engine.ps1"
. "$Root\core\recovery_engine.ps1"


Write-Host ""
Write-Host "System Verification"
Write-Host "------------------"

Test-Nexus98System


Write-Host ""
Write-Host "Assets Registered"
Write-Host "-----------------"

(Get-Content "$Root\config\assets.json" -Raw |
ConvertFrom-Json).assets |
Format-Table name,priority,snapshot


New-Nexus98RecoveryPoint -Reason "Guardian Installation"


Write-Host ""
Write-Host "Guardian Ready"
