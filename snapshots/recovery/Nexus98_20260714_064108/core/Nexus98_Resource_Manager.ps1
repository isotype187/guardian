function Get-Nexus98Resources {

=(Get-CimInstance Win32_Processor | Select-Object -First 1 LoadPercentage)
=(Get-CimInstance Win32_OperatingSystem)

return @{
cpu=.LoadPercentage
memoryFreeGB=[math]::Round(.FreePhysicalMemory/1048576,2)
timestamp=(Get-Date)
}
}
