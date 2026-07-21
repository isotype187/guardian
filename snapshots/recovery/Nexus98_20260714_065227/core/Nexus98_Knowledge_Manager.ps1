function Register-Nexus98Knowledge {
param([string]$Component='unknown')

return @{
component=$Component
registered=$true
timestamp=(Get-Date)
}
}

function Get-Nexus98Knowledge {
return Get-Content 'D:\Nexus98_Toolkit\config\nexus98_knowledge_registry.json'
}
