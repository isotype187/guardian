# Guardian Governance Integration (M5).
# Single decision surface combining policy, checkpoint, audit, memory,
# and explanation into one evaluated action request.

function Request-GuardianDecision {
    param(
        [Parameter(Mandatory=$true)][string]$ActionDescription,
        [ValidateSet('low','medium','high','critical')][string]$RiskLevel='low',
        [bool]$CheckpointAvailable=$true,
        [double]$CurrentHealth=100.0,
        [bool]$SafeguardsIntact=$true,
        [string]$Context=''
    )
    # 1. Policy evaluation (M1 governance engine).
    $policy = Test-GuardianPolicy -ActionDescription $ActionDescription -RiskLevel $RiskLevel -CheckpointAvailable $CheckpointAvailable -CurrentHealth $CurrentHealth -SafeguardsIntact $SafeguardsIntact

    # 2. Build an explanation for the decision.
    $explanation = Get-GuardianDecisionExplanation -PolicyResponse $policy

    # 3. Record the request in memory (operational learning).
    $mem = New-GuardianMemory -Source 'governance' -Category short_term -Importance 'medium' `
        -Description "Decision $($policy.decision): $ActionDescription" -RetentionClass 'ACTIVE'
    Write-GuardianMemory -Memory $mem | Out-Null

    # 4. Audit the decision.
    Write-GuardianAudit -Action 'governance_decision' -Reason "$ActionDescription -> $($policy.decision)" -NewState $policy.decision -Validation 'pending' | Out-Null

    # 5. Nexus98-facing contract (interface only).
    $contract = New-GuardianResponse -Decision $policy.decision -Reason $policy.reason -Context @{ riskLevel=$RiskLevel; context=$Context }

    return @{
        decision=$policy.decision
        reason=$policy.reason
        explanation=$explanation
        memory_id=$mem.memory_id
        nexus98_contract=$contract
        timestamp=(Get-Date).ToString('o')
    }
}

function Get-GuardianGovernanceSummary {
    $decisions = @(Get-GuardianMemory -Category short_term) | Where-Object { $_.source -eq 'governance' }
    return @{
        totalDecisions=$decisions.Count
        byDecision=($decisions | Group-Object { $_.description -replace '^Decision (\w+):.*','$1' } | ForEach-Object { @{ decision=$_.Name; count=$_.Count } })
        timestamp=(Get-Date).ToString('o')
    }
}
