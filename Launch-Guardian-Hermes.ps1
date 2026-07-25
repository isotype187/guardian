# Guardian Hermes Launcher

$ErrorActionPreference = "Stop"

$GuardianPath = "D:\Nexus98_Guardian"
$HermesExe = "$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts\hermes.exe"

Write-Host "================================="
Write-Host " Guardian Hermes Session"
Write-Host "================================="
Write-Host ""

# Verify paths
if (!(Test-Path $GuardianPath)) {
    Write-Host "Guardian folder missing:"
    Write-Host $GuardianPath
    exit 1
}

if (!(Test-Path $HermesExe)) {
    Write-Host "Hermes executable missing:"
    Write-Host $HermesExe
    exit 1
}

# Move into Guardian repo
Set-Location $GuardianPath

Write-Host "Working Directory:"
Write-Host (Get-Location)

Write-Host ""
Write-Host "Launching Hermes:"
Write-Host $HermesExe

Write-Host ""

# Launch Hermes
& $HermesExe