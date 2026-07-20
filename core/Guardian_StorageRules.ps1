# Guardian Storage Hygiene Rules (M1 P5).
# Enforces the no-entropy policy: no recursive backups, uncontrolled
# snapshots, duplicate project copies, random generated folders, or
# unmanaged logs. Every generated artifact must have owner/location/
# lifecycle/cleanup policy.

$GuardianStorageAntiPatterns = @(
    '(?i)backup(_final|_old|_new)?\d*'
    '(?i)copy_of'
    '(?i)temp\d*'
    '(?i)_v\d+_\d+'
    '(?i)snapshot.*snapshot'
    '(?i)(final|old|new|realfinal|final2)\b'
)

function Test-GuardianStorageHygiene {
    param([string]$Path=$GuardianEnv.Root)
    $violations = @()
    Get-ChildItem -Path $Path -Recurse -Force -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        foreach ($pat in $GuardianStorageAntiPatterns) {
            if ($_.Name -match $pat) {
                $violations += [PSCustomObject]@{
                    type='naming_entropy'
                    path=$_.FullName
                    pattern=$pat
                }
            }
        }
    }
    return $violations
}

# Classification per the M1 brief.
function Get-GuardianArtifactClassification {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 'UNKNOWN' }
    $isManaged = $Path -like "*\data\checkpoints\*" -or $Path -like "*\core\Guardian_*" -or $Path -like "*\docs\*"
    if ($isManaged) { return 'ACTIVE' }
    if ($Path -like "*\archive\*") { return 'ARCHIVE' }
    if ($Path -like "*\snapshots\*") { return 'TEMPORARY' }
    if ($Path -like "*\logs\*" -or $Path -like "*\reports\*") { return 'OBSOLETE' }
    return 'UNKNOWN'
}

function New-GuardianHygieneReport {
    $violations = Test-GuardianStorageHygiene
    return @{
        generated=(Get-Date).ToString('o')
        violations=$violations
        violationCount=$violations.Count
        rule='No recursive backups, uncontrolled snapshots, duplicate copies, random folders, or unmanaged logs.'
    }
}
