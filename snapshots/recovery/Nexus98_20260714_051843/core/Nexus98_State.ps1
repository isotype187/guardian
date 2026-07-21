function Update-Nexus98State {
$File="D:\Nexus98_Toolkit\config\nexus98_state.json"
@{core_version="0.2.0";updated=(Get-Date)} | ConvertTo-Json | Set-Content $File
}
