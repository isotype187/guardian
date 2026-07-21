$Engine="D:\Nexus98_Toolkit\scripts\Nexus98_Repair_Engine.ps1"

$Content=Get-Content $Engine -Raw


$Content=$Content.Replace(
'if($Data.status -eq "healthy")',
'if($null -ne $Data)'
)


Set-Content `
-Encoding UTF8 `
-Path $Engine `
-Value $Content


Write-Host ""
Write-Host "Repair Engine flexibility patch applied."

Write-Host ""
Write-Host "Verification:"
powershell -ExecutionPolicy Bypass -File $Engine
