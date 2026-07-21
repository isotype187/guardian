# ============================================================
# Nexus98 State Manager v1.0
# ============================================================

param(
    [string]$Action = "status"
)


$Toolkit = "D:\Nexus98_Toolkit"
$Config = "$Toolkit\config"

$StateFile = "$Config\nexus98_state.json"


New-Item `
-ItemType Directory `
-Force `
-Path $Config | Out-Null



if(!(Test-Path $StateFile))
{

$InitialState = @{
    toolkit = "Nexus98 Toolkit"
    version = "1.0"

    timestamps = @{
        created = "$(Get-Date)"
        last_check = ""
        last_bootstrap = ""
        last_repair = ""
        last_snapshot = ""
    }

    components = @{
        ollama = "unknown"
        continue = "unknown"
        vscode = "unknown"
        ssh = "unknown"
        tailscale = "unknown"
    }

    history = @()
}


$InitialState |
ConvertTo-Json -Depth 5 |
Set-Content `
-Encoding UTF8 `
$StateFile

}



$State = Get-Content `
$StateFile `
-Raw |
ConvertFrom-Json



switch($Action)
{

"status"
{
    Write-Host ""
    Write-Host "================================="
    Write-Host " Nexus98 Current State"
    Write-Host "================================="

    $State | ConvertTo-Json -Depth 5

    break
}



"check"
{
    $State.timestamps.last_check = "$(Get-Date)"

    $State.history += "System check completed $(Get-Date)"

    break
}



"snapshot"
{
    $State.timestamps.last_snapshot = "$(Get-Date)"

    $State.history += "Snapshot created $(Get-Date)"

    break
}



"repair"
{
    $State.timestamps.last_repair = "$(Get-Date)"

    $State.history += "Repair completed $(Get-Date)"

    break
}



default
{
    Write-Host ""
    Write-Host "Available:"
    Write-Host " status"
    Write-Host " check"
    Write-Host " snapshot"
    Write-Host " repair"
}

}



$State |
ConvertTo-Json -Depth 5 |
Set-Content `
-Encoding UTF8 `
$StateFile


Write-Host ""
Write-Host "State updated:"
Write-Host $StateFile

