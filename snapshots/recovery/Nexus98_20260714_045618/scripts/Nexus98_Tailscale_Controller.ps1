$Toolkit="D:\Nexus98_Toolkit"

$Output="$Toolkit\config\nexus98_tailscale.json"

$StateFile="$Toolkit\config\nexus98_state.json"


$Result=[ordered]@{
    timestamp=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
    installed=$false
    service=$false
    connected=$false
    ip=""
    hostname=""
    status="unknown"
}



$Tailscale=Get-Command tailscale -ErrorAction SilentlyContinue


if($null -ne $Tailscale)
{
    $Result.installed=$true
    Write-Host "[OK] Tailscale installed"
}
else
{
    Write-Host "[FAIL] Tailscale command missing"
}



$Service=Get-Service -Name "Tailscale" -ErrorAction SilentlyContinue


if($null -ne $Service)
{
    $Result.service=$true
    Write-Host "[OK] Tailscale service detected"
}
else
{
    Write-Host "[WARN] Tailscale service not detected"
}



if($Result.installed)
{
    try
    {
        $Status=tailscale status --json | ConvertFrom-Json

        if($null -ne $Status)
        {
            $Result.connected=$true

            if($Status.TailscaleIPs)
            {
                $Result.ip=$Status.TailscaleIPs[0]
            }

            $Result.hostname=$Status.Self.HostName

            Write-Host "[OK] Tailscale connected"
            Write-Host "[INFO] IP: $($Result.ip)"
            Write-Host "[INFO] Host: $($Result.hostname)"
        }
    }
    catch
    {
        Write-Host "[WARN] Unable to query Tailscale status"
    }
}



if($Result.installed -and $Result.connected)
{
    $Result.status="healthy"
}
else
{
    $Result.status="offline"
}



$Result |
ConvertTo-Json -Depth 10 |
Set-Content -Encoding UTF8 $Output



if(Test-Path $StateFile)
{
    $State=Get-Content $StateFile -Raw | ConvertFrom-Json

    $State.components.tailscale=$Result.status

    $State.timestamps.last_check=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")

    $State |
    ConvertTo-Json -Depth 10 |
    Set-Content -Encoding UTF8 $StateFile
}



Write-Host ""
Write-Host "Tailscale Controller complete."

Write-Host ""
Write-Host "Verification:"
Get-Content $Output
