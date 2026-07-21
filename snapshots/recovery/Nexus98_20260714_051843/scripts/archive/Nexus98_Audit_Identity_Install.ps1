$Target = "D:\AI_Model_Hub\tools\Nexus98_System_Check.ps1"

$Backup = "D:\Nexus98_Toolkit\snapshots\script_backups"

New-Item -ItemType Directory -Force -Path $Backup | Out-Null

if(!(Test-Path $Target))
{
    Write-Host "System Check missing"
    exit 1
}

Copy-Item $Target "$Backup\System_Check_backup_$(Get-Date -Format yyyyMMdd_HHmmss).ps1" -Force

$Content = [System.IO.File]::ReadAllText($Target)

if($Content.Contains("Nexus98 Identity"))
{
    Write-Host "Identity already installed"
}
else
{
    $Block = @'

# ============================================================
# Nexus98 Identity
# ============================================================

$NexusVersionFile = "D:\Nexus98_Toolkit\config\nexus98_version.json"

if(Test-Path $NexusVersionFile)
{
    $Identity = Get-Content $NexusVersionFile -Raw | ConvertFrom-Json

    Write-Host ""
    Write-Host "================================="
    Write-Host " Nexus98 Identity"
    Write-Host "================================="

    Write-Host "Version:"
    Write-Host $Identity.version

    Write-Host "Status:"
    Write-Host $Identity.status
}

'@

    $Content = $Block + "
" + $Content

    [System.IO.File]::WriteAllText($Target, $Content)

    Write-Host "Identity installed"
}

Write-Host ""
Write-Host "Running verification"

powershell -ExecutionPolicy Bypass -File "D:\Nexus98_Toolkit\Nexus98.ps1" check

Write-Host ""
Write-Host "Nexus98 Identity Integration Complete"
