$Toolkit="D:\Nexus98_Toolkit"

$Snapshots="$Toolkit\snapshots"

$Source="$Snapshots\recovery\Snapshot_2026-07-14_023132"

$Permanent="$Snapshots\permanent\Nexus98_v0.1.10"


Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Snapshot Cleanup"
Write-Host "================================="
Write-Host ""


if(!(Test-Path $Source))
{
    Write-Host "Missing source snapshot:"
    Write-Host $Source
    exit 1
}


New-Item -ItemType Directory -Force -Path "$Snapshots\permanent" | Out-Null


if(Test-Path $Permanent)
{
    Write-Host "Existing milestone found. Removing old copy."
    Remove-Item $Permanent -Recurse -Force
}


Move-Item `
-Path $Source `
-Destination $Permanent


Write-Host "[OK] Snapshot moved to permanent"



$Cleanup=@(
    "$Permanent\AI_Model_Hub\.venv",
    "$Permanent\AI_Model_Hub\.git",
    "$Permanent\AI_Model_Hub\snapshots"
)


foreach($Item in $Cleanup)
{
    if(Test-Path $Item)
    {
        Remove-Item `
        -Path $Item `
        -Recurse `
        -Force

        Write-Host "[REMOVED] $Item"
    }
}



$Meta=[ordered]@{
    milestone="Nexus98_v0.1.10"
    type="permanent"
    status="verified"
    created=(Get-Date)
}


$Meta |
ConvertTo-Json -Depth 5 |
Set-Content `
-Encoding UTF8 `
"$Permanent\checkpoint.json"


$RemoveFolders=@(
    "$Snapshots\continue_backups",
    "$Snapshots\script_backups"
)


foreach($Folder in $RemoveFolders)
{
    if(Test-Path $Folder)
    {
        Remove-Item `
        $Folder `
        -Recurse `
        -Force

        Write-Host "[REMOVED] $Folder"
    }
}



Write-Host ""
Write-Host "================================="
Write-Host " Snapshot Cleanup Complete"
Write-Host "================================="


Write-Host ""
Write-Host "Verification:"
Get-ChildItem $Snapshots -Directory

Write-Host ""
Get-Content "$Permanent\checkpoint.json"

