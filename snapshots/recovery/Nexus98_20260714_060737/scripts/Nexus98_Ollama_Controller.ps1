# ============================================================
# Nexus98 Ollama Controller v1
# Foundation
# ============================================================

$Toolkit="D:\Nexus98_Toolkit"

$Config="$Toolkit\config\nexus98_ollama.json"


Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Ollama Controller v1"
Write-Host "================================="
Write-Host ""


$Result=[ordered]@{
    timestamp=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
    installed=$false
    process=$false
    api=$false
    models=@()
}



$Ollama=Get-Command ollama -ErrorAction SilentlyContinue


if($null -ne $Ollama)
{
    $Result.installed=$true
    Write-Host "[OK] Ollama installed"
}
else
{
    Write-Host "[FAIL] Ollama not found"
}



$Process=Get-Process ollama -ErrorAction SilentlyContinue


if($null -ne $Process)
{
    $Result.process=$true
    Write-Host "[OK] Ollama process running"
}
else
{
    Write-Host "[WARN] Ollama process not detected"
}



try
{
    $Response=Invoke-WebRequest `
    -Uri "http://127.0.0.1:11434/api/tags" `
    -TimeoutSec 5 `
    -UseBasicParsing


    if($Response.StatusCode -eq 200)
    {
        $Result.api=$true

        Write-Host "[OK] Ollama API responding"


        $Models=($Response.Content | ConvertFrom-Json).models


        foreach($Model in $Models)
        {
            $Result.models += $Model.name
            Write-Host "[MODEL] $($Model.name)"
        }
    }
}
catch
{
    Write-Host "[FAIL] Ollama API unavailable"
}



$Result | ConvertTo-Json -Depth 10 | Set-Content `
-Encoding UTF8 `
$Config



Write-Host ""

Write-Host "Saved:"
Write-Host $Config


Write-Host ""
Write-Host "================================="
Write-Host " Ollama Controller Complete"
Write-Host "================================="
