function Add-Nexus98MemoryRecord {

param(
[string]$Event="System Event",
[string]$Status="UNKNOWN"
)

$Record=@{
event=$Event
status=$Status
timestamp=(Get-Date)
}

$File="D:\Nexus98_Toolkit\logs\nexus98_memory_history.json"

$Existing=@()

if(Test-Path $File){
    $Existing=Get-Content $File -Raw | ConvertFrom-Json
}

$Existing += $Record

$Existing | ConvertTo-Json -Depth 10 | Set-Content $File -Encoding UTF8

return $Record

}


function Get-Nexus98MemoryHistory {

$File="D:\Nexus98_Toolkit\logs\nexus98_memory_history.json"

if(Test-Path $File){
    return Get-Content $File -Raw | ConvertFrom-Json
}

return @()

}
