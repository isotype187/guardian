# Remove Export-ModuleMember from all scribe files
$files = @(
    'core\Nexus98_Scribe_Core.ps1',
    'core\Nexus98_Scribe_Roadmap.ps1',
    'core\Nexus98_Scribe_TOC.ps1',
    'core\Nexus98_Scribe_Status.ps1',
    'core\Nexus98_Scribe_History.ps1',
    'core\Nexus98_Scribe_Sync.ps1',
    'core\Nexus98_Scribe.ps1'
)

foreach ($f in $files) {
    $content = Get-Content $f -Raw
    $content = $content -replace '(?m)^\s*Export-ModuleMember.*$', ''
    Set-Content $f -Value $content -Encoding UTF8
    Write-Host "Cleaned $f"
}