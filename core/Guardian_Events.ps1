# Guardian Event Intelligence (M2 P2).
# Structured intelligence about system activity. Events are NOT random
# logs; they are classified, searchable, and follow Guardian lifecycle rules.

$GuardianEventCategories = @('SYSTEM','FILE_SYSTEM','SECURITY','RECOVERY','GOVERNANCE')
$GuardianEventSeverities = @('INFO','WARNING','ERROR','CRITICAL')

function New-GuardianEvent {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][ValidateSet('SYSTEM','FILE_SYSTEM','SECURITY','RECOVERY','GOVERNANCE')][string]$Category,
        [ValidateSet('INFO','WARNING','ERROR','CRITICAL')][string]$Severity='INFO',
        [Parameter(Mandatory=$true)][string]$Description,
        [string]$AffectedComponent='',
        [hashtable]$Metadata=@{},
        [string]$ResolutionStatus='open',
        [string]$RelatedCheckpoint=''
    )
    $event = [PSCustomObject]@{
        event_id          = "EV_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 9999)"
        timestamp         = (Get-Date).ToString('o')
        source            = $Source
        category          = $Category
        severity          = $Severity
        description       = $Description
        affected_component= $AffectedComponent
        metadata          = $Metadata
        resolution_status = $ResolutionStatus
        related_checkpoint= $RelatedCheckpoint
    }
    return $event
}

function Write-GuardianEvent {
    param(
        [Parameter(Mandatory=$true)][object]$Event
    )
    $store = Join-Path $GuardianEnv.Data 'events'
    if (-not (Test-Path $store)) { New-Item -ItemType Directory -Force -Path $store | Out-Null }
    $file = Join-Path $store 'guardian_events.jsonl'
    $line = $Event | ConvertTo-Json -Depth 10 -Compress
    Add-Content -Path $file -Value $line -Encoding UTF8

    # Bridge into the audit trail for critical/error events.
    if ($Event.severity -in @('ERROR','CRITICAL') -and (Get-Command Write-GuardianAudit -ErrorAction SilentlyContinue)) {
        Write-GuardianAudit -Action "event_$($Event.category)" -Reason $Event.description -NewState $Event.event_id -Validation 'pending'
    }
    return $Event
}

function Get-GuardianEvents {
    param(
        [ValidateSet('SYSTEM','FILE_SYSTEM','SECURITY','RECOVERY','GOVERNANCE')][string]$Category='',
        [ValidateSet('INFO','WARNING','ERROR','CRITICAL')][string]$Severity='',
        [int]$Last=0
    )
    $file = Join-Path $GuardianEnv.Data 'events\guardian_events.jsonl'
    if (-not (Test-Path $file)) { return @() }
    $catFilter = $Category
    $sevFilter = $Severity
    $events = Get-Content -Path $file -Encoding UTF8 -ErrorAction SilentlyContinue |
        Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    if ($catFilter) { $events = $events | Where-Object { $_.category -eq $catFilter } }
    if ($sevFilter) { $events = $events | Where-Object { $_.severity -eq $sevFilter } }
    if ($Last -gt 0) { $events = $events | Select-Object -Last $Last }
    return $events
}

# De-duplication: collapse identical (source/category/description) within a window.
function Get-GuardianEventDuplicates {
    param([int]$WindowMinutes=60)
    $events = Get-GuardianEvents
    $cutoff = (Get-Date).AddMinutes(-$WindowMinutes)
    $groups = $events | Where-Object { [datetime]::Parse($_.timestamp) -ge $cutoff } |
        Group-Object { "$($_.source)|$($_.category)|$($_.description)" }
    return $groups | Where-Object { $_.Count -gt 1 } | ForEach-Object {
        [PSCustomObject]@{ key=$_.Name; count=$_.Count; sample=$_.Group[0] }
    }
}

function Invoke-GuardianEventRotation {
    param([int]$KeepDays=30)
    $file = Join-Path $GuardianEnv.Data 'events\guardian_events.jsonl'
    if (-not (Test-Path $file)) { return @{ rotated=0 } }
    $events = Get-Content -Path $file -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    $cutoff = (Get-Date).AddDays(-$KeepDays)
    $recent = $events | Where-Object { [datetime]::Parse($_.timestamp) -ge $cutoff }
    $archiveFile = Join-Path $GuardianEnv.Data "events\archive\events_$(Get-Date -Format 'yyyyMM').jsonl"
    New-Item -ItemType Directory -Force -Path (Split-Path $archiveFile) | Out-Null
    $old = $events | Where-Object { [datetime]::Parse($_.timestamp) -lt $cutoff }
    if ($old.Count -gt 0) { $old | ConvertTo-Json -Depth 10 -Compress | Set-Content -Path $archiveFile -Encoding UTF8 }
    $recent | ForEach-Object { $_ | ConvertTo-Json -Depth 10 -Compress } | Set-Content -Path $file -Encoding UTF8
    return @{ rotated=$old.Count; retained=$recent.Count }
}


