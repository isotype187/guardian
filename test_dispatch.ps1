$root = 'D:\Nexus98_Guardian'
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

# Test 3: Dispatch queued outbound messages
Write-Host "=== Test 3: Dispatch outbound messages ==="
$m = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' -MessageType 'SYSTEM_HEALTH_REPORT' -Content @{}
Send-GuardianBridgeMessage -Message $m | Out-Null
$d = Invoke-GuardianBridgeDispatch
$d

# Check completed
$completed = Join-Path $root 'communication\completed'
Get-ChildItem $completed -File | Select-Object -Last 1