$Toolkit="D:\Nexus98_Toolkit"
$Target="$Toolkit\Nexus98.ps1"
$Backup="$Toolkit\snapshots\script_backups"
$Version="$Toolkit\config\nexus98_version.json"

New-Item -ItemType Directory -Force -Path $Backup | Out-Null

if(!(Test-Path $Target))
{
    Write-Host "Missing Nexus98.ps1"
    exit 1
}

Copy-Item $Target "$Backup\Nexus98_before_v4_$(Get-Date -Format yyyyMMdd_HHmmss).ps1" -Force

$Content=[System.IO.File]::ReadAllText($Target)

$Content=$Content.Replace("Nexus98 Command Center v3","Nexus98 Command Center v4")

[System.IO.File]::WriteAllText($Target,$Content)

if(Test-Path $Version)
{
    $Data=Get-Content $Version -Raw | ConvertFrom-Json

    $Data.components.command_center="v4"
    $Data.components.audit_identity="v1"
    $Data.verified=Get-Date

    $Data | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $Version
}

Write-Host ""
Write-Host "Command Center v4 alignment complete."

Write-Host ""
Write-Host "Verification:"
powershell -ExecutionPolicy Bypass -File "$Toolkit\Nexus98.ps1" status
