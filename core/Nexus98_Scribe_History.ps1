# Nexus98 Scribe History Tracker
# Part of Nexus98 External Scribe Framework
# Version: 1.0.0

<#
.SYNOPSIS
    Tracks changes and generates changelog/history

.DESCRIPTION
    Observes git history, test results, and system events to generate
    a comprehensive history/changelog. Designed for clean absorption
    into mature Nexus98.
#>

function Invoke-Nexus98ScribeHistory {
    param(
        [hashtable]$Config,
        [string]$OutputPath,
        [string]$RootPath = (Resolve-Path ".").Path,
        [int]$MaxEntries = 100
    )

    Write-Host "[Nexus98 Scribe History] Generating..." -ForegroundColor Cyan

    # Load core module if not already loaded
    $corePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "Nexus98_Scribe_Core.ps1"
    if (Test-Path $corePath) {
        . $corePath
    }

    $snapshot = Get-Nexus98FullSnapshot -RootPath $RootPath -Config $Config

    $history = @{
        generated   = (Get-Date).ToString('o')
        version     = "1.0.0"
        entries     = @()
        milestones  = @()
        sessions    = @()
    }

    # 1. Git History
    $history.entries += Get-GitHistory -RootPath $RootPath -MaxEntries $MaxEntries

    # 2. Milestone Events
    $history.milestones = Get-MilestoneEvents -RootPath $RootPath -Snapshot $snapshot

    # 3. Session Events
    $history.sessions = Get-SessionEvents -RootPath $RootPath

    # 4. Test History
    $history.entries += Get-TestHistory -RootPath $RootPath -MaxEntries $MaxEntries

    # 5. Documentation Changes
    $history.entries += Get-DocHistory -RootPath $RootPath -MaxEntries $MaxEntries

    # 6. Configuration Changes
    $history.entries += Get-ConfigHistory -RootPath $RootPath -MaxEntries $MaxEntries

    # Sort all entries by timestamp
    $history.entries = $history.entries | Sort-Object { [datetime]::Parse($_.timestamp) } -Descending

    # Write outputs
    $historyPath = Join-Path $OutputPath "HISTORY.md"
    $historyJsonPath = Join-Path $OutputPath "HISTORY.json"
    $changelogPath = Join-Path $OutputPath "CHANGELOG.md"

    ConvertTo-MarkdownHistory -History $history | Set-Content $historyPath -Encoding UTF8
    $history | ConvertTo-Json -Depth 10 | Set-Content $historyJsonPath -Encoding UTF8
    ConvertTo-Changelog -History $history | Set-Content $changelogPath -Encoding UTF8

    Write-Host "[History] Written to $historyPath" -ForegroundColor Green

    return $history
}

function Get-GitHistory {
    param([string]$RootPath, [int]$MaxEntries)

    $entries = @()

    try {
        # Get recent commits
        $commits = & git -C $RootPath log --oneline --all --max-count $MaxEntries --pretty=format:"%H|%an|%ad|%s" --date=iso 2>$null

        if ($LASTEXITCODE -eq 0 -and $commits) {
            foreach ($line in $commits) {
                $parts = $line -split '\|', 4
                if ($parts.Count -eq 4) {
                    $entries += @{
                        type        = 'commit'
                        timestamp   = $parts[2]
                        author      = $parts[1]
                        hash        = $parts[0].Substring(0, 7)
                        message     = $parts[3]
                        category    = Classify-CommitMessage $parts[3]
                        breaking    = ($parts[3] -match 'BREAKING CHANGE|!:' -or $parts[3] -match '^\w+\(.+\)!') 
                    }
                }
            }
        }
    } catch {
        $entries += @{
            type      = 'error'
            timestamp = (Get-Date).ToString('o')
            message   = "Failed to get git history: $($_.Exception.Message)"
        }
    }

    return $entries
}

function Classify-CommitMessage {
    param([string]$Message)

    if ($Message -match '^feat')      { return 'Feature' }
    if ($Message -match '^fix')       { return 'Fix' }
    if ($Message -match '^docs')      { return 'Documentation' }
    if ($Message -match '^test')      { return 'Test' }
    if ($Message -match '^refactor')  { return 'Refactor' }
    if ($Message -match '^chore')     { return 'Chore' }
    if ($Message -match '^style')     { return 'Style' }
    if ($Message -match '^perf')      { return 'Performance' }
    if ($Message -match '^ci')        { return 'CI/CD' }
    if ($Message -match '^build')     { return 'Build' }
    if ($Message -match '^revert')    { return 'Revert' }

    return 'Other'
}

function Get-MilestoneEvents {
    param([string]$RootPath, [hashtable]$Snapshot)

    $milestones = @()

    # From Knowledge/INDEX.md
    if ($Snapshot.knowledge.index) {
        $lines = $Snapshot.knowledge.index -split "`r?`n"
        foreach ($line in $lines) {
            if ($line -match '^\s*[-*]\s*(M\d+.*?):\s*(.+)') {
                $milestones += @{
                    id          = $matches[1].Trim()
                    description = $matches[2].Trim()
                    source      = 'knowledge_index'
                    timestamp   = (Get-Date).ToString('o') # Approximate
                    events      = @()
                }
            }
        }
    }

    # From session files
    foreach ($session in $Snapshot.knowledge.sessions) {
        if ($session.name -match '(M\d+)') {
            $mId = $matches[1]
            $existing = $milestones | Where-Object { $_.id -eq $mId }
            if ($existing) {
                $existing.events += @{
                    type      = 'session'
                    timestamp = $session.modified
                    title     = $session.name
                    path      = $session.path
                }
            }
        }
    }

    return $milestones | Sort-Object { [int]($_.id -replace 'M', '') }
}

function Get-SessionEvents {
    param([string]$RootPath)

    $sessionsPath = Join-Path $RootPath "Knowledge\Sessions"
    $sessions = @()

    if (Test-Path $sessionsPath) {
        $files = Get-ChildItem $sessionsPath -Filter "*.md" | Sort-Object LastWriteTime -Descending

        foreach ($f in $files) {
            $content = Get-Content $f.FullName -Raw
            $sessions += @{
                name      = $f.BaseName
                path      = $f.FullName
                timestamp = $f.LastWriteTime.ToString('o')
                size      = $f.Length
                preview   = $content.Substring(0, [math]::Min(500, $content.Length))
            }
        }
    }

    return $sessions
}

function Get-TestHistory {
    param([string]$RootPath, [int]$MaxEntries)

    $entries = @()
    $testResultsPath = Join-Path $RootPath "data\test_results"

    if (Test-Path $testResultsPath) {
        $files = Get-ChildItem $testResultsPath -Filter "*.json" | Sort-Object LastWriteTime -Descending
        foreach ($f in $files | Select-Object -First $MaxEntries) {
            try {
                $content = Get-Content $f.FullName -Raw | ConvertFrom-Json
                $entries += @{
                    type      = 'test_run'
                    timestamp = $f.LastWriteTime.ToString('o')
                    file      = $f.Name
                    passed    = if ($content.passed) { $content.passed } elseif ($content.TestsPassed) { $content.TestsPassed } else { 0 }
                    failed    = if ($content.failed) { $content.failed } elseif ($content.TestsFailed) { $content.TestsFailed } else { 0 }
                    total     = if ($content.total) { $content.total } elseif ($content.TestsTotal) { $content.TestsTotal } else { 0 }
                    duration  = if ($content.duration) { $content.duration } elseif ($content.Duration) { $content.Duration } else { 0 }
                }
            } catch { }
        }
    }

    return $entries
}

function Get-DocHistory {
    param([string]$RootPath, [int]$MaxEntries)

    $entries = @()
    $docPath = Join-Path $RootPath "docs"

    if (Test-Path $docPath) {
        $files = Get-ChildItem $docPath -Filter "*.md" -Recurse | Sort-Object LastWriteTime -Descending

        foreach ($f in $files | Select-Object -First $MaxEntries) {
            $entries += @{
                type      = 'doc_change'
                timestamp = $f.LastWriteTime.ToString('o')
                path      = $f.FullName.Substring($RootPath.Length + 1)
                action    = 'modified'
                size      = $f.Length
            }
        }
    }

    return $entries
}

function Get-ConfigHistory {
    param([string]$RootPath, [int]$MaxEntries)

    $entries = @()
    $configPath = Join-Path $RootPath "config"

    if (Test-Path $configPath) {
        $files = Get-ChildItem $configPath -Filter "*.json" -Recurse | Sort-Object LastWriteTime -Descending

        foreach ($f in $files | Select-Object -First $MaxEntries) {
            $entries += @{
                type      = 'config_change'
                timestamp = $f.LastWriteTime.ToString('o')
                path      = $f.FullName.Substring($RootPath.Length + 1)
                action    = 'modified'
                size      = $f.Length
            }
        }
    }

    return $entries
}

function ConvertTo-MarkdownHistory {
    param([hashtable]$History)

    $md = @()
    $md += "# Nexus98 Project History"
    $md += ""
    $md += "> Generated: $($History.generated)"
    $md += "> Version: $($History.version)"
    $md += ""
    $md += "## Summary"
    $md += ""
    $md += "- **Total Events**: $($History.entries.Count)"
    $md += "- **Milestones**: $($History.milestones.Count)"
    $md += "- **Sessions**: $($History.sessions.Count)"
    $md += ""

    # Milestones
    $md += "## Milestones"
    $md += ""
    foreach ($m in $History.milestones) {
        $md += "### $($m.id)"
        $md += ""
        $md += "- **Description**: $($m.description)"
        $md += "- **Source**: $($m.source)"
        if ($m.events.Count -gt 0) {
            $md += "- **Events**:"
            foreach ($e in $m.events) {
                $md += "  - $($e.type): $($e.title) ($($e.timestamp))"
            }
        }
        $md += ""
    }

    # Recent Events
    $md += "## Recent Events (Last 50)"
    $md += ""
    $md += "| Time | Type | Category | Message |"
    $md += "|------|------|----------|---------|"

    foreach ($e in $History.entries | Select-Object -First 50) {
        $time = [datetime]::Parse($e.timestamp).ToString('yyyy-MM-dd HH:mm')
        $cat = if ($e.category) { $e.category } else { '' }
        $msg = if ($e.message) { $e.message } elseif ($e.title) { $e.title } else { '' }
        $msg = $msg -replace '\|', '\\|' -replace "`r?`n", ' '
        $md += "| $time | $($e.type) | $cat | $msg |"
    }
    $md += ""

    # Sessions
    $md += "## Sessions"
    $md += ""
    $md += "| Session | Time | Preview |"
    $md += "|---------|------|---------|"
    foreach ($s in $History.sessions | Select-Object -First 20) {
        $time = [datetime]::Parse($s.timestamp).ToString('yyyy-MM-dd HH:mm')
        $preview = $s.preview -replace '\|', '\\|' -replace "`r?`n", ' ' -replace '\s+', ' '
        $preview = $preview.Substring(0, [math]::Min(100, $preview.Length))
        $md += "| $($s.name) | $time | $preview... |"
    }
    $md += ""

    $md += "---"
    $md += ""
    $md += "*Auto-generated by Nexus98 Scribe v1.0.0*"

    return $md -join "`n"
}

function ConvertTo-Changelog {
    param([hashtable]$History)

    $md = @()
    $md += "# Nexus98 Changelog"
    $md += ""
    $md += "> Generated: $($History.generated)"
    $md += ""
    $md += "## [Unreleased]"
    $md += ""

    # Group by date
    $byDate = $History.entries | Group-Object { [datetime]::Parse($_.timestamp).ToString('yyyy-MM-dd') }

    foreach ($group in $byDate | Sort-Object Name -Descending) {
        $date = $group.Name
        $md += "### $date"
        $md += ""

        $byCat = $group.Group | Group-Object { if ($_.category) { $_.category } else { $_.type } }

        foreach ($cat in $byCat) {
            $catName = $cat.Name
            $md += "#### $catName"
            $md += ""

            foreach ($e in $cat.Group) {
                $msg = if ($e.message) { $e.message } elseif ($e.title) { $e.title } else { '' }
                $hash = if ($e.hash) { " ($($e.hash))" } else { '' }
                $md += "- $msg$hash"
            }
            $md += ""
        }
    }

    $md += "---"
    $md += ""
    $md += "*Auto-generated by Nexus98 Scribe v1.0.0*"

    return $md -join "`n"
}