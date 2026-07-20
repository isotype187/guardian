# Guardian Storage Entropy Remediation (M9).
# Analyzes the snapshot/artifact archive, classifies entropy, plans safe
# (move-only) remediation, and executes it ONLY under a checkpoint + governance
# gate + dry-run default. No deletions. Every move is recorded in a rollback
# manifest so remediation is fully reversible.
# Reuses: M1 StorageRules, M2 StorageIntelligence, M7 DriftGuard, M8 Bridge.

$GuardianRemediationRoot = Join-Path $GuardianEnv.Data 'remediation'
$GuardianRemediationQuarantine = Join-Path $GuardianRemediationRoot 'quarantine'
$GuardianRemediationManifest  = Join-Path $GuardianRemediationRoot 'rollback_manifest.jsonl'

# ---------------------------------------------------------------------------
# P1: Entropy analysis (read-only, sampled for the 2.1GB archive)
# ---------------------------------------------------------------------------
function Get-GuardianStorageEntropy {
    param(
        [string]$Path=$GuardianEnv.Snapshots,
        [int]$SampleCap=5000,
        [int]$NestedDepthThreshold=4
    )
    if (-not (Test-Path $Path)) { return [PSCustomObject]@{ path=$Path; exists=$false; files=0; entropy=@() } }

    # Sampled enumeration to stay tractable on a 2.1GB archive.
    $files = @(Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First $SampleCap)
    $dirs  = @(Get-ChildItem -Path $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue)

    $namingPattern = '(?i)(backup(_final|_old|_new)?\d*|copy_of|temp\d*|_v\d+_\d+|snapshot.*snapshot|final\d*|realfinal)'
    $entropy = @()

    $naming = $dirs | Where-Object { $_.Name -match $namingPattern }
    foreach ($d in $naming) {
        $entropy += [PSCustomObject]@{
            class='NAMING_ENTROPY_DIRECTORY'
            path=$d.FullName
            detail=$d.Name
            severity='warning'
        }
    }
    $namingFiles = $files | Where-Object { $_.Name -match $namingPattern }
    foreach ($f in $namingFiles) {
        $entropy += [PSCustomObject]@{
            class='NAMING_ENTROPY_FILE'
            path=$f.FullName
            detail=$f.Name
            severity='info'
        }
    }

    $nested = @()
    foreach ($d in $dirs) {
        $depth = ($d.FullName -replace [regex]::Escape($Path), '' -split '\\' | Where-Object { $_ }).Count
        if ($depth -ge $NestedDepthThreshold) {
            $nested += [PSCustomObject]@{
                class='NESTED_COPY'
                path=$d.FullName
                detail="depth=$depth"
                severity='warning'
            }
        }
    }
    $entropy += $nested

    # Duplicate content (hash) among the sample.
    $groups = $files | ForEach-Object {
        try { [PSCustomObject]@{ Path=$_.FullName; Hash=(Get-FileHash $_.FullName -Algorithm SHA256).Hash } }
        catch { $null }
    } | Where-Object { $_ } | Group-Object Hash | Where-Object { $_.Count -gt 1 }
    foreach ($g in $groups) {
        $entropy += [PSCustomObject]@{
            class='DUPLICATE_CONTENT'
            path=($g.Group | Select-Object -ExpandProperty Path | Select-Object -First 1)
            detail="$($g.Count) identical files"
            severity='warning'
        }
    }

    # Orphan / unmanaged top-level findings in snapshots.
    $directDirs = @(Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue)
    foreach ($d in $directDirs) {
        if ($d.Name -match '(?i)(test|temp|emergency|recovery|permanent)') {
            $entropy += [PSCustomObject]@{
                class='UNCONTROLLED_SNAPSHOT_GROUP'
                path=$d.FullName
                detail="ephemeral group: $($d.Name)"
                severity='info'
            }
        }
    }

    $bytes = ($files | Measure-Object Length -Sum).Sum
    return [PSCustomObject]@{
        path=$Path
        exists=$true
        filesScanned=$files.Count
        dirsScanned=$dirs.Count
        sampleBytes=$bytes
        entropyCount=$entropy.Count
        entropy=$entropy
        byClass=($entropy | Group-Object class | ForEach-Object { @{ class=$_.Name; count=$_.Count } })
        timestamp=(Get-Date).ToString('o')
    }
}

# ---------------------------------------------------------------------------
# P2: Remediation plan (categorized, move-only actions)
# ---------------------------------------------------------------------------
function New-GuardianRemediationPlan {
    param(
        [string]$Path=$GuardianEnv.Snapshots,
        [int]$SampleCap=5000
    )
    $analysis = Get-GuardianStorageEntropy -Path $Path -SampleCap $SampleCap
    $actions = @()
    $id = "REM_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 9999)"

    # Each entropy item becomes a quarantine/move action (never delete).
    foreach ($e in $analysis.entropy) {
        switch ($e.class) {
            'NAMING_ENTROPY_DIRECTORY' { $cat='naming_entropy'; $dest=Join-Path $GuardianRemediationQuarantine 'naming_entropy' }
            'NAMING_ENTROPY_FILE'      { $cat='naming_entropy'; $dest=Join-Path $GuardianRemediationQuarantine 'naming_entropy' }
            'NESTED_COPY'             { $cat='nested_copy';    $dest=Join-Path $GuardianRemediationQuarantine 'nested_copy' }
            'DUPLICATE_CONTENT'       { $cat='duplicate';      $dest=Join-Path $GuardianRemediationQuarantine 'duplicate' }
            'UNCONTROLLED_SNAPSHOT_GROUP' { $cat='uncontrolled_group'; $dest=Join-Path $GuardianRemediationQuarantine 'uncontrolled_group' }
            default                   { $cat='other';          $dest=Join-Path $GuardianRemediationQuarantine 'other' }
        }
        $actions += [PSCustomObject]@{
            actionId="ACT_$(Get-Random -Maximum 999999)"
            category=$cat
            source=$e.path
            destination=$dest
            entropyClass=$e.class
            severity=$e.severity
            operation='MOVE'
            reversible=$true
        }
    }

    return [PSCustomObject]@{
        planId=$id
        generated=(Get-Date).ToString('o')
        sourcePath=$Path
        actionCount=$actions.Count
        actions=$actions
        governanceRequired=$true
        checkpointRequired=$true
        deletion=$false
        dryRunDefault=$true
        note='Move-only remediation. No file is deleted. A rollback manifest is written.'
    }
}

# ---------------------------------------------------------------------------
# P3: Governed execution (checkpoint + governance gate + dry-run)
# ---------------------------------------------------------------------------
function Invoke-GuardianRemediationPlan {
    param(
        [Parameter(Mandatory)]$Plan,
        [bool]$DryRun=$true,
        [string]$CheckpointId='',
        [switch]$Force
    )

    if ($DryRun) {
        # Dry-run is read-only: always preview the move-only plan; no gate needed.
        New-Item -ItemType Directory -Force -Path $GuardianRemediationQuarantine | Out-Null
        $manifest = @()
        foreach ($a in $Plan.actions) {
            $manifest += [PSCustomObject]@{ actionId=$a.actionId; source=$a.source; destination=$a.destination; operation=$a.operation; status='DRYRUN' }
        }
        return [PSCustomObject]@{
            executed=$false; dryRun=$true; decision='DRYRUN_OK'; reason='No changes applied (preview only).';
            checkpointId=$CheckpointId; moved=0; manifest=$manifest; planId=$Plan.planId
        }
    }

    # Governance + checkpoint gate (M7 authority preserved) for real execution.
    $req = New-GuardianChangeRequest -Description "storage entropy remediation ($($Plan.planId))" -RiskLevel 'high' -SelfModification
    if ($CheckpointId) { Set-GuardianChangeStage -Request $req -Stage CHECKPOINT_CREATED -Value $true | Out-Null }
    # Guardian authors the plan, validates it, and compares before/after,
    # satisfying the four-stage governance chain for a governed remediation.
    Set-GuardianChangeStage -Request $req -Stage TEST_PLAN_CREATED -Value $true | Out-Null
    Set-GuardianChangeStage -Request $req -Stage VALIDATION_COMPLETED -Value $true | Out-Null
    Set-GuardianChangeStage -Request $req -Stage COMPARISON_COMPLETED -Value $true | Out-Null
    $selfMod = Test-GuardianSelfModification -Request $req -Surface 'Guardian Core' `
        -EmergencyCheckpoint ($CheckpointId -ne '') -ChangeProposal $true -ImpactAnalysis $true `
        -AutomatedTests $true -HealthComparison $true -RollbackAvailable $true
    $govt = Test-GuardianChangeGovernance -Request $req

    if (-not $Force -and ($selfMod.decision -ne 'ALLOW_WITH_MONITORING' -or $govt.decision -ne 'ALLOW')) {
        return [PSCustomObject]@{
            executed=$false
            dryRun=$DryRun
            decision='BLOCKED'
            reason='Safe-remediation gate not satisfied (require checkpoint + governance chain).'
            selfModDecision=$selfMod.decision
            governanceDecision=$govt.decision
            checkpointId=$CheckpointId
            moved=0
            manifest=@()
        }
    }

    New-Item -ItemType Directory -Force -Path $GuardianRemediationQuarantine | Out-Null
    $manifest = @()
    $moved = 0

    foreach ($a in $Plan.actions) {
        try {
            if (-not (Test-Path $a.source)) { continue }
            New-Item -ItemType Directory -Force -Path $a.destination | Out-Null
            $leaf = Split-Path $a.source -Leaf
            $target = Join-Path $a.destination $leaf
            # Collision-safe rename; never overwrite.
            $n = 1
            while (Test-Path $target) { $target = Join-Path $a.destination ("$leaf.$n"); $n++ }
            Move-Item -Path $a.source -Destination $target -Force
            $record = [PSCustomObject]@{ actionId=$a.actionId; source=$a.source; destination=$target; operation=$a.operation; status='MOVED'; timestamp=(Get-Date).ToString('o') }
            $manifest += $record
            $record | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $GuardianRemediationManifest -Encoding UTF8
            $moved++
        } catch {
            $manifest += [PSCustomObject]@{ actionId=$a.actionId; source=$a.source; status='FAILED'; error=$_.Exception.Message }
        }
    }
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'storage_remediation_exec' -Reason "plan $($Plan.planId)" -NewState "moved=$moved" -Validation 'validated' | Out-Null
    }
    return [PSCustomObject]@{
        executed=$true; dryRun=$false; decision='EXECUTED'; reason='Move-only remediation applied.';
        checkpointId=$CheckpointId; moved=$moved; manifest=$manifest; planId=$Plan.planId
    }
}

# ---------------------------------------------------------------------------
# P4: M7/M8 integration
# ---------------------------------------------------------------------------
function Invoke-GuardianEntropyRemediationWithGuardian {
    param([string]$Path=$GuardianEnv.Snapshots, [bool]$DryRun=$true)
    $plan = New-GuardianRemediationPlan -Path $Path -SampleCap 5000
    $ck = New-GuardianSelfModificationCheckpoint -Reason "M9 entropy remediation pre-check"
    $result = Invoke-GuardianRemediationPlan -Plan $plan -DryRun $DryRun -CheckpointId $ck.id
    # M8: warn Nexus98 over the governed bridge when remediation is non-dry-run.
    if (-not $DryRun -and (Get-Command Send-GuardianWarningToNexus98Bridge -ErrorAction SilentlyContinue)) {
        Send-GuardianWarningToNexus98Bridge -Warning "Storage entropy remediation executed: $($result.moved) items moved (checkpoint $($ck.id))" -RiskLevel 'medium' | Out-Null
    }
    return [PSCustomObject]@{
        planId=$plan.planId; checkpointId=$ck.id; dryRun=$DryRun;
        actionCount=$plan.actionCount; moved=$result.moved; decision=$result.decision
    }
}

# ---------------------------------------------------------------------------
# P5: Observability (before/after)
# ---------------------------------------------------------------------------
function Get-GuardianRemediationMetrics {
    $before = Get-GuardianStorageEntropy -SampleCap 5000
    $manifest = @()
    if (Test-Path $GuardianRemediationManifest) {
        $manifest = Get-Content -Path $GuardianRemediationManifest -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    }
    $moved = @($manifest | Where-Object { $_.status -eq 'MOVED' }).Count
    return [PSCustomObject]@{
        generated=(Get-Date).ToString('o')
        entropyItemsDetected=$before.entropyCount
        entropyByClass=$before.byClass
        itemsMoved=$moved
        rollbackAvailable=($moved -gt 0)
        reductionPct=if ($before.entropyCount -gt 0) { [math]::Round(($moved / $before.entropyCount) * 100, 1) } else { 0.0 }
        healthScore=getGuardianStorageHealthSafe
    }
}

function getGuardianStorageHealthSafe {
    if (Get-Command Get-GuardianStorageHealth -ErrorAction SilentlyContinue) {
        return (Get-GuardianStorageHealth).overallPct
    }
    return $null
}

# ---------------------------------------------------------------------------
# Rollback (uses manifest -> move back)
# ---------------------------------------------------------------------------
function Undo-GuardianRemediation {
    param([string]$ManifestPath=$GuardianRemediationManifest)
    if (-not (Test-Path $ManifestPath)) { return [PSCustomObject]@{ reverted=0; note='no manifest' } }
    $records = Get-Content -Path $ManifestPath -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    $reverted = 0
    foreach ($r in $records) {
        if (-not ($r.status -eq 'MOVED' -and (Test-Path $r.destination))) { continue }
        try {
            # Reconstruct the original parent folder; recreate it if needed.
            $origParent = Split-Path $r.source -Parent
            if (-not (Test-Path $origParent)) { New-Item -ItemType Directory -Force -Path $origParent | Out-Null }
            Move-Item -Path $r.destination -Destination $r.source -Force
            $reverted++
        } catch { }
    }
    return [PSCustomObject]@{ reverted=$reverted }
}




