# Nexus98 Scribe Status Dashboard
# Part of Nexus98 External Scribe Framework
# Version: 1.0.0

<#
.SYNOPSIS
    Generates comprehensive status dashboard

.DESCRIPTION
    Aggregates health, alerts, metrics, and component status
    into a unified dashboard. Outputs Markdown and HTML.
    Designed for clean absorption into mature Nexus98.
#>

function Invoke-Nexus98ScribeStatus {
    param(
        [hashtable]$Config,
        [string]$OutputPath,
        [string]$Root = (Resolve-Path ".").Path
    )

    Write-Host "[Nexus98 Scribe Status] Generating dashboard..." -ForegroundColor Cyan

    # Load core module if not already loaded
    $corePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "Nexus98_Scribe_Core.ps1"
    if (Test-Path $corePath) {
        . $corePath
    }

    $snapshot = Get-Nexus98FullSnapshot -RootPath $Root -Config $Config

    $status = @{
        generated      = (Get-Date).ToString('o')
        version        = "1.0.0"
        root           = $Root
        overallHealth  = "UNKNOWN"
        components     = @()
        alerts         = @()
        metrics        = @{}
        recommendations = @()
    }

    # 1. Guardian Health
    $guardian = $snapshot.system.guardian
    if ($guardian.healthScore) {
        $healthClass = if ($guardian.healthScore -ge 90) { 'HEALTHY' }
                      elseif ($guardian.healthScore -ge 70) { 'DEGRADED' }
                      elseif ($guardian.healthScore -ge 50) { 'UNHEALTHY' }
                      else { 'CRITICAL' }

        $status.components += @{
            category = 'Guardian Core'
            status   = $healthClass
            healthy  = if ($healthClass -eq 'HEALTHY') { 1 } else { 0 }
            total    = 1
            score    = $guardian.healthScore
            details  = "Overall Guardian health score"
        }
        $status.metrics.guardianHealth = $guardian.healthScore
    } else {
        $status.components += @{
            category = 'Guardian Core'
            status   = 'UNKNOWN'
            healthy  = 0
            total    = 1
            score    = 0
            details  = 'Guardian not loaded or health unavailable'
        }
    }

    # 2. Test Health
    $testFiles = $snapshot.tests.files
    if ($testFiles.Count -gt 0) {
        $testPassed = 0
        $testTotal = $testFiles.Count
        
        # Try running foundation tests
        $runner = Join-Path $Root "tests\run_foundation_tests.ps1"
        if (Test-Path $runner) {
            $output = & powershell -ExecutionPolicy Bypass -File $runner 2>&1
            if ($output -match 'Tests Passed:\s*(\d+)') {
                $testPassed = [int]$matches[1]
            }
        }
        
        $testClass = if ($testPassed -eq $testTotal) { 'HEALTHY' }
                     elseif ($testPassed -gt 0) { 'DEGRADED' }
                     else { 'UNHEALTHY' }

        $status.components += @{
            category = 'Test Suite'
            status   = $testClass
            healthy  = $testPassed
            total    = $testTotal
            score    = if ($testTotal -gt 0) { [math]::Round(($testPassed / $testTotal) * 100, 1) } else { 0 }
            details  = "Foundation tests: $testPassed/$testTotal passing"
        }
        $status.metrics.testPassRate = $status.components[-1].score
    }

    # 3. Documentation Coverage
    $docFiles = $snapshot.docs.files
    $moduleFiles = $snapshot.system.modules
    $undocModules = $moduleFiles.Keys | Where-Object { 
        -not (Test-Path (Join-Path $Root "docs" ($_.BaseName + ".md")))
    }
    
    $docCoverage = if ($moduleFiles.Count -gt 0) {
        [math]::Round((($moduleFiles.Count - $undocModules.Count) / $moduleFiles.Count) * 100, 1)
    } else { 0 }
    
    $docClass = if ($docCoverage -ge 80) { 'HEALTHY' }
                elseif ($docCoverage -ge 50) { 'DEGRADED' }
                else { 'UNHEALTHY' }
    
    $status.components += @{
        category = 'Documentation'
        status   = $docClass
        healthy  = $moduleFiles.Count - $undocModules.Count
        total    = $moduleFiles.Count
        score    = $docCoverage
        details  = "Module documentation coverage: $docCoverage%"
    }
    $status.metrics.docCoverage = $docCoverage

    # 3. Knowledge Base Health
    $kbFiles = $snapshot.knowledge.sessions.Count + $snapshot.knowledge.milestones.Count + $snapshot.knowledge.decisions.Count
    $kbClass = if ($kbFiles -gt 0) { 'HEALTHY' } else { 'DEGRADED' }
    
    $status.components += @{
        category = 'Knowledge Base'
        status   = $kbClass
        healthy  = if ($kbFiles -gt 0) { 1 } else { 0 }
        total    = 1
        score    = if ($kbFiles -gt 0) { 100 } else { 50 }
        details  = "Sessions: $($snapshot.knowledge.sessions.Count), Milestones: $($snapshot.knowledge.milestones.Count), Decisions: $($snapshot.knowledge.decisions.Count)"
    }
    $status.metrics.knowledgeFiles = $kbFiles

    # 4. Git Status
    $git = $snapshot.system.git
    $gitClass = if ($git.available) { 'HEALTHY' } else { 'WARNING' }
    $status.components += @{
        category = 'Version Control'
        status   = $gitClass
        healthy  = if ($git.available) { 1 } else { 0 }
        total    = 1
        score    = if ($git.available) { 100 } else { 50 }
        details  = if ($git.available) { "Branch: $($git.branch), Commit: $($git.commit)" } else { 'Git not available' }
    }
    $status.metrics.gitAvailable = if ($git.available) { 1 } else { 0 }

    # 5. Communication Bus
    $commDir = Join-Path $Root "communication"
    $commHealth = 'UNKNOWN'
    if (Test-Path $commDir) {
        $inbox = @(Get-ChildItem (Join-Path $commDir "inbox") -Filter "*.json" -ErrorAction SilentlyContinue).Count
        $outbox = @(Get-ChildItem (Join-Path $commDir "outbox") -Filter "*.json" -ErrorAction SilentlyContinue).Count
        $failed = @(Get-ChildItem (Join-Path $commDir "failed") -Filter "*.json" -ErrorAction SilentlyContinue).Count
        
        $commClass = if ($failed -eq 0) { 'HEALTHY' } elseif ($failed -le 5) { 'DEGRADED' } else { 'UNHEALTHY' }
        $status.components += @{
            category = 'Communication Bus'
            status   = $commClass
            healthy  = if ($commClass -eq 'HEALTHY') { 1 } else { 0 }
            total    = 1
            score    = if ($failed -eq 0) { 100 } elseif ($failed -le 5) { 75 } else { 50 }
            details  = "Inbox: $inbox, Outbox: $outbox, Failed: $failed"
        }
        $status.metrics.commInbox = $inbox
        $status.metrics.commOutbox = $outbox
        $status.metrics.commFailed = $failed
    }

    # Calculate overall health
    $healthScores = $status.components | Where-Object { $_.score -ne $null } | ForEach-Object { $_.score }
    $avgHealth = if ($healthScores.Count -gt 0) { [math]::Round(($healthScores | Measure-Object -Average).Average, 1) } else { 0 }
    
    $status.overallHealth = if ($avgHealth -ge 90) { 'HEALTHY' }
                           elseif ($avgHealth -ge 70) { 'DEGRADED' }
                           elseif ($avgHealth -ge 50) { 'UNHEALTHY' }
                           else { 'CRITICAL' }

    # Generate alerts
    $status.alerts = Generate-Alerts -Components $status.components -Metrics $status.metrics

    # Generate recommendations
    $status.recommendations = Generate-Recommendations -Components $status.components -Metrics $status.metrics

    # Write outputs
    $outPath = $OutputPath
    if (-not (Test-Path $outPath)) { New-Item -ItemType Directory -Force -Path $outPath | Out-Null }

    $statusPath = Join-Path $outPath "STATUS.md"
    $statusHtmlPath = Join-Path $outPath "STATUS.html"
    $statusJsonPath = Join-Path $outPath "STATUS.json"

    ConvertTo-MarkdownStatus -Status $status | Set-Content $statusPath -Encoding UTF8
    ConvertTo-HtmlStatus -Status $status | Set-Content $statusHtmlPath -Encoding UTF8
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusJsonPath -Encoding UTF8

    Write-Host "[Status] Written to $statusPath" -ForegroundColor Green

    return $status
}

function Generate-Alerts {
    param([array]$Components, [hashtable]$Metrics)
    $alerts = @()

    foreach ($c in $Components) {
        if ($c.status -eq 'CRITICAL' -or $c.status -eq 'UNHEALTHY') {
            $alerts += @{
                level   = 'CRITICAL'
                message = "$($c.category) is $($c.status): $($c.details)"
                time    = (Get-Date).ToString('o')
            }
        }
        elseif ($c.status -eq 'DEGRADED') {
            $alerts += @{
                level   = 'WARNING'
                message = "$($c.category) is $($c.status): $($c.details)"
                time    = (Get-Date).ToString('o')
            }
        }
    }

    # Metric-based alerts
    if ($Metrics.testPassRate -lt 100) {
        $alerts += @{ level = 'WARNING'; message = "Test pass rate below 100%: $($Metrics.testPassRate)%"; time = (Get-Date).ToString('o') }
    }
    if ($Metrics.docCoverage -lt 80) {
        $alerts += @{ level = 'WARNING'; message = "Documentation coverage below 80%: $($Metrics.docCoverage)%"; time = (Get-Date).ToString('o') }
    }
    if ($Metrics.commFailed -gt 10) {
        $alerts += @{ level = 'CRITICAL'; message = "Communication bus has $($Metrics.commFailed) failed messages"; time = (Get-Date).ToString('o') }
    }
    if (-not $Metrics.gitAvailable) {
        $alerts += @{ level = 'CRITICAL'; message = "Git repository not available"; time = (Get-Date).ToString('o') }
    }

    return $alerts
}

function Generate-Recommendations {
    param([array]$Components, [hashtable]$Metrics)
    $recs = @()

    # Priority: Critical health
    $critical = $Components | Where-Object { $_.status -in @('CRITICAL', 'UNHEALTHY') }
    if ($critical.Count -gt 0) {
        $recs += "🔴 CRITICAL: $($critical.Count) components need immediate attention"
    }

    # Documentation gaps
    if ($Metrics.docCoverage -lt 80) {
        $recs += "📄 Documentation coverage is $($Metrics.docCoverage)% - add missing module docs"
    }

    # Test failures
    if ($Metrics.testPassRate -lt 100) {
        $recs += "🧪 Test pass rate is $($Metrics.testPassRate)% - investigate failing tests"
    }

    # Communication failures
    if ($Metrics.commFailed -gt 0) {
        $recs += "📨 $($Metrics.commFailed) failed messages in communication bus - run recovery"
    }

    # Git
    if (-not $Metrics.gitAvailable) {
        $recs += "🔧 Git repository not accessible - check vcs/.git"
    }

    if ($recs.Count -eq 0) {
        $recs += "✅ All systems healthy - no immediate action required"
    }

    return $recs
}

function ConvertTo-MarkdownStatus {
    param([hashtable]$Status)
    
    $md = @()
    $md += "# Nexus98 Status Dashboard"
    $md += ""
    $md += "> Generated: $($Status.generated)"
    $md += "> Version: $($Status.version)"
    $md += ""

    # Overall health
    $healthClass = $Status.overallHealth
    $md += "## Overall Health: $healthClass"
    $md += ""
    
    # Components table
    $md += "## Component Health"
    $md += ""
    $md += "| Component | Status | Healthy/Total | Score | Details |"
    $md += "|-----------|--------|---------------|-------|---------|"
    foreach ($c in $Status.components) {
        $statusText = $c.status
        $md += "| $($c.category) | $statusText | $($c.healthy)/$($c.total) | $($c.score)% | $($c.details) |"
    }
    $md += ""

    # Metrics
    $md += "## Key Metrics"
    $md += ""
    $md += "| Metric | Value |"
    $md += "|--------|-------|"
    foreach ($m in $Status.metrics.GetEnumerator()) {
        $md += "| $($m.Key) | $($m.Value) |"
    }
    $md += ""

    # Alerts
    if ($Status.alerts.Count -gt 0) {
        $md += "## Alerts"
        $md += ""
        $md += "| Level | Message | Time |"
        $md += "|-------|---------|------|"
        foreach ($a in $Status.alerts) {
            $md += "| $($a.level) | $($a.message) | $($a.time) |"
        }
        $md += ""
    }

    # Recommendations
    $md += "## Recommendations"
    $md += ""
    foreach ($r in $Status.recommendations) {
        $md += "- $r"
    }
    $md += ""

    $md += "---"
    $md += ""
    $md += "*Auto-generated by Nexus98 Scribe v1.0.0*"

    return $md -join "`n"
}

function ConvertTo-HtmlStatus {
    param([hashtable]$Status)
    
    $html = @()
    $html += "<!DOCTYPE html>"
    $html += "<html><head>"
    $html += "<title>Nexus98 Status Dashboard</title>"
    $html += "<style>"
    $html += "body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #1e1e1e; color: #d4d4d4; }"
    $html += "h1 { color: #4ec9b0; } h2 { color: #9cdcfe; }"
    $html += "table { border-collapse: collapse; width: 100%; margin: 10px 0; }"
    $html += "th, td { border: 1px solid #333; padding: 8px; text-align: left; }"
    $html += "th { background: #2d2d2d; }"
    $html += ".healthy { color: #4ec9b0; } .degraded { color: #dcdcaa; } .unhealthy { color: #f44747; } .critical { color: #f44747; font-weight: bold; }"
    $html += ".alert-critical { color: #f44747; font-weight: bold; } .alert-warning { color: #dcdcaa; }"
    $html += ".metric { display: inline-block; background: #2d2d2d; padding: 10px; margin: 5px; border-radius: 4px; min-width: 150px; }"
    $html += ".metric-label { color: #9cdcfe; font-size: 0.9em; } .metric-value { font-size: 1.2em; font-weight: bold; }"
    $html += "</style></head><body>"
    
    $html += "<h1>Nexus98 Status Dashboard</h1>"
    $html += "<p>Generated: $($Status.generated) | Version: $($Status.version)</p>"
    
    $healthClass = switch ($Status.overallHealth) {
        'HEALTHY'   { 'healthy' }
        'DEGRADED'  { 'degraded' }
        'UNHEALTHY' { 'unhealthy' }
        'CRITICAL'  { 'critical' }
        default     { '' }
    }
    $html += "<h2 class='$healthClass'>Overall Health: $($Status.overallHealth)</h2>"
    
    # Components table
    $html += "<h2>Component Health</h2>"
    $html += "<table><thead><tr><th>Component</th><th>Status</th><th>Healthy/Total</th><th>Score</th><th>Details</th></tr></thead><tbody>"
    foreach ($c in $Status.components) {
        $class = switch ($c.status) {
            'HEALTHY'   { 'healthy' }
            'DEGRADED'  { 'degraded' }
            'UNHEALTHY' { 'unhealthy' }
            'CRITICAL'  { 'critical' }
            default     { '' }
        }
        $html += "<tr><td>$($c.category)</td><td class='$class'>$($c.status)</td><td>$($c.healthy)/$($c.total)</td><td>$($c.score)%</td><td>$($c.details)</td></tr>"
    }
    $html += "</tbody></table>"
    
    # Metrics
    $html += "<h2>Key Metrics</h2>"
    $html += "<div class='metrics'>"
    foreach ($m in $Status.metrics.GetEnumerator()) {
        $html += "<div class='metric'><div class='metric-label'>$($m.Key)</div><div class='metric-value'>$($m.Value)</div></div>"
    }
    $html += "</div>"
    
    # Alerts
    if ($Status.alerts.Count -gt 0) {
        $html += "<h2>Alerts</h2><ul>"
        foreach ($a in $Status.alerts) {
            $alertClass = if ($a.level -eq 'CRITICAL') { 'alert-critical' } elseif ($a.level -eq 'WARNING') { 'alert-warning' } else { '' }
            $html += "<li class='$alertClass'><strong>$($a.level)</strong>: $($a.message) <em>($($a.time))</em></li>"
        }
        $html += "</ul>"
    }
    
    # Recommendations
    $html += "<h2>Recommendations</h2><ul>"
    foreach ($r in $Status.recommendations) {
        $html += "<li>$r</li>"
    }
    $html += "</ul>"
    
    $html += "<hr><p><em>Auto-generated by Nexus98 Scribe v1.0.0</em></p>"
    $html += "</body></html>"
    
    return $html -join "`n"
}