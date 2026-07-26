# Nexus98 Scribe Sync Validator
# Part of Nexus98 External Scribe Framework
# Version: 1.0.0

<#
.SYNOPSIS
    Validates documentation stays in sync with system state

.DESCRIPTION
    Checks that documentation reflects actual system state.
    Reports drift, missing docs, stale content.
    Designed for clean absorption into mature Nexus98.
#>

function Test-Nexus98DocSync {
    param(
        [hashtable]$Config,
        [string]$DocsPath,
        [string]$RootPath = (Resolve-Path ".").Path,
        [switch]$Fix
    )

    Write-Host "[Nexus98 Scribe Sync] Validating..." -ForegroundColor Cyan

    # Load core module if not already loaded
    $corePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "Nexus98_Scribe_Core.ps1"
    if (Test-Path $corePath) {
        . $corePath
    }

    $snapshot = Get-Nexus98FullSnapshot -RootPath $RootPath -Config $Config

    $syncReport = @{
        timestamp    = (Get-Date).ToString('o')
        version      = "1.0.0"
        rootPath     = $RootPath
        docsPath     = $DocsPath
        overallSync  = $true
        issues       = @()
        missing      = @()
        stale        = @()
        drift        = @()
        recommendations = @()
    }

    # 1. Check all core modules have documentation
    $syncReport.issues += Check-ModuleDocs -Snapshot $snapshot

    # 2. Check all tests have documentation
    $syncReport.issues += Check-TestDocs -Snapshot $snapshot

    # 3. Check configuration docs
    $syncReport.issues += Check-ConfigDocs -Snapshot $snapshot

    # 4. Check milestone documentation
    $syncReport.issues += Check-MilestoneDocs -Snapshot $snapshot

    # 5. Check for stale documentation (>30 days)
    $syncReport.stale = Check-StaleDocs -Snapshot $snapshot

    # 6. Check for drift between code and docs
    $syncReport.drift = Check-CodeDocDrift -Snapshot $snapshot

    # 7. Check README consistency
    $syncReport.issues += Check-ReadmeConsistency -Snapshot $snapshot

    # 8. Check Knowledge Base consistency
    $syncReport.issues += Check-KnowledgeConsistency -Snapshot $snapshot

    # Determine overall sync status
    $criticalIssues = $syncReport.issues | Where-Object { $_.severity -eq 'CRITICAL' }
    $warningIssues = $syncReport.issues | Where-Object { $_.severity -eq 'WARNING' }

    if ($criticalIssues.Count -gt 0) {
        $syncReport.overallSync = $false
    }

    # Generate recommendations
    $syncReport.recommendations = Generate-SyncRecommendations -Issues $syncReport.issues -Stale $syncReport.stale -Drift $syncReport.drift

    # Write report
    $reportPath = Join-Path $DocsPath "SYNC_REPORT.md"
    $reportJsonPath = Join-Path $DocsPath "SYNC_REPORT.json"

    ConvertTo-MarkdownSyncReport -Report $syncReport | Set-Content $reportPath -Encoding UTF8
    $syncReport | ConvertTo-Json -Depth 10 | Set-Content $reportJsonPath -Encoding UTF8

    Write-Host "[Sync] Report written to $reportPath" -ForegroundColor Green

    return $syncReport
}

function Check-ModuleDocs {
    param([hashtable]$Snapshot)

    $issues = @()
    $corePath = Join-Path $Snapshot.rootPath "core"

    if (Test-Path $corePath) {
        $modules = Get-ChildItem $corePath -Filter "*.ps1"

        foreach ($m in $modules) {
            # Skip scribe modules themselves
            if ($m.BaseName -like "Nexus98_Scribe*") { continue }

            $docPath = Join-Path $Snapshot.rootPath "docs" ($m.BaseName + ".md")
            $hasDoc = Test-Path $docPath

            if (-not $hasDoc) {
                $issues += @{
                    severity    = 'WARNING'
                    category    = 'Module Documentation'
                    message     = "Module $($m.BaseName) lacks documentation"
                    path        = $m.FullName
                    expectedDoc = $docPath
                    fix         = "Create $docPath with module description, parameters, and examples"
                }
            }
        }
    }

    return $issues
}

function Check-TestDocs {
    param([hashtable]$Snapshot)

    $issues = @()
    $testPath = Join-Path $Snapshot.rootPath "tests"

    if (Test-Path $testPath) {
        $tests = Get-ChildItem $testPath -Filter "*.ps1"

        foreach ($t in $tests) {
            # Check if test file has documentation header
            $content = Get-Content $t.FullName -TotalCount 20 -Raw -ErrorAction SilentlyContinue

            if ($content -notmatch '^#.*SYNOPSIS|^#.*DESCRIPTION|^<#.*SYNOPSIS') {
                $issues += @{
                    severity = 'WARNING'
                    category = 'Test Documentation'
                    message  = "Test file $($t.BaseName) lacks documentation header"
                    path     = $t.FullName
                    fix      = "Add .SYNOPSIS and .DESCRIPTION comment block"
                }
            }
        }
    }

    return $issues
}

function Check-ConfigDocs {
    param([hashtable]$Snapshot)

    $issues = @()
    $configPath = Join-Path $Snapshot.rootPath "config"

    if (Test-Path $configPath) {
        $configs = Get-ChildItem $configPath -Filter "*.json"

        foreach ($c in $configs) {
            $docPath = Join-Path $Snapshot.rootPath "docs" ($c.BaseName + ".md")

            if (-not (Test-Path $docPath)) {
                $issues += @{
                    severity = 'INFO'
                    category = 'Config Documentation'
                    message  = "Config $($c.BaseName) lacks documentation"
                    path     = $c.FullName
                    expectedDoc = $docPath
                    fix      = "Create $docPath describing config schema and purpose"
                }
            }
        }
    }

    return $issues
}

function Check-MilestoneDocs {
    param([hashtable]$Snapshot)

    $issues = @()

    # Check if milestones in INDEX.md have corresponding docs
    if ($Snapshot.knowledge.index) {
        $lines = $Snapshot.knowledge.index -split "`r?`n"
        foreach ($line in $lines) {
            if ($line -match '^\s*[-*]\s*(M\d+.*?):\s*(.+)') {
                $milestone = $matches[1].Trim()
                $desc = $matches[2].Trim()

                # Check for milestone doc
                $docPath = Join-Path $Snapshot.rootPath "docs" ($milestone + ".md")
                $reportPath = Join-Path $Snapshot.rootPath "reports" ("*$milestone*.md")
                $reports = Get-ChildItem $Snapshot.rootPath "reports" -Filter "*$milestone*.md" -ErrorAction SilentlyContinue

                $hasDoc = (Test-Path $docPath) -or ($reports.Count -gt 0)

                if (-not $hasDoc) {
                    $issues += @{
                        severity = 'WARNING'
                        category = 'Milestone Documentation'
                        message  = "Milestone $milestone ($desc) lacks documentation"
                        path     = "Knowledge/INDEX.md"
                        fix      = "Create docs/$milestone.md or ensure report exists in reports/"
                    }
                }
            }
        }
    }

    return $issues
}

function Check-StaleDocs {
    param([hashtable]$Snapshot)

    $stale = @()
    $now = Get-Date
    $threshold = 30 # days

    # Check docs/
    $docPath = Join-Path $Snapshot.rootPath "docs"
    if (Test-Path $docPath) {
        $files = Get-ChildItem $docPath -Filter "*.md" -Recurse
        foreach ($f in $files) {
            $age = $now - $f.LastWriteTime
            if ($age.Days -gt $threshold) {
                $stale += @{
                    path     = $f.FullName.Substring($Snapshot.rootPath.Length + 1)
                    modified = $f.LastWriteTime.ToString('o')
                    ageDays  = $age.Days
                    size     = $f.Length
                }
            }
        }
    }

    # Check Knowledge/Sessions
    $sessionPath = Join-Path $Snapshot.rootPath "Knowledge\Sessions"
    if (Test-Path $sessionPath) {
        $files = Get-ChildItem $sessionPath -Filter "*.md"
        foreach ($f in $files) {
            $age = $now - $f.LastWriteTime
            if ($age.Days -gt $threshold) {
                $stale += @{
                    path     = $f.FullName.Substring($Snapshot.rootPath.Length + 1)
                    modified = $f.LastWriteTime.ToString('o')
                    ageDays  = $age.Days
                    size     = $f.Length
                }
            }
        }
    }

    return $stale
}

function Check-CodeDocDrift {
    param([hashtable]$Snapshot)

    $drift = @()

    $corePath = Join-Path $Snapshot.rootPath "core"
    if (Test-Path $corePath) {
        $modules = Get-ChildItem $corePath -Filter "*.ps1"

        foreach ($m in $modules) {
            $content = Get-Content $m.FullName -Raw
            $functions = [regex]::Matches($content, 'function\s+(\w+)') | ForEach-Object { $_.Groups[1].Value }

            if ($functions.Count -gt 0) {
                $docPath = Join-Path $Snapshot.rootPath "docs" ($m.BaseName + ".md")
                if (Test-Path $docPath) {
                    $docContent = Get-Content $docPath -Raw

                    # Simple check - do documented functions exist in code?
                    foreach ($fn in $functions) {
                        if ($docContent -notmatch $fn) {
                            $drift += @{
                                module    = $m.BaseName
                                function  = $fn
                                type      = 'undocumented_function'
                                severity  = 'INFO'
                                message   = "Function $fn in $($m.BaseName) not mentioned in documentation"
                            }
                        }
                    }
                }
            }
        }
    }

    return $drift
}

function Check-ReadmeConsistency {
    param([hashtable]$Snapshot)

    $issues = @()
    $readmePath = Join-Path $Snapshot.rootPath "README.md"

    if (Test-Path $readmePath) {
        $content = Get-Content $readmePath -Raw

        # Check version references
        if ($content -match 'Milestone:\s*\*\*M(\d+)') {
            $readmeMilestone = [int]$matches[1]

            # Check if knowledge index has same milestone
            if ($Snapshot.knowledge.index -match 'M(\d+)\s+Repository') {
                $indexMilestone = [int]$matches[1]

                if ($readmeMilestone -ne $indexMilestone) {
                    $issues += @{
                        severity = 'WARNING'
                        category = 'README Consistency'
                        message  = "README milestone (M$readmeMilestone) differs from INDEX.md (M$indexMilestone)"
                        path     = "README.md"
                        fix      = "Update README.md to match current milestone"
                    }
                }
            }
        }

        # Check test count references
        if ($content -match '(\d+)/(\d+)\s+passing') {
            $passed = [int]$matches[1]
            $total = [int]$matches[2]

            if ($passed -ne 14 -or $total -ne 14) {
                $issues += @{
                    severity = 'WARNING'
                    category = 'README Consistency'
                    message  = "README test count ($passed/$total) may be outdated"
                    path     = "README.md"
                    fix      = "Update test count in README.md"
                }
            }
        }
    }

    return $issues
}

function Check-KnowledgeConsistency {
    param([hashtable]$Snapshot)

    $issues = @()
    $kb = $Snapshot.knowledge

    # Check INDEX.md references exist
    if ($kb.index) {
        $lines = $kb.index -split "`r?`n"
        foreach ($line in $lines) {
            if ($line -match '\(([^)]+\.md)\)') {
                $ref = $matches[1]
                $refPath = Join-Path $Snapshot.rootPath "Knowledge" $ref
                if (-not (Test-Path $refPath)) {
                    $issues += @{
                        severity = 'WARNING'
                        category = 'Knowledge Base Link'
                        message  = "Broken link in INDEX.md: $ref"
                        path     = "Knowledge/INDEX.md"
                        fix      = "Create $refPath or fix link in INDEX.md"
                    }
                }
            }
        }
    }

    # Check session files referenced in INDEX
    foreach ($session in $kb.sessions) {
        if (-not (Test-Path $session.path)) {
            $issues += @{
                severity = 'WARNING'
                category = 'Session File'
                message  = "Session file referenced but missing: $($session.name)"
                path     = $session.path
                fix      = "Restore session file or remove reference"
            }
        }
    }

    return $issues
}

function Generate-SyncRecommendations {
    param([array]$Issues, [array]$Stale, [array]$Drift)

    $recs = @()

    # Critical issues first
    $critical = $Issues | Where-Object { $_.severity -eq 'CRITICAL' }
    if ($critical.Count -gt 0) {
        $recs += "CRITICAL: $($critical.Count) critical sync issues require immediate attention"
    }

    # Warnings
    $warnings = $Issues | Where-Object { $_.severity -eq 'WARNING' }
    if ($warnings.Count -gt 0) {
        $recs += "WARNING: $($warnings.Count) documentation gaps identified"
        $byCat = $warnings | Group-Object category
        foreach ($g in $byCat) {
            $recs += "  - $($g.Name): $($g.Count) issues"
        }
    }

    # Stale docs
    if ($Stale.Count -gt 0) {
        $recs += "$($Stale.Count) documents older than 30 days - review for currency"
    }

    # Drift
    if ($Drift.Count -gt 0) {
        $recs += "$($Drift.Count) potential code/doc drift items - verify documentation coverage"
    }

    # General
    if ($Issues.Count -eq 0 -and $Stale.Count -eq 0 -and $Drift.Count -eq 0) {
        $recs += "Documentation is well synchronized with system state"
    }

    return $recs
}

function ConvertTo-MarkdownSyncReport {
    param([hashtable]$Report)

    $md = @()
    $md += "# Nexus98 Documentation Sync Report"
    $md += ""
    $md += "> Generated: $($Report.timestamp)"
    $md += "> Version: $($Report.version)"
    $md += ""

    # Overall status
    $statusIcon = if ($Report.overallSync) { 'PASS' } else { 'FAIL' }
    $md += "## $statusIcon Overall Sync Status: $(if ($Report.overallSync) { 'IN SYNC' } else { 'OUT OF SYNC' })"
    $md += ""

    # Issues summary
    $critical = ($Report.issues | Where-Object { $_.severity -eq 'CRITICAL' }).Count
    $warning = ($Report.issues | Where-Object { $_.severity -eq 'WARNING' }).Count
    $info = ($Report.issues | Where-Object { $_.severity -eq 'INFO' }).Count

    $md += "### Issues Summary"
    $md += ""
    $md += "| Severity | Count |"
    $md += "|----------|-------|"
    $md += "| CRITICAL | $critical |"
    $md += "| WARNING  | $warning |"
    $md += "| INFO     | $info |"
    $md += ""

    # Stale docs
    if ($Report.stale.Count -gt 0) {
        $md += "### Stale Documents ($($Report.stale.Count))"
        $md += ""
        $md += "| Document | Last Modified | Age (days) | Size |"
        $md += "|----------|---------------|------------|------|"
        foreach ($s in $Report.stale | Sort-Object ageDays -Descending) {
            $md += "| $($s.path) | $($s.modified) | $($s.ageDays) | $($s.size) bytes |"
        }
        $md += ""
    }

    # Drift
    if ($Report.drift.Count -gt 0) {
        $md += "### Code/Doc Drift ($($Report.drift.Count))"
        $md += ""
        $md += "| Module | Function | Type | Severity |"
        $md += "|--------|----------|------|----------|"
        foreach ($d in $Report.drift) {
            $md += "| $($d.module) | $($d.function) | $($d.type) | $($d.severity) |"
        }
        $md += ""
    }

    # Detailed issues
    if ($Report.issues.Count -gt 0) {
        $md += "### Detailed Issues"
        $md += ""
        $md += "| Severity | Category | Message | Path | Fix |"
        $md += "|----------|----------|---------|------|-----|"
        foreach ($i in $Report.issues | Sort-Object { @{CRITICAL=0; WARNING=1; INFO=2}[$_.severity] }) {
            $sevIcon = switch ($i.severity) {
                'CRITICAL' { 'CRITICAL' }
                'WARNING'  { 'WARNING' }
                'INFO'     { 'INFO' }
                default    { 'INFO' }
            }
            $md += "| $sevIcon $($i.severity) | $($i.category) | $($i.message) | $($i.path) | $($i.fix) |"
        }
        $md += ""
    }

    # Recommendations
    $md += "## Recommendations"
    $md += ""
    foreach ($r in $Report.recommendations) {
        $md += "- $r"
    }
    $md += ""

    $md += "---"
    $md += ""
    $md += "*Auto-generated by Nexus98 Scribe v1.0.0*"

    return $md -join "`n"
}