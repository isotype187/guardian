# Guardian Action Planning (M5).
# Produces structured, reviewable plans for remediation actions.
# Every plan carries objective, affected items, risks, rollback, acceptance.

function New-GuardianActionPlan {
    param(
        [Parameter(Mandatory=$true)][string]$Objective,
        [ValidateSet('low','medium','high','critical')][string]$RiskLevel='low',
        [string[]]$AffectedItems=@(),
        [string]$RollbackPlan='',
        [string]$AcceptanceCriteria='',
        [string]$PlannedBy='guardian'
    )
    return [PSCustomObject]@{
        plan_id="PLAN_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 9999)"
        objective=$Objective
        riskLevel=$RiskLevel
        affectedItems=$AffectedItems
        rollbackPlan=$RollbackPlan
        acceptanceCriteria=$AcceptanceCriteria
        plannedBy=$PlannedBy
        created=(Get-Date).ToString('o')
        status='planned'
    }
}

function Test-GuardianActionPlan {
    param([Parameter(Mandatory=$true)][object]$Plan)
    $issues = @()
    if (-not $Plan.objective) { $issues += 'missing objective' }
    if ($Plan.riskLevel -in @('high','critical') -and -not $Plan.rollbackPlan) { $issues += 'high-risk plan requires rollback plan' }
    if (-not $Plan.acceptanceCriteria) { $issues += 'missing acceptance criteria' }
    return @{ valid=($issues.Count -eq 0); issues=$issues }
}

function Get-GuardianRemediationPlan {
    param([Parameter(Mandatory=$true)][string]$Issue)
    # Maps a known observation to a conservative, reversible remediation plan.
    switch -Regex ($Issue) {
        'checkpoint.*rotation|rolling.*full' {
            return New-GuardianActionPlan -Objective "Rotate rolling checkpoints" -RiskLevel 'low' `
                -AffectedItems @('data/checkpoints/rolling') -RollbackPlan "Archived checkpoints remain in data/checkpoints/archive; restore by moving back." `
                -AcceptanceCriteria "Rolling checkpoint count within Keep policy after rotation."
        }
        'storage|growth|accumulation' {
            return New-GuardianActionPlan -Objective "Recommend storage hygiene review (no auto-delete)" -RiskLevel 'medium' `
                -AffectedItems @('snapshots') -RollbackPlan "N/A - observation only; no data removed." `
                -AcceptanceCriteria "Recommendation delivered; no uncontrolled deletion."
        }
        'security|drift|modification' {
            return New-GuardianActionPlan -Objective "Flag security drift for human review" -RiskLevel 'high' `
                -AffectedItems @('core','config') -RollbackPlan "Revert changed files from last verified checkpoint if approved." `
                -AcceptanceCriteria "Human reviews drift; no automatic change applied."
        }
        default {
            return New-GuardianActionPlan -Objective "Investigate: $Issue" -RiskLevel 'medium' `
                -AffectedItems @() -RollbackPlan "N/A" -AcceptanceCriteria "Issue understood and classified."
        }
    }
}
