function Submit-Nexus98Command {
param([string]='unknown')

return @{
command=
route='pending'
created=(Get-Date)
}
}

function Get-Nexus98CommandRoute {
param()

return @{
command=.command
destination='Orchestrator'
status='queued'
}
}
