# Guardian Continuous Operations Engine (M10).
# Transforms Guardian from on-demand analysis into a continuously operating
# supervisory platform: scheduler, heartbeat, Nexus98 bus consumer, message
# acknowledgement, continuous risk analysis, unified operational state, managed
# runtime config, and component-level failure handling.
# Reuses M0-M9: Health, Bridge, Memory, Checkpoint, Events, Storage, Security,
# DriftGuard, Resource, Agents, Observability, Explanation.

$GuardianOpsDir         = Join-Path $GuardianEnv.Data 'ops'
$GuardianSchedulerState = Join-Path $GuardianOpsDir 'scheduler_state.json'
$GuardianHeartbeatLog   = Join-Path $GuardianOpsDir 'heartbeat.jsonl'
$GuardianRuntimeState   = Join-Path $GuardianOpsDir 'runtime_state.json'
$GuardianRiskLatest     = Join-Path $GuardianOpsDir 'risk_latest.json'
$GuardianOpState        = Join-Path $GuardianOpsDir 'operational_state.json'
$GuardianAckLog         = Join-Path $GuardianOpsDir 'acks.jsonl'
$GuardianRuntimeConfig  = Join-Path $GuardianEnv.Config 'guardian_runtime_config.json'

$GuardianDefaultJobs = @(
    @{ name='HEALTH_SCAN';           intervalSeconds=60;  enabled=$true; description='Health, resource, and communication checks' }
    @{ name='STORAGE_SCAN';          intervalSeconds=300; enabled=$true; description='Entropy analysis, growth tracking, classification' }
    @{ name='EVENT_REVIEW';          intervalSeconds=120; enabled=$true; description='Event analysis, severity review, pattern detection' }
    @{ name='MEMORY_MAINTENANCE';    intervalSeconds=600; enabled=$true; description='Memory cleanup, compression, archival' }
    @{ name='CHECKPOINT_VALIDATION'; intervalSeconds=900; enabled=$true; description='Checkpoint verification, recovery readiness' }
)

function Initialize-GuardianOperations {
    New-Item -ItemType Directory -Force -Path $GuardianOpsDir | Out-Null
    if (-not (Test-Path $GuardianSchedulerState)) {
        $jobs = @()
        foreach ($d in $GuardianDefaultJobs) {
            $jobs += [PSCustomObject]@{ name=$d.name; intervalSeconds=$d.intervalSeconds; enabled=$d.enabled; description=$d.description; lastRun=$null; lastStatus='never'; lastError='' }
        }
        [PSCustomObject]@{ jobs=$jobs; lastCycle=$null; created=(Get-Date).ToString('o') } |
            ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    }
    if (-not (Test-Path $GuardianRuntimeState)) {
        [PSCustomObject]@{ status='stopped'; started=$null; lastHeartbeat=$null; pid=$null; created=(Get-Date).ToString('o') } |
            ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    }
    return $GuardianOpsDir
}

# ---------------------------------------------------------------------------
# Phase 1: Scheduler engine
# ---------------------------------------------------------------------------
function Register-GuardianJob {
    param([Parameter(Mandatory)]$Name, [int]$IntervalSeconds=60, [bool]$Enabled=$true, [string]$Description='')
    Initialize-GuardianOperations | Out-Null
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $found = $false
    for ($i = 0; $i -lt $state.jobs.Count; $i++) {
        if ($state.jobs[$i].name -eq $Name) {
            $state.jobs[$i].intervalSeconds = $IntervalSeconds
            $state.jobs[$i].enabled = $Enabled
            if ($Description) { $state.jobs[$i].description = $Description }
            $found = $true
            break
        }
    }
    if (-not $found) {
        $state.jobs += [PSCustomObject]@{ name=$Name; intervalSeconds=$IntervalSeconds; enabled=$Enabled; description=$Description; lastRun=$null; lastStatus='never'; lastError='' }
    }
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    return (Get-GuardianJob -Name $Name)
}

function Get-GuardianJob {
    param([string]$Name='')
    if (-not (Test-Path $GuardianSchedulerState)) { return @() }
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    if ($Name) { return @($state.jobs | Where-Object { $_.name -eq $Name }) }
    return @($state.jobs)
}

function Invoke-GuardianJob {
    param([Parameter(Mandatory)]$Name)
    Initialize-GuardianOperations | Out-Null
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $idx = -1
    for ($i = 0; $i -lt $state.jobs.Count; $i++) { if ($state.jobs[$i].name -eq $Name) { $idx = $i; break } }
    if ($idx -lt 0) { return [PSCustomObject]@{ name=$Name; status='not_found' } }
    $started = Get-Date
    try {
        switch ($Name) {
            'HEALTH_SCAN'           { $result = Invoke-GuardianHealthScan }
            'STORAGE_SCAN'          { $result = Invoke-GuardianStorageScan }
            'EVENT_REVIEW'          { $result = Invoke-GuardianEventReview }
            'MEMORY_MAINTENANCE'    { $result = Invoke-GuardianMemoryMaintenance }
            'CHECKPOINT_VALIDATION' { $result = Invoke-GuardianCheckpointValidation }
            default                 { $result = [PSCustomObject]@{ note="no handler for $Name" } }
        }
        $state.jobs[$idx].lastRun = $started.ToString('o')
        $state.jobs[$idx].lastStatus = 'ok'
        $state.jobs[$idx].lastError = ''
        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
        return [PSCustomObject]@{ name=$Name; status='ok'; started=$started.ToString('o'); result=$result }
    } catch {
        $state.jobs[$idx].lastRun = $started.ToString('o')
        $state.jobs[$idx].lastStatus = 'failed'
        $state.jobs[$idx].lastError = $_.Exception.Message
        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
        if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
            New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity ERROR -Description "JOB_FAILURE: $Name - $($_.Exception.Message)" -AffectedComponent 'scheduler' | Out-Null
        }
        if (Get-Command Send-GuardianWarningToNexus98Bridge -ErrorAction SilentlyContinue) {
            Send-GuardianWarningToNexus98Bridge -Warning "Job $Name failed: $($_.Exception.Message)" -RiskLevel 'medium' | Out-Null
        }
        return [PSCustomObject]@{ name=$Name; status='failed'; started=$started.ToString('o'); error=$_.Exception.Message }
    }
}

function Invoke-GuardianSchedulerCycle {

    Initialize-GuardianOperations | Out-Null

    $cycleStart = Get-Date

    $results = @()


    $state = Get-Content `
        -Path $GuardianSchedulerState `
        -Encoding UTF8 |
        ConvertFrom-Json



    foreach ($job in $state.jobs) {

        if (-not $job.enabled) {
            continue
        }


        $shouldRun = $false


        if (-not $job.lastRun) {

            $shouldRun = $true

        }
        else {

            $lastRun = [datetime]::Parse($job.lastRun)

            if ((New-TimeSpan -Start $lastRun -End $cycleStart).TotalSeconds -ge $job.intervalSeconds) {

                $shouldRun = $true

            }
        }



        if ($shouldRun) {

            $results += Invoke-GuardianJob -Name $job.name

        }

    }



    # Reload state after jobs.
    # Prevent stale cycle state overwriting job updates.

    $fresh = Get-Content `
        -Path $GuardianSchedulerState `
        -Encoding UTF8 |
        ConvertFrom-Json



    $okCount =
        @($results | Where-Object {
            # Guardian Continuous Operations Engine (M10).
# Transforms Guardian from on-demand analysis into a continuously operating
# supervisory platform: scheduler, heartbeat, Nexus98 bus consumer, message
# acknowledgement, continuous risk analysis, unified operational state, managed
# runtime config, and component-level failure handling.
# Reuses M0-M9: Health, Bridge, Memory, Checkpoint, Events, Storage, Security,
# DriftGuard, Resource, Agents, Observability, Explanation.

$GuardianOpsDir         = Join-Path $GuardianEnv.Data 'ops'
$GuardianSchedulerState = Join-Path $GuardianOpsDir 'scheduler_state.json'
$GuardianHeartbeatLog   = Join-Path $GuardianOpsDir 'heartbeat.jsonl'
$GuardianRuntimeState   = Join-Path $GuardianOpsDir 'runtime_state.json'
$GuardianRiskLatest     = Join-Path $GuardianOpsDir 'risk_latest.json'
$GuardianOpState        = Join-Path $GuardianOpsDir 'operational_state.json'
$GuardianAckLog         = Join-Path $GuardianOpsDir 'acks.jsonl'
$GuardianRuntimeConfig  = Join-Path $GuardianEnv.Config 'guardian_runtime_config.json'

$GuardianDefaultJobs = @(
    @{ name='HEALTH_SCAN';           intervalSeconds=60;  enabled=$true; description='Health, resource, and communication checks' }
    @{ name='STORAGE_SCAN';          intervalSeconds=300; enabled=$true; description='Entropy analysis, growth tracking, classification' }
    @{ name='EVENT_REVIEW';          intervalSeconds=120; enabled=$true; description='Event analysis, severity review, pattern detection' }
    @{ name='MEMORY_MAINTENANCE';    intervalSeconds=600; enabled=$true; description='Memory cleanup, compression, archival' }
    @{ name='CHECKPOINT_VALIDATION'; intervalSeconds=900; enabled=$true; description='Checkpoint verification, recovery readiness' }
)

function Initialize-GuardianOperations {
    New-Item -ItemType Directory -Force -Path $GuardianOpsDir | Out-Null
    if (-not (Test-Path $GuardianSchedulerState)) {
        $jobs = @()
        foreach ($d in $GuardianDefaultJobs) {
            $jobs += [PSCustomObject]@{ name=$d.name; intervalSeconds=$d.intervalSeconds; enabled=$d.enabled; description=$d.description; lastRun=$null; lastStatus='never'; lastError='' }
        }
        [PSCustomObject]@{ jobs=$jobs; lastCycle=$null; created=(Get-Date).ToString('o') } |
            ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    }
    if (-not (Test-Path $GuardianRuntimeState)) {
        [PSCustomObject]@{ status='stopped'; started=$null; lastHeartbeat=$null; pid=$null; created=(Get-Date).ToString('o') } |
            ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    }
    return $GuardianOpsDir
}

# ---------------------------------------------------------------------------
# Phase 1: Scheduler engine
# ---------------------------------------------------------------------------
function Register-GuardianJob {
    param([Parameter(Mandatory)]$Name, [int]$IntervalSeconds=60, [bool]$Enabled=$true, [string]$Description='')
    Initialize-GuardianOperations | Out-Null
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $found = $false
    for ($i = 0; $i -lt $state.jobs.Count; $i++) {
        if ($state.jobs[$i].name -eq $Name) {
            $state.jobs[$i].intervalSeconds = $IntervalSeconds
            $state.jobs[$i].enabled = $Enabled
            if ($Description) { $state.jobs[$i].description = $Description }
            $found = $true
            break
        }
    }
    if (-not $found) {
        $state.jobs += [PSCustomObject]@{ name=$Name; intervalSeconds=$IntervalSeconds; enabled=$Enabled; description=$Description; lastRun=$null; lastStatus='never'; lastError='' }
    }
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    return (Get-GuardianJob -Name $Name)
}

function Get-GuardianJob {
    param([string]$Name='')
    if (-not (Test-Path $GuardianSchedulerState)) { return @() }
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    if ($Name) { return @($state.jobs | Where-Object { $_.name -eq $Name }) }
    return @($state.jobs)
}

function Invoke-GuardianJob {
    param([Parameter(Mandatory)]$Name)
    Initialize-GuardianOperations | Out-Null
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $idx = -1
    for ($i = 0; $i -lt $state.jobs.Count; $i++) { if ($state.jobs[$i].name -eq $Name) { $idx = $i; break } }
    if ($idx -lt 0) { return [PSCustomObject]@{ name=$Name; status='not_found' } }
    $started = Get-Date
    try {
        switch ($Name) {
            'HEALTH_SCAN'           { $result = Invoke-GuardianHealthScan }
            'STORAGE_SCAN'          { $result = Invoke-GuardianStorageScan }
            'EVENT_REVIEW'          { $result = Invoke-GuardianEventReview }
            'MEMORY_MAINTENANCE'    { $result = Invoke-GuardianMemoryMaintenance }
            'CHECKPOINT_VALIDATION' { $result = Invoke-GuardianCheckpointValidation }
            default                 { $result = [PSCustomObject]@{ note="no handler for $Name" } }
        }
        $state.jobs[$idx].lastRun = $started.ToString('o')
        $state.jobs[$idx].lastStatus = 'ok'
        $state.jobs[$idx].lastError = ''
        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
        return [PSCustomObject]@{ name=$Name; status='ok'; started=$started.ToString('o'); result=$result }
    } catch {
        $state.jobs[$idx].lastRun = $started.ToString('o')
        $state.jobs[$idx].lastStatus = 'failed'
        $state.jobs[$idx].lastError = $_.Exception.Message
        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
        if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
            New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity ERROR -Description "JOB_FAILURE: $Name - $($_.Exception.Message)" -AffectedComponent 'scheduler' | Out-Null
        }
        if (Get-Command Send-GuardianWarningToNexus98Bridge -ErrorAction SilentlyContinue) {
            Send-GuardianWarningToNexus98Bridge -Warning "Job $Name failed: $($_.Exception.Message)" -RiskLevel 'medium' | Out-Null
        }
        return [PSCustomObject]@{ name=$Name; status='failed'; started=$started.ToString('o'); error=$_.Exception.Message }
    }
}

function Invoke-GuardianSchedulerCycle {
    Initialize-GuardianOperations | Out-Null
    $now = Get-Date
    $ran = @()
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    foreach ($job in $state.jobs) {
        if (-not $job.enabled) { continue }
        $due = $false
        if (-not $job.lastRun) { $due = $true }
        else {
            $last = [datetime]::Parse($job.lastRun)
            if (($now - $last).TotalSeconds -ge $job.intervalSeconds) { $due = $true }
        }
        if ($due) { $ran += (Invoke-GuardianJob -Name $job.name) }
    }
    # Persist ONLY cycle-level metadata; job state already saved by Invoke-GuardianJob.
    $fresh = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $okCount = @($ran | Where-Object { $_.status -eq 'ok' }).Count
    $failCount = @($ran | Where-Object { $_.status -eq 'failed' }).Count
    $fresh.lastCycle = $now.ToString('o')
    $fresh.cycleDurationMs = [math]::Round(((Get-Date) - $now).TotalMilliseconds, 1)
    $fresh.cycleResult = if ($failCount -eq 0) { 'ok' } else { 'degraded' }
    $fresh.cycleSummary = [PSCustomObject]@{ jobsRun=$ran.Count; ok=$okCount; failed=$failCount }
    $fresh | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    return [PSCustomObject]@{ cycle=$now.ToString('o'); jobsRun=$ran.Count; results=$ran }
}
function Invoke-GuardianHealthScan {
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $res = @{ healthOverall=$health.overallPct; runtimePct=$health.runtimePct; communicationEnabled=if($comm){$comm.enabled}else{$null} }
    if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
        New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity INFO -Description "HEALTH_SCAN ok overall=$($health.overallPct)" -AffectedComponent 'health' | Out-Null
    }
    return $res
}
function Invoke-GuardianStorageScan {
    $entropy = if (Get-Command Get-GuardianStorageEntropy -ErrorAction SilentlyContinue) { Get-GuardianStorageEntropy -SampleCap 800 } else { $null }
    $storage = Get-GuardianStorageHealth
    return @{ storageOverallPct=$storage.overallPct; entropyItems=if($entropy){$entropy.entropyCount}else{$null} }
}
function Invoke-GuardianEventReview {
    $events = @(Get-GuardianEvents -Last 50)
    $sev = $events | Group-Object severity | ForEach-Object { @{ severity=$_.Name; count=$_.Count } }
    $dups = if (Get-Command Get-GuardianEventDuplicates -ErrorAction SilentlyContinue) { (Get-GuardianEventDuplicates).Count } else { 0 }
    return @{ eventCount=$events.Count; bySeverity=$sev; duplicateEvents=$dups }
}
function Invoke-GuardianMemoryMaintenance {
    $life = if (Get-Command Invoke-GuardianMemoryLifecycle -ErrorAction SilentlyContinue) { Invoke-GuardianMemoryLifecycle } else { @{ archived=0; expired=0; retained=0 } }
    $comp = if (Get-Command Compress-GuardianMemory -ErrorAction SilentlyContinue) { (Compress-GuardianMemory).Count } else { 0 }
    return @{ lifecycle=$life; compressed=$comp }
}
function Invoke-GuardianCheckpointValidation {
    $rolling = @(Get-GuardianCheckpoints -Tier rolling).Count
    $milestones = @(Get-GuardianCheckpoints -Tier milestones).Count
    $readiness = if (($rolling + $milestones) -gt 0) { 'ready' } else { 'no-checkpoints' }
    return @{ rolling=$rolling; milestones=$milestones; recoveryReadiness=$readiness }
}

# ---------------------------------------------------------------------------
# Phase 2: Heartbeat
# ---------------------------------------------------------------------------
function Invoke-GuardianHeartbeat {
    Initialize-GuardianOperations | Out-Null
    $health = Get-GuardianHealthScore
    $jobs = @(Get-GuardianJob)
    $activeJobs = @($jobs | Where-Object { $_.enabled -and $_.lastStatus -eq 'ok' }).Count
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $ck = @(Get-GuardianCheckpoints -Tier rolling)
    $lastCk = if ($ck.Count -gt 0) { (($ck | Sort-Object { $_.created } | Select-Object -Last 1).id) } else { $null }
    $warnings = @()
    if ($health.overallPct -lt 50) { $warnings += 'low overall health' }
    if ($comm -and $comm.enabled -eq $false) { $warnings += 'bridge disabled' }
    $record = [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        status='ALIVE'
        health=$health.overallPct
        active_jobs=$activeJobs
        communication_state=if($comm){$comm.enabled}else{$false}
        last_checkpoint=$lastCk
        warnings=$warnings
    }
    $record | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $GuardianHeartbeatLog -Encoding UTF8
    if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
        New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity INFO -Description 'GUARDIAN_ALIVE' -AffectedComponent 'operations' -Metadata @{ health=$health.overallPct; activeJobs=$activeJobs } | Out-Null
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'heartbeat' -Reason 'operational heartbeat' -NewState 'ALIVE' -Validation 'completed' | Out-Null
    }
    $rt = Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json
    $rt.lastHeartbeat = $record.timestamp
    $rt | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    return $record
}

function Get-GuardianHeartbeatStatus {
    if (-not (Test-Path $GuardianHeartbeatLog)) { return $null }
    $lines = Get-Content -Path $GuardianHeartbeatLog -Encoding UTF8 | Where-Object { $_.Trim() }
    if ($lines.Count -eq 0) { return $null }
    return ($lines[-1] | ConvertFrom-Json)
}

# ---------------------------------------------------------------------------
# Phase 3/4: Nexus98 bus consumer + acknowledgement
# ---------------------------------------------------------------------------
function Invoke-GuardianNexus98ConsumerCycle {
    Initialize-GuardianBridge | Out-Null
    $processed = 0
    $completed = Join-Path $GuardianEnv.Root 'communication\completed'
    if (Test-Path $completed) {
        foreach ($f in @(Get-ChildItem -Path $completed -File -Filter *.json -ErrorAction SilentlyContinue)) {
            try {
                $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
                Add-GuardianAck -MessageId $msg.message_id -Stage 'completed' -Note 'delivered to Nexus98 bus'
                $processed++
            } catch {}
        }
    }
    $inbox = Join-Path $GuardianEnv.Root 'communication\inbox'
    if (Test-Path $inbox) {
        foreach ($f in @(Get-ChildItem -Path $inbox -File -Filter *.json -ErrorAction SilentlyContinue)) {
            try {
                $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
                $g = if (Get-Command Invoke-GuardianBridgeGovernance -ErrorAction SilentlyContinue) { Invoke-GuardianBridgeGovernance -Message $msg } else { $null }
                $decision = if ($g) { $g.decision } else { 'BLOCK' }
                Add-GuardianAck -MessageId $msg.message_id -Stage 'processed' -Note "decision=$decision"
                $processed++
            } catch {}
        }
    }
    return [PSCustomObject]@{ processed=$processed; timestamp=(Get-Date).ToString('o') }
}

function Add-GuardianAck {
    param([Parameter(Mandatory)]$MessageId, [Parameter(Mandatory)]$Stage, [string]$Note='', [int]$RetryCount=0, [string]$Resolution='')
    New-Item -ItemType Directory -Force -Path $GuardianOpsDir | Out-Null
    $rec = [PSCustomObject]@{
        message_id=$MessageId
        stage=$Stage
        note=$Note
        retry_count=$RetryCount
        resolution=$Resolution
        timestamp=(Get-Date).ToString('o')
    }
    $rec | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $GuardianAckLog -Encoding UTF8
    return $rec
}

function Get-GuardianAcks {
    param([string]$MessageId='', [int]$Last=0)
    if (-not (Test-Path $GuardianAckLog)) { return @() }
    $recs = Get-Content -Path $GuardianAckLog -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    if ($MessageId) { $recs = @($recs | Where-Object { $_.message_id -eq $MessageId }) }
    if ($Last -gt 0) { $recs = @($recs | Select-Object -Last $Last) }
    return $recs
}

# ---------------------------------------------------------------------------
# Phase 5: Continuous risk analysis
# ---------------------------------------------------------------------------
function Invoke-GuardianRiskAnalysis {
    $now = Get-Date
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $sec = if (Get-Command Get-GuardianSecurityPosture -ErrorAction SilentlyContinue) { Get-GuardianSecurityPosture } else { $null }
    $drift = if (Get-Command Get-GuardianDrift -ErrorAction SilentlyContinue) { @(Get-GuardianDrift) } else { @() }
    $anomalies = if (Get-Command Get-GuardianResourceAnomalies -ErrorAction SilentlyContinue) { @(Get-GuardianResourceAnomalies) } else { @() }

    $factors = @()
    if ($health.overallPct -lt 50) { $factors += 'low overall health' }
    if ($comm -and $comm.enabled -eq $false) { $factors += 'communication disabled' }
    if ($comm -and $comm.successRatePct -lt 80) { $factors += 'communication failures' }
    if ($sec -and $sec.modified.Count -gt 0) { $factors += 'security modification' }
    if ($drift.Count -gt 0) { $factors += 'architecture drift' }
    if ($anomalies.Count -gt 0) { $factors += 'resource anomaly' }

    $score = 100.0
    if ($health.overallPct -lt 50) { $score -= 30 }
    elseif ($health.overallPct -lt 75) { $score -= 15 }
    if ($comm -and $comm.enabled -eq $false) { $score -= 20 }
    if ($sec -and $sec.modified.Count -gt 0) { $score -= 15 }
    $score -= [math]::Min(20, $drift.Count * 2)
    $score -= [math]::Min(15, $anomalies.Count * 3)
    $score = [math]::Max(0, [math]::Round($score, 1))

    $level = if ($score -ge 80) { 'low' } elseif ($score -ge 50) { 'medium' } else { 'high' }
    $recommendation = if ($level -eq 'low') { 'Continue monitoring.' }
                     elseif ($level -eq 'medium') { 'Review flagged factors; consider a checkpoint before risky change.' }
                     else { 'Escalate: create a checkpoint and require review before any change.' }

    $result = [PSCustomObject]@{
        timestamp=$now.ToString('o')
        riskScore=$score
        riskLevel=$level
        factors=$factors
        health=$health.overallPct
        communicationEnabled=if($comm){$comm.enabled}else{$null}
        securityModifications=if($sec){$sec.modified.Count}else{$null}
        driftCount=$drift.Count
        resourceAnomalies=$anomalies.Count
        recommendation=$recommendation
    }
    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRiskLatest -Encoding UTF8
    if (Get-Command Write-GuardianMemory -ErrorAction SilentlyContinue) {
        Write-GuardianMemory -Memory (New-GuardianMemory -Source 'operations' -Category pattern -Importance medium -Description "Risk analysis: score=$score level=$level") | Out-Null
    }
    return $result
}

# ---------------------------------------------------------------------------
# Phase 6: Unified operational state
# ---------------------------------------------------------------------------
function Get-GuardianOperationalState {
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $storage = Get-GuardianStorageHealth
    $mem = Get-GuardianMemorySummary
    $events = @(Get-GuardianEvents -Last 100)
    $rolling = @(Get-GuardianCheckpoints -Tier rolling).Count
    $milestones = @(Get-GuardianCheckpoints -Tier milestones).Count
    $agents = if (Get-Command Get-GuardianAgentRegistrySummary -ErrorAction SilentlyContinue) { Get-GuardianAgentRegistrySummary } else { @{ total=0; active=0; failed=0 } }
    $jobs = @(Get-GuardianJob)
    $risk = if (Test-Path $GuardianRiskLatest) { (Get-Content $GuardianRiskLatest -Encoding UTF8 | ConvertFrom-Json) } else { $null }

    $state = [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        guardianHealth=@{ overallPct=$health.overallPct; runtimePct=$health.runtimePct; storageHygienePct=$health.storageHygienePct }
        nexus98Connection=@{ bridgeEnabled=if($comm){$comm.enabled}else{$false}; commHealthScore=if($comm){$comm.healthScore}else{$null} }
        storageHealth=@{ overallPct=$storage.overallPct }
        memoryHealth=@{ total=$mem.total; avgConfidence=$mem.avgConfidence }
        eventStatus=@{ recentCount=$events.Count; bySeverity=($events | Group-Object severity | ForEach-Object { @{ severity=$_.Name; count=$_.Count } }) }
        checkpointStatus=@{ rolling=$rolling; milestones=$milestones; recoveryReadiness=if(($rolling+$milestones)-gt 0){'ready'}else{'none'} }
        agentStatus=@{ total=$agents.total; active=$agents.active; failed=$agents.failed }
        schedulerStatus=@{ jobCount=$jobs.Count; enabled=@($jobs | Where-Object { $_.enabled }).Count; lastCycle=if(Test-Path $GuardianSchedulerState){(Get-Content $GuardianSchedulerState -Encoding UTF8|ConvertFrom-Json).lastCycle}else{$null} }
        risk=if($risk){@{ score=$risk.riskScore; level=$risk.riskLevel }}else{$null}
    }
    $state | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianOpState -Encoding UTF8
    return $state
}

# ---------------------------------------------------------------------------
# Phase 7: Managed runtime configuration
# ---------------------------------------------------------------------------
function Get-GuardianRuntimeConfig {
    if (Test-Path $GuardianRuntimeConfig) { return (Get-Content -Path $GuardianRuntimeConfig -Encoding UTF8 | ConvertFrom-Json) }
    return $null
}

function Set-GuardianRuntimeConfig {
    param([Parameter(Mandatory)]$Config)
    $ck = New-GuardianSelfModificationCheckpoint -Reason 'runtime config change'
    $Config | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianRuntimeConfig -Encoding UTF8
    $cfg = Get-Content -Path $GuardianRuntimeConfig -Encoding UTF8 | ConvertFrom-Json
    if ($cfg.schedulerIntervals) {
        $cfg.schedulerIntervals.PSObject.Properties | ForEach-Object {
            $j = Get-GuardianJob -Name $_.Name
            if ($j.Count -gt 0) { Register-GuardianJob -Name $_.Name -IntervalSeconds $_.Value -Enabled $true }
        }
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'runtime_config_change' -Reason 'guardian_runtime_config.json updated' -NewState $GuardianRuntimeConfig -Validation 'validated' | Out-Null
    }
    return [PSCustomObject]@{ updated=$true; checkpoint=$ck.id }
}

function New-GuardianRuntimeConfig {
    return [PSCustomObject]@{
        version='1.0.0'
        schedulerIntervals=[PSCustomObject]@{
            HEALTH_SCAN=60; STORAGE_SCAN=300; EVENT_REVIEW=120; MEMORY_MAINTENANCE=600; CHECKPOINT_VALIDATION=900
        }
        monitoringLevel='standard'
        retentionRules=[PSCustomObject]@{ heartbeatDays=30; acksDays=30; eventsMax=1000 }
        communication=[PSCustomObject]@{ bridgeEnabled=$true; requirePermissionForHighRisk=$true }
        logging=[PSCustomObject]@{ audit=$true; level='info' }
    }
}

# ---------------------------------------------------------------------------
# Phase 8: Runtime lifecycle management
# ---------------------------------------------------------------------------
function Start-GuardianOperations {
    param([int]$MaxCycles=0)
    Initialize-GuardianOperations | Out-Null
    if (-not (Test-Path $GuardianRuntimeConfig)) {
        New-GuardianRuntimeConfig | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianRuntimeConfig -Encoding UTF8
    }
    $rt = Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json
    $rt.status='running'; $rt.started=(Get-Date).ToString('o'); $rt.pid=$PID
    $rt | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'operations_start' -Reason 'continuous operations engine started' -NewState 'running' -Validation 'validated' | Out-Null
    }
    $cycles = 0
    $limit = if ($MaxCycles -le 0) { 1 } else { $MaxCycles }
    try {
        while ($cycles -lt $limit) {
            Invoke-GuardianSchedulerCycle | Out-Null
            Invoke-GuardianNexus98ConsumerCycle | Out-Null
            Invoke-GuardianRiskAnalysis | Out-Null
            Invoke-GuardianHeartbeat | Out-Null
            Get-GuardianOperationalState | Out-Null
            $cycles++
        }
    } catch {
        if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
            New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity ERROR -Description "OPERATIONS_LOOP_FAILURE: $($_.Exception.Message)" -AffectedComponent 'operations' | Out-Null
        }
    }
    return [PSCustomObject]@{ status='running'; cyclesRun=$cycles; started=$rt.started }
}

function Stop-GuardianOperations {
    Initialize-GuardianOperations | Out-Null
    $prev = if (Test-Path $GuardianRuntimeState) { Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $obj = [PSCustomObject]@{
        status='stopped'
        started=if($prev){$prev.started}else{$null}
        pid=if($prev){$prev.pid}else{$null}
        lastHeartbeat=if($prev){$prev.lastHeartbeat}else{$null}
        stopped=(Get-Date).ToString('o')
        created=if($prev){$prev.created}else{(Get-Date).ToString('o')}
    }
    $obj | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'operations_stop' -Reason 'continuous operations engine stopped' -NewState 'stopped' -Validation 'completed' | Out-Null
    }
    return [PSCustomObject]@{ status='stopped'; stopped=$obj.stopped }
}

function Get-GuardianOperationsStatus {
    if (-not (Test-Path $GuardianRuntimeState)) { return $null }
    return (Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json)
}

.status -eq "ok"
        }).Count



    $failCount =
        @($results | Where-Object {
            # Guardian Continuous Operations Engine (M10).
# Transforms Guardian from on-demand analysis into a continuously operating
# supervisory platform: scheduler, heartbeat, Nexus98 bus consumer, message
# acknowledgement, continuous risk analysis, unified operational state, managed
# runtime config, and component-level failure handling.
# Reuses M0-M9: Health, Bridge, Memory, Checkpoint, Events, Storage, Security,
# DriftGuard, Resource, Agents, Observability, Explanation.

$GuardianOpsDir         = Join-Path $GuardianEnv.Data 'ops'
$GuardianSchedulerState = Join-Path $GuardianOpsDir 'scheduler_state.json'
$GuardianHeartbeatLog   = Join-Path $GuardianOpsDir 'heartbeat.jsonl'
$GuardianRuntimeState   = Join-Path $GuardianOpsDir 'runtime_state.json'
$GuardianRiskLatest     = Join-Path $GuardianOpsDir 'risk_latest.json'
$GuardianOpState        = Join-Path $GuardianOpsDir 'operational_state.json'
$GuardianAckLog         = Join-Path $GuardianOpsDir 'acks.jsonl'
$GuardianRuntimeConfig  = Join-Path $GuardianEnv.Config 'guardian_runtime_config.json'

$GuardianDefaultJobs = @(
    @{ name='HEALTH_SCAN';           intervalSeconds=60;  enabled=$true; description='Health, resource, and communication checks' }
    @{ name='STORAGE_SCAN';          intervalSeconds=300; enabled=$true; description='Entropy analysis, growth tracking, classification' }
    @{ name='EVENT_REVIEW';          intervalSeconds=120; enabled=$true; description='Event analysis, severity review, pattern detection' }
    @{ name='MEMORY_MAINTENANCE';    intervalSeconds=600; enabled=$true; description='Memory cleanup, compression, archival' }
    @{ name='CHECKPOINT_VALIDATION'; intervalSeconds=900; enabled=$true; description='Checkpoint verification, recovery readiness' }
)

function Initialize-GuardianOperations {
    New-Item -ItemType Directory -Force -Path $GuardianOpsDir | Out-Null
    if (-not (Test-Path $GuardianSchedulerState)) {
        $jobs = @()
        foreach ($d in $GuardianDefaultJobs) {
            $jobs += [PSCustomObject]@{ name=$d.name; intervalSeconds=$d.intervalSeconds; enabled=$d.enabled; description=$d.description; lastRun=$null; lastStatus='never'; lastError='' }
        }
        [PSCustomObject]@{ jobs=$jobs; lastCycle=$null; created=(Get-Date).ToString('o') } |
            ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    }
    if (-not (Test-Path $GuardianRuntimeState)) {
        [PSCustomObject]@{ status='stopped'; started=$null; lastHeartbeat=$null; pid=$null; created=(Get-Date).ToString('o') } |
            ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    }
    return $GuardianOpsDir
}

# ---------------------------------------------------------------------------
# Phase 1: Scheduler engine
# ---------------------------------------------------------------------------
function Register-GuardianJob {
    param([Parameter(Mandatory)]$Name, [int]$IntervalSeconds=60, [bool]$Enabled=$true, [string]$Description='')
    Initialize-GuardianOperations | Out-Null
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $found = $false
    for ($i = 0; $i -lt $state.jobs.Count; $i++) {
        if ($state.jobs[$i].name -eq $Name) {
            $state.jobs[$i].intervalSeconds = $IntervalSeconds
            $state.jobs[$i].enabled = $Enabled
            if ($Description) { $state.jobs[$i].description = $Description }
            $found = $true
            break
        }
    }
    if (-not $found) {
        $state.jobs += [PSCustomObject]@{ name=$Name; intervalSeconds=$IntervalSeconds; enabled=$Enabled; description=$Description; lastRun=$null; lastStatus='never'; lastError='' }
    }
    $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    return (Get-GuardianJob -Name $Name)
}

function Get-GuardianJob {
    param([string]$Name='')
    if (-not (Test-Path $GuardianSchedulerState)) { return @() }
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    if ($Name) { return @($state.jobs | Where-Object { $_.name -eq $Name }) }
    return @($state.jobs)
}

function Invoke-GuardianJob {
    param([Parameter(Mandatory)]$Name)
    Initialize-GuardianOperations | Out-Null
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $idx = -1
    for ($i = 0; $i -lt $state.jobs.Count; $i++) { if ($state.jobs[$i].name -eq $Name) { $idx = $i; break } }
    if ($idx -lt 0) { return [PSCustomObject]@{ name=$Name; status='not_found' } }
    $started = Get-Date
    try {
        switch ($Name) {
            'HEALTH_SCAN'           { $result = Invoke-GuardianHealthScan }
            'STORAGE_SCAN'          { $result = Invoke-GuardianStorageScan }
            'EVENT_REVIEW'          { $result = Invoke-GuardianEventReview }
            'MEMORY_MAINTENANCE'    { $result = Invoke-GuardianMemoryMaintenance }
            'CHECKPOINT_VALIDATION' { $result = Invoke-GuardianCheckpointValidation }
            default                 { $result = [PSCustomObject]@{ note="no handler for $Name" } }
        }
        $state.jobs[$idx].lastRun = $started.ToString('o')
        $state.jobs[$idx].lastStatus = 'ok'
        $state.jobs[$idx].lastError = ''
        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
        return [PSCustomObject]@{ name=$Name; status='ok'; started=$started.ToString('o'); result=$result }
    } catch {
        $state.jobs[$idx].lastRun = $started.ToString('o')
        $state.jobs[$idx].lastStatus = 'failed'
        $state.jobs[$idx].lastError = $_.Exception.Message
        $state | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
        if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
            New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity ERROR -Description "JOB_FAILURE: $Name - $($_.Exception.Message)" -AffectedComponent 'scheduler' | Out-Null
        }
        if (Get-Command Send-GuardianWarningToNexus98Bridge -ErrorAction SilentlyContinue) {
            Send-GuardianWarningToNexus98Bridge -Warning "Job $Name failed: $($_.Exception.Message)" -RiskLevel 'medium' | Out-Null
        }
        return [PSCustomObject]@{ name=$Name; status='failed'; started=$started.ToString('o'); error=$_.Exception.Message }
    }
}

function Invoke-GuardianSchedulerCycle {
    Initialize-GuardianOperations | Out-Null
    $now = Get-Date
    $ran = @()
    $state = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    foreach ($job in $state.jobs) {
        if (-not $job.enabled) { continue }
        $due = $false
        if (-not $job.lastRun) { $due = $true }
        else {
            $last = [datetime]::Parse($job.lastRun)
            if (($now - $last).TotalSeconds -ge $job.intervalSeconds) { $due = $true }
        }
        if ($due) { $ran += (Invoke-GuardianJob -Name $job.name) }
    }
    # Persist ONLY cycle-level metadata; job state already saved by Invoke-GuardianJob.
    $fresh = Get-Content -Path $GuardianSchedulerState -Encoding UTF8 | ConvertFrom-Json
    $okCount = @($ran | Where-Object { $_.status -eq 'ok' }).Count
    $failCount = @($ran | Where-Object { $_.status -eq 'failed' }).Count
    $fresh.lastCycle = $now.ToString('o')
    $fresh.cycleDurationMs = [math]::Round(((Get-Date) - $now).TotalMilliseconds, 1)
    $fresh.cycleResult = if ($failCount -eq 0) { 'ok' } else { 'degraded' }
    $fresh.cycleSummary = [PSCustomObject]@{ jobsRun=$ran.Count; ok=$okCount; failed=$failCount }
    $fresh | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianSchedulerState -Encoding UTF8
    return [PSCustomObject]@{ cycle=$now.ToString('o'); jobsRun=$ran.Count; results=$ran }
}
function Invoke-GuardianHealthScan {
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $res = @{ healthOverall=$health.overallPct; runtimePct=$health.runtimePct; communicationEnabled=if($comm){$comm.enabled}else{$null} }
    if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
        New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity INFO -Description "HEALTH_SCAN ok overall=$($health.overallPct)" -AffectedComponent 'health' | Out-Null
    }
    return $res
}
function Invoke-GuardianStorageScan {
    $entropy = if (Get-Command Get-GuardianStorageEntropy -ErrorAction SilentlyContinue) { Get-GuardianStorageEntropy -SampleCap 800 } else { $null }
    $storage = Get-GuardianStorageHealth
    return @{ storageOverallPct=$storage.overallPct; entropyItems=if($entropy){$entropy.entropyCount}else{$null} }
}
function Invoke-GuardianEventReview {
    $events = @(Get-GuardianEvents -Last 50)
    $sev = $events | Group-Object severity | ForEach-Object { @{ severity=$_.Name; count=$_.Count } }
    $dups = if (Get-Command Get-GuardianEventDuplicates -ErrorAction SilentlyContinue) { (Get-GuardianEventDuplicates).Count } else { 0 }
    return @{ eventCount=$events.Count; bySeverity=$sev; duplicateEvents=$dups }
}
function Invoke-GuardianMemoryMaintenance {
    $life = if (Get-Command Invoke-GuardianMemoryLifecycle -ErrorAction SilentlyContinue) { Invoke-GuardianMemoryLifecycle } else { @{ archived=0; expired=0; retained=0 } }
    $comp = if (Get-Command Compress-GuardianMemory -ErrorAction SilentlyContinue) { (Compress-GuardianMemory).Count } else { 0 }
    return @{ lifecycle=$life; compressed=$comp }
}
function Invoke-GuardianCheckpointValidation {
    $rolling = @(Get-GuardianCheckpoints -Tier rolling).Count
    $milestones = @(Get-GuardianCheckpoints -Tier milestones).Count
    $readiness = if (($rolling + $milestones) -gt 0) { 'ready' } else { 'no-checkpoints' }
    return @{ rolling=$rolling; milestones=$milestones; recoveryReadiness=$readiness }
}

# ---------------------------------------------------------------------------
# Phase 2: Heartbeat
# ---------------------------------------------------------------------------
function Invoke-GuardianHeartbeat {
    Initialize-GuardianOperations | Out-Null
    $health = Get-GuardianHealthScore
    $jobs = @(Get-GuardianJob)
    $activeJobs = @($jobs | Where-Object { $_.enabled -and $_.lastStatus -eq 'ok' }).Count
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $ck = @(Get-GuardianCheckpoints -Tier rolling)
    $lastCk = if ($ck.Count -gt 0) { (($ck | Sort-Object { $_.created } | Select-Object -Last 1).id) } else { $null }
    $warnings = @()
    if ($health.overallPct -lt 50) { $warnings += 'low overall health' }
    if ($comm -and $comm.enabled -eq $false) { $warnings += 'bridge disabled' }
    $record = [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        status='ALIVE'
        health=$health.overallPct
        active_jobs=$activeJobs
        communication_state=if($comm){$comm.enabled}else{$false}
        last_checkpoint=$lastCk
        warnings=$warnings
    }
    $record | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $GuardianHeartbeatLog -Encoding UTF8
    if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
        New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity INFO -Description 'GUARDIAN_ALIVE' -AffectedComponent 'operations' -Metadata @{ health=$health.overallPct; activeJobs=$activeJobs } | Out-Null
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'heartbeat' -Reason 'operational heartbeat' -NewState 'ALIVE' -Validation 'completed' | Out-Null
    }
    $rt = Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json
    $rt.lastHeartbeat = $record.timestamp
    $rt | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    return $record
}

function Get-GuardianHeartbeatStatus {
    if (-not (Test-Path $GuardianHeartbeatLog)) { return $null }
    $lines = Get-Content -Path $GuardianHeartbeatLog -Encoding UTF8 | Where-Object { $_.Trim() }
    if ($lines.Count -eq 0) { return $null }
    return ($lines[-1] | ConvertFrom-Json)
}

# ---------------------------------------------------------------------------
# Phase 3/4: Nexus98 bus consumer + acknowledgement
# ---------------------------------------------------------------------------
function Invoke-GuardianNexus98ConsumerCycle {
    Initialize-GuardianBridge | Out-Null
    $processed = 0
    $completed = Join-Path $GuardianEnv.Root 'communication\completed'
    if (Test-Path $completed) {
        foreach ($f in @(Get-ChildItem -Path $completed -File -Filter *.json -ErrorAction SilentlyContinue)) {
            try {
                $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
                Add-GuardianAck -MessageId $msg.message_id -Stage 'completed' -Note 'delivered to Nexus98 bus'
                $processed++
            } catch {}
        }
    }
    $inbox = Join-Path $GuardianEnv.Root 'communication\inbox'
    if (Test-Path $inbox) {
        foreach ($f in @(Get-ChildItem -Path $inbox -File -Filter *.json -ErrorAction SilentlyContinue)) {
            try {
                $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
                $g = if (Get-Command Invoke-GuardianBridgeGovernance -ErrorAction SilentlyContinue) { Invoke-GuardianBridgeGovernance -Message $msg } else { $null }
                $decision = if ($g) { $g.decision } else { 'BLOCK' }
                Add-GuardianAck -MessageId $msg.message_id -Stage 'processed' -Note "decision=$decision"
                $processed++
            } catch {}
        }
    }
    return [PSCustomObject]@{ processed=$processed; timestamp=(Get-Date).ToString('o') }
}

function Add-GuardianAck {
    param([Parameter(Mandatory)]$MessageId, [Parameter(Mandatory)]$Stage, [string]$Note='', [int]$RetryCount=0, [string]$Resolution='')
    New-Item -ItemType Directory -Force -Path $GuardianOpsDir | Out-Null
    $rec = [PSCustomObject]@{
        message_id=$MessageId
        stage=$Stage
        note=$Note
        retry_count=$RetryCount
        resolution=$Resolution
        timestamp=(Get-Date).ToString('o')
    }
    $rec | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $GuardianAckLog -Encoding UTF8
    return $rec
}

function Get-GuardianAcks {
    param([string]$MessageId='', [int]$Last=0)
    if (-not (Test-Path $GuardianAckLog)) { return @() }
    $recs = Get-Content -Path $GuardianAckLog -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    if ($MessageId) { $recs = @($recs | Where-Object { $_.message_id -eq $MessageId }) }
    if ($Last -gt 0) { $recs = @($recs | Select-Object -Last $Last) }
    return $recs
}

# ---------------------------------------------------------------------------
# Phase 5: Continuous risk analysis
# ---------------------------------------------------------------------------
function Invoke-GuardianRiskAnalysis {
    $now = Get-Date
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $sec = if (Get-Command Get-GuardianSecurityPosture -ErrorAction SilentlyContinue) { Get-GuardianSecurityPosture } else { $null }
    $drift = if (Get-Command Get-GuardianDrift -ErrorAction SilentlyContinue) { @(Get-GuardianDrift) } else { @() }
    $anomalies = if (Get-Command Get-GuardianResourceAnomalies -ErrorAction SilentlyContinue) { @(Get-GuardianResourceAnomalies) } else { @() }

    $factors = @()
    if ($health.overallPct -lt 50) { $factors += 'low overall health' }
    if ($comm -and $comm.enabled -eq $false) { $factors += 'communication disabled' }
    if ($comm -and $comm.successRatePct -lt 80) { $factors += 'communication failures' }
    if ($sec -and $sec.modified.Count -gt 0) { $factors += 'security modification' }
    if ($drift.Count -gt 0) { $factors += 'architecture drift' }
    if ($anomalies.Count -gt 0) { $factors += 'resource anomaly' }

    $score = 100.0
    if ($health.overallPct -lt 50) { $score -= 30 }
    elseif ($health.overallPct -lt 75) { $score -= 15 }
    if ($comm -and $comm.enabled -eq $false) { $score -= 20 }
    if ($sec -and $sec.modified.Count -gt 0) { $score -= 15 }
    $score -= [math]::Min(20, $drift.Count * 2)
    $score -= [math]::Min(15, $anomalies.Count * 3)
    $score = [math]::Max(0, [math]::Round($score, 1))

    $level = if ($score -ge 80) { 'low' } elseif ($score -ge 50) { 'medium' } else { 'high' }
    $recommendation = if ($level -eq 'low') { 'Continue monitoring.' }
                     elseif ($level -eq 'medium') { 'Review flagged factors; consider a checkpoint before risky change.' }
                     else { 'Escalate: create a checkpoint and require review before any change.' }

    $result = [PSCustomObject]@{
        timestamp=$now.ToString('o')
        riskScore=$score
        riskLevel=$level
        factors=$factors
        health=$health.overallPct
        communicationEnabled=if($comm){$comm.enabled}else{$null}
        securityModifications=if($sec){$sec.modified.Count}else{$null}
        driftCount=$drift.Count
        resourceAnomalies=$anomalies.Count
        recommendation=$recommendation
    }
    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRiskLatest -Encoding UTF8
    if (Get-Command Write-GuardianMemory -ErrorAction SilentlyContinue) {
        Write-GuardianMemory -Memory (New-GuardianMemory -Source 'operations' -Category pattern -Importance medium -Description "Risk analysis: score=$score level=$level") | Out-Null
    }
    return $result
}

# ---------------------------------------------------------------------------
# Phase 6: Unified operational state
# ---------------------------------------------------------------------------
function Get-GuardianOperationalState {
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $storage = Get-GuardianStorageHealth
    $mem = Get-GuardianMemorySummary
    $events = @(Get-GuardianEvents -Last 100)
    $rolling = @(Get-GuardianCheckpoints -Tier rolling).Count
    $milestones = @(Get-GuardianCheckpoints -Tier milestones).Count
    $agents = if (Get-Command Get-GuardianAgentRegistrySummary -ErrorAction SilentlyContinue) { Get-GuardianAgentRegistrySummary } else { @{ total=0; active=0; failed=0 } }
    $jobs = @(Get-GuardianJob)
    $risk = if (Test-Path $GuardianRiskLatest) { (Get-Content $GuardianRiskLatest -Encoding UTF8 | ConvertFrom-Json) } else { $null }

    $state = [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        guardianHealth=@{ overallPct=$health.overallPct; runtimePct=$health.runtimePct; storageHygienePct=$health.storageHygienePct }
        nexus98Connection=@{ bridgeEnabled=if($comm){$comm.enabled}else{$false}; commHealthScore=if($comm){$comm.healthScore}else{$null} }
        storageHealth=@{ overallPct=$storage.overallPct }
        memoryHealth=@{ total=$mem.total; avgConfidence=$mem.avgConfidence }
        eventStatus=@{ recentCount=$events.Count; bySeverity=($events | Group-Object severity | ForEach-Object { @{ severity=$_.Name; count=$_.Count } }) }
        checkpointStatus=@{ rolling=$rolling; milestones=$milestones; recoveryReadiness=if(($rolling+$milestones)-gt 0){'ready'}else{'none'} }
        agentStatus=@{ total=$agents.total; active=$agents.active; failed=$agents.failed }
        schedulerStatus=@{ jobCount=$jobs.Count; enabled=@($jobs | Where-Object { $_.enabled }).Count; lastCycle=if(Test-Path $GuardianSchedulerState){(Get-Content $GuardianSchedulerState -Encoding UTF8|ConvertFrom-Json).lastCycle}else{$null} }
        risk=if($risk){@{ score=$risk.riskScore; level=$risk.riskLevel }}else{$null}
    }
    $state | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianOpState -Encoding UTF8
    return $state
}

# ---------------------------------------------------------------------------
# Phase 7: Managed runtime configuration
# ---------------------------------------------------------------------------
function Get-GuardianRuntimeConfig {
    if (Test-Path $GuardianRuntimeConfig) { return (Get-Content -Path $GuardianRuntimeConfig -Encoding UTF8 | ConvertFrom-Json) }
    return $null
}

function Set-GuardianRuntimeConfig {
    param([Parameter(Mandatory)]$Config)
    $ck = New-GuardianSelfModificationCheckpoint -Reason 'runtime config change'
    $Config | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianRuntimeConfig -Encoding UTF8
    $cfg = Get-Content -Path $GuardianRuntimeConfig -Encoding UTF8 | ConvertFrom-Json
    if ($cfg.schedulerIntervals) {
        $cfg.schedulerIntervals.PSObject.Properties | ForEach-Object {
            $j = Get-GuardianJob -Name $_.Name
            if ($j.Count -gt 0) { Register-GuardianJob -Name $_.Name -IntervalSeconds $_.Value -Enabled $true }
        }
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'runtime_config_change' -Reason 'guardian_runtime_config.json updated' -NewState $GuardianRuntimeConfig -Validation 'validated' | Out-Null
    }
    return [PSCustomObject]@{ updated=$true; checkpoint=$ck.id }
}

function New-GuardianRuntimeConfig {
    return [PSCustomObject]@{
        version='1.0.0'
        schedulerIntervals=[PSCustomObject]@{
            HEALTH_SCAN=60; STORAGE_SCAN=300; EVENT_REVIEW=120; MEMORY_MAINTENANCE=600; CHECKPOINT_VALIDATION=900
        }
        monitoringLevel='standard'
        retentionRules=[PSCustomObject]@{ heartbeatDays=30; acksDays=30; eventsMax=1000 }
        communication=[PSCustomObject]@{ bridgeEnabled=$true; requirePermissionForHighRisk=$true }
        logging=[PSCustomObject]@{ audit=$true; level='info' }
    }
}

# ---------------------------------------------------------------------------
# Phase 8: Runtime lifecycle management
# ---------------------------------------------------------------------------
function Start-GuardianOperations {
    param([int]$MaxCycles=0)
    Initialize-GuardianOperations | Out-Null
    if (-not (Test-Path $GuardianRuntimeConfig)) {
        New-GuardianRuntimeConfig | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianRuntimeConfig -Encoding UTF8
    }
    $rt = Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json
    $rt.status='running'; $rt.started=(Get-Date).ToString('o'); $rt.pid=$PID
    $rt | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'operations_start' -Reason 'continuous operations engine started' -NewState 'running' -Validation 'validated' | Out-Null
    }
    $cycles = 0
    $limit = if ($MaxCycles -le 0) { 1 } else { $MaxCycles }
    try {
        while ($cycles -lt $limit) {
            Invoke-GuardianSchedulerCycle | Out-Null
            Invoke-GuardianNexus98ConsumerCycle | Out-Null
            Invoke-GuardianRiskAnalysis | Out-Null
            Invoke-GuardianHeartbeat | Out-Null
            Get-GuardianOperationalState | Out-Null
            $cycles++
        }
    } catch {
        if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
            New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity ERROR -Description "OPERATIONS_LOOP_FAILURE: $($_.Exception.Message)" -AffectedComponent 'operations' | Out-Null
        }
    }
    return [PSCustomObject]@{ status='running'; cyclesRun=$cycles; started=$rt.started }
}

function Stop-GuardianOperations {
    Initialize-GuardianOperations | Out-Null
    $prev = if (Test-Path $GuardianRuntimeState) { Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $obj = [PSCustomObject]@{
        status='stopped'
        started=if($prev){$prev.started}else{$null}
        pid=if($prev){$prev.pid}else{$null}
        lastHeartbeat=if($prev){$prev.lastHeartbeat}else{$null}
        stopped=(Get-Date).ToString('o')
        created=if($prev){$prev.created}else{(Get-Date).ToString('o')}
    }
    $obj | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'operations_stop' -Reason 'continuous operations engine stopped' -NewState 'stopped' -Validation 'completed' | Out-Null
    }
    return [PSCustomObject]@{ status='stopped'; stopped=$obj.stopped }
}

function Get-GuardianOperationsStatus {
    if (-not (Test-Path $GuardianRuntimeState)) { return $null }
    return (Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json)
}

.status -eq "failed"
        }).Count



    $fresh.lastCycle =
        $cycleStart.ToString("o")



    $fresh.cycleDurationMs =
        [math]::Round(
            ((Get-Date)-$cycleStart).TotalMilliseconds,
            2
        )



    $fresh.cycleResult =
        if ($failCount -eq 0) {
            "ok"
        }
        else {
            "degraded"
        }



    $fresh.cycleSummary = [PSCustomObject]@{

        jobsRun = $results.Count

        ok = $okCount

        failed = $failCount

    }



    $fresh |
        ConvertTo-Json -Depth 20 |
        Set-Content `
            -Path $GuardianSchedulerState `
            -Encoding UTF8



    return [PSCustomObject]@{

        cycle = $cycleStart.ToString("o")

        jobsRun = $results.Count

        results = $results

    }

}
function Invoke-GuardianHealthScan {
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $res = @{ healthOverall=$health.overallPct; runtimePct=$health.runtimePct; communicationEnabled=if($comm){$comm.enabled}else{$null} }
    if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
        New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity INFO -Description "HEALTH_SCAN ok overall=$($health.overallPct)" -AffectedComponent 'health' | Out-Null
    }
    return $res
}
function Invoke-GuardianStorageScan {
    $entropy = if (Get-Command Get-GuardianStorageEntropy -ErrorAction SilentlyContinue) { Get-GuardianStorageEntropy -SampleCap 800 } else { $null }
    $storage = Get-GuardianStorageHealth
    return @{ storageOverallPct=$storage.overallPct; entropyItems=if($entropy){$entropy.entropyCount}else{$null} }
}
function Invoke-GuardianEventReview {
    $events = @(Get-GuardianEvents -Last 50)
    $sev = $events | Group-Object severity | ForEach-Object { @{ severity=$_.Name; count=$_.Count } }
    $dups = if (Get-Command Get-GuardianEventDuplicates -ErrorAction SilentlyContinue) { (Get-GuardianEventDuplicates).Count } else { 0 }
    return @{ eventCount=$events.Count; bySeverity=$sev; duplicateEvents=$dups }
}
function Invoke-GuardianMemoryMaintenance {
    $life = if (Get-Command Invoke-GuardianMemoryLifecycle -ErrorAction SilentlyContinue) { Invoke-GuardianMemoryLifecycle } else { @{ archived=0; expired=0; retained=0 } }
    $comp = if (Get-Command Compress-GuardianMemory -ErrorAction SilentlyContinue) { (Compress-GuardianMemory).Count } else { 0 }
    return @{ lifecycle=$life; compressed=$comp }
}
function Invoke-GuardianCheckpointValidation {
    $rolling = @(Get-GuardianCheckpoints -Tier rolling).Count
    $milestones = @(Get-GuardianCheckpoints -Tier milestones).Count
    $readiness = if (($rolling + $milestones) -gt 0) { 'ready' } else { 'no-checkpoints' }
    return @{ rolling=$rolling; milestones=$milestones; recoveryReadiness=$readiness }
}

# ---------------------------------------------------------------------------
# Phase 2: Heartbeat
# ---------------------------------------------------------------------------
function Invoke-GuardianHeartbeat {
    Initialize-GuardianOperations | Out-Null
    $health = Get-GuardianHealthScore
    $jobs = @(Get-GuardianJob)
    $activeJobs = @($jobs | Where-Object { $_.enabled -and $_.lastStatus -eq 'ok' }).Count
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $ck = @(Get-GuardianCheckpoints -Tier rolling)
    $lastCk = if ($ck.Count -gt 0) { (($ck | Sort-Object { $_.created } | Select-Object -Last 1).id) } else { $null }
    $warnings = @()
    if ($health.overallPct -lt 50) { $warnings += 'low overall health' }
    if ($comm -and $comm.enabled -eq $false) { $warnings += 'bridge disabled' }
    $record = [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        status='ALIVE'
        health=$health.overallPct
        active_jobs=$activeJobs
        communication_state=if($comm){$comm.enabled}else{$false}
        last_checkpoint=$lastCk
        warnings=$warnings
    }
    $record | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $GuardianHeartbeatLog -Encoding UTF8
    if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
        New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity INFO -Description 'GUARDIAN_ALIVE' -AffectedComponent 'operations' -Metadata @{ health=$health.overallPct; activeJobs=$activeJobs } | Out-Null
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'heartbeat' -Reason 'operational heartbeat' -NewState 'ALIVE' -Validation 'completed' | Out-Null
    }
    $rt = Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json
    $rt.lastHeartbeat = $record.timestamp
    $rt | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    return $record
}

function Get-GuardianHeartbeatStatus {
    if (-not (Test-Path $GuardianHeartbeatLog)) { return $null }
    $lines = Get-Content -Path $GuardianHeartbeatLog -Encoding UTF8 | Where-Object { $_.Trim() }
    if ($lines.Count -eq 0) { return $null }
    return ($lines[-1] | ConvertFrom-Json)
}

# ---------------------------------------------------------------------------
# Phase 3/4: Nexus98 bus consumer + acknowledgement
# ---------------------------------------------------------------------------
function Invoke-GuardianNexus98ConsumerCycle {
    Initialize-GuardianBridge | Out-Null
    $processed = 0
    $completed = Join-Path $GuardianEnv.Root 'communication\completed'
    if (Test-Path $completed) {
        foreach ($f in @(Get-ChildItem -Path $completed -File -Filter *.json -ErrorAction SilentlyContinue)) {
            try {
                $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
                Add-GuardianAck -MessageId $msg.message_id -Stage 'completed' -Note 'delivered to Nexus98 bus'
                $processed++
            } catch {}
        }
    }
    $inbox = Join-Path $GuardianEnv.Root 'communication\inbox'
    if (Test-Path $inbox) {
        foreach ($f in @(Get-ChildItem -Path $inbox -File -Filter *.json -ErrorAction SilentlyContinue)) {
            try {
                $msg = Get-Content -Path $f.FullName -Encoding UTF8 | ConvertFrom-Json
                $g = if (Get-Command Invoke-GuardianBridgeGovernance -ErrorAction SilentlyContinue) { Invoke-GuardianBridgeGovernance -Message $msg } else { $null }
                $decision = if ($g) { $g.decision } else { 'BLOCK' }
                Add-GuardianAck -MessageId $msg.message_id -Stage 'processed' -Note "decision=$decision"
                $processed++
            } catch {}
        }
    }
    return [PSCustomObject]@{ processed=$processed; timestamp=(Get-Date).ToString('o') }
}

function Add-GuardianAck {
    param([Parameter(Mandatory)]$MessageId, [Parameter(Mandatory)]$Stage, [string]$Note='', [int]$RetryCount=0, [string]$Resolution='')
    New-Item -ItemType Directory -Force -Path $GuardianOpsDir | Out-Null
    $rec = [PSCustomObject]@{
        message_id=$MessageId
        stage=$Stage
        note=$Note
        retry_count=$RetryCount
        resolution=$Resolution
        timestamp=(Get-Date).ToString('o')
    }
    $rec | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $GuardianAckLog -Encoding UTF8
    return $rec
}

function Get-GuardianAcks {
    param([string]$MessageId='', [int]$Last=0)
    if (-not (Test-Path $GuardianAckLog)) { return @() }
    $recs = Get-Content -Path $GuardianAckLog -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    if ($MessageId) { $recs = @($recs | Where-Object { $_.message_id -eq $MessageId }) }
    if ($Last -gt 0) { $recs = @($recs | Select-Object -Last $Last) }
    return $recs
}

# ---------------------------------------------------------------------------
# Phase 5: Continuous risk analysis
# ---------------------------------------------------------------------------
function Invoke-GuardianRiskAnalysis {
    $now = Get-Date
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $sec = if (Get-Command Get-GuardianSecurityPosture -ErrorAction SilentlyContinue) { Get-GuardianSecurityPosture } else { $null }
    $drift = if (Get-Command Get-GuardianDrift -ErrorAction SilentlyContinue) { @(Get-GuardianDrift) } else { @() }
    $anomalies = if (Get-Command Get-GuardianResourceAnomalies -ErrorAction SilentlyContinue) { @(Get-GuardianResourceAnomalies) } else { @() }

    $factors = @()
    if ($health.overallPct -lt 50) { $factors += 'low overall health' }
    if ($comm -and $comm.enabled -eq $false) { $factors += 'communication disabled' }
    if ($comm -and $comm.successRatePct -lt 80) { $factors += 'communication failures' }
    if ($sec -and $sec.modified.Count -gt 0) { $factors += 'security modification' }
    if ($drift.Count -gt 0) { $factors += 'architecture drift' }
    if ($anomalies.Count -gt 0) { $factors += 'resource anomaly' }

    $score = 100.0
    if ($health.overallPct -lt 50) { $score -= 30 }
    elseif ($health.overallPct -lt 75) { $score -= 15 }
    if ($comm -and $comm.enabled -eq $false) { $score -= 20 }
    if ($sec -and $sec.modified.Count -gt 0) { $score -= 15 }
    $score -= [math]::Min(20, $drift.Count * 2)
    $score -= [math]::Min(15, $anomalies.Count * 3)
    $score = [math]::Max(0, [math]::Round($score, 1))

    $level = if ($score -ge 80) { 'low' } elseif ($score -ge 50) { 'medium' } else { 'high' }
    $recommendation = if ($level -eq 'low') { 'Continue monitoring.' }
                     elseif ($level -eq 'medium') { 'Review flagged factors; consider a checkpoint before risky change.' }
                     else { 'Escalate: create a checkpoint and require review before any change.' }

    $result = [PSCustomObject]@{
        timestamp=$now.ToString('o')
        riskScore=$score
        riskLevel=$level
        factors=$factors
        health=$health.overallPct
        communicationEnabled=if($comm){$comm.enabled}else{$null}
        securityModifications=if($sec){$sec.modified.Count}else{$null}
        driftCount=$drift.Count
        resourceAnomalies=$anomalies.Count
        recommendation=$recommendation
    }
    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRiskLatest -Encoding UTF8
    if (Get-Command Write-GuardianMemory -ErrorAction SilentlyContinue) {
        Write-GuardianMemory -Memory (New-GuardianMemory -Source 'operations' -Category pattern -Importance medium -Description "Risk analysis: score=$score level=$level") | Out-Null
    }
    return $result
}

# ---------------------------------------------------------------------------
# Phase 6: Unified operational state
# ---------------------------------------------------------------------------
function Get-GuardianOperationalState {
    $health = Get-GuardianHealthScore
    $comm = if (Get-Command Get-GuardianCommunicationHealth -ErrorAction SilentlyContinue) { Get-GuardianCommunicationHealth } else { $null }
    $storage = Get-GuardianStorageHealth
    $mem = Get-GuardianMemorySummary
    $events = @(Get-GuardianEvents -Last 100)
    $rolling = @(Get-GuardianCheckpoints -Tier rolling).Count
    $milestones = @(Get-GuardianCheckpoints -Tier milestones).Count
    $agents = if (Get-Command Get-GuardianAgentRegistrySummary -ErrorAction SilentlyContinue) { Get-GuardianAgentRegistrySummary } else { @{ total=0; active=0; failed=0 } }
    $jobs = @(Get-GuardianJob)
    $risk = if (Test-Path $GuardianRiskLatest) { (Get-Content $GuardianRiskLatest -Encoding UTF8 | ConvertFrom-Json) } else { $null }

    $state = [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        guardianHealth=@{ overallPct=$health.overallPct; runtimePct=$health.runtimePct; storageHygienePct=$health.storageHygienePct }
        nexus98Connection=@{ bridgeEnabled=if($comm){$comm.enabled}else{$false}; commHealthScore=if($comm){$comm.healthScore}else{$null} }
        storageHealth=@{ overallPct=$storage.overallPct }
        memoryHealth=@{ total=$mem.total; avgConfidence=$mem.avgConfidence }
        eventStatus=@{ recentCount=$events.Count; bySeverity=($events | Group-Object severity | ForEach-Object { @{ severity=$_.Name; count=$_.Count } }) }
        checkpointStatus=@{ rolling=$rolling; milestones=$milestones; recoveryReadiness=if(($rolling+$milestones)-gt 0){'ready'}else{'none'} }
        agentStatus=@{ total=$agents.total; active=$agents.active; failed=$agents.failed }
        schedulerStatus=@{ jobCount=$jobs.Count; enabled=@($jobs | Where-Object { $_.enabled }).Count; lastCycle=if(Test-Path $GuardianSchedulerState){(Get-Content $GuardianSchedulerState -Encoding UTF8|ConvertFrom-Json).lastCycle}else{$null} }
        risk=if($risk){@{ score=$risk.riskScore; level=$risk.riskLevel }}else{$null}
    }
    $state | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianOpState -Encoding UTF8
    return $state
}

# ---------------------------------------------------------------------------
# Phase 7: Managed runtime configuration
# ---------------------------------------------------------------------------
function Get-GuardianRuntimeConfig {
    if (Test-Path $GuardianRuntimeConfig) { return (Get-Content -Path $GuardianRuntimeConfig -Encoding UTF8 | ConvertFrom-Json) }
    return $null
}

function Set-GuardianRuntimeConfig {
    param([Parameter(Mandatory)]$Config)
    $ck = New-GuardianSelfModificationCheckpoint -Reason 'runtime config change'
    $Config | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianRuntimeConfig -Encoding UTF8
    $cfg = Get-Content -Path $GuardianRuntimeConfig -Encoding UTF8 | ConvertFrom-Json
    if ($cfg.schedulerIntervals) {
        $cfg.schedulerIntervals.PSObject.Properties | ForEach-Object {
            $j = Get-GuardianJob -Name $_.Name
            if ($j.Count -gt 0) { Register-GuardianJob -Name $_.Name -IntervalSeconds $_.Value -Enabled $true }
        }
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'runtime_config_change' -Reason 'guardian_runtime_config.json updated' -NewState $GuardianRuntimeConfig -Validation 'validated' | Out-Null
    }
    return [PSCustomObject]@{ updated=$true; checkpoint=$ck.id }
}

function New-GuardianRuntimeConfig {
    return [PSCustomObject]@{
        version='1.0.0'
        schedulerIntervals=[PSCustomObject]@{
            HEALTH_SCAN=60; STORAGE_SCAN=300; EVENT_REVIEW=120; MEMORY_MAINTENANCE=600; CHECKPOINT_VALIDATION=900
        }
        monitoringLevel='standard'
        retentionRules=[PSCustomObject]@{ heartbeatDays=30; acksDays=30; eventsMax=1000 }
        communication=[PSCustomObject]@{ bridgeEnabled=$true; requirePermissionForHighRisk=$true }
        logging=[PSCustomObject]@{ audit=$true; level='info' }
    }
}

# ---------------------------------------------------------------------------
# Phase 8: Runtime lifecycle management
# ---------------------------------------------------------------------------
function Start-GuardianOperations {
    param([int]$MaxCycles=0)
    Initialize-GuardianOperations | Out-Null
    if (-not (Test-Path $GuardianRuntimeConfig)) {
        New-GuardianRuntimeConfig | ConvertTo-Json -Depth 12 | Set-Content -Path $GuardianRuntimeConfig -Encoding UTF8
    }
    $rt = Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json
    $rt.status='running'; $rt.started=(Get-Date).ToString('o'); $rt.pid=$PID
    $rt | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'operations_start' -Reason 'continuous operations engine started' -NewState 'running' -Validation 'validated' | Out-Null
    }
    $cycles = 0
    $limit = if ($MaxCycles -le 0) { 1 } else { $MaxCycles }
    try {
        while ($cycles -lt $limit) {
            Invoke-GuardianSchedulerCycle | Out-Null
            Invoke-GuardianNexus98ConsumerCycle | Out-Null
            Invoke-GuardianRiskAnalysis | Out-Null
            Invoke-GuardianHeartbeat | Out-Null
            Get-GuardianOperationalState | Out-Null
            $cycles++
        }
    } catch {
        if (Get-Command New-GuardianEvent -ErrorAction SilentlyContinue) {
            New-GuardianEvent -Source 'operations' -Category SYSTEM -Severity ERROR -Description "OPERATIONS_LOOP_FAILURE: $($_.Exception.Message)" -AffectedComponent 'operations' | Out-Null
        }
    }
    return [PSCustomObject]@{ status='running'; cyclesRun=$cycles; started=$rt.started }
}

function Stop-GuardianOperations {
    Initialize-GuardianOperations | Out-Null
    $prev = if (Test-Path $GuardianRuntimeState) { Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json } else { $null }
    $obj = [PSCustomObject]@{
        status='stopped'
        started=if($prev){$prev.started}else{$null}
        pid=if($prev){$prev.pid}else{$null}
        lastHeartbeat=if($prev){$prev.lastHeartbeat}else{$null}
        stopped=(Get-Date).ToString('o')
        created=if($prev){$prev.created}else{(Get-Date).ToString('o')}
    }
    $obj | ConvertTo-Json -Depth 10 | Set-Content -Path $GuardianRuntimeState -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'operations_stop' -Reason 'continuous operations engine stopped' -NewState 'stopped' -Validation 'completed' | Out-Null
    }
    return [PSCustomObject]@{ status='stopped'; stopped=$obj.stopped }
}

function Get-GuardianOperationsStatus {
    if (-not (Test-Path $GuardianRuntimeState)) { return $null }
    return (Get-Content -Path $GuardianRuntimeState -Encoding UTF8 | ConvertFrom-Json)
}


