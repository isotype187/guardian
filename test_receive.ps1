$root = 'D:\Nexus98_Guardian'
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

# Test 2: Receive a message into inbox
Write-Host "=== Test 2: Receive message into inbox ==="
$m = New-GuardianBridgeMessage -Sender 'Nexus98' -Receiver 'Guardian' -MessageType 'ANALYSIS_REQUEST' -Content @{analysisKind='storage'} -RiskLevel 'low'
$r = Receive-GuardianBridgeMessage -Message $m
$r
$r.accepted

# Check inbox
$inbox = Join-Path (Join-Path $root 'communication') 'inbox'
Get-ChildItem $inbox -File | Select-Object -Last 1