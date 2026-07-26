# Coding Standards — Nexus98 Guardian

> **Authoritative coding standards for all Guardian PowerShell modules.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, coding, powershell
> **Related:** [[DOCUMENTATION_STANDARDS]], [[TESTING_STANDARDS]], [[BRANCH_STRATEGY]], [[REVIEW_PROCESS]], [[TEMPLATE_MODULE]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Language & Runtime

| Requirement | Standard |
|-------------|----------|
| **Language** | PowerShell 7.4+ (Core) |
| **Encoding** | UTF-8 without BOM |
| **Line Endings** | LF (Unix) |
| **Indentation** | 4 spaces (no tabs) |
| **Max Line Length** | 120 characters |
| **Script Block Style** | Allman (braces on new lines) |

---

## 2. Naming Conventions

### 2.1 Functions (Public API)
```powershell
# Verb-Noun with PascalCase, module prefix implied
New-GuardianCheckpoint
Test-GuardianPolicy
Get-GuardianHealthReport
Invoke-GuardianRemediation
```

**Approved Verbs:** `Get`, `Set`, `New`, `Remove`, `Test`, `Invoke`, `Start`, `Stop`, `Export`, `Import`, `Register`, `Unregister`, `Enable`, `Disable`, `Compress`, `Search`, `Export`

### 2.2 Functions (Private/Internal)
```powershell
# Underscore prefix + Verb-Noun
_Internal-HelperFunction
_Validate-Input
_Build-Manifest
```

### 2.3 Variables
```powershell
# Global/module-scoped: PascalCase
$GuardianEnv
$GuardianLoadedModules
$GuardianRiskTiers

# Local/function-scoped: camelCase
$checkpointId
$policyResult
$remediationPlan

# Constants: UPPER_SNAKE_CASE
$MAX_RETRIES = 5
$DEFAULT_TIMEOUT_SECONDS = 30
```

### 2.4 Parameters
```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$ActionDescription,

    [ValidateSet('low','medium','high','critical')]
    [string]$RiskLevel = 'low',

    [bool]$CheckpointAvailable = $true
)
```

### 2.5 Types & Classes
```powershell
# PascalCase with module prefix
class GuardianCheckpointManifest { ... }
class GuardianEvent { ... }
class GuardianHealthReport { ... }

# Enums: PascalCase
enum GuardianRiskTier { Low, Medium, High, Critical }
```

### 2.6 Files & Folders
```
Guardian_ModuleName/
├── Guardian_ModuleName.psd1      # Manifest
├── Guardian_ModuleName.psm1      # Root module
├── Public/
│   ├── Verb-Noun.ps1             # One file per public function
│   └── ...
├── Private/
│   └── _Helper.ps1               # Internal functions
├── Types/
│   └── ModuleTypes.ps1xml        # Type extensions
├── Formats/
│   └── ModuleFormat.ps1xml       # Format definitions
├── Tests/
│   └── Guardian.ModuleName.Tests.ps1
└── Docs/
    └── Guardian_ModuleName.md
```

---

## 3. Module Structure Standards

### 3.1 Module Manifest (`.psd1`)
```powershell
@{
    ModuleName        = 'Guardian_ModuleName'
    ModuleVersion     = '1.0.0'
    GUID              = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    Author            = 'Guardian Engineering Team'
    Description       = 'One-sentence description'
    PowerShellVersion = '7.4'
    RootModule        = 'Guardian_ModuleName.psm1'
    FunctionsToExport = @('Verb-Noun1', 'Verb-Noun2')
    CmdletsToExport   = @()
    VariablesToExport = @('GuardianModuleVariable')
    TypesToExport     = @('GuardianTypeName')
    FormatsToExport   = @('GuardianFormatName')
    RequiredModules   = @('Guardian_Contracts', 'Guardian_Audit')
    Tags              = @('Guardian', 'M0', 'Foundation')
    PrivateData = @{
        PSData = @{
            LicenseUri     = 'MIT'
            ProjectUri     = 'https://github.com/...'
            ReleaseNotes   = 'Initial release'
        }
    }
}
```

### 3.2 Root Module (`.psm1`)
```powershell
# Guardian_ModuleName.psm1
# Dot-source public functions, export types/formats

$Public  = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -ErrorAction SilentlyContinue)

foreach ($file in $Public + $Private) {
    . $file.FullName
}

Export-ModuleMember -Function $Public.BaseName -Variable GuardianModuleVariable -Alias *
```

---

## 4. Function Template (Public)

```powershell
<#
.SYNOPSIS
    Short description of what the function does.

.DESCRIPTION
    Longer description with context, behavior, and side effects.

.PARAMETER ParamName
    Description of parameter, constraints, defaults.

.PARAMETER RiskLevel
    Risk tier: low, medium, high, critical. Affects policy gate.

.EXAMPLE
    Verb-Noun -Param 'value' -RiskLevel medium
    # Creates a checkpoint and executes...

.OUTPUTS
    [GuardianResponse] Policy decision with context

.LINK
    [[COMPONENT_NAME]]
#>
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$ParamName,

        [ValidateSet('low','medium','high','critical')]
        [string]$RiskLevel = 'low',

        [bool]$CheckpointAvailable = $true
    )

    # 1. Policy Gate (MANDATORY for all mutations)
    $policy = Test-GuardianPolicy -ActionDescription $MyInvocation.MyCommand -RiskLevel $RiskLevel -CheckpointAvailable $CheckpointAvailable
    if ($policy.decision -in @('BLOCK', 'DENY')) {
        Write-GuardianAudit -Action $MyInvocation.MyCommand -Decision $policy.decision -Reason $policy.reason
        return $policy
    }

    # 2. Safety Checkpoint (for ALLOW/REQUIRE_CHECKPOINT)
    $checkpoint = $null
    if ($policy.decision -in @('ALLOW', 'REQUIRE_CHECKPOINT', 'ALLOW_WITH_MONITORING')) {
        $checkpoint = New-GuardianCheckpoint -Tier Emergency -Label "Pre-$($MyInvocation.MyCommand)"
    }

    try {
        # 3. Execute Core Logic
        $result = _Internal-DoTheWork -Param $ParamName

        # 4. Success Audit
        Write-GuardianAudit -Action $MyInvocation.MyCommand -Decision 'SUCCESS' -CheckpointId $checkpoint?.CheckpointId -Context $result
        return $result
    }
    catch {
        # 5. Automatic Rollback on Failure
        if ($checkpoint) {
            Restore-GuardianCheckpoint -Checkpoint $checkpoint -Confirm:$false
        }
        Write-GuardianAudit -Action $MyInvocation.MyCommand -Decision 'ROLLED_BACK' -Error $_.Exception.Message -CheckpointId $checkpoint?.CheckpointId
        throw
    }
}
```

---

## 5. Error Handling Standards

### 5.1 Exception Handling
```powershell
# Use try/catch for recoverable operations
try {
    $result = Do-RiskyOperation
}
catch [System.IO.IOException] {
    # Specific exception handling
    Write-GuardianAudit -Action 'operation' -Decision 'FAILED_IO' -Error $_.Exception.Message
    throw
}
catch {
    # Generic catch for unexpected errors
    Write-GuardianAudit -Action 'operation' -Decision 'FAILED_UNEXPECTED' -Error $_.Exception.Message
    throw
}
finally {
    # Cleanup (but NOT rollback - that's in catch)
}
```

### 5.2 Parameter Validation
```powershell
param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,

    [ValidateRange(1, 100)]
    [int]$RetryCount = 3,

    [ValidateSet('json', 'yaml', 'csv')]
    [string]$Format = 'json'
)
```

### 5.3 Error Output
```powershell
# Use structured error records
throw [System.Management.Automation.ErrorRecord]::new(
    [Exception]::new("Descriptive message"),
    'ERROR_CODE',
    'InvalidOperation',
    $null
)

# Or use Write-Error for non-terminating
Write-Error -Message "Validation failed" -ErrorAction Continue -Category InvalidArgument
```

---

## 6. Logging Standards

### 6.1 Audit Logging (Mandatory)
```powershell
# Every mutation MUST write audit
Write-GuardianAudit -Action 'verb-noun' -Decision 'SUCCESS|FAILED|BLOCKED|ROLLED_BACK' `
    -Reason 'Human-readable reason' -Context @{ key = 'value' } -CheckpointId $ckp?.CheckpointId
```

### 6.2 Event Logging (Operational)
```powershell
# For operational visibility (not audit)
$event = New-GuardianEvent -Source 'Guardian_ModuleName' -Category 'SYSTEM' -Severity 'INFO' -Description 'Operation started'
Write-GuardianEvent -Event $event
```

### 6.3 Structured Context
```powershell
# Always include correlation IDs for traceability
$context = @{
    correlationId = (New-Guid).Guid
    checkpointId  = $checkpoint?.CheckpointId
    policyDecision = $policy.decision
    durationMs    = $sw.ElapsedMilliseconds
}
```

---

## 7. Testing Requirements

### 7.1 Test File Naming
`Tests/Guardian.ModuleName.Tests.ps1`

### 7.2 Minimum Coverage
| Surface | Target |
|---------|--------|
| Public Functions | 90%+ |
| Policy-Gated Mutations | 100% |
| Architecture Drift | 100% |
| Bridge Contracts | 100% |

### 7.3 Test Patterns
```powershell
# Unit Test
Describe 'Module - Verb-Noun' -Tag 'Unit' {
    It 'does X when Y' {
        $result = Verb-Noun -Param 'value'
        $result | Should -Be 'expected'
    }
    It 'validates input' {
        { Verb-Noun -Param '' } | Should -Throw
    }
}

# Integration Test (checkpoint-wrapped)
Describe 'Integration - Cross-Module Flow' -Tag 'Integration' {
    BeforeEach { $script:ckp = New-GuardianCheckpoint -Tier Emergency -Label "Test-$([guid]::NewGuid())" }
    AfterEach  { Restore-GuardianCheckpoint -Checkpoint $script:ckp -Confirm:$false }
    It 'integrates with Guardian_Events' { ... }
}
```

---

## 8. Documentation Requirements

### 8.1 Per Function
- Comment-based help (SYNOPSIS, DESCRIPTION, PARAMETER, EXAMPLE, OUTPUTS, LINK)
- Policy gate behavior documented
- Checkpoint behavior documented
- Return type documented

### 8.2 Per Module
- `Docs/Guardian_ModuleName.md` using [[TEMPLATE_MODULE]]
- Architecture decision references
- Dependencies listed
- Configuration documented

---

## 9. PowerShell-Specific Rules

| Rule | Standard |
|------|----------|
| Pipeline | Support `-PipelineInput` where logical |
| Output | Use `Write-Output` explicitly; avoid implicit output |
| Splatting | Use for complex parameter sets |
| Modules | No `Import-Module` in functions; use `Guardian_Loader` |
| Scope | `$script:` for module state; avoid `$global:` |
| Aliases | Define in manifest; never in code |
| StrictMode | `Set-StrictMode -Version Latest` in module init |

---

## 10. Anti-Patterns (Forbidden)

| Anti-Pattern | Correct Approach |
|--------------|------------------|
| Direct file writes without checkpoint | `New-GuardianCheckpoint` → write → audit |
| `Write-Host` for logging | `Write-GuardianAudit` / `Write-GuardianEvent` |
| Hard-coded paths | Use `$GuardianEnv` contracts |
| Untyped hashtables in public API | `Guardian_Contracts` classes/types |
| Module load outside `Guardian_Loader` | `Import-Guardian` only |
| Pester v5 syntax (`Should Be`) | Pester v6 (`Should -Be`) |
| Silent exception swallowing | Always audit, then `throw` or return policy |
| Mutable global state | `$script:` scope, checkpoint before change |
| Missing policy gate on mutation | Every mutation calls `Test-GuardianPolicy` |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial coding standards from M10 validated patterns |

---