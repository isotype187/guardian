function Test-Nexus98SafetyPolicy {
param([string]='unknown')
return @{
action=
approved=True
checked=(Get-Date)
}
}

function New-Nexus98SafetyEvent {
param([string]='unknown')
return @{
event=
severity='normal'
timestamp=(Get-Date)
}
}
