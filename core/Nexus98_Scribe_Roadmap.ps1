# Nexus98 Scribe Roadmap Generator
# Part of Nexus98 External Scribe Framework
# Version: 1.0.0

<#
.SYNOPSIS
    Auto-generates roadmap documentation from system state

.DESCRIPTION
    Observes milestones, test results, and system state to generate
    a living roadmap document. Designed for clean absorption into Nexus98.

.OUTPUTS
    - ROADMAP.md          - Main roadmap
    - ROADMAP.json        - Machine-readable roadmap
    - MILESTONE_DETAIL.md - Detailed milestone breakdown
#>

function Invoke-Nexus98ScribeRoadmap {
    param(
        [hashtable]$Config,
        [string]$OutputPath
    )

    Write-Host "[Nexus98 Scribe Roadmap] Generating..." -ForegroundColor Cyan

    # Load core module if not already loaded
    $corePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "Nexus98_Scribe_Core.ps1"
    if (-not $corePath -or -not (Test-Path $corePath)) { 
        $corePath = Join-Path (Resolve-Path ".").Path "core\Nexus98_Scribe_Core.ps1" 
    }
    if (-not $corePath -or -not (Test-Path $corePath)) { 
        $corePath = "D:\Nexus98_Guardian\core\Nexus98_Scribe_Core.ps1" 
    }
    if (Test-Path $corePath) {
        . $corePath
    }

    $rootPath = Split-Path $OutputPath -Parent
    if (-not $rootPath) { $rootPath = (Resolve-Path ".").Path }
    $snapshot = Get-Nexus98FullSnapshot -RootPath $rootPath -Config $Config

    $roadmap = @{
        generated   = (Get-Date).ToString('o')
        version     = "1.0.0"
        milestones  = @()
        current     = $null
        next        = @()
        summary     = @{}
    }

    # Extract milestones from Knowledge/INDEX.md
    if ($snapshot.knowledge.index) {
        $lines = $snapshot.knowledge.index -split "`r?`n"
        foreach ($line in $lines) {
            if ($line -match '^\s*[-*]\s*(M\d+.*?):\s*(.+)') {
                $id = $matches[1].Trim()
                $desc = $matches[2].Trim()
                $status = if ($line -match 'PASS') { 'COMPLETE' } elseif ($line -match 'ACTIVE|NEXT') { 'ACTIVE' } else { 'PENDING' }
                $roadmap.milestones += @{
                    id          = $id
                    description = $desc
                    status      = $status
                    source      = 'knowledge_index'
                    tests       = @()
                    related     = @()
                }
            }
        }
    }

    # Cross-reference with test results
    foreach ($test in $snapshot.tests.files) {
        if ($test.name -match '(M\d+)') {
            $mid = $matches[1]
            $existing = $roadmap.milestones | Where-Object { $_.id -eq $mid }
            if ($existing) {
                $existing.tests += $test.name
            }
        }
    }

    # Cross-reference with session files
    foreach ($session in $snapshot.knowledge.sessions) {
        if ($session.name -match '(M\d+)') {
            $mid = $matches[1]
            $existing = $roadmap.milestones | Where-Object { $_.id -eq $mid }
            if ($existing) {
                $existing.related += @{
                    type      = 'session'
                    title     = $session.name
                    path      = $session.path
                    timestamp = $session.modified
                }
            }
        }
    }

    # Determine current and next
    $completed = $roadmap.milestones | Where-Object { $_.status -eq 'COMPLETE' }
    $pending   = $roadmap.milestones | Where-Object { $_.status -ne 'COMPLETE' }

    $roadmap.current = if ($completed) { $completed | Select-Object -Last 1 } else { $null }
    $roadmap.next    = $pending | Sort-Object { [int]($_.id -replace 'M', '') }

    $roadmap.summary = @{
        total      = $roadmap.milestones.Count
        completed  = $completed.Count
        pending    = $pending.Count
        inProgress = ($roadmap.milestones | Where-Object { $_.status -eq 'ACTIVE' }).Count
    }

    # Write outputs
    $outPath = $OutputPath
    if (-not (Test-Path $outPath)) { New-Item -ItemType Directory -Force -Path $outPath | Out-Null }

    $roadmapPath = Join-Path $outPath "ROADMAP.md"
    $roadmapJsonPath = Join-Path $outPath "ROADMAP.json"
    $milestoneDetailPath = Join-Path $outPath "MILESTONE_DETAIL.md"

    ConvertTo-MarkdownRoadmap -Roadmap $roadmap | Set-Content $roadmapPath -Encoding UTF8
    $roadmap | ConvertTo-Json -Depth 10 | Set-Content $roadmapJsonPath -Encoding UTF8
    ConvertTo-MilestoneDetail -Roadmap $roadmap | Set-Content $milestoneDetailPath -Encoding UTF8

    Write-Host "[Roadmap] Written to $roadmapPath" -ForegroundColor Green

    return $roadmap
}

function ConvertTo-MarkdownRoadmap {
    param([hashtable]$Roadmap)

    $md = @()
    $md += "# Nexus98 Project Roadmap"
    $md += ""
    $md += "> Generated: $($Roadmap.generated)"
    $md += "> Version: $($Roadmap.version)"
    $md += ""
    $md += "## Summary"
    $md += ""
    $md += "- **Total Milestones**: $($Roadmap.summary.total)"
    $md += "- **Completed**: $($Roadmap.summary.completed)"
    $md += "- **In Progress**: $($Roadmap.summary.inProgress)"
    $md += "- **Pending**: $($Roadmap.summary.pending)"
    $md += ""

    if ($Roadmap.current) {
        $md += "## Current Milestone"
        $md += ""
        $md += "### $($Roadmap.current.id): $($Roadmap.current.description)"
        $md += ""
        $md += "- **Status**: $($Roadmap.current.status)"
        if ($Roadmap.current.tests.Count -gt 0) {
            $md += "- **Tests**: $($Roadmap.current.tests -join ', ')"
        }
        if ($Roadmap.current.related.Count -gt 0) {
            $md += "- **Related Sessions**: $($Roadmap.current.related.Count)"
        }
        $md += ""
    }

    if ($Roadmap.next.Count -gt 0) {
        $md += "## Upcoming Milestones"
        $md += ""
        foreach ($m in $Roadmap.next | Select-Object -First 5) {
            $md += "### $($m.id): $($m.description)"
            $md += ""
            $md += "- **Status**: $($m.status)"
            if ($m.tests.Count -gt 0) {
                $md += "- **Tests**: $($m.tests -join ', ')"
            }
            $md += ""
        }
    }

    $md += "## All Milestones"
    $md += ""
    $md += "| ID | Description | Status | Tests | Related |"
    $md += "|----|-------------|--------|-------|---------|"
    foreach ($m in $Roadmap.milestones) {
        $tests = $m.tests.Count
        $related = $m.related.Count
        $md += "| $($m.id) | $($m.description) | $($m.status) | $tests | $related |"
    }
    $md += ""

    $md += "---"
    $md += ""
    $md += "*Auto-generated by Nexus98 Scribe v1.0.0*"

    return $md -join "`n"
}

function ConvertTo-MilestoneDetail {
    param([hashtable]$Roadmap)

    $md = @()
    $md += "# Nexus98 Milestone Details"
    $md += ""
    $md += "> Generated: $($Roadmap.generated)"
    $md += "> Version: $($Roadmap.version)"
    $md += ""

    foreach ($m in $Roadmap.milestones) {
        $md += "## $($m.id): $($m.description)"
        $md += ""
        $md += "- **Status**: $($m.status)"
        $md += "- **Source**: $($m.source)"
        $md += ""

        if ($m.tests.Count -gt 0) {
            $md += "### Tests"
            $md += ""
            foreach ($t in $m.tests) {
                $md += "- $t"
            }
            $md += ""
        }

        if ($m.related.Count -gt 0) {
            $md += "### Related Artifacts"
            $md += ""
            foreach ($r in $m.related) {
                $md += "- **$($r.type)**: $($r.title) ($($r.timestamp))"
            }
            $md += ""
        }
    }

    $md += "---"
    $md += ""
    $md += "*Auto-generated by Nexus98 Scribe v1.0.0*"

    return $md -join "`n"
}