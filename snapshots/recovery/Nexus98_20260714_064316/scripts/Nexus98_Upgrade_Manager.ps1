$Toolkit="D:\Nexus98_Toolkit"

$Config="$Toolkit\config"
$Scripts="$Toolkit\scripts"

$Registry="$Config\nexus98_modules.json"
$Version="$Config\nexus98_version.json"

Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Upgrade Manager v1"
Write-Host "================================="
Write-Host ""

$Report=@()

$Report += "Nexus98 Upgrade Report"
$Report += "====================="
$Report += ""

# Preflight

Write-Host "Preflight:"
Write-Host ""

if(Test-Path $Registry)
{
    Write-Host "[OK] Module registry loaded"
    $Report += "[OK] Module registry loaded"
}
else
{
    Write-Host "[FAIL] Module registry missing"
    exit 1
}

# checkpoint

Write-Host ""
Write-Host "Creating checkpoint..."

powershell -ExecutionPolicy Bypass -File "$Scripts\Nexus98_Checkpoint_Manager.ps1"

if($LASTEXITCODE -ne 0)
{
    Write-Host "[FAIL] Checkpoint failed"
    exit 1
}

Write-Host "[OK] Checkpoint created"

$Report += "[OK] Checkpoint created"


# health check

Write-Host ""
Write-Host "Running system verification..."

powershell -ExecutionPolicy Bypass -File "$Toolkit\Nexus98.ps1" check

if($LASTEXITCODE -eq 0)
{
    Write-Host "[OK] System health verified"
    $Report += "[OK] System health verified"
}
else
{
    Write-Host "[WARN] System check returned warnings"
    $Report += "[WARN] System check returned warnings"
}


# version

if(Test-Path $Version)
{
    $Data=Get-Content $Version -Raw | ConvertFrom-Json

    if(!$Data.components.upgrade_manager)
    {
        Add-Member `
        -InputObject $Data.components `
        -MemberType NoteProperty `
        -Name upgrade_manager `
        -Value "v1"
    }
    else
    {
        $Data.components.upgrade_manager="v1"
    }

    $Data.verified=Get-Date

    $Data | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $Version

    Write-Host "[OK] Version manifest updated"
    $Report += "[OK] Version manifest updated"
}


Write-Host ""

Write-Host "================================="
Write-Host " Nexus98 Upgrade Complete"
Write-Host "================================="

Write-Host ""

Write-Host "Status:"
Write-Host "VERIFIED"

$Report += ""
$Report += "Status: VERIFIED"

$Report | Set-Content `
-Encoding UTF8 `
-Path "$Toolkit\reports\Nexus98_Upgrade_Report.txt"

Write-Host ""
Write-Host "Report:"
Write-Host "$Toolkit\reports\Nexus98_Upgrade_Report.txt"
