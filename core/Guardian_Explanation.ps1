# Guardian Explanation Engine (M3 P5).
# Produces structured explanations: WHAT / WHY / EVIDENCE / IMPACT / RECOMMENDATION.

function New-GuardianExplanation {
    param(
        [Parameter(Mandatory=$true)][string]$What,
        [Parameter(Mandatory=$true)][string]$Why,
        [string[]]$Evidence=@(),
        [string]$Impact='',
        [string]$Recommendation=''
    )
    return [PSCustomObject]@{
        type='EXPLANATION'
        what=$What
        why=$Why
        evidence=$Evidence
        impact=$Impact
        recommendation=$Recommendation
        timestamp=(Get-Date).ToString('o')
    }
}

# Build an explanation from a storage-health observation.
function Get-GuardianStorageExplanation {
    $sh = Get-GuardianStorageHealth
    if ($sh.growthControlPct -lt 60) {
        return New-GuardianExplanation `
            -What "Storage growth warning triggered." `
            -Why "The snapshot archive contains $($sh.snapshotFiles) files, indicating uncontrolled accumulation." `
            -Evidence @("Snapshot file count: $($sh.snapshotFiles)","Growth Control score: $($sh.growthControlPct)%") `
            -Impact "Storage efficiency may decline and recovery operations slow." `
            -Recommendation "Review artifact retention and consider archive rotation for the snapshot directory."
    }
    return New-GuardianExplanation `
        -What "Storage health nominal." `
        -Why "Growth control and directory structure within expected bounds." `
        -Evidence @("Overall storage health: $($sh.overallPct)%") `
        -Impact "No immediate storage risk." `
        -Recommendation "Continue periodic monitoring."
}

# Build an explanation from a decision (governance response).
function Get-GuardianDecisionExplanation {
    param([Parameter(Mandatory=$true)][hashtable]$PolicyResponse)
    return New-GuardianExplanation `
        -What "Guardian decision: $($PolicyResponse.decision)." `
        -Why $PolicyResponse.reason `
        -Evidence @("Decision source: Governance Engine") `
        -Impact "Operation may proceed, be delayed, or require review depending on the decision." `
        -Recommendation "Honor the decision state before continuing the operation."
}

function Export-GuardianExplanation {
    param([Parameter(Mandatory=$true)][object]$Explanation,[string]$Path)
    $json = $Explanation | ConvertTo-Json -Depth 10 -Compress
    if ($Path) { $json | Set-Content -Path $Path -Encoding UTF8 }
    return $json
}
