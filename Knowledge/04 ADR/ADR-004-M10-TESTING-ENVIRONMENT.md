# ADR-004: M10 Testing Environment Initialization

**Status:** Accepted  
**Date:** 2026-07-26  
**Author:** Guardian Engineering Team  
**Reviewers:** Guardian Architecture Review  

## Context

During M10 validation, the test suite `Guardian.M10.Tests.ps1` failed with 34 tests showing:
```
ParameterBindingValidationException: Cannot bind argument to parameter 'Path' because it is null.
```

The error occurred at `Join-Path $GuardianEnv.Data 'ops'` in the `BeforeEach` blocks across all test suites.

## Root Cause

**Pester v6 Scope Isolation**

- Foundation tests (`Guardian.Foundation.Tests.ps1`) used `BeforeAll` block for module loading:
  ```powershell
  BeforeAll {
      . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
      Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
  }
  ```

- M10 tests used top-level dot-sourcing:
  ```powershell
  . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
  Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
  ```

In Pester v6, top-level script scope variables are **not** accessible inside `BeforeEach`/`It` child scopes. The `BeforeAll` block runs in a shared scope that properly propagates module-level variables (like `$GuardianEnv`) to child scopes.

## Decision

**All Pester test files MUST use `BeforeAll` for module initialization.**

### Pattern

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}
```

## Consequences

### Positive
- Module-level variables (`$GuardianEnv`, `$GuardianOpsDir`, etc.) are properly available in all test scopes
- Consistent initialization across all milestone test files
- Clear separation between test setup and test execution

### Negative
- Requires updating any existing test files that use top-level loading
- Slight increase in test file boilerplate

## Implementation

Fixed `Guardian.M10.Tests.ps1` by wrapping module loading in `BeforeAll`:

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}
```

## Verification

- M10 test suite: 34/34 tests PASS (was 0/34 FAIL)
- All other milestone tests (M0, M2-M9) continue to pass
- Created verification script confirming `$GuardianEnv.Data` accessibility in child scopes

## Prevention Rule

**For all future Pester v6 test files:**
1. Always use `BeforeAll` for module loading and environment initialization
2. Never rely on top-level dot-sourcing for module variables needed in `BeforeEach`/`It` blocks
3. Include a comment referencing this ADR

## Related

- ADR-002: Pester v5 → v6 Migration
- ADR-003: Checkpoint-Before-Change Pattern