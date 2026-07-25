. .\core\Guardian_Loader.ps1
Import-Guardian -Root (Resolve-Path .)

# Test manually
$m = New-GuardianHealthMessage -Component 'test' -Status 'healthy'
Write-Host "Health Message Type: $($m.type)"
Write-Host "Component: $($m.component)"

$r = New-GuardianResponse -Decision 'ALLOW' -Reason 'ok'
Write-Host "Response Type: $($r.type)"
Write-Host "Decision: $($r.decision)"

$j = Export-GuardianMessage -Message (New-GuardianSystemEvent -Component 'x' -Event 'y')
Write-Host "JSON contains SYSTEM_EVENT: $($j -match 'SYSTEM_EVENT')"

$policy = Test-GuardianPolicy -ActionDescription 'read' -RiskLevel low -CheckpointAvailable $true
Write-Host "Policy Decision: $($policy.decision)"

$ck = New-GuardianCheckpoint -Tier rolling -Reason 'test'
Write-Host "Checkpoint ID: $($ck.id)"
Write-Host "Checkpoint Path Exists: $(Test-Path (Join-Path $GuardianEnv.Rolling $ck.id))"

$found = Get-GuardianCheckpoint -Id $ck.id
Write-Host "Found Checkpoint ID: $($found.id)"

$before = (Get-GuardianAuditTrail).Count
Write-GuardianAudit -Action 'test_action' -Reason 'unit-test'
$after = (Get-GuardianAuditTrail).Count
Write-Host "Audit Count Before: $before, After: $after"

$events = Get-GuardianIntegrityEvents
Write-Host "Integrity Events Count: $($events.Count)"

$h = Get-GuardianHealthScore
Write-Host "Health Overall: $($h.overallPct)"
Write-Host "Health Subsystems Total: $($h.subsystemsTotal)"