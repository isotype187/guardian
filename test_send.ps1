$root = 'D:\Nexus98_Guardian'
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

# Test 1: Initialize bridge and send a message
Write-Host "=== Test 1: Send message to outbox ==="
Initialize-GuardianBridge -Force | Out-Null
$m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
$m.message_id
$m.sender
$m.message_type
$r = Send-GuardianBridgeMessage -Message $m
$r
$r.accepted

# Check outbox
$outbox = Join-Path (Join-Path $root 'communication') 'outbox'
Get-ChildItem $outbox -File | Select-Object -Last 1