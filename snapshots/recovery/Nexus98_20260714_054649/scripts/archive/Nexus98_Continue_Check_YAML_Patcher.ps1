$Target = "D:\Nexus98_Toolkit\scripts\Nexus98_System_Check.ps1"

$BackupDir = "D:\Nexus98_Toolkit\snapshots\script_backups"


New-Item `
-ItemType Directory `
-Force `
-Path $BackupDir | Out-Null


Copy-Item `
$Target `
"$BackupDir\Nexus98_System_Check_before_yaml_$(Get-Date -Format yyyyMMdd_HHmmss).ps1" `
-Force


$Content = [System.IO.File]::ReadAllText($Target)


$Content = $Content.Replace(
"config.json",
"config.yaml"
)


[System.IO.File]::WriteAllText(
$Target,
$Content
)


Write-Host ""
Write-Host "Continue YAML check migration complete."
Write-Host $Target
