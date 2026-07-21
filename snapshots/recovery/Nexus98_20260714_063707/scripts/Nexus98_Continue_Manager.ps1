# ============================================================
# Nexus98 Continue Manager v1.0
# ============================================================

$ContinueDir = "$env:USERPROFILE\.continue"

$ConfigFile = "$ContinueDir\config.json"

$BackupDir = "D:\Nexus98_Toolkit\snapshots\continue_backups"


New-Item `
-ItemType Directory `
-Force `
-Path $ContinueDir | Out-Null


New-Item `
-ItemType Directory `
-Force `
-Path $BackupDir | Out-Null



if(Test-Path $ConfigFile)
{
    Copy-Item `
    $ConfigFile `
    "$BackupDir\config_$(Get-Date -Format yyyyMMdd_HHmmss).json" `
    -Force
}



$Config = @{
    models = @(
        @{
            title = "Qwen3 Coder"
            provider = "ollama"
            model = "qwen3-coder:latest"
            apiBase = "http://localhost:11434"
        },

        @{
            title = "DeepSeek R1"
            provider = "ollama"
            model = "deepseek-r1:32b"
            apiBase = "http://localhost:11434"
        }
    )
}


$Config |
ConvertTo-Json -Depth 10 |
Set-Content `
-Encoding UTF8 `
$ConfigFile



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Continue Manager"
Write-Host "================================="

Write-Host ""
Write-Host "Config created:"
Write-Host $ConfigFile -ForegroundColor Green

