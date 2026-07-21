$Toolkit="D:\Nexus98_Toolkit"

$Output="$Toolkit\config\nexus98_ssh.json"

$StateFile="$Toolkit\config\nexus98_state.json"


$Result=[ordered]@{
    timestamp=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
    client=$false
    server=$false
    service=$false
    ssh_folder=$false
    keys=$false
    status="unknown"
}



if(Get-Command ssh.exe -ErrorAction SilentlyContinue)
{
    $Result.client=$true
    Write-Host "[OK] SSH client available"
}
else
{
    Write-Host "[FAIL] SSH client missing"
}



try
{
    $Server=Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop

    if($null -ne $Server -and $Server.State -eq "Installed")
    {
        $Result.server=$true
        Write-Host "[OK] SSH server installed"
    }
    else
    {
        Write-Host "[WARN] SSH server not installed"
    }
}
catch
{
    Write-Host "[WARN] SSH server check requires administrator privileges"
}



$Service=Get-Service sshd -ErrorAction SilentlyContinue

if($null -ne $Service)
{
    $Result.service=$true
    Write-Host "[OK] SSH service exists"
}
else
{
    Write-Host "[WARN] SSH service not found"
}



$SSHFolder="$env:USERPROFILE\.ssh"

if(Test-Path $SSHFolder)
{
    $Result.ssh_folder=$true
    Write-Host "[OK] SSH folder exists"
}
else
{
    Write-Host "[WARN] SSH folder missing"
}



if((Test-Path "$SSHFolder\id_rsa") -or (Test-Path "$SSHFolder\id_ed25519"))
{
    $Result.keys=$true
    Write-Host "[OK] SSH keys detected"
}
else
{
    Write-Host "[WARN] SSH keys not detected"
}



if($Result.client -and $Result.ssh_folder)
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

    $State.components.ssh=$Result.status

    $State.timestamps.last_check=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")

    $State |
    ConvertTo-Json -Depth 10 |
    Set-Content -Encoding UTF8 $StateFile
}



Write-Host ""
Write-Host "SSH Controller complete."

Write-Host ""
Write-Host "Verification:"
Get-Content $Output


