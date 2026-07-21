function New-Nexus98Task {
param([string]='unknown')

return @{
task=
status='queued'
created=(Get-Date)
}
}

function Update-Nexus98Task {
param([string],[string])

return @{
task=
status=
updated=(Get-Date)
}
}
