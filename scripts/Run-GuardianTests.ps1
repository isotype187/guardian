<#
.SYNOPSIS
    Guardian Test Runner - Executes all Guardian test suites in order.

.DESCRIPTION
    Runs Foundation (M0), M2-M10 test suites sequentially.
    Produces summary report with pass/fail counts and exit code for CI.

.NOTES
    Must be run from the Guardian root directory (D:\Nexus98_Guardian).
    Requires Pester v6+.
#>

param(
    [switch]$VerboseOutput,
    [switch]$FailFast,
    [string[]]$TestFilter = @()
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$testsDir = Join-Path $root 'tests'

# Test suites in dependency order
$testSuites = @(
    @{ Name = 'Foundation (M0)'; Path = 'Guardian.Foundation.Tests.ps1' }
    @{ Name = 'M2 Event + Storage Intelligence'; Path = 'Guardian.M2.Tests.ps1' }
    @{ Name = 'M3 Memory + Observability'; Path = 'Guardian.M3.Tests.ps1' }
    @{ Name = 'M4 Resource + Agent + Security'; Path = 'Guardian.M4.Tests.ps1' }
    @{ Name = 'M5 Architecture Drift Detector'; Path = 'Guardian.M5.Tests.ps1' }
    @{ Name = 'M6 Nexus98 Communication Layer'; Path = 'Guardian.M6.Tests.ps1' }
    @{ Name = 'M7 Self-Development Guard + Drift Gate'; Path = 'Guardian.M7.Tests.ps1' }
    @{ Name = 'M8 Governed Communication Loop'; Path = 'Guardian.M8.Tests.ps1' }
    @{ Name = 'M9 Storage Entropy Remediation'; Path = 'Guardian.M9.Tests.ps1' }
    @{ Name = 'M10 Continuous Operations'; Path = 'Guardian.M10.Tests.ps1' }
)

$totalPassed = 0
$totalFailed = 0
$totalSkipped = 0
$totalTime = 0
$results = @()

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Guardian Test Runner - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Root: $root" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Load Guardian foundation
. (Join-Path $root 'core\Guardian_Loader.ps1')
Import-Guardian -Root $root

foreach ($suite in $testSuites) {
    $suitePath = Join-Path $testsDir $suite.Path
    if (-not (Test-Path $suitePath)) {
        Write-Warning "Test suite not found: $suitePath - skipping"
        continue
    }

    Write-Host "`n--- Running: $($suite.Name) ---" -ForegroundColor Yellow

    $startTime = Get-Date
    $pesterParams = @{
        Path = $suitePath
        Output = if ($VerboseOutput) { 'Detailed' } else { 'Normal' }
    }
    if ($FailFast) { $pesterParams['Strict'] = $true }
    if ($TestFilter.Count -gt 0) { $pesterParams['Filter'] = $TestFilter -join ',' }

    try {
            $result = Invoke-Pester @pesterParams -PassThru
            $duration = (Get-Date) - $startTime
            $totalTime += $duration.TotalSeconds

            $passed = $result.PassedCount
                    $failed = $result.FailedCount
                    $skipped = $result.SkippedCount
        $totalPassed += $passed
        $totalFailed += $failed
        $totalSkipped += $skipped

        $statusColor = if ($failed -gt 0) { 'Red' } else { 'Green' }
        Write-Host "$($suite.Name): $passed passed, $failed failed, $skipped skipped in $([math]::Round($duration.TotalSeconds, 1))s" -ForegroundColor $statusColor

        $results += @{ Name = $suite.Name; Passed = $passed; Failed = $failed; Skipped = $skipped; Duration = $duration.TotalSeconds }

        if ($FailFast -and $failed -gt 0) {
            Write-Error "Fail-fast triggered: $($suite.Name) had failures"
            break
        }
    }
    catch {
        Write-Error "Error running $($suite.Name): $($_.Exception.Message)"
        $totalFailed++
        $results += @{ Name = $suite.Name; Passed = 0; Failed = 1; Skipped = 0; Duration = 0; Error = $_.Exception.Message }
        if ($FailFast) { break }
    }
}

# Summary
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Total Time: $([math]::Round($totalTime, 1))s" -ForegroundColor Cyan
$summaryColor = if ($totalFailed -gt 0) { 'Red' } else { 'Green' }
Write-Host "Total Tests: $($totalPassed + $totalFailed + $totalSkipped) | Passed: $totalPassed | Failed: $totalFailed | Skipped: $totalSkipped" -ForegroundColor $summaryColor

foreach ($r in $results) {
    $status = if ($r.Failed -gt 0) { 'FAIL' } elseif ($r.Passed -gt 0) { 'PASS' } else { 'SKIP' }
    Write-Host "  [$status] $($r.Name) - $($r.Passed)/$($r.Failed)/$($r.Skipped) in $([math]::Round($r.Duration, 1))s"
}

# Exit code for CI
if ($totalFailed -gt 0) {
    Write-Host "`nRESULT: FAILED ($totalFailed failures)" -ForegroundColor Red
    exit 1
}
else {
    Write-Host "`nRESULT: ALL TESTS PASSED" -ForegroundColor Green
    exit 0
}