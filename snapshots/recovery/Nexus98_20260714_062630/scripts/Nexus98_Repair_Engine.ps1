$Toolkit="D:\Nexus98_Toolkit"

$Config="$Toolkit\config"

$Report="$Toolkit\reports\Nexus98_Repair_Report.txt"


New-Item -ItemType Directory -Force -Path "$Toolkit\reports" | Out-Null


$Lines=@()

$Issues=0


$Lines += "================================="
$Lines += " Nexus98 Repair Engine v1"
$Lines += "================================="
$Lines += ""


function Test-JSONComponent
{
    param(
        [string]$Name,
        [string]$Path
    )

    if(Test-Path $Path)
    {
        $Data=Get-Content $Path -Raw | ConvertFrom-Json

        if($null -ne $Data)
        {
            $Lines += "[OK] $Name healthy"
        }
        else
        {
            $Lines += "[WARN] $Name status: $($Data.status)"
            $script:Issues++
        }
    }
    else
    {
        $Lines += "[FAIL] $Name configuration missing"
        $script:Issues++
    }
}



Test-JSONComponent `
"Ollama" `
"$Config\nexus98_ollama.json"



$Continue="$env:USERPROFILE\.continue\config.yaml"

if(Test-Path $Continue)
{
    $Lines += "[OK] Continue YAML healthy"
}
else
{
    $Lines += "[FAIL] Continue YAML missing"
    $Issues++
}



Test-JSONComponent `
"SSH" `
"$Config\nexus98_ssh.json"



Test-JSONComponent `
"VS Code" `
"$Config\nexus98_vscode.json"



Test-JSONComponent `
"Tailscale" `
"$Config\nexus98_tailscale.json"



$Lines += ""

$Lines += "================================="


if($Issues -eq 0)
{
    $Lines += "System Diagnosis: HEALTHY"
}
else
{
    $Lines += "System Diagnosis: $Issues issue(s) detected"
}


$Lines += "================================="


$Lines | Set-Content -Encoding UTF8 $Report


Get-Content $Report


