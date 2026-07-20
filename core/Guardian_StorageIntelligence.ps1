# Guardian Storage Intelligence (M2 P3).
# Observes and classifies storage to prevent uncontrolled growth.
# Observation only: it reports and classifies; it never deletes.

$GuardianArtifactClasses = @('ACTIVE','ARCHIVE','TEMPORARY','EXPERIMENTAL','OBSOLETE','UNKNOWN')

# Management locations and their lifecycle class.
$GuardianManagedPaths = @{
    'data\checkpoints' = 'ACTIVE'
    'core'             = 'ACTIVE'
    'config'           = 'ACTIVE'
    'docs'             = 'ACTIVE'
    'tests'            = 'ACTIVE'
    'archive'          = 'ARCHIVE'
    'snapshots'        = 'TEMPORARY'
    'logs'             = 'OBSOLETE'
    'reports'          = 'OBSOLETE'
}

function Get-GuardianArtifactClass {
    param([string]$Path)
    $norm = $Path -replace [regex]::Escape($GuardianEnv.Root), '' -replace '^\\',''
    foreach ($k in $GuardianManagedPaths.Keys) {
        if ($norm -like "$k*") { return $GuardianManagedPaths[$k] }
    }
    return 'UNKNOWN'
}

# Storage health metrics.
function Get-GuardianStorageHealth {
    $score = @{};
    $events = @()

    # Directory Structure: penalize unexpected top-level dirs.
    $approved = @('core','config','data','logs','reports','tests','plugins','snapshots','scripts','.vscode','.codex','.venv','vcs','archive','communication','governance','memory','monitoring','recovery','storage','docs')
    $unexpected = @(Get-ChildItem -Path $GuardianEnv.Root -Directory -Force | Where-Object { $_.Name -notin $approved })
    $dirStructPct = if ($unexpected.Count -eq 0) { 100.0 } else { [math]::Max(40, 100 - $unexpected.Count * 15) }
    $score['directoryStructurePct'] = $dirStructPct
    if ($unexpected.Count -gt 0) { $events += New-GuardianEvent -Source 'storage' -Category FILE_SYSTEM -Severity WARNING -Description "UNEXPECTED_DIRECTORY: $($unexpected.Name -join ', ')" -AffectedComponent 'filesystem' }

    # Artifact Hygiene: based on UNKNOWN-class items.
    $unknown = @(Get-ChildItem -Path $GuardianEnv.Root -Recurse -Force -File -ErrorAction SilentlyContinue | Where-Object { (Get-GuardianArtifactClass $_.FullName) -eq 'UNKNOWN' })
    $artifactHygienePct = if ($unknown.Count -eq 0) { 100.0 } else { [math]::Max(50, 100 - $unknown.Count) }
    $score['artifactHygienePct'] = $artifactHygienePct
    if ($unknown.Count -gt 0) { $events += New-GuardianEvent -Source 'storage' -Category FILE_SYSTEM -Severity INFO -Description "UNKNOWN_ARTIFACTS: $($unknown.Count) require review" -AffectedComponent 'filesystem' }

    # Growth Control: snapshot accumulation as proxy.
    $snapFiles = 0
    if (Test-Path $GuardianEnv.Snapshots) { $snapFiles = (Get-ChildItem -Path $GuardianEnv.Snapshots -Recurse -File -ErrorAction SilentlyContinue).Count }
    $growthPct = if ($snapFiles -gt 2000) { 40.0 } elseif ($snapFiles -gt 500) { 70.0 } else { 95.0 }
    $score['growthControlPct'] = $growthPct
    if ($snapFiles -gt 2000) { $events += New-GuardianEvent -Source 'storage' -Category FILE_SYSTEM -Severity CRITICAL -Description "ARTIFACT_ACCUMULATION: $snapFiles snapshot files" -AffectedComponent 'snapshots' }

    # Duplicate Risk: detect duplicate file content (by hash) among managed files.
    $dupGroups = Get-GuardianDuplicateGroups -Path (Join-Path $GuardianEnv.Root 'core') -SampleOnly
    $dupPct = if ($dupGroups.Count -eq 0) { 100.0 } else { [math]::Max(60, 100 - $dupGroups.Count * 10) }
    $score['duplicateRiskPct'] = $dupPct

    $score['overallPct'] = [math]::Round(($dirStructPct + $artifactHygienePct + $growthPct + $dupPct) / 4, 1)
    $score['events'] = $events
    $score['snapshotFiles'] = $snapFiles
    $score['unknownArtifacts'] = $unknown.Count
    $score['timestamp'] = (Get-Date).ToString('o')
    return $score
}

# Duplicate content detection by SHA256.
function Get-GuardianDuplicateGroups {
    param([string]$Path=$GuardianEnv.Root, [switch]$SampleOnly)
    if (-not (Test-Path $Path)) { return @() }
    $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
    if ($SampleOnly) { $files = $files | Select-Object -First 200 }
    $groups = $files | ForEach-Object {
        try { [PSCustomObject]@{ Path=$_.FullName; Hash=(Get-FileHash $_.FullName -Algorithm SHA256).Hash; Size=$_.Length } }
        catch { $null }
    } | Where-Object { $_ } | Group-Object Hash | Where-Object { $_.Count -gt 1 }
    return $groups | ForEach-Object {
        [PSCustomObject]@{ hash=$_.Name; count=$_.Count; files=($_.Group | Select-Object -ExpandProperty Path) }
    }
}

# Nested folder drift detection (project/project/project).
function Get-GuardianNestedDrift {
    param([string]$Path=$GuardianEnv.Root, [int]$DepthThreshold=4)
    $result = @()
    Get-ChildItem -Path $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $depth = ($_.FullName -replace [regex]::Escape($Path), '' -split '\\' | Where-Object { $_ }).Count
        if ($depth -ge $DepthThreshold) {
            $result += [PSCustomObject]@{ path=$_.FullName; depth=$depth }
        }
    }
    return $result
}

# Growth analysis: snapshot current sizes for trend comparison over time.
function Save-GuardianStorageBaseline {
    $stats = Get-GuardianStorageStats
    $baseline = Join-Path $GuardianEnv.Data 'storage_baseline.json'
    $payload = @{
        captured=(Get-Date).ToString('o')
        stats=$stats
    }
    $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $baseline -Encoding UTF8
    return $payload
}

function Get-GuardianStorageGrowth {
    $baseFile = Join-Path $GuardianEnv.Data 'storage_baseline.json'
    if (-not (Test-Path $baseFile)) { return @{ available=$false; note='no baseline captured' } }
    $base = Get-Content -Path $baseFile -Encoding UTF8 | ConvertFrom-Json
    $current = Get-GuardianStorageStats
    $delta = @{}
    foreach ($k in $current.Keys) {
        $prev = if ($base.stats.$k) { $base.stats.$k.mb } else { 0 }
        $delta[$k] = [math]::Round($current[$k].mb - $prev, 2)
    }
    return @{
        available=$true
        captured=$base.captured
        current=$current
        deltaMB=$delta
    }
}
