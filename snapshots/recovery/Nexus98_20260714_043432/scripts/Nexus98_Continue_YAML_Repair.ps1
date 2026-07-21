# ============================================================
# Nexus98 Continue YAML Repair
# ============================================================

$ContinueDir = "$env:USERPROFILE\.continue"

$BackupDir = "D:\Nexus98_Toolkit\snapshots\continue_backups"

$JsonConfig = "$ContinueDir\config.json"

$YamlConfig = "$ContinueDir\config.yaml"


New-Item `
-ItemType Directory `
-Force `
-Path $ContinueDir | Out-Null


New-Item `
-ItemType Directory `
-Force `
-Path $BackupDir | Out-Null



if(Test-Path $JsonConfig)
{
    Copy-Item `
    $JsonConfig `
    "$BackupDir\config_json_backup_$(Get-Date -Format yyyyMMdd_HHmmss).json" `
    -Force

    Remove-Item `
    $JsonConfig `
    -Force
}



$Yaml = @"
name: Nexus98 Local Ollama

models:
  - name: Qwen3 Coder
    provider: ollama
    model: qwen3-coder:latest
    apiBase: http://localhost:11434

  - name: DeepSeek R1
    provider: ollama
    model: deepseek-r1:32b
    apiBase: http://localhost:11434
"@


Set-Content `
-Encoding UTF8 `
-Path $YamlConfig `
-Value $Yaml



Write-Host ""
Write-Host "================================="
Write-Host " Nexus98 Continue YAML Repair"
Write-Host "================================="

Write-Host ""
Write-Host "Created:"
Write-Host $YamlConfig -ForegroundColor Green

Write-Host ""
Write-Host "Removed JSON config:"
Write-Host $JsonConfig

