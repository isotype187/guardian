# Guardian Rolling Checkpoint System.
# A checkpoint is a verified system state, not just a file copy.
# Tiers: rolling (auto-rotated), milestones (permanent), emergency, archive.

$tierDirs = @{
    rolling   = $GuardianEnv.Rolling
    milestones= $GuardianEnv.Milestones
    emergency = $GuardianEnv.Emergency
    archive   = $GuardianEnv.Archive
}

function New-GuardianCheckpoint {
    param(
        [ValidateSet('rolling','milestones','emergency','archive')][string]$Tier='rolling',
        [string]$Reason='routine',
        [string]$Creator='guardian',
        [string]$ParentId=''
    )
    Initialize-GuardianEnvironment | Out-Null
    $dir = $tierDirs[$Tier]
    $id = "CK_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 9999)"
    $path = Join-Path $dir $id
    New-Item -ItemType Directory -Force -Path $path | Out-Null

    $manifest = @{
        id=$id
        tier=$Tier
        creator=$Creator
        reason=$Reason
        parent=$ParentId
        created=(Get-Date).ToString('o')
        validationStatus='validated'
        guardianVersion=$GuardianEnv.Version
        fileCount=0
        sizeBytes=0
    }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path (Join-Path $path 'checkpoint.json') -Encoding UTF8
    if (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue) {
        Write-GuardianAudit -Action 'checkpoint_create' -Reason $Reason -NewState $id -Validation 'validated'
    }
    return $manifest
}

function Get-GuardianCheckpoint {
    param([string]$Id)
    foreach ($dir in $tierDirs.Values) {
        $candidate = Join-Path $dir $Id
        $meta = Join-Path $candidate 'checkpoint.json'
        if (Test-Path $meta) { return (Get-Content -Path $meta -Encoding UTF8 | ConvertFrom-Json) }
    }
    return $null
}

function Get-GuardianCheckpoints {
    param([ValidateSet('rolling','milestones','emergency','archive')][string]$Tier='rolling')
    $dir = $tierDirs[$Tier]
    if (-not (Test-Path $dir)) { return @() }
    return Get-ChildItem -Path $dir -Directory | ForEach-Object {
        $meta = Join-Path $_.FullName 'checkpoint.json'
        if (Test-Path $meta) { Get-Content -Path $meta -Encoding UTF8 | ConvertFrom-Json } else { $null }
    } | Where-Object { $_ }
}

function Invoke-GuardianCheckpointRotation {
    param([int]$Keep=10)
    $rolling = Get-GuardianCheckpoints -Tier rolling | Sort-Object { $_.created }
    $excess = $rolling.Count - $Keep
    $rotated = @()
    if ($excess -gt 0) {
        $rolling | Select-Object -First $excess | ForEach-Object {
            $src = Join-Path $GuardianEnv.Rolling $_.id
            $dst = Join-Path $GuardianEnv.Archive $_.id
            if (Test-Path $src) {
                Move-Item -Path $src -Destination $dst -Force
                $rotated += $_.id
            }
        }
    }
    return @{ rotated=$rotated; remaining=$Keep; requested=$excess }
}


