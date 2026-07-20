# Guardian Controlled Remediation (M5).
# Executes only safe, reversible, policy-approved actions. High/critical
# and any destructive intent are deferred to human review. Never deletes
# UNKNOWN data without approval.

function Invoke-GuardianRemediation {
    param(
        [Parameter(Mandatory=$true)][object]$Plan,
        [switch]$DryRun
    )
    # Validate the plan first.
    $v = Test-GuardianActionPlan -Plan $Plan
    if (-not $v.valid) {
        return @{ status='REJECTED'; reason="Invalid plan: $($v.issues -join '; ')"; executed=$false }
    }

    # Policy gate: use the M1 governance engine.
    $policy = Test-GuardianPolicy -ActionDescription $Plan.objective -RiskLevel $Plan.riskLevel -CheckpointAvailable $true
    if ($policy.decision -in @('BLOCK','DELAYED','REQUIRE_REVIEW','REQUIRE_CHECKPOINT') -or $Plan.riskLevel -in @('high','critical')) {
        return @{
            status='DEFERRED'
            decision=$policy.decision
            reason=$policy.reason
            executed=$false
            humanReviewRequired=($policy.decision -in @('REQUIRE_REVIEW','REQUIRE_CHECKPOINT'))
        }
    }

    # Destructive guard: never execute deletions of UNKNOWN/unowned data.
    if ($Plan.objective -match '(?i)delete|remove|purge') {
        return @{ status='DEFERRED'; decision='REQUIRE_REVIEW'; reason='Destructive action requires human approval.'; executed=$false }
    }

    if ($DryRun) {
        return @{ status='DRYRUN_OK'; decision='APPROVED'; reason='Plan validated; execution skipped (dry run).'; executed=$false }
    }

    # Execute the reversible low/medium action under a fresh checkpoint.
    $ck = New-GuardianCheckpoint -Tier rolling -Reason "remediation:$($Plan.plan_id)" -Creator 'remediation'
    try {
        switch -Regex ($Plan.objective) {
            'Rotate rolling checkpoints' {
                $rot = Invoke-GuardianCheckpointRotation -Keep 10
                $result = "Rotated $($rot.rotated.Count) checkpoints to archive."
            }
            'storage hygiene|Investigate' {
                $result = "Observation recorded; no system changes made."
            }
            default {
                $result = "No automated mutation applied for objective: $($Plan.objective)"
            }
        }
        Write-GuardianAudit -Action 'remediation_execute' -Reason $Plan.objective -NewState $ck.id -Validation 'validated' | Out-Null
        return @{ status='EXECUTED'; decision='APPROVED'; checkpoint=$ck.id; result=$result; executed=$true }
    } catch {
        return @{ status='FAILED'; decision='RECOVERY_REQUIRED'; reason=$_.Exception.Message; checkpoint=$ck.id; executed=$false }
    }
}

function Get-GuardianRemediationOptions {
    # Translate current detections into candidate (deferred/auto) plans.
    $options = @()
    $anoms = Get-GuardianResourceAnomalies
    if (@($anoms.anomalies).Count -gt 0) {
        $options += Get-GuardianRemediationPlan -Issue "resource anomaly detected"
    }
    $sec = Get-GuardianSecurityPosture
    if ($sec.baselineAvailable -and $sec.modifiedCount -gt 0) {
        $options += Get-GuardianRemediationPlan -Issue "security drift: $($sec.modifiedCount) modified"
    }
    $sh = Get-GuardianStorageHealth
    if ($sh.growthControlPct -lt 60) {
        $options += Get-GuardianRemediationPlan -Issue "storage growth control $($sh.growthControlPct)%"
    }
    return $options
}


