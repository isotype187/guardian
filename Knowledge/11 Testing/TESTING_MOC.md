# Testing MOC (Map of Content)

> **Navigation hub for testing strategy, frameworks, standards, and test organization.**

---

## 🧪 Testing Strategy

| Document | Purpose |
|----------|---------|
| [[TESTING_STRATEGY]] | Pyramid: Unit → Integration → E2E → Architecture Drift → Policy Compliance |
| [[TEST_ORGANIZATION]] | Test file structure, naming, fixtures, shared utilities |
| [[COVERAGE_GOALS]] | Public API 90%, Policy-gated mutations 100%, Architecture drift 100% |

---

## 🏗️ Test Pyramid

```
                    ┌─────────────────┐
                    │   E2E / Milestone│  ← Guardian.M10.Tests (34)
                    │  Integration    │  ← Cross-module flows (M2-M9)
           ┌────────┴─────────────────┴────────┐
           │         Integration Tests         │  ← Event→Memory, Bridge→Gov
    ┌────────┴─────────────────────────────┐   │
    │            Unit Tests                 │   │  ← Foundation (14), M2 (25), M3 (35)...
    │  Contracts, Policy, Checkpoint, Health│   │
    └───────────────────────────────────────┘   │
                          ┌─────────────────────┘
                          ▼
               ┌─────────────────────┐
               │ Architecture Drift  │  ← Test-GuardianArchitectureDrift (every load)
               │ Policy Compliance   │  ← Test-GuardianPolicy (every mutation)
               └─────────────────────┘
```

---

## 📁 Test Suite Inventory

| Test File | Milestone | Tests | Category | Status |
|-----------|-----------|-------|----------|--------|
| `Guardian.Foundation.Tests.ps1` | M0 | 14 | Unit/Integration | ✅ PASS |
| `Guardian.M2.Tests.ps1` | M2 | 25 | Unit/Integration | ✅ PASS |
| `Guardian.M3.Tests.ps1` | M3 | 35 | Unit/Integration | ✅ PASS |
| `Guardian.M4.Tests.ps1` | M4 | 28 | Unit/Integration | ✅ PASS |
| `Guardian.M5.Tests.ps1` | M5 | 22 | Unit/Integration | ✅ PASS |
| `Guardian.M6.Tests.ps1` | M6 | 11 | Unit/Integration | ✅ PASS |
| `Guardian.M7.Tests.ps1` | M7 | 17 | Unit/Integration | ✅ PASS |
| `Guardian.M8.Tests.ps1` | M8 | 18 | Unit/Integration | ✅ PASS |
| `Guardian.M9.Tests.ps1` | M9 | 10 | Unit/Integration | ✅ PASS |
| `Guardian.M10.Tests.ps1` | M10 | 34 | Integration/E2E | ✅ PASS |

**Total: 214+ tests, all passing**

---

## 📝 Test Writing Standards

### Pester v6 Syntax (Required)
```powershell
# ✅ Correct
$x | Should -Be 5
$x | Should -Match 'pattern'
{ ... } | Should -Throw
$x | Should -BeNullOrEmpty

# ❌ Deprecated (Pester v5)
$x | Should Be 5
$x | Should Match 'pattern'
{ ... } | Should Throw
$x | Should BeNullOrEmpty
```

### Standard Test File Structure
```powershell
# Pester tests for Guardian M[n] [Module Name].

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Module - Feature' -Tag 'Unit|Integration|Architecture|Governance' {
    It 'does specific behavior when condition' {
        $result = FunctionName -Param 'value'
        $result | Should -Be 'expected'
    }
    
    It 'validates input' {
        { FunctionName -Param 'invalid' } | Should -Throw
    }
}

Describe 'Integration - Cross-Module Flow' -Tag 'Integration' {
    BeforeEach { 
        $script:testCheckpoint = New-GuardianCheckpoint -Tier Emergency -Label "Test-$([guid]::NewGuid())" 
    }
    AfterEach { 
        Restore-GuardianCheckpoint -Checkpoint $script:testCheckpoint -Confirm:$false 
    }
    
    It 'integrates with Guardian_Events' { ... }
}
```

### Required Tags
- `Unit` — Single module, mocked dependencies
- `Integration` — Cross-module, real state, checkpoint-wrapped
- `Architecture` — `Test-GuardianArchitectureDrift`
- `Governance` — `Test-GuardianPolicy` on mutations
- `Performance` — Latency/throughput baselines (nightly)

### Pester v6 Scope Rule (ADR-004)

**Critical:** All test files MUST use `BeforeAll` for module loading. Top-level dot-sourcing does NOT propagate variables to child scopes in Pester v6.

```powershell
# ✅ CORRECT - Variables available in BeforeEach/It blocks
BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'My Tests' {
    BeforeEach {
        $GuardianEnv.Data  # Available here
    }
    It 'works' { ... }
}
```

```powershell
# ❌ INCORRECT - $GuardianEnv is null in BeforeEach/It
. (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))

Describe 'My Tests' {
    BeforeEach { $GuardianEnv.Data }  # NULL - scope isolation!
}
```

---

## 🔗 Related MOCs

| Gate | Command | Blocking |
|------|---------|----------|
| **Syntax** | `pwsh -c "Import-Module ./core/Guardian_*.ps1"` | ✅ |
| **Unit Tests** | `Invoke-Pester tests/Guardian.Foundation.Tests.ps1 -Tag Unit` | ✅ |
| **Milestone Tests** | `Invoke-Pester tests/Guardian.M<n>.Tests.ps1` | ✅ |
| **Architecture Drift** | `Test-GuardianArchitectureDrift` | ✅ |
| **Policy Compliance** | `Test-GuardianPolicy` on changed files | ✅ |
| **Contract Testing** | JSON Schema validation on bridge messages | 📋 M11 |
| **Performance** | `Invoke-GuardianBenchmarks` regression < 10% | 📋 M11 |

---

## 🔧 Test Infrastructure

| Component | Purpose |
|-----------|---------|
| `tests/fixtures/` | Shared test data: events, memory, checkpoints |
| `tests/guardian_test_utils.psm1` | Helpers: `New-TestRoot`, `Remove-TestRoot`, `Get-TestEvent` |
| `tests/pester.config.json` | Pester configuration: output, coverage, parallel |
| `scripts/Run-GuardianTests.ps1` | Orchestrated test runner with exit codes |

---

## 📊 Coverage Targets

| Surface | Target | Enforcement |
|---------|--------|-------------|
| Public Functions | 90%+ | CI gate (M11) |
| Policy-Gated Mutations | 100% | CI gate |
| Architecture Drift Detection | 100% | CI gate |
| Bridge Message Contracts | 100% | CI gate (M11) |
| Checkpoint/Rollback Paths | 100% | CI gate |

---

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[DEVELOPMENT_MOC]] — Dev standards including test patterns
- [[ARCHITECTURE_MOC]] — Architecture drift testing
- [[ROADMAP_MOC]] — Milestone test requirements
- [[CI_CD_MOC]] — Pipeline integration

---

*Tests are the specification. If it's not tested, it doesn't exist.*