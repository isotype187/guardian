$Toolkit="D:\Nexus98_Toolkit"

$Config="$Toolkit\config"

$Report="$Toolkit\reports\Nexus98_Dashboard.txt"


New-Item -ItemType Directory -Force -Path "$Toolkit\reports" | Out-Null


$State=Get-Content "$Config\nexus98_state.json" -Raw | ConvertFrom-Json

$Lines=@()


$Lines += "================================="
$Lines += " Nexus98 System Dashboard v1"
$Lines += "================================="
$Lines += ""

$Lines += "Generated:"
$Lines += (Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
$Lines += ""


$Lines += "CORE"
$Lines += "-----"
$Lines += "Toolkit: $($State.toolkit)"
$Lines += "Version: $($State.version)"
$Lines += ""


$Lines += "AI STACK"
$Lines += "---------"


$Ollama=Get-Content "$Config\nexus98_ollama.json" -Raw | ConvertFrom-Json

$Lines += "Ollama: $($Ollama.api)"
$Lines += "Models: $($Ollama.models.Count)"


$Continue=Get-Content "$Config\nexus98_continue.json" -Raw | ConvertFrom-Json

$Lines += "Continue: $($Continue.status)"

$Lines += ""


$Lines += "DEVELOPMENT"
$Lines += "------------"

$SSH=Get-Content "$Config\nexus98_ssh.json" -Raw | ConvertFrom-Json

$Lines += "SSH: $($SSH.status)"


$VS=Get-Content "$Config\nexus98_vscode.json" -Raw | ConvertFrom-Json

$Lines += "VS Code: $($VS.status)"


$Lines += ""


$Lines += "NETWORK"
$Lines += "--------"


$TS=Get-Content "$Config\nexus98_tailscale.json" -Raw | ConvertFrom-Json

$Lines += "Tailscale: $($TS.status)"
$Lines += "Node: $($TS.hostname)"
$Lines += "IP: $($TS.ip)"


$Lines += ""

$Healthy=($State.components.Values | Where-Object {$_ -ne "healthy"}).Count -eq 0


if($Healthy)
{
    $Lines += "Overall Status: OPERATIONAL"
}
else
{
    $Lines += "Overall Status: DEGRADED"
}



$Lines | Set-Content -Encoding UTF8 $Report


Write-Host ""
Get-Content $Report
