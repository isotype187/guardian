Clear-Host

$Root="D:\Nexus98_Guardian"


. "$Root\core\snapshot_engine.ps1"


$result=New-Nexus98Snapshot -Name "Emergency_Test"


Write-Host ""
Write-Host "Snapshot Result:"
Write-Host $result
