# Guardian <-> Nexus98 Governed Communication Bridge (M8).
# Local JSONL/file-based message bus with a full lifecycle, governance
# gating, security validation, dedup, failure recovery, and observability.
# Reuses M3/M6 contract builders, Governance, Memory, Events, Audit, DriftGuard.
# Observation-first: messages are never deleted; they transition folders.

$GuardianBridgeRoot     = Join-Path $GuardianEnv.Root 'communication'
$GuardianBridgeEnabled   = $true
$GuardianBridgeProcessed = @{}   # in-memory dedup: message_id -> last result

$GuardianBridgeKnownAgents = @('Guardian','Nexus98')
$GuardianBridgeMessageTypes = @(
    'SYSTEM_HEALTH_REPORT','SYSTEM_HEALTH_REQUEST','ANALYSIS_REQUEST','ANALYSIS_RESPONSE',
    'WORKFLOW_STATUS_UPDATE','EVENT_NOTIFICATION','RECOVERY_STATUS','GOVERNANCE_DECISION'
)
$GuardianBridgeStatuses = @(
    'CREATED','VALIDATING','ACCEPTED','PROCESSING','COMPLETED','FAILED','RETRY_PENDING','ARCHIVED'
)
$GuardianBridgeAuthStates = @('GRANTED','DENIED','PENDING','NONE')

# ---------------------------------------------------------------------------
# Foundation
# ---------------------------------------------------------------------------
function Initialize-GuardianBridge {
    param([switch]$Force)
    $dirs = @('inbox','outbox','processing','completed','failed','archive')
    foreach ($d in $dirs) {
        $p = Join-Path $GuardianBridgeRoot $d
        if (-not (Test-Path $p) -or $Force) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
    }
    return $GuardianBridgeRoot
}

function Set-GuardianBridgeEnabled {
    param([bool]$Enabled=$true)
    $script:GuardianBridgeEnabled = $Enabled
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'bridge_mode' -Reason 'bridge enabled toggle' -NewState $Enabled -Validation 'validated'
    }
    return $script:GuardianBridgeEnabled
}

# ---------------------------------------------------------------------------
# Message construction (MESSAGE STANDARD)
# ---------------------------------------------------------------------------
function New-GuardianBridgeMessage {
    param(
        [Parameter(Mandatory=$true)][string]$Sender,
        [Parameter(Mandatory=$true)][string]$Receiver,
        [Parameter(Mandatory=$true)][string]$MessageType,
        [object]$Content=@{},
        [hashtable]$Metadata=@{},
        [ValidateSet('low','medium','high','critical')][string]$RiskLevel='low',
        [bool]$PermissionRequired=$false,
        [ValidateSet('GRANTED','DENIED','PENDING','NONE')][string]$AuthorizationStatus='NONE',
        [string]$CheckpointReference='',
        [string]$CorrelationId=''
    )
    $now = Get-Date
    return [PSCustomObject]@{
        message_id          = "MSG_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 999999)"
        correlation_id      = if ($CorrelationId) { $CorrelationId } else { "COR_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 999999)" }
        timestamp           = $now.ToString('o')
        sender              = $Sender
        receiver            = $Receiver
        message_type        = $MessageType
        risk_level          = $RiskLevel
        permission_required = $PermissionRequired
        authorization_status= $AuthorizationStatus
        checkpoint_reference= $CheckpointReference
        content             = $Content
        metadata            = $Metadata
        status              = 'CREATED'
        attempt_count       = 0
        created_time        = $now.ToString('o')
        updated_time        = $now.ToString('o')
    }
}

# ---------------------------------------------------------------------------
# Phase 7: Security hardening — schema / sender / permission validation
# ---------------------------------------------------------------------------
function Test-GuardianBridgeMessageSchema {
    param([Parameter(Mandatory)]$Message)
    $required = @('message_id','correlation_id','timestamp','sender','receiver',
                  'message_type','risk_level','authorization_status','status',
                  'attempt_count','created_time','updated_time','content')
    $missing = @()
    foreach ($k in $required) {
        if (-not $Message.PSObject.Properties.Name.Contains($k)) { $missing += $k }
    }
    $valid = $true
    if ($Message.sender -notin $GuardianBridgeKnownAgents) { $valid = $false }
    if ($Message.receiver -notin $GuardianBridgeKnownAgents) { $valid = $false }
    if ($Message.message_type -notin $GuardianBridgeMessageTypes) { $valid = $false }
    if ($Message.status -notin $GuardianBridgeStatuses) { $valid = $false }
    if ($Message.authorization_status -notin $GuardianBridgeAuthStates) { $valid = $false }
    return [PSCustomObject]@{
        valid = ($missing.Count -eq 0 -and $valid)
        missingFields = $missing
        reason = if ($missing.Count -eq 0 -and $valid) { 'schema ok' } else { 'schema violation: ' + ($missing -join ',') }
    }
}

function Test-GuardianBridgeSender {
    param([Parameter(Mandatory)]$Message)
    $ok = $Message.sender -in $GuardianBridgeKnownAgents
    return [PSCustomObject]@{
        valid = $ok
        reason = if ($ok) { 'known agent' } else { "unknown sender: $($Message.sender)" }
    }
}

function Test-GuardianBridgePermission {
    param([Parameter(Mandatory)]$Message)
    if ($Message.permission_required -and $Message.authorization_status -ne 'GRANTED') {
        return [PSCustomObject]@{ valid=$false; reason='permission required but not granted' }
    }
    return [PSCustomObject]@{ valid=$true; reason='permission satisfied' }
}

function Test-GuardianBridgeSecurity {
    param([Parameter(Mandatory)]$Message)
    $schema = Test-GuardianBridgeMessageSchema -Message $Message
    $sender = Test-GuardianBridgeSender -Message $Message
    $perm   = Test-GuardianBridgePermission -Message $Message
    $blocked = @()
    if (-not $schema.valid) { $blocked += $schema.reason }
    if (-not $sender.valid) { $blocked += $sender.reason }
    if (-not $perm.valid)   { $blocked += $perm.reason }
    $passed = $blocked.Count -eq 0
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'bridge_security_check' -Reason ($Message.message_id) -NewState $passed -Validation $(if($passed){'validated'}else{'failed'}) | Out-Null
    }
    return [PSCustomObject]@{
        passed = $passed
        reasons = $blocked
        decision = if ($passed) { 'ACCEPTED' } else { 'BLOCKED' }
    }
}

# ---------------------------------------------------------------------------
# Transport helpers
# ---------------------------------------------------------------------------
function Save-GuardianBridgeMessage {
    param([Parameter(Mandatory)]$Message, [Parameter(Mandatory)][string]$Folder)
    Initialize-GuardianBridge | Out-Null
    $dir = Join-Path $GuardianBridgeRoot $Folder
    $fileName = $Message.message_id + '.json'; $file = Join-Path $dir $fileName
    $Message | ConvertTo-Json -Depth 12 | Set-Content -Path $file -Encoding UTF8
    return $file
}

function Move-GuardianBridgeMessage {
    param([Parameter(Mandatory)]$Message, [Parameter(Mandatory)][string]$ToFolder)
    $fromDirs = @('outbox','inbox','processing','completed','failed','archive')
    foreach ($fd in $fromDirs) {
        $src = Join-Path (Join-Path $GuardianBridgeRoot $fd) ($Message.message_id + '.json')
        if (Test-Path $src) {
            $dst = Join-Path (Join-Path $GuardianBridgeRoot $ToFolder) ($Message.message_id + '.json')
            Move-Item -Path $src -Destination $dst -Force
            return $dst
        }
    }
    # Not found on disk; persist at target.
    return (Save-GuardianBridgeMessage -Message $Message -Folder $ToFolder)
}

function Set-GuardianBridgeMessageStatus {
    param([Parameter(Mandatory)]$Message, [Parameter(Mandatory)][string]$Status, [string]$Reason='')
    $Message.status = $Status
    $Message.updated_time = (Get-Date).ToString('o')
    $Message.attempt_count = if ($Status -eq 'PROCESSING' -or $Status -eq 'RETRY_PENDING') { [int]$Message.attempt_count + 1 } else { $Message.attempt_count }
    if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
        New-GuardianEvent -Source 'bridge' -Category SYSTEM -Severity INFO `
            -Description "BRIDGE_TRANSITION: $($Message.message_id) -> $Status" `
            -AffectedComponent 'communication' -Metadata @{ messageType=$Message.message_type; reason=$Reason } | Out-Null
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'bridge_transition' -Reason "$($Message.message_id):$Status" -NewState $Status -Validation 'completed' | Out-Null
    }
    return $Message
}

# ---------------------------------------------------------------------------
# Phase 2/3: Outbound + Dispatcher
# ---------------------------------------------------------------------------
function Send-GuardianBridgeMessage {
    param([Parameter(Mandatory)]$Message)
    if (-not $script:GuardianBridgeEnabled) {
        return [PSCustomObject]@{ accepted=$false; reason='bridge disabled'; message_id=$Message.message_id }
    }
    $sec = Test-GuardianBridgeSecurity -Message $Message
    if (-not $sec.passed) {
        $Message = Set-GuardianBridgeMessageStatus -Message $Message -Status 'FAILED' -Reason ($sec.reasons -join '; ')
        Save-GuardianBridgeMessage -Message $Message -Folder 'failed' | Out-Null
        return [PSCustomObject]@{ accepted=$false; reason=($sec.reasons -join '; '); message_id=$Message.message_id }
    }
    $Message = Set-GuardianBridgeMessageStatus -Message $Message -Status 'VALIDATING'
    $Message = Set-GuardianBridgeMessageStatus -Message $Message -Status 'ACCEPTED'
    Save-GuardianBridgeMessage -Message $Message -Folder 'outbox' | Out-Null
    return [PSCustomObject]@{ accepted=$true; reason='queued in outbox'; message_id=$Message.message_id }
}

function Invoke-GuardianBridgeDispatch {
    param([int]$MaxProcess=50)
    if (-not $script:GuardianBridgeEnabled) {
        return [PSCustomObject]@{ processed=0; note='bridge disabled' }
    }
    Initialize-GuardianBridge | Out-Null
    $outbox = Join-Path $GuardianBridgeRoot 'outbox'
    $files = @(Get-ChildItem -Path $outbox -File -Filter *.json -ErrorAction SilentlyContinue | Select-Object -First $MaxProcess)
    $processed = 0
    foreach ($f in $files) {
        try {
            $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
            # dedup by message_id
            if ($script:GuardianBridgeProcessed.ContainsKey($msg.message_id)) {
                $msg = Set-GuardianBridgeMessageStatus -Message $msg -Status 'ARCHIVED' -Reason 'duplicate detected at dispatch'
                Move-GuardianBridgeMessage -Message $msg -ToFolder 'archive' | Out-Null
                $processed++
                continue
            }
            $msg = Set-GuardianBridgeMessageStatus -Message $msg -Status 'PROCESSING'
            Move-GuardianBridgeMessage -Message $msg -ToFolder 'processing' | Out-Null
            # Mark completed (delivery to Nexus98 outbox is recorded; no deletion).
            $msg = Set-GuardianBridgeMessageStatus -Message $msg -Status 'COMPLETED'
            Move-GuardianBridgeMessage -Message $msg -ToFolder 'completed' | Out-Null
            $script:GuardianBridgeProcessed[$msg.message_id] = 'COMPLETED'
            if (Get-Command Write-GuardianMemory -ErrorAction SilentlyContinue) {
                Write-GuardianMemory -Memory (New-GuardianMemory -Source 'bridge' -Category short_term -Importance medium -Description "Dispatched $($msg.message_type) to $($msg.receiver)") | Out-Null
            }
            $processed++
        } catch {
            $msg = if ($msg) { $msg } else { [PSCustomObject]@{ message_id=$f.BaseName } }
            $msg = Set-GuardianBridgeMessageStatus -Message $msg -Status 'FAILED' -Reason $_.Exception.Message
            Move-GuardianBridgeMessage -Message $msg -ToFolder 'failed' | Out-Null
        }
    }
    return [PSCustomObject]@{ processed=$processed; outboxRemaining=@(Get-ChildItem -Path $outbox -File -ErrorAction SilentlyContinue).Count }
}

# ---------------------------------------------------------------------------
# Phase 2: Inbound (Nexus98 -> Guardian)
# ---------------------------------------------------------------------------
function Receive-GuardianBridgeMessage {
    param([Parameter(Mandatory)]$Message)
    if (-not $script:GuardianBridgeEnabled) {
        return [PSCustomObject]@{ accepted=$false; reason='bridge disabled'; message_id=$Message.message_id }
    }
    $sec = Test-GuardianBridgeSecurity -Message $Message
    if (-not $sec.passed) {
        $Message = Set-GuardianBridgeMessageStatus -Message $Message -Status 'FAILED' -Reason ($sec.reasons -join '; ')
        Save-GuardianBridgeMessage -Message $Message -Folder 'failed' | Out-Null
        return [PSCustomObject]@{ accepted=$false; reason=($sec.reasons -join '; '); message_id=$Message.message_id }
    }
    # dedup by message_id (allow a Nexus98 resend to be recorded but not double-processed)
    if ($script:GuardianBridgeProcessed.ContainsKey($Message.message_id)) {
        $Message = Set-GuardianBridgeMessageStatus -Message $Message -Status 'ARCHIVED' -Reason 'duplicate inbound'
        Save-GuardianBridgeMessage -Message $Message -Folder 'archive' | Out-Null
        return [PSCustomObject]@{ accepted=$true; dedup=$true; reason='duplicate recorded'; message_id=$Message.message_id }
    }
    $Message = Set-GuardianBridgeMessageStatus -Message $Message -Status 'ACCEPTED'
    Save-GuardianBridgeMessage -Message $Message -Folder 'inbox' | Out-Null
    $script:GuardianBridgeProcessed[$Message.message_id] = 'ACCEPTED'
    return [PSCustomObject]@{ accepted=$true; dedup=$false; reason='queued in inbox'; message_id=$Message.message_id }
}

# ---------------------------------------------------------------------------
# Phase 4: Governance integration for inbound requests
# ---------------------------------------------------------------------------
function Invoke-GuardianBridgeGovernance {
    param([Parameter(Mandatory)]$Message)
    if ($Message.sender -ne 'Nexus98') {
        return [PSCustomObject]@{ decision='BLOCK'; reason='only Nexus98 inbound requests are governed' }
    }
    $ck = $false
    if ($Message.checkpoint_reference) { $ck = $true }
    $policy = Test-GuardianPolicy -ActionDescription $Message.message_type -RiskLevel $Message.risk_level -CheckpointAvailable $ck
    # Build a GOVERNANCE_DECISION message back to Nexus98.
    $decisionMsg = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' `
        -MessageType 'GOVERNANCE_DECISION' -RiskLevel $Message.risk_level `
        -Content @{ request=$Message.message_id; decision=$policy.decision; reason=$policy.reason } `
        -Metadata @{ correlation_id=$Message.correlation_id }
    return [PSCustomObject]@{ decision=$policy.decision; reason=$policy.reason; governanceMessage=$decisionMsg }
}

# ---------------------------------------------------------------------------
# Phase 5: Nexus98 modulation helpers
# ---------------------------------------------------------------------------
function Send-GuardianHealthReportToNexus98Bridge {
    $obs = Get-GuardianObservability
    $payload = New-GuardianToNexus98HealthReport -ObservabilityModel $obs
    $msg = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' `
        -MessageType 'SYSTEM_HEALTH_REPORT' -Content $payload -RiskLevel 'low'
    Send-GuardianBridgeMessage -Message $msg | Out-Null
    return $msg
}

function Send-GuardianGovernanceDecisionToNexus98 {
    param([Parameter(Mandatory)]$Decision, [string]$Reason='', [string]$RequestId='')
    $msg = New-GuardianBridgeMessage -Sender 'Guardian' -Receiver 'Nexus98' `
        -MessageType 'GOVERNANCE_DECISION' -Content @{ decision=$Decision; reason=$Reason; request=$RequestId } `
        -RiskLevel 'low'
    Send-GuardianBridgeMessage -Message $msg | Out-Null
    return $msg
}

function Receive-Nexus98AnalysisRequestBridge {
    param([Parameter(Mandatory)][string]$AnalysisKind, [string]$Scope='', [string]$RiskLevel='low', [string]$CheckpointReference='')
    $msg = New-GuardianBridgeMessage -Sender 'Nexus98' -Receiver 'Guardian' `
        -MessageType 'ANALYSIS_REQUEST' -RiskLevel $RiskLevel -CheckpointReference $CheckpointReference `
        -Content @{ analysisKind=$AnalysisKind; scope=$Scope } `
        -PermissionRequired ($RiskLevel -in @('high','critical'))
    Receive-GuardianBridgeMessage -Message $msg | Out-Null
    return $msg
}

# ---------------------------------------------------------------------------
# Phase 6: Event + Memory integration
# ---------------------------------------------------------------------------
function Get-GuardianBridgeHistory {
    param([int]$Last=0)
    $all = @()
    foreach ($d in @('outbox','inbox','processing','completed','failed','archive')) {
        $dir = Join-Path $GuardianBridgeRoot $d
        if (-not (Test-Path $dir)) { continue }
        Get-ChildItem -Path $dir -File -Filter *.json -ErrorAction SilentlyContinue | ForEach-Object {
            $m = Get-Content -Path $_.FullName -Encoding UTF8 | ConvertFrom-Json
            $all += [PSCustomObject]@{ folder=$d; message_id=$m.message_id; type=$m.message_type; status=$m.status; sender=$m.sender; receiver=$m.receiver; updated=$m.updated_time }
        }
    }
    if ($Last -gt 0) { $all = $all | Select-Object -Last $Last }
    return $all
}

# ---------------------------------------------------------------------------
# Phase 9: Observability
# ---------------------------------------------------------------------------
function Get-GuardianCommunicationHealth {
    Initialize-GuardianBridge | Out-Null
    $counts = @{}
    $total = 0
    foreach ($d in @('outbox','inbox','processing','completed','failed','archive')) {
        $dir = Join-Path $GuardianBridgeRoot $d
        $c = if (Test-Path $dir) { @(Get-ChildItem -Path $dir -File -Filter *.json -ErrorAction SilentlyContinue).Count } else { 0 }
        $counts[$d] = $c
        $total += $c
    }
    $completed = $counts['completed']; $failed = $counts['failed']; $outbox = $counts['outbox']; $inbox = $counts['inbox']
    $successRate = if (($completed + $failed) -gt 0) { [math]::Round(($completed / ($completed + $failed)) * 100, 1) } else { 100.0 }
    $queueHealth = if (($outbox + $inbox) -gt 100) { 60.0 } elseif (($outbox + $inbox) -gt 20) { 80.0 } else { 100.0 }
    $failurePenalty = if ($failed -gt 10) { 50.0 } elseif ($failed -gt 0) { 75.0 } else { 100.0 }
    $score = [math]::Round(($successRate * 0.4) + ($queueHealth * 0.3) + ($failurePenalty * 0.3), 1)
    return [PSCustomObject]@{
        enabled = $script:GuardianBridgeEnabled
        healthScore = $score
        successRatePct = $successRate
        queueSize = ($outbox + $inbox)
        counts = $counts
        total = $total
        timestamp = (Get-Date).ToString('o')
    }
}

# ---------------------------------------------------------------------------
# Phase 8: Failure recovery
# ---------------------------------------------------------------------------
function Repair-GuardianBridgeFailures {
    param([int]$MaxRetry=20)
    $failedDir = Join-Path $GuardianBridgeRoot 'failed'
    if (-not (Test-Path $failedDir)) { return @{ retried=0; archived=0 } }
    $files = @(Get-ChildItem -Path $failedDir -File -Filter *.json -ErrorAction SilentlyContinue | Select-Object -First $MaxRetry)
    $retried = 0; $archived = 0
    foreach ($f in $files) {
        $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
        if ([int]$msg.attempt_count -ge 3) {
            $msg = Set-GuardianBridgeMessageStatus -Message $msg -Status 'ARCHIVED' -Reason 'max retries exceeded'
            Move-GuardianBridgeMessage -Message $msg -ToFolder 'archive' | Out-Null
            $archived++
        } else {
            $msg = Set-GuardianBridgeMessageStatus -Message $msg -Status 'RETRY_PENDING'
            Move-GuardianBridgeMessage -Message $msg -ToFolder 'outbox' | Out-Null
            $retried++
        }
    }
    return @{ retried=$retried; archived=$archived }
}



