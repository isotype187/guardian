# ============================================================
# Nexus98 Core Loader v1.0
# Central Configuration Loader
# ============================================================

$ErrorActionPreference = "Stop"


$ManifestPath = "D:\Nexus98_Toolkit\config\nexus98_manifest.json"


if(!(Test-Path $ManifestPath))
{
    throw "Nexus98 manifest missing: $ManifestPath"
}


$Nexus98 = Get-Content `
$ManifestPath `
-Raw |
ConvertFrom-Json



foreach($Property in $Nexus98.paths.PSObject.Properties)
{
    $Path = $Property.Value

    if(!(Test-Path $Path))
    {
        New-Item `
        -ItemType Directory `
        -Force `
        -Path $Path | Out-Null
    }
}



$LogFolder = $Nexus98.paths.logs

$LogFile = Join-Path `
$LogFolder `
"CoreLoader.log"


Add-Content `
$LogFile `
"$(Get-Date) Nexus98 Core Loaded"



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Core Loader Active"
Write-Host " Version:"
Write-Host $Nexus98.toolkit.version
Write-Host "================================="


return $Nexus98

