$StateFile="D:\Nexus98_Toolkit\config\nexus98_state.json"
$OllamaConfig="D:\Nexus98_Toolkit\config\nexus98_ollama.json"
$Backup="D:\Nexus98_Toolkit\snapshots\script_backups"

New-Item -ItemType Directory -Force -Path $Backup | Out-Null

if(!(Test-Path $StateFile))
{
    Write-Host "State file missing"
    exit 1
}

Copy-Item $StateFile "$Backup\nexus98_state_before_status_v2_$(Get-Date -Format yyyyMMdd_HHmmss).json" -Force

$State=Get-Content $StateFile -Raw | ConvertFrom-Json

if(Test-Path $OllamaConfig)
{
    $Ollama=Get-Content $OllamaConfig -Raw | ConvertFrom-Json

    if($Ollama.api -eq $true)
    {
        $State.components.ollama="healthy"
    }

    if($Ollama.api -ne $true)
    {
        $State.components.ollama="offline"
    }
}

$State.timestamps.last_check=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")

$State | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $StateFile

Write-Host ""
Write-Host "Status Engine v2 Ollama integration complete."
Write-Host ""

Get-Content $StateFile
