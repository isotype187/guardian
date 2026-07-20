function New-Nexus98RecoveryPoint {

param(
[string]$Reason="Manual"
)

$Manifest=@{
Reason=$Reason
Time=(Get-Date)
System="Nexus98 Guardian"
}

$Manifest |
ConvertTo-Json |
Set-Content "D:\Nexus98_Guardian\data\latest_recovery.json"

}
