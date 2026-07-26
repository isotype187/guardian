# Fix all param() blocks in scribe files - add missing closing parens
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
    
    # Fix param blocks - find "param(" followed by params but missing closing )
    # The pattern is: param(\n    [type]$var,\n    [type]$var\n
    # Should become: param(\n    [type]$var,\n    [type]$var\n)
    
    # First, fix param blocks that are missing closing paren
    $content = $content -replace '(?s)param\(([^)]*?)(\n\s*\n)', 'param($1)`n)'
    # Fix the case where the closing ) was removed
    $content = $content -replace '(?m)^param\((\s*\n(?:.*?\n)*?)\s*Write-Host', 'param($1)`n    Write-Host'
    $content = $content -replace '(?m)^param\((\s*\n(?:.*?\n)*?)\s*#', 'param($1)`n    #'
    $content = $content -replace '(?m)^param\((\s*\n(?:.*?\n)*?)\s*$', 'param($1)`n)'
    
    # Fix any subexpressions missing closing paren
    $content = $content -replace '\$\([^)]*$', '$0)'
    
    # Fix the specific case where file ends with missing )
    if ($content -notmatch '\)$') {
        $content += "`n)"
    }
    
    Set-Content $f -Value $content -Encoding UTF8
    Write-Host "Fixed $f"
}