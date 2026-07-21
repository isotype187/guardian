$Toolkit="D:\Nexus98_Toolkit"

$Output="$Toolkit\config\nexus98_vscode.json"

$StateFile="$Toolkit\config\nexus98_state.json"


$Result=[ordered]@{
    timestamp=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")
    installed=$false
    cli=$false
    config=$false
    extensions=$false
    status="unknown"
}



$Code=Get-Command code -ErrorAction SilentlyContinue

if($null -ne $Code)
{
    $Result.installed=$true
    $Result.cli=$true
    Write-Host "[OK] VS Code CLI available"
}
else
{
    $VSPaths=@(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
        "C:\Program Files\Microsoft VS Code\Code.exe"
    )

    foreach($Path in $VSPaths)
    {
        if(Test-Path $Path)
        {
            $Result.installed=$true
            Write-Host "[OK] VS Code installed"
            break
        }
    }
}



$VSConfig="$env:APPDATA\Code\User"

if(Test-Path $VSConfig)
{
    $Result.config=$true
    Write-Host "[OK] VS Code user config exists"
}
else
{
    Write-Host "[WARN] VS Code user config missing"
}



$Extensions="$env:USERPROFILE\.vscode\extensions"

if(Test-Path $Extensions)
{
    $Result.extensions=$true
    Write-Host "[OK] VS Code extensions folder exists"
}
else
{
    Write-Host "[WARN] VS Code extensions folder missing"
}



if($Result.installed)
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

    $State.components.vscode=$Result.status

    $State.timestamps.last_check=(Get-Date).ToString("MM/dd/yyyy HH:mm:ss")

    $State |
    ConvertTo-Json -Depth 10 |
    Set-Content -Encoding UTF8 $StateFile
}



Write-Host ""
Write-Host "VS Code Controller complete."

Write-Host ""
Write-Host "Verification:"
Get-Content $Output
