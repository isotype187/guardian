# Guardian Governance / Policy Engine.
# Evaluates whether an action is safe, permitted, and recoverable.
# Decisions: ALLOW, ALLOW_WITH_MONITORING, REQUIRE_CHECKPOINT,
# REQUIRE_REVIEW, BLOCK.

$GuardianRiskTiers = @{
    low      = 'reading files, generating reports, running analysis, checking status'
    medium   = 'installing dependencies, modifying configuration, changing workflows, adding tools'
    high     = 'changing core architecture, modifying governance, self modification, deleting data, changing permissions, replacing critical components'
    critical = 'disabling safeguards, modifying Guardian itself, removing recovery capability'
}

function Test-GuardianPolicy {
    param(
        [Parameter(Mandatory=$true)][string]$ActionDescription,
        [ValidateSet('low','medium','high','critical')][string]$RiskLevel='low',
        [bool]$CheckpointAvailable=$true,
        [double]$CurrentHealth=100.0,
        [bool]$SafeguardsIntact=$true
    )

    $decision = 'ALLOW'
    $reason = 'Action is within permitted policy.'

    # Critical actions that remove safety or recovery are blocked outright.
    if ($RiskLevel -eq 'critical' -and -not $SafeguardsIntact) {
        $decision = 'BLOCK'
        $reason = 'Action would disable safeguards or remove recovery capability.'
        return New-GuardianResponse -Decision $decision -Reason $reason `
            -Context @{ riskLevel=$RiskLevel; health=$CurrentHealth }
    }

    if ($RiskLevel -eq 'critical') {
        $decision = 'REQUIRE_REVIEW'
        $reason = 'Critical action requires human approval before execution.'
    }
    elseif ($RiskLevel -eq 'high') {
        if ($CheckpointAvailable) {
            $decision = 'REQUIRE_CHECKPOINT'
            $reason = 'High-risk action requires a verified checkpoint and monitoring.'
        } else {
            $decision = 'DELAYED'
            $reason = 'No verified recovery point exists; create a checkpoint first.'
        }
    }
    elseif ($RiskLevel -eq 'medium') {
        $decision = 'ALLOW_WITH_MONITORING'
        $reason = 'Medium-risk action is permitted but must be monitored.'
    }

    if ($CurrentHealth -lt 50.0 -and $decision -in @('ALLOW','ALLOW_WITH_MONITORING')) {
        $decision = 'DELAYED'
        $reason = 'System health below safe threshold; defer until health improves.'
    }

    return New-GuardianResponse -Decision $decision -Reason $reason `
        -Context @{ riskLevel=$RiskLevel; health=$CurrentHealth; checkpoint=$CheckpointAvailable }
}
