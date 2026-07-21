$Toolkit="D:\Nexus98_Toolkit"

$SnapshotRoot="$Toolkit\snapshots"
$Permanent="$SnapshotRoot\permanent"
$Recovery="$SnapshotRoot\recovery"

$Manifest="$Toolkit\config\nexus98_checkpoint_manifest.json"

$Exclude=@(
    ".venv",
    ".git",
    "snapshots",
    "__pycache__",
    "node_modules"
)

New-Item -ItemType Directory -Force -Path $Permanent | Out-Null
New-Item -ItemType Directory -Force -Path $Recovery | Out-Null
New-Item -ItemType Directory -Force -Path "$Toolkit\config" | Out-Null


function New-NexusCheckpoint
{
    param(
        [string]$Type="recovery",
        [string]$Name
    )

    if(!$Name)
    {
        $Name="Nexus98_"+(Get-Date -Format "yyyyMMdd_HHmmss")
    }

    if($Type -eq "permanent")
    {
        $Destination="$Permanent\$Name"
    }
    else
    {
        $Destination="$Recovery\$Name"
    }


    New-Item -ItemType Directory -Force -Path $Destination | Out-Null


    $Source=$Toolkit


    Get-ChildItem $Source -Force | ForEach-Object {

        if($Exclude -contains $_.Name)
        {
            Write-Host "[SKIP] $($_.Name)"
        }
        else
        {
            Copy-Item `
            $_.FullName `
            "$Destination\$($_.Name)" `
            -Recurse `
            -Force
        }

    }


    $Checkpoint=@{
        name=$Name
        type=$Type
        created=(Get-Date)
        excluded=$Exclude
        status="verified"
    }


    $Checkpoint |
    ConvertTo-Json -Depth 5 |
    Set-Content `
    "$Destination\checkpoint.json" `
    -Encoding UTF8


    return $Destination
}



$Latest=New-NexusCheckpoint `
-Type "recovery"


$ManifestData=@{
    latest_recovery=$Latest
    latest_run=(Get-Date)
    excluded=$Exclude
}


$ManifestData |
ConvertTo-Json -Depth 5 |
Set-Content `
$Manifest `
-Encoding UTF8


Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Checkpoint Manager v1.1"
Write-Host "================================="
Write-Host ""

Write-Host "Recovery checkpoint:"
Write-Host $Latest

Write-Host ""
Write-Host "Manifest:"
Write-Host $Manifest

Write-Host ""
Write-Host "Verification:"
Get-ChildItem $Latest

Write-Host ""
Write-Host "================================="
Write-Host " Checkpoint Complete"
Write-Host "================================="
