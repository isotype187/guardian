function New-Nexus98Task {

param(
[string]$TaskName="System Task",
[string[]]$Modules=@("System_Check")
)

return @{
name=$TaskName
modules=$Modules
status="queued"
created=(Get-Date)
}

}


function Invoke-Nexus98Automation {

param($Task)

return @{
task=$Task.name
status="ready"
executed=(Get-Date)
}

}
