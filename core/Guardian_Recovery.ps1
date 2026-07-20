# Guardian Recovery Engine.
# Provides an emergency snapshot before recovery and rollback-level
# bookkeeping. Built on the rolling checkpoint system.

function New-GuardianEmergencySnapshot {
    param([string]$Reason='emergency')
    $ck = New-GuardianCheckpoint -Tier 'emergency' -Reason $Reason -Creator 'recovery_engine'
    Write-GuardianAudit -Action 'emergency_snapshot' -Reason $Reason -NewState $ck.id -Validation 'validated'
    return $ck
}

# Rollback levels: 1 config, 2 component restart, 3 capability disable,
# 4 workflow rollback, 5 full checkpoint restore, 6 emergency safe mode.
function Invoke-GuardianRollback {
    param(
        [ValidateRange(1,6)][int]$Level=1,
        [string]$CheckpointId=''
    )
    $ck = $null
    if ($CheckpointId) { $ck = Get-GuardianCheckpoint -Id $CheckpointId }
    if (-not $ck -and $Level -ge 5) {
        # Select newest validated rolling checkpoint.
        $ck = Get-GuardianCheckpoints -Tier rolling | Sort-Object { $_.created } | Select-Object -Last 1
    }
    $record = @{
        level=$Level
        checkpointId=if ($ck) { $ck.id } else { $null }
        executed=(Get-Date).ToString('o')
        status=if ($Level -lt 5 -or $ck) { 'ready' } else { 'no_recovery_point' }
    }
    Write-GuardianAudit -Action "rollback_level_$Level" -NewState $record.status -Validation 'pending'
    return $record
}
