# Guardian Drift Guard (M7).
# Architecture baseline, drift detection, change governance,
# self-modification guard, and storage governance integration.
# Core principle: every change has a reason, a checkpoint, a validation
# process, a comparison step, and a rollback path. No autonomous
# modification without this chain. Observation-first: never deletes.

$baselinePath = Join-Path $GuardianEnv.Config 'guardian_architecture_baseline.json'
$baselineFileName = 'guardian_architecture_baseline.json'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
function New-GuardianDriftEvent {
    param(
        [Parameter(Mandatory=$true)][string]$Type,
        [string]$Detail='',
        [ValidateSet('info','warning','error','critical')][string]$Severity='warning'
    )
    return [PSCustomObject]@{
        type=$Type
        detail=$Detail
        severity=$Severity
        timestamp=(Get-Date).ToString('o')
        recommendedAction='review and reconcile against architecture baseline'
    }
}

# ---------------------------------------------------------------------------
# PHASE 1: Architecture Baseline
# ---------------------------------------------------------------------------
function New-GuardianArchitectureBaseline {
    param([string]$Root=$GuardianEnv.Root)
    $managedClasses = @{
        'core'='ACTIVE'; 'config'='ACTIVE'; 'data'='ACTIVE'; 'docs'='ACTIVE';
        'tests'='ACTIVE'; 'archive'='ARCHIVE'; 'snapshots'='TEMPORARY';
        'logs'='OBSOLETE'; 'reports'='OBSOLETE'; 'vcs'='ACTIVE';
        'plugins'='ACTIVE'; 'scripts'='ACTIVE'; 'communication'='ACTIVE';
        'governance'='ACTIVE'; 'memory'='ACTIVE'; 'monitoring'='ACTIVE';
        'recovery'='ACTIVE'; 'storage'='ACTIVE'; '.codex'='ACTIVE';
        '.vscode'='ACTIVE'; '.venv'='ACTIVE'
    }

    $approvedDirs = @()
    Get-ChildItem -Path $Root -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $cls = if ($managedClasses.ContainsKey($_.Name)) { $managedClasses[$_.Name] } else { 'REVIEW' }
        $approvedDirs += [PSCustomObject]@{
            path=$_.Name
            owner='guardian'
            purpose="managed directory: $($_.Name)"
            lifecycle='permanent'
            allowedModifications= if ($cls -eq 'REVIEW') { 'manual review required' } else { 'guardian managed' }
        }
    }

    $approvedModules = @()
    $coreDir = Join-Path $Root 'core'
    if (Test-Path $coreDir) {
        Get-ChildItem -Path $coreDir -File -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
            $status = if ($_.Name -like 'Guardian_*') { 'active' } else { 'legacy-stub' }
            $hash = $null
            try { $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash } catch {}
            $approvedModules += [PSCustomObject]@{
                name=$_.Name
                directory='core'
                owner='guardian'
                purpose="module: $($_.Name)"
                lifecycle='permanent'
                allowedModifications= if ($status -eq 'active') { 'guardian edits under checkpoint' } else { 'frozen; not wired into loader' }
                status=$status
                hash=$hash
            }
        }
    }

    $approvedData = @()
    $dataDir = Join-Path $Root 'data'
    if (Test-Path $dataDir) {
        Get-ChildItem -Path $dataDir -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $approvedData += [PSCustomObject]@{
                path="data/$($_.Name)"
                owner='guardian'
                purpose="data location: $($_.Name)"
                lifecycle='managed'
                allowedModifications='guardian runtime only'
            }
        }
    }

    $approvedConfig = @()
    $configDir = Join-Path $Root 'config'
    if (Test-Path $configDir) {
        Get-ChildItem -Path $configDir -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -eq $baselineFileName) { return }  # baseline is self-managed, not a monitored config
            $hash = $null
            try { $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash } catch {}
            $approvedConfig += [PSCustomObject]@{
                name=$_.Name
                owner='guardian'
                purpose="config: $($_.Name)"
                lifecycle='managed'
                allowedModifications='guardian edits under checkpoint'
                hash=$hash
            }
        }
    }

    $genPaths = @('logs','reports','snapshots','data/checkpoints','data/comms',
                  'data/memory','data/events','data/agents','data/resource_baseline.json',
                  'data/security_baseline.json','data/storage_baseline.json')
    $approvedGenerated = $genPaths | ForEach-Object {
        $cat = if ($_ -like 'snapshots*') { 'TEMPORARY' }
               elseif ($_ -like 'logs*' -or $_ -like 'reports*') { 'OBSOLETE' }
               else { 'ACTIVE' }
        [PSCustomObject]@{
            path=$_
            owner='guardian'
            category=$cat
            retentionPolicy='governed by lifecycle rules'
            cleanupStatus='managed'
            allowedModifications='guardian runtime generates'
        }
    }

    $approvedTopFiles = @()
    Get-ChildItem -Path $Root -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $approvedTopFiles += [PSCustomObject]@{
            name=$_.Name
            owner='guardian'
            purpose="top-level artifact: $($_.Name)"
            lifecycle='managed'
            allowedModifications='guardian managed'
        }
    }

    $protectedSurfaces = @(
        [PSCustomObject]@{ name='Guardian Core';          paths=@('core/Guardian_Env.ps1','core/Guardian_Loader.ps1','core/Guardian_DriftGuard.ps1'); selfModification='gated' }
        [PSCustomObject]@{ name='Governance Rules';       paths=@('core/Guardian_Governance.ps1','core/Guardian_GovernanceIntegration.ps1'); selfModification='gated' }
        [PSCustomObject]@{ name='Recovery System';        paths=@('core/Guardian_Recovery.ps1'); selfModification='gated' }
        [PSCustomObject]@{ name='Checkpoint System';      paths=@('core/Guardian_Checkpoint.ps1'); selfModification='gated' }
        [PSCustomObject]@{ name='Communication Layer';    paths=@('core/Guardian_Comms.ps1','core/Guardian_Contracts.ps1'); selfModification='gated' }
    )

    return [PSCustomObject]@{
        version='1.0.0'
        captured=(Get-Date).ToString('o')
        guardianVersion=$GuardianEnv.Version
        approvedDirectories=$approvedDirs
        approvedModules=$approvedModules
        approvedDataLocations=$approvedData
        approvedConfigFiles=$approvedConfig
        approvedGeneratedArtifacts=$approvedGenerated
        approvedTopLevelFiles=$approvedTopFiles
        protectedSurfaces=$protectedSurfaces
    }
}

function Save-GuardianArchitectureBaseline {
    param([string]$Root=$GuardianEnv.Root)
    $b = New-GuardianArchitectureBaseline -Root $Root
    New-Item -ItemType Directory -Force -Path (Split-Path $baselinePath) | Out-Null
    $b | ConvertTo-Json -Depth 12 | Set-Content -Path $baselinePath -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'drift_baseline_create' -Reason 'architecture baseline captured' -NewState $baselinePath -Validation 'validated'
    }
    return $b
}

function Get-GuardianArchitectureBaseline {
    param([switch]$GenerateIfMissing)
    if (Test-Path $baselinePath) {
        return (Get-Content -Path $baselinePath -Encoding UTF8 | ConvertFrom-Json)
    }
    if ($GenerateIfMissing) { return (New-GuardianArchitectureBaseline) }
    return $null
}

function Get-GuardianProtectedSurfaces {
    $b = Get-GuardianArchitectureBaseline -GenerateIfMissing
    if ($b.protectedSurfaces) { return $b.protectedSurfaces }
    return @()
}

# ---------------------------------------------------------------------------
# PHASE 2: Drift Detection
# ---------------------------------------------------------------------------
function Get-GuardianDrift {
    param([string]$Root=$GuardianEnv.Root, [object]$Baseline=$null)
    if (-not $Baseline) { $Baseline = Get-GuardianArchitectureBaseline -GenerateIfMissing }
    $drift = @()

    $approvedDirNames = @($Baseline.approvedDirectories | ForEach-Object { $_.path })
    Get-ChildItem -Path $Root -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -notin $approvedDirNames -and $_.Name -ne '.git') {
            $drift += New-GuardianDriftEvent -Type 'NEW_UNAPPROVED_DIRECTORY' -Detail $_.FullName -Severity 'warning'
        }
    }

    $approvedModules = @($Baseline.approvedModules)
    $approvedModuleNames = @($approvedModules | ForEach-Object { $_.name })
    $coreDir = Join-Path $Root 'core'
    $currentModuleNames = @()
    if (Test-Path $coreDir) {
        Get-ChildItem -Path $coreDir -File -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object { $currentModuleNames += $_.Name }
    }
    foreach ($m in $approvedModules) {
        $approvedPath = Join-Path $coreDir $m.name
        if (Test-Path $approvedPath) { continue }
        $hits = @(Get-ChildItem -Path $Root -Recurse -File -Filter $m.name -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -ne $approvedPath })
        if ($hits.Count -gt 0) {
            $drift += New-GuardianDriftEvent -Type 'MOVED_COMPONENT' -Detail "$($m.name) moved to $($hits[0].FullName)" -Severity 'warning'
        } else {
            $drift += New-GuardianDriftEvent -Type 'RENAMED_COMPONENT' -Detail "$($m.name) absent; possible rename" -Severity 'warning'
        }
    }
    foreach ($name in $currentModuleNames) {
        if ($name -notin $approvedModuleNames) {
            $drift += New-GuardianDriftEvent -Type 'NEW_UNAPPROVED_MODULE' -Detail (Join-Path 'core' $name) -Severity 'warning'
        }
    }

    $approvedConfig = @($Baseline.approvedConfigFiles)
    $approvedConfigNames = @($approvedConfig | ForEach-Object { $_.name })
    $configDir = Join-Path $Root 'config'
    if (Test-Path $configDir) {
        Get-ChildItem -Path $configDir -File -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -eq $baselineFileName) { return }
            if ($_.Name -notin $approvedConfigNames) {
                $drift += New-GuardianDriftEvent -Type 'CONFIGURATION_DRIFT' -Detail "new config file: $($_.Name)" -Severity 'warning'
            }
        }
        # Hash-drift: only for Guardian-owned (guardian_*) config, since
        # reference state files (nexus98_*) are volatile by nature.
        foreach ($entry in $approvedConfig) {
            if (-not ($entry.name -like 'guardian_*')) { continue }
            $cf = Join-Path $configDir $entry.name
            if (-not (Test-Path $cf)) { continue }
            try {
                $h = (Get-FileHash $cf -Algorithm SHA256).Hash
                if ($entry.hash -and $entry.hash -ne $h) {
                    $drift += New-GuardianDriftEvent -Type 'CONFIGURATION_DRIFT' -Detail "modified Guardian config: $($entry.name)" -Severity 'critical'
                }
            } catch {}
        }
    }

    if (Test-Path $coreDir) {
        $dups = Get-GuardianDuplicateGroups -Path $coreDir -SampleOnly
        foreach ($g in $dups) {
            if ($g.count -gt 1) {
                $drift += New-GuardianDriftEvent -Type 'DUPLICATE_SYSTEM' -Detail ("duplicate modules: " + ($g.files -join ' | ')) -Severity 'warning'
            }
        }
    }

    $approvedTopNames = @($Baseline.approvedTopLevelFiles | ForEach-Object { $_.name })
    Get-ChildItem -Path $Root -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -notin $approvedTopNames -and $_.Name -ne '.gitignore') {
            $drift += New-GuardianDriftEvent -Type 'UNCONTROLLED_ARTIFACT' -Detail $_.FullName -Severity 'info'
        }
    }

    return @($drift)
}

# ---------------------------------------------------------------------------
# PHASE 3: Change Governance
# ---------------------------------------------------------------------------
function New-GuardianChangeRequest {
    param(
        [Parameter(Mandatory=$true)][string]$Description,
        [string]$Target='',
        [ValidateSet('low','medium','high','critical')][string]$RiskLevel='medium',
        [switch]$SelfModification
    )
    return [PSCustomObject]@{
        requestId="CHG_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 9999)"
        description=$Description
        target=$Target
        riskLevel=$RiskLevel
        selfModification=$SelfModification.IsPresent
        stages=@{
            CHECKPOINT_CREATED=$false
            CHANGE_DECLARED=$true
            RISK_CLASSIFIED=$true
            TEST_PLAN_CREATED=$false
            CHANGE_EXECUTED=$false
            VALIDATION_COMPLETED=$false
            COMPARISON_COMPLETED=$false
        }
        status='PENDING'
        created=(Get-Date).ToString('o')
    }
}

function Set-GuardianChangeStage {
    param(
        [Parameter(Mandatory)]$Request,
        [Parameter(Mandatory)]$Stage,
        [bool]$Value=$true
    )
    if ($Request.stages.ContainsKey($Stage)) { $Request.stages[$Stage]=$Value }
    return $Request
}

function Test-GuardianChangeGovernance {
    param([Parameter(Mandatory)]$Request)
    $required = @('CHECKPOINT_CREATED','TEST_PLAN_CREATED','VALIDATION_COMPLETED','COMPARISON_COMPLETED')
    $missing = @()
    foreach ($s in $required) { if (-not $Request.stages[$s]) { $missing += $s } }
    # CHANGE_EXECUTED is the act itself (recorded post-hoc for audit), not a pre-condition gate.
    if ($missing.Count -eq 0) {
        return New-GuardianResponse -Decision 'ALLOW' -Reason 'Full change governance chain satisfied.' `
            -Context @{ requestId=$Request.requestId; selfModification=$Request.selfModification }
    }
    return New-GuardianResponse -Decision 'BLOCK' -Reason ("Missing governance stages: " + ($missing -join ', ')) `
        -Context @{ requestId=$Request.requestId; missingStages=$missing }
}

# ---------------------------------------------------------------------------
# PHASE 4: Self-Modification Guard
# ---------------------------------------------------------------------------
function New-GuardianSelfModificationCheckpoint {
    param([string]$Reason='self-modification safeguard')
    return New-GuardianCheckpoint -Tier emergency -Reason $Reason -Creator 'drift_guard'
}

function Test-GuardianSelfModification {
    param(
        [Parameter(Mandatory)]$Request,
        [string]$Surface='',
        [bool]$EmergencyCheckpoint=$false,
        [bool]$ChangeProposal=$false,
        [bool]$ImpactAnalysis=$false,
        [bool]$AutomatedTests=$false,
        [bool]$HealthComparison=$false,
        [bool]$RollbackAvailable=$false
    )
    $surfaces = Get-GuardianProtectedSurfaces
    $matched = $surfaces
    if ($Surface) { $matched = @($surfaces | Where-Object { $_.name -eq $Surface }) }
    if ($Surface -and @($matched).Count -eq 0) {
        return New-GuardianResponse -Decision 'BLOCK' -Reason "Target surface '$Surface' is not a recognized protected surface." `
            -Context @{ surface=$Surface }
    }
    $requirements = @{
        EMERGENCY_CHECKPOINT=$EmergencyCheckpoint
        CHANGE_PROPOSAL=$ChangeProposal
        IMPACT_ANALYSIS=$ImpactAnalysis
        AUTOMATED_TESTS=$AutomatedTests
        HEALTH_COMPARISON=$HealthComparison
        ROLLBACK_AVAILABILITY=$RollbackAvailable
    }
    $missing = @()
    foreach ($k in $requirements.Keys) { if (-not $requirements[$k]) { $missing += $k } }
    if ($missing.Count -eq 0) {
        return New-GuardianResponse -Decision 'ALLOW_WITH_MONITORING' -Reason 'All self-modification safeguards satisfied; proceed under monitoring.' `
            -Context @{ surface=$Surface; requirements=$requirements }
    }
    return New-GuardianResponse -Decision 'BLOCK' -Reason ("Self-modification requires: " + ($missing -join ', ')) `
        -Context @{ surface=$Surface; missing=$missing }
}

# ---------------------------------------------------------------------------
# PHASE 5: Storage Governance Integration
# ---------------------------------------------------------------------------
function Get-GuardianStorageGovernance {
    param([string]$Root=$GuardianEnv.Root)
    $findings = @()

    if (Test-Path $GuardianEnv.Snapshots) {
        $snapFiles = (Get-ChildItem -Path $GuardianEnv.Snapshots -Recurse -File -ErrorAction SilentlyContinue).Count
        if ($snapFiles -gt 2000) {
            $findings += [PSCustomObject]@{
                rule='UNCONTROLLED_SNAPSHOTS'
                detail="$snapFiles snapshot files"
                severity='critical'
                lifecycle=@{ owner='guardian'; category='TEMPORARY'; retentionPolicy='rotate/archive'; cleanupStatus='required' }
            }
        }
    }

    # Scan managed locations only (exclude the 2.1GB snapshot archive from
    # deep recursion); observe, do not touch.
    $managedScan = @('core','config','data','reports','scripts','docs','plugins','communication','governance','memory','monitoring','recovery','storage','tests')
    $managedFiles = @()
    $managedDirs = @()
    foreach ($d in $managedScan) {
        $full = Join-Path $Root $d
        if (-not (Test-Path $full)) { continue }
        $managedFiles += @(Get-ChildItem -Path $full -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 400)
        $managedDirs += @(Get-ChildItem -Path $full -Recurse -Force -Directory -ErrorAction SilentlyContinue | Select-Object -First 400)
    }

    foreach ($dir in $managedDirs) {
        if ($dir.Name -match '(?i)(backup(_final|_old|_new)?\d*|copy_of|temp\d*|_v\d+_\d+|snapshot.*snapshot)') {
            $findings += [PSCustomObject]@{
                rule='BACKUP_MULTIPLICATION'
                detail=$dir.FullName
                severity='warning'
                lifecycle=@{ owner='unknown'; category='OBSOLETE'; retentionPolicy='review'; cleanupStatus='required' }
            }
        }
    }

    $repDir = Join-Path $Root 'reports'
    if (Test-Path $repDir) {
        Get-ChildItem -Path $repDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | ForEach-Object {
            $findings += [PSCustomObject]@{
                rule='ABANDONED_REPORT'
                detail=$_.FullName
                severity='info'
                lifecycle=@{ owner='guardian'; category='OBSOLETE'; retentionPolicy='30d'; cleanupStatus='review' }
            }
        }
    }

    $dups = Get-GuardianDuplicateGroups -Path (Join-Path $Root 'core') -SampleOnly
    foreach ($g in $dups) {
        if ($g.count -gt 1) {
            $findings += [PSCustomObject]@{
                rule='DUPLICATE_ARTIFACT'
                detail=($g.files -join ' | ')
                severity='warning'
                lifecycle=@{ owner='unknown'; category='UNKNOWN'; retentionPolicy='dedupe'; cleanupStatus='required' }
            }
        }
    }

    foreach ($dir in $managedDirs) {
        $depth = ($dir.FullName -replace [regex]::Escape($Root), '' -split '\\' | Where-Object { $_ }).Count
        if ($depth -ge 4) {
            $findings += [PSCustomObject]@{
                rule='NESTED_PROJECT_COPY'
                detail=$dir.FullName
                severity='warning'
                lifecycle=@{ owner='unknown'; category='UNKNOWN'; retentionPolicy='review'; cleanupStatus='required' }
            }
        }
    }

    return @($findings)
}

# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------
function Invoke-GuardianDriftGuard {
    param([string]$Root=$GuardianEnv.Root, [switch]$EnsureBaseline)
    if ($EnsureBaseline -or -not (Test-Path $baselinePath)) {
        Save-GuardianArchitectureBaseline -Root $Root | Out-Null
    }
    $baseline = Get-GuardianArchitectureBaseline
    $drift = @(Get-GuardianDrift -Root $Root -Baseline $baseline)
    $storage = @(Get-GuardianStorageGovernance -Root $Root)
    $report = [PSCustomObject]@{
        timestamp=(Get-Date).ToString('o')
        baselineCaptured=$baseline.captured
        driftCount=$drift.Count
        drift=$drift
        storageFindingsCount=$storage.Count
        storageFindings=$storage
        verdict= if ($drift.Count -eq 0) { 'STABLE' } else { 'DRIFT_DETECTED' }
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'drift_guard_run' -Reason 'periodic architecture + storage governance scan' -NewState $report.verdict -Validation 'completed'
    }
    return $report
}

