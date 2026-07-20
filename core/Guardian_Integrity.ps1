# Guardian System Integrity & Entropy Monitor.
# Detects directory drift, uncontrolled growth, duplicate artifacts,
# and orphan files. Produces integrity events instead of silent deletes.

$ApprovedDirs = @('core','config','data','logs','reports','tests','plugins','snapshots','scripts','.vscode','.codex')
$ApprovedTopLevel = @('core','config','data','logs','reports','tests','plugins','snapshots','scripts','.vscode','.codex','.venv')

function Get-GuardianIntegrityEvents {
    param([string]$Path=$GuardianEnv.Root)
    $events = @()

    # 1. Unexpected top-level directories (entropy / drift).
    Get-ChildItem -Path $Path -Directory -Force | ForEach-Object {
        if ($_.Name -notin $ApprovedTopLevel) {
            $events += New-GuardianSystemEvent -Component 'integrity' -Event "DIRECTORY_DRIFT_DETECTED: $($_.Name)" -Severity 'warning'
        }
    }

    # 2. Naming-entropy patterns (backup_final, copy_of, _vN_N).
    Get-ChildItem -Path $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -match '(?i)(backup(_final|_old|_new)?\d*|copy_of|temp\d*|_v\d+_\d+|snapshot.*snapshot)') {
            $events += New-GuardianSystemEvent -Component 'integrity' -Event "DUPLICATE_ARTIFACT_DETECTED: $($_.FullName)" -Severity 'warning'
        }
    }

    # 3. Snapshot growth.
    if (Test-Path $GuardianEnv.Snapshots) {
        $snapFiles = (Get-ChildItem -Path $GuardianEnv.Snapshots -Recurse -File -ErrorAction SilentlyContinue).Count
        if ($snapFiles -gt 2000) {
            $events += New-GuardianSystemEvent -Component 'storage' -Event "UNCONTROLLED_STORAGE_GROWTH: $snapFiles snapshot files" -Severity 'critical'
        }
    }

    return $events
}

function Get-GuardianStorageStats {
    $dirs = @('core','config','data','logs','reports','tests','snapshots','scripts')
    $result = @{}
    foreach ($d in $dirs) {
        $full = Join-Path $GuardianEnv.Root $d
        if (Test-Path $full) {
            $files = Get-ChildItem -Path $full -Recurse -File -ErrorAction SilentlyContinue
            $bytes = ($files | Measure-Object Length -Sum).Sum
            $result[$d] = @{ files=$files.Count; mb=[math]::Round($bytes/1MB,2) }
        }
    }
    return $result
}
