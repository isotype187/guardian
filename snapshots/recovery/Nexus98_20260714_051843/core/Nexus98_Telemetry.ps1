function Get-Nexus98Telemetry {
return @{
Computer=$env:COMPUTERNAME
OS=(Get-CimInstance Win32_OperatingSystem).Caption
}
}
