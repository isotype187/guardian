$VersionFile="D:\Nexus98_Toolkit\config\nexus98_version.json"
$BackupDir="D:\Nexus98_Toolkit\snapshots\script_backups"

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

if(!(Test-Path $VersionFile))
{
    Write-Host "Version file missing"
    exit 1
}

Copy-Item $VersionFile "$BackupDir\nexus98_version_before_schema_fix_$(Get-Date -Format yyyyMMdd_HHmmss).json" -Force

$Raw=Get-Content $VersionFile -Raw

$Data=$Raw | ConvertFrom-Json


$Data.verified=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")


$Components=@{}

$Data.components.PSObject.Properties | ForEach-Object {
    $Components[$_.Name]=$_.Value
}


$Components["audit_identity"]="v1"


$Data.components=$Components


$Data | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $VersionFile


Write-Host ""
Write-Host "Version schema repaired."

Write-Host ""
Write-Host "Verification:"
Get-Content $VersionFile
