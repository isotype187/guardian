$Toolkit="D:\Nexus98_Toolkit"

$ContinueFolder="$env:USERPROFILE\.continue"

$Config="$ContinueFolder\config.yaml"

$Output="$Toolkit\config\nexus98_continue.json"


$Result=[ordered]@{
    timestamp=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
    folder=$false
    config=$false
    status="unknown"
}



if(Test-Path $ContinueFolder)
{
    $Result.folder=$true
    Write-Host "[OK] Continue folder exists"
}
else
{
    Write-Host "[FAIL] Continue folder missing"
}



if(Test-Path $Config)
{
    $Result.config=$true
    Write-Host "[OK] Continue YAML config exists"
}
else
{
    Write-Host "[FAIL] Continue YAML config missing"
}



if($Result.folder -and $Result.config)
{
    $Result.status="healthy"
}
else
{
    $Result.status="offline"
}



$Result |
ConvertTo-Json -Depth 10 |
Set-Content -Encoding UTF8 $Output



$StateFile="$Toolkit\config\nexus98_state.json"


if(Test-Path $StateFile)
{
    $State=Get-Content $StateFile -Raw | ConvertFrom-Json

    $State.components.continue=$Result.status

    $State.timestamps.last_check=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")

    $State |
    ConvertTo-Json -Depth 10 |
    Set-Content -Encoding UTF8 $StateFile
}



Write-Host ""
Write-Host "Continue Controller complete."

Write-Host ""
Write-Host "Verification:"
Get-Content $Output

Write-Host ""
Get-Content $StateFile
