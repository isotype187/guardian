# Nexus98 Scribe - External Documentation & Observability Framework
# Main entry point for the Nexus98 Scribe framework
# Version: 1.0.0

<#
.SYNOPSIS
    Nexus98 Scribe - External Documentation & Observability Framework

.DESCRIPTION
    Main entry point for the Nexus98 Scribe framework.
    Runs all scribe modules: Roadmap, TOC, Status, History, Sync.
    Designed for clean absorption into mature Nexus98.

.USAGE
    . .\Nexus98_Scribe.ps1
    Invoke-Nexus98Scribe -All

    # Or run individual modules
    Invoke-Nexus98Scribe -Roadmap
    Invoke-Nexus98Scribe -TOC
    Invoke-Nexus98Scribe -Status
    Invoke-Nexus98Scribe -History
    Invoke-Nexus98Scribe -Sync

.NOTES
    Version: 1.0.0
    Designed for clean absorption into mature Nexus98.
    All modules are self-contained in core\Nexus98_Scribe_*.ps1
#>

# Load all scribe modules
$script:ScribeModules = @(
    "Nexus98_Scribe_Core.ps1",
    "Nexus98_Scribe_Roadmap.ps1",
    "Nexus98_Scribe_TOC.ps1",
    "Nexus98_Scribe_Status.ps1",
    "Nexus98_Scribe_History.ps1",
    "Nexus98_Scribe_Sync.ps1"
)

$script:ModulePath = Split-Path $MyInvocation.MyCommand.Path -Parent

foreach ($m in $script:ScribeModules) {
    $p = Join-Path $script:ModulePath $m
    if (Test-Path $p) {
        . $p
    } else {
        Write-Warning "[Nexus98 Scribe] Module not found: $p"
    }
}

$global:Nexus98ScribeVersion = "1.0.0"
$global:Nexus98ScribeConfig = @{
    OutputPath = (Resolve-Path ".\docs").Path
    DocsPath   = (Resolve-Path ".\docs").Path
    RootPath   = (Resolve-Path ".").Path
    RunTests   = $false
    FixDrift   = $false
}

function Invoke-Nexus98Scribe {
    param(
        [switch]$All,
        [switch]$Roadmap,
        [switch]$TOC,
        [switch]$Status,
        [switch]$History,
        [switch]$Sync,
        [switch]$Watch,
        [int]$WatchInterval = 300,  # 5 minutes
        [string]$OutputPath,
        [hashtable]$Config
    )

    Write-Host "`n[Nexus98 Scribe v$global:Nexus98ScribeVersion] Starting..." -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan

    # Merge config
    $effectiveConfig = @{}
    $effectiveConfig += $global:Nexus98ScribeConfig
    if ($Config) { $effectiveConfig += $Config }
    if ($OutputPath) { $effectiveConfig.OutputPath = $OutputPath; $effectiveConfig.DocsPath = $OutputPath }

    # Ensure output directory exists
    if (-not (Test-Path $effectiveConfig.OutputPath)) {
        New-Item -ItemType Directory -Force -Path $effectiveConfig.OutputPath | Out-Null
    }

    $ranAny = $false

    if ($All -or $Roadmap) {
        $ranAny = $true
        Write-Host "`n[1/5] Generating Roadmap..." -ForegroundColor Yellow
        try {
            Invoke-Nexus98ScribeRoadmap -Config $effectiveConfig -OutputPath $effectiveConfig.OutputPath
        } catch {
            Write-Error "[Roadmap] Failed: $($_.Exception.Message)"
        }
    }

    if ($All -or $TOC) {
        $ranAny = $true
        Write-Host "`n[2/5] Generating Table of Contents..." -ForegroundColor Yellow
        try {
            Invoke-Nexus98ScribeTOC -Config $effectiveConfig -OutputPath $effectiveConfig.OutputPath
        } catch {
            Write-Error "[TOC] Failed: $($_.Exception.Message)"
        }
    }

    if ($All -or $Status) {
        $ranAny = $true
        Write-Host "`n[3/5] Generating Status Dashboard..." -ForegroundColor Yellow
        try {
            Invoke-Nexus98ScribeStatus -Config $effectiveConfig -OutputPath $effectiveConfig.OutputPath
        } catch {
            Write-Error "[Status] Failed: $($_.Exception.Message)"
        }
    }

    if ($All -or $History) {
        $ranAny = $true
        Write-Host "`n[4/5] Generating History/Changelog..." -ForegroundColor Yellow
        try {
            Invoke-Nexus98ScribeHistory -Config $effectiveConfig -OutputPath $effectiveConfig.OutputPath
        } catch {
            Write-Error "[History] Failed: $($_.Exception.Message)"
        }
    }

    if ($All -or $Sync) {
        $ranAny = $true
        Write-Host "`n[5/5] Validating Documentation Sync..." -ForegroundColor Yellow
        try {
            Test-Nexus98DocSync -Config $effectiveConfig -DocsPath $effectiveConfig.DocsPath
        } catch {
            Write-Error "[Sync] Failed: $($_.Exception.Message)"
        }
    }

    if (-not $ranAny) {
        Write-Host "`nNo action specified. Use -All or individual switches:" -ForegroundColor Yellow
        Write-Host "  -All       Run all scribe modules"
        Write-Host "  -Roadmap   Generate roadmap"
        Write-Host "  -TOC       Generate table of contents"
        Write-Host "  -Status    Generate status dashboard"
        Write-Host "  -History   Generate history/changelog"
        Write-Host "  -Sync      Validate documentation sync"
        Write-Host "  -Watch     Run continuously with interval (use with -All)"
    }

    if ($Watch -and $ranAny) {
        Write-Host "`n[Watch] Running continuously every $WatchInterval seconds..." -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray

        while ($true) {
            Start-Sleep -Seconds $WatchInterval
            Write-Host "`n[Nexus98 Scribe] Scheduled run..." -ForegroundColor Cyan
            Invoke-Nexus98Scribe -All -Config $effectiveConfig -OutputPath $effectiveConfig.OutputPath
        }
    }

    Write-Host "`n[Nexus98 Scribe] Complete." -ForegroundColor Green
}

function Get-Nexus98ScribeConfig {
    return $global:Nexus98ScribeConfig
}

function Set-Nexus98ScribeConfig {
    param([hashtable]$Config)

    $global:Nexus98ScribeConfig += $Config
    Write-Host "[Config] Updated" -ForegroundColor Green
}

# Auto-dot-source when loaded directly
if ($MyInvocation.InvocationName -eq '.') {
    Write-Host "[Nexus98 Scribe v$global:Nexus98ScribeVersion] Loaded. Use Invoke-Nexus98Scribe to run." -ForegroundColor Cyan
}