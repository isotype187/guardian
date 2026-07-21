# ============================================================
# Nexus98 Version Manager v1.0
# ============================================================

$ConfigDir = "D:\Nexus98_Toolkit\config"

$VersionFile = "$ConfigDir\nexus98_version.json"


New-Item `
-ItemType Directory `
-Force `
-Path $ConfigDir | Out-Null



$VersionData = @{
    toolkit = "Nexus98 Toolkit"
    version = "0.1"
    status = "Operational"

    components = @{
        command_center = "v3"
        python_manager = "v1"
        continue_manager = "yaml"
        execution_logger = "v1"
        state_manager = "v1"
    }

    verified = "$(Get-Date)"
}



$VersionData |
ConvertTo-Json -Depth 10 |
Set-Content `
-Encoding UTF8 `
$VersionFile



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Version Manager"
Write-Host "================================="

Write-Host ""
Write-Host "Version file:"
Write-Host $VersionFile -ForegroundColor Green

Write-Host ""
Get-Content $VersionFile

