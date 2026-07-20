# Guardian Pattern Recognition Foundation (M3 P3).
# Detects repeated behavior from events + memory. Insight only; no action.

function Get-GuardianPatterns {
    param([int]$MinOccurrences=2)
    $patterns = @()

    # 1. Recurring event signatures (source|category|description).
    $events = Get-GuardianEvents
    if ($events) {
        $groups = $events | Group-Object { "$($_.source)|$($_.category)|$($_.description)" } |
            Where-Object { $_.Count -ge $MinOccurrences }
        foreach ($g in $groups) {
            $sample = $g.Group[0]
            $patterns += [PSCustomObject]@{
                type='recurring_event'
                signature=$g.Name
                occurrences=$g.Count
                severity=$sample.severity
                recommendation=("Recurring $($sample.category) signal detected ($($g.Count) times). Consider reviewing the underlying $($sample.source) process.")
            }
        }
    }

    # 2. Recurring memory descriptions (long-term repetition).
    $mem = Get-GuardianMemory -Category pattern
    if ($mem) {
        $mg = $mem | Group-Object description | Where-Object { $_.Count -ge $MinOccurrences }
        foreach ($g in $mg) {
            $patterns += [PSCustomObject]@{
                type='recurring_pattern'
                signature=$g.Name
                occurrences=$g.Count
                severity='info'
                recommendation="Pattern memory records this $($g.Count) times. Validate the recommended mitigation before any future action."
            }
        }
    }

    # 3. Known heuristic: dependency-related failures -> checkpoint recommendation.
    $depEvents = @($events) | Where-Object { $_.description -match '(?i)dependenc' -and $_.severity -in @('ERROR','CRITICAL') }
    if ($depEvents.Count -ge $MinOccurrences) {
        $patterns += [PSCustomObject]@{
            type='heuristic'
            signature='dependency_failure'
            occurrences=$depEvents.Count
            severity='warning'
            recommendation="Dependency changes have caused failures $($depEvents.Count) times. Recommendation: create a checkpoint before dependency modifications."
        }
    }

    return $patterns
}

function New-GuardianPatternMemory {
    param([Parameter(Mandatory=$true)][string]$Description, [double]$Confidence=0.6)
    $m = New-GuardianMemory -Source 'pattern_engine' -Category pattern -Importance 'medium' -Confidence $Confidence -Description $Description -RetentionClass 'LONG_TERM'
    return Write-GuardianMemory -Memory $m
}
