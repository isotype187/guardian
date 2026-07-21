function New-Nexus98Report {
param([string]$Name,[array]$Data)
$Path="D:\Nexus98_Toolkit\reports\$Name"
$Data | Set-Content $Path
return $Path
}
