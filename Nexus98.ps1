# Nexus98 Guardian - canonical entry point.
# Bootstraps the production Guardian foundation via the loader. Do NOT dot-source
# the legacy engines (snapshot_engine.ps1 / verification_engine.ps1 /
# recovery_engine.ps1) - those are abandoned duplicates superseded by the M0
# foundation (see docs\ARCHITECTURE_MAP.md).

$ErrorActionPreference = 'Stop'

try {
    $Root = Resolve-Path (Join-Path $PSScriptRoot '..')
    if (-not (Test-Path (Join-Path $Root 'core\Guardian_Loader.ps1'))) {
        $Root = $PSScriptRoot
    }
    . (Join-Path $Root 'core\Guardian_Loader.ps1')
    Import-Guardian -Root $Root.Path

    Write-Host "================================="
    Write-Host " Nexus98 Guardian (loaded via canonical loader)"
    Write-Host "================================="
    Write-Host ""
    Write-Host "Assets Registered"
    Write-Host "-----------------"
    $assets = Join-Path $GuardianEnv.Config 'assets.json'
    if (Test-Path $assets) {
        (Get-Content $assets -Raw | ConvertFrom-Json).assets |
            Format-Table name, priority, snapshot
    }
    Write-Host ""
    Write-Host "Guardian Ready"
} catch {
    Write-Host ("Guardian bootstrap failed: " + $_.Exception.Message)
    exit 1
}
