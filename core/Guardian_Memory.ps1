# Guardian Memory Intelligence (M3 P2).
# Converts historical events and system states into operational knowledge.
# Memory is not a log: it answers "what does this mean?".

$GuardianMemoryTiers = @('short_term','long_term','pattern')
$GuardianRetentionClasses = @('ACTIVE','ARCHIVE','TEMPORARY','EXPERIMENTAL','OBSOLETE','UNKNOWN')

function New-GuardianMemory {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][ValidateSet('short_term','long_term','pattern')][string]$Category,
        [ValidateSet('low','medium','high','critical')][string]$Importance='medium',
        [double]$Confidence=0.5,
        [Parameter(Mandatory=$true)][string]$Description,
        [string[]]$RelatedEvents=@(),
        [string]$RelatedCheckpoint='',
        [ValidateSet('ACTIVE','ARCHIVE','TEMPORARY','EXPERIMENTAL','OBSOLETE','UNKNOWN')][string]$RetentionClass='ACTIVE'
    )
    return [PSCustomObject]@{
        memory_id        = "MEM_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(Get-Random -Maximum 9999)"
        timestamp        = (Get-Date).ToString('o')
        source           = $Source
        category         = $Category
        importance       = $Importance
        confidence       = $Confidence
        description      = $Description
        related_events   = $RelatedEvents
        related_checkpoint = $RelatedCheckpoint
        retention_class  = $RetentionClass
    }
}

function Write-GuardianMemory {
    param([Parameter(Mandatory=$true)][object]$Memory)
    $store = Join-Path $GuardianEnv.Data 'memory'
    New-Item -ItemType Directory -Force -Path $store | Out-Null
    $file = Join-Path $store 'guardian_memory.jsonl'
    $Memory | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $file -Encoding UTF8
    Write-GuardianAudit -Action 'memory_create' -Reason $Memory.description -NewState $Memory.memory_id -Validation 'pending' | Out-Null
    return $Memory
}

function Get-GuardianMemory {
    param(
        [ValidateSet('short_term','long_term','pattern')][string]$Category='',
        [ValidateSet('ACTIVE','ARCHIVE','TEMPORARY','EXPERIMENTAL','OBSOLETE','UNKNOWN')][string]$RetentionClass='',
        [int]$Last=0
    )
    $file = Join-Path $GuardianEnv.Data 'memory\guardian_memory.jsonl'
    if (-not (Test-Path $file)) { return @() }
    $catFilter = $Category
    $retFilter = $RetentionClass
    $mem = Get-Content -Path $file -Encoding UTF8 -ErrorAction SilentlyContinue |
        Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    if ($catFilter) { $mem = $mem | Where-Object { $_.category -eq $catFilter } }
    if ($retFilter) { $mem = $mem | Where-Object { $_.retention_class -eq $retFilter } }
    if ($Last -gt 0) { $mem = $mem | Select-Object -Last $Last }
    return $mem
}

function Search-GuardianMemory {
    param([Parameter(Mandatory=$true)][string]$Query)
    $mem = Get-GuardianMemory
    return $mem | Where-Object { ($_.description -match [regex]::Escape($Query)) -or ($_.source -match [regex]::Escape($Query)) }
}

function Compress-GuardianMemory {
    # Merge duplicate descriptions, keep highest importance/confidence.
    $mem = Get-GuardianMemory
    $groups = $mem | Group-Object { "$($_.category)|$($_.description)" }
    $merged = $groups | ForEach-Object {
        $g = $_.Group
        $imp = ($g | Sort-Object { @{low=0;medium=1;high=2;critical=3}[$_.importance] } -Descending | Select-Object -First 1).importance
        $conf = if ($g.confidence) { ($g.confidence | Measure-Object -Maximum).Maximum } else { 0.0 }
        $ev = @($g | ForEach-Object { $_.related_events } | ForEach-Object { $_ } | Where-Object { $_ } | Sort-Object -Unique)
        [PSCustomObject]@{
            memory_id=$g[0].memory_id; timestamp=$g[0].timestamp; source=$g[0].source; category=$g[0].category
            importance=$imp; confidence=$conf; description=$g[0].description
            related_events=$ev; related_checkpoint=$g[0].related_checkpoint; retention_class=$g[0].retention_class
        }
    }
    return $merged
}

function Invoke-GuardianMemoryLifecycle {
    param(
        [double]$MinImportance=0.2,
        [int]$ShortTermMaxDays=7
    )
    $file = Join-Path $GuardianEnv.Data 'memory\guardian_memory.jsonl'
    if (-not (Test-Path $file)) { return @{ archived=0; expired=0; retained=0 } }
    $mem = Get-Content -Path $file -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json }
    $now = Get-Date
    $retained = @(); $expired = @(); $archived = @()
    foreach ($m in $mem) {
        $age = ($now - [datetime]::Parse($m.timestamp)).Days
        if ($m.importance -lt $MinImportance -or ($m.category -eq 'short_term' -and $age -gt $ShortTermMaxDays)) {
            $expired += $m
        } elseif ($m.category -eq 'short_term' -and $m.importance -ge 'high') {
            $archived += $m
        } else {
            $retained += $m
        }
    }
    $archived | ForEach-Object { $_.retention_class = 'ARCHIVE' }
    ($retained + $archived) | ForEach-Object { $_ | ConvertTo-Json -Depth 10 -Compress } | Set-Content -Path $file -Encoding UTF8
    return @{ archived=$archived.Count; expired=$expired.Count; retained=$retained.Count }
}

function Get-GuardianMemorySummary {
    $mem = Get-GuardianMemory
    $byCat = ($mem | Group-Object category | ForEach-Object { @{ category=$_.Name; count=$_.Count } })
    return @{
        total=$mem.Count
        byCategory=($mem | Group-Object category | ForEach-Object { @{ category=$_.Name; count=$_.Count } })
        avgConfidence=if($mem.Count){ [math]::Round(($mem.confidence | Measure-Object -Average).Average,2) }else{0}
        timestamp=(Get-Date).ToString('o')
    }
}


