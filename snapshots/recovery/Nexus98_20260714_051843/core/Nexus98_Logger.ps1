function Write-Nexus98Log {
param([string]$Message)
$Log="D:\Nexus98_Toolkit\logs\nexus98_execution.log"
New-Item -ItemType Directory -Force -Path (Split-Path $Log) | Out-Null
Add-Content $Log "07/14/2026 05:16:14 $Message"
}
