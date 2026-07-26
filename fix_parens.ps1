# Remove Export-ModuleMember from all scribe files (clean up any remaining issues)
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
    # Fix any double closing parens that may have been introduced
    $content = $content -replace '\)\)$', ')'
    # Ensure function lists end with just )
    $content = $content -replace '\)\)$', ')'
    # Remove any stray )
    $content = $content -replace '(?m)^\s*\)\)$', ')'
    Set-Content $f -Value $content -Encoding UTF8
    Write-Host "Fixed $f"
}