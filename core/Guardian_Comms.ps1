# Guardian <-> Nexus98 Communication Layer (M6).
# Activates the M3 contracts into a runtime bridge. Messages are persisted
# in structured outbox/inbox stores (JSONL), auditable and recoverable.
# Guardian never modifies Nexus98; it only exchanges structured messages.

$GuardianCommsDir = Join-Path $GuardianEnv.Data 'comms'

function Send-GuardianMessage {
    param([Parameter(Mandatory=$true)][object]$Message)
    New-Item -ItemType Directory -Force -Path $GuardianCommsDir | Out-Null
    $box = Join-Path $GuardianCommsDir 'outbox.jsonl'
    $Message | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $box -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'comms_send' -Reason ($Message.type) -NewState $Message.timestamp -Validation 'pending' | Out-Null
    }
    return $Message
}

function Receive-GuardianMessage {
    param([object]$Message)
    New-Item -ItemType Directory -Force -Path $GuardianCommsDir | Out-Null
    $box = Join-Path $GuardianCommsDir 'inbox.jsonl'
    $Message | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $box -Encoding UTF8
    return $Message
}

function Get-GuardianOutbox { param([int]$Last=0); $f=Join-Path $GuardianCommsDir 'outbox.jsonl'; if(-not(Test-Path $f)){return @()}; $m=Get-Content $f -Encoding UTF8 -ErrorAction SilentlyContinue|Where-Object{$_.Trim()}|ForEach-Object{$_|ConvertFrom-Json}; if($Last-gt 0){$m=$m|Select-Object -Last $Last}; return $m }
function Get-GuardianInbox { param([int]$Last=0); $f=Join-Path $GuardianCommsDir 'inbox.jsonl'; if(-not(Test-Path $f)){return @()}; $m=Get-Content $f -Encoding UTF8 -ErrorAction SilentlyContinue|Where-Object{$_.Trim()}|ForEach-Object{$_|ConvertFrom-Json}; if($Last-gt 0){$m=$m|Select-Object -Last $Last}; return $m }

# ---- Guardian -> Nexus98 modulation helpers (use M3 contracts) ----

function Send-GuardianHealthReportToNexus98 {
    $obs = Get-GuardianObservability
    $msg = New-GuardianToNexus98HealthReport -ObservabilityModel $obs
    return Send-GuardianMessage -Message $msg
}

function Send-GuardianWarningToNexus98 {
    param([Parameter(Mandatory=$true)][string]$Warning, [ValidateSet('low','medium','high','critical')][string]$RiskLevel='medium')
    $msg = New-GuardianToNexus98Warning -Warning $Warning -RiskLevel $RiskLevel
    return Send-GuardianMessage -Message $msg
}

function Send-GuardianExplanationToNexus98 {
    param([Parameter(Mandatory=$true)][object]$Explanation)
    $msg = New-GuardianToNexus98Explanation -Explanation $Explanation
    return Send-GuardianMessage -Message $msg
}

function Send-GuardianRecommendationToNexus98 {
    param([Parameter(Mandatory=$true)][string]$Recommendation, [string]$Context='')
    $msg = New-GuardianToNexus98Recommendation -Recommendation $Recommendation -Context $Context
    return Send-GuardianMessage -Message $msg
}

# ---- Nexus98 -> Guardian intake + modulation ----

function Receive-Nexus98TaskContext {
    param([Parameter(Mandatory=$true)][string]$TaskDescription, [string]$OperationStatus='pending', [string[]]$RequestedAnalysis=@())
    $msg = New-Nexus98ToGuardianTaskContext -TaskDescription $TaskDescription -OperationStatus $OperationStatus -RequestedAnalysis $RequestedAnalysis
    return Receive-GuardianMessage -Message $msg
}

function Receive-Nexus98OperationStatus {
    param([Parameter(Mandatory=$true)][string]$Component, [Parameter(Mandatory=$true)][string]$Status, [string]$Detail='')
    $msg = New-Nexus98ToGuardianOperationStatus -Component $Component -Status $Status -Detail $Detail
    return Receive-GuardianMessage -Message $msg
}

function Receive-Nexus98AnalysisRequest {
    param([Parameter(Mandatory=$true)][string]$AnalysisKind, [string]$Scope='')
    $msg = New-Nexus98ToGuardianAnalysisRequest -AnalysisKind $AnalysisKind -Scope $Scope
    return Receive-GuardianMessage -Message $msg
}

# ---- Modulation: translate an inbound Nexus98 request into a Guardian response ----
# Guardian gauges risk; if high/critical without checkpoint, it modulates
# the reply toward caution (REQUIRE_CHECKPOINT / REQUIRE_REVIEW) instead of
# blindly approving. This is the Guardian<->Nexus98 modulation core.

function Invoke-GuardianModulation {
    param([Parameter(Mandatory=$true)][object]$InboundMessage)
    # Inbound contracts are hashtables; normalize to a uniform accessor.
    $isHash = $InboundMessage -is [System.Collections.Hashtable] -or $InboundMessage.ContainsKey
    $has = { param($k) if ($isHash) { return $InboundMessage.ContainsKey($k) } else { return ($InboundMessage.PSObject.Properties.Name -contains $k) } }
    $get = { param($k) if ($isHash) { return $InboundMessage[$k] } else { return $InboundMessage.$k } }

    $risk = 'low'; $hasCheckpoint = $true
    if (& $has 'task') {
        # Task context: treat creation as medium; if status shows risky op, escalate
        # and assume NO verified checkpoint until one is presented (caution by default).
        $op = & $get 'operationStatus'
        if ($op -match 'destructive|delete|modify') {
            $risk = 'high'; $hasCheckpoint = $false
        } else {
            $risk = 'medium'
        }
    }
    elseif (& $has 'requestedAnalysis') {
        # Analysis request: low risk, always safe to observe.
        $risk = 'low'
    }
    $taskDesc = if (& $has 'task') { & $get 'task' } else { 'inbound request' }
    $decision = Test-GuardianPolicy -ActionDescription $taskDesc -RiskLevel $risk -CheckpointAvailable $hasCheckpoint
    $response = New-GuardianResponse -Decision $decision.decision -Reason $decision.reason -Context @{ riskLevel=$risk; sourceType=$InboundMessage.type }
    Send-GuardianMessage -Message $response | Out-Null
    return $response
}



