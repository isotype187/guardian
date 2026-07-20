# Guardian communication contract layer.
# Defines the structured message types that Guardian and Nexus98
# use to communicate. No subsystem may rely on shared mutable state
# or direct filesystem manipulation for coordination.

function New-GuardianHealthMessage {
    param(
        [Parameter(Mandatory=$true)][string]$Component,
        [ValidateSet('healthy','degraded','unhealthy','unknown')][string]$Status='healthy',
        [string[]]$Warnings=@()
    )
    return @{
        type='HEALTH_MESSAGE'
        component=$Component
        status=$Status
        timestamp=(Get-Date).ToString('o')
        warnings=$Warnings
    }
}

function New-GuardianSystemEvent {
    param(
        [Parameter(Mandatory=$true)][string]$Component,
        [Parameter(Mandatory=$true)][string]$Event,
        [ValidateSet('info','warning','error','critical')][string]$Severity='info'
    )
    return @{
        type='SYSTEM_EVENT'
        component=$Component
        event=$Event
        severity=$Severity
        timestamp=(Get-Date).ToString('o')
    }
}

function New-GuardianTaskRequest {
    param(
        [Parameter(Mandatory=$true)][string]$Description,
        [string[]]$RequiredCapabilities=@(),
        [ValidateSet('low','medium','high','critical')][string]$RiskLevel='low',
        [string]$ExpectedImpact='',
        [bool]$RollbackRequired=$true
    )
    return @{
        type='TASK_REQUEST'
        description=$Description
        requiredCapabilities=$RequiredCapabilities
        riskLevel=$RiskLevel
        expectedImpact=$ExpectedImpact
        rollbackRequired=$RollbackRequired
        timestamp=(Get-Date).ToString('o')
    }
}

function New-GuardianPermissionRequest {
    param(
        [Parameter(Mandatory=$true)][hashtable]$TaskRequest
    )
    return @{
        type='PERMISSION_REQUEST'
        task=$TaskRequest
        timestamp=(Get-Date).ToString('o')
    }
}

function New-GuardianRecoveryRequest {
    param(
        [Parameter(Mandatory=$true)][string]$Reason,
        [string]$CheckpointId=''
    )
    return @{
        type='RECOVERY_REQUEST'
        reason=$Reason
        checkpointId=$CheckpointId
        timestamp=(Get-Date).ToString('o')
    }
}

# Guardian response states: APPROVED, APPROVED_WITH_WARNING,
# DELAYED, DENIED, RECOVERY_REQUIRED, HUMAN_REVIEW_REQUIRED.
function New-GuardianResponse {
    param(
        [Parameter(Mandatory=$true)][string]$Decision,
        [string]$Reason='',
        [hashtable]$Context=@{}
    )
    return @{
        type='GUARDIAN_RESPONSE'
        decision=$Decision
        reason=$Reason
        context=$Context
        timestamp=(Get-Date).ToString('o')
    }
}

# ============================================================
# M3 NEXUS98 COMMUNICATION CONTRACTS (interfaces only)
# Guardian -> Nexus98: health reports, warnings, explanations,
# recommendations. Nexus98 -> Guardian: task context, operation
# status, requested analysis. Not activated until later milestone.
# ============================================================

function New-GuardianToNexus98HealthReport {
    param(
        [Parameter(Mandatory=$true)][hashtable]$ObservabilityModel
    )
    return @{
        type='GUARDIAN_HEALTH_REPORT'
        target='Nexus98'
        overallPct=$ObservabilityModel.overallPct
        health=$ObservabilityModel.health
        storage=$ObservabilityModel.storage
        memory=$ObservabilityModel.memory
        checkpoints=$ObservabilityModel.checkpoints
        timestamp=(Get-Date).ToString('o')
    }
}

function New-GuardianToNexus98Warning {
    param(
        [Parameter(Mandatory=$true)][string]$Warning,
        [ValidateSet('low','medium','high','critical')][string]$RiskLevel='medium'
    )
    return @{
        type='GUARDIAN_WARNING'
        target='Nexus98'
        warning=$Warning
        riskLevel=$RiskLevel
        timestamp=(Get-Date).ToString('o')
    }
}

function New-GuardianToNexus98Explanation {
    param([Parameter(Mandatory=$true)][object]$Explanation)
    return @{
        type='GUARDIAN_EXPLANATION'
        target='Nexus98'
        what=$Explanation.what
        why=$Explanation.why
        evidence=$Explanation.evidence
        impact=$Explanation.impact
        recommendation=$Explanation.recommendation
        timestamp=(Get-Date).ToString('o')
    }
}

function New-GuardianToNexus98Recommendation {
    param(
        [Parameter(Mandatory=$true)][string]$Recommendation,
        [string]$Context=''
    )
    return @{
        type='GUARDIAN_RECOMMENDATION'
        target='Nexus98'
        recommendation=$Recommendation
        context=$Context
        timestamp=(Get-Date).ToString('o')
    }
}

function New-Nexus98ToGuardianTaskContext {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [string]$OperationStatus='pending',
        [string[]]$RequestedAnalysis=@()
    )
    return @{
        type='NEXUS98_TASK_CONTEXT'
        source='Nexus98'
        task=$TaskDescription
        operationStatus=$OperationStatus
        requestedAnalysis=$RequestedAnalysis
        timestamp=(Get-Date).ToString('o')
    }
}

function New-Nexus98ToGuardianOperationStatus {
    param(
        [Parameter(Mandatory=$true)][string]$Component,
        [Parameter(Mandatory=$true)][string]$Status,
        [string]$Detail=''
    )
    return @{
        type='NEXUS98_OPERATION_STATUS'
        source='Nexus98'
        component=$Component
        status=$Status
        detail=$Detail
        timestamp=(Get-Date).ToString('o')
    }
}

function New-Nexus98ToGuardianAnalysisRequest {
    param(
        [Parameter(Mandatory=$true)][string]$AnalysisKind,
        [string]$Scope=''
    )
    return @{
        type='NEXUS98_ANALYSIS_REQUEST'
        source='Nexus98'
        analysisKind=$AnalysisKind
        scope=$Scope
        timestamp=(Get-Date).ToString('o')
    }
}

function Export-GuardianMessage {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Message,
        [string]$Path
    )
    $json = $Message | ConvertTo-Json -Depth 10 -Compress
    if ($Path) { $json | Set-Content -Path $Path -Encoding UTF8 }
    return $json
}

