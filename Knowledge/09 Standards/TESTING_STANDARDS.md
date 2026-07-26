# Testing Strategy — Nexus98 Guardian

> **Comprehensive testing framework covering unit, integration, system, performance, security, and chaos testing.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, testing, quality
> **Related:** [[CODING_STANDARDS]], [[BRANCH_STRATEGY]], [[REVIEW_PROCESS]], [[CI_CD_PIPELINE]], [[TESTING_MOC]], [[TEMPLATE_MODULE]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Test Pyramid

```
                           ┌─────────────────┐
                           │   E2E / Chaos   │  ← Guardian.M10.Tests (34)
                    ┌──────┴─────────────────┴──────┐
                    │      Integration Tests       │  ← M2-M9 Milestone Tests (10-35 each)
           ┌────────┴─────────────────────────────┴────────┐
           │            Unit Tests                         │  ← Foundation (14) + Per-module
    ┌────────┴─────────────────────────────────────────────┴────────┐
    │           Architecture Drift + Policy Gates                  │  ← Every load + every mutation
    │   Test-GuardianArchitectureDrift | Test-GuardianPolicy      │
    └──────────────────────────────────────────────────────────────┘
```

---

## 2. Test Categories & Requirements

### 2.1 Unit Tests
| Aspect | Standard |
|--------|----------|
| **Framework** | Pester v6.x |
| **Syntax** | `Should -Be`, `Should -Match`, `Should -Throw`, `Should -BeNullOrEmpty` |
| **Scope** | Single module, mocked dependencies |
| **Coverage Target** | 90%+ public functions |
| **Naming** | `Describe 'Module - Feature' -Tag 'Unit'` |
| **Structure** | `It 'does specific behavior when condition'` |
| **Fixtures** | Shared in `tests/fixtures/` |
| **Checkpoint Pattern** | NOT required (mocked state) |

### 2.2 Integration Tests
| Aspect | Standard |
|--------|----------|
| **Scope** | Cross-module flows, real state |
| **State Isolation** | **Mandatory checkpoint pattern** |
| **Checkpoint Pattern** | ```powershell BeforeEach { $script:testCp = New-GuardianCheckpoint -Tier Emergency -Label "Test-$([guid]::NewGuid())" } AfterEach { Restore-GuardianCheckpoint -Checkpoint $script:testCp -Confirm:$false } ``` |
| **Naming** | `Describe 'Integration - Cross-Module Flow' -Tag 'Integration'` |
| **Milestone Suites** | `Guardian.M<n>.Tests.ps1` |

### 2.3 Architecture Drift Tests
| Aspect | Standard |
|--------|----------|
| **Trigger** | Every `Import-Guardian`, CI, pre-release |
| **Command** | `Test-GuardianArchitectureDrift` |
| **Pass Criteria** | Zero drift items |
| **Failure** | Blocks merge, requires ADR or remediation |

### 2.4 Policy Compliance Tests
| Aspect | Standard |
|--------|----------|
| **Trigger** | Every mutation function, CI on changed files |
| **Command** | `Test-GuardianPolicy -ActionDescription '...' -RiskLevel '...'` |
| **Pass Criteria** | Decision ≠ `BLOCK` (unless safeguards intact) |
| **Coverage** | 100% of mutation functions |

### 2.5 Contract Tests (M11+)
| Aspect | Standard |
|--------|----------|
| **Schema Source** | Generated from `Guardian_Contracts` classes |
| **Validation** | All bridge messages (inbound/outbound) |
| **Tool** | JSON Schema (Draft 2020-12) |
| **CI Gate** | All messages validate against schema |

### 2.5 Performance Tests (M11+)
| Aspect | Standard |
|--------|----------|
| **Tool** | `Invoke-GuardianBenchmarks` (custom) |
| **Frequency** | Nightly + pre-release |
| **Baselines** | Stored in `data/benchmarks/` |
| **Regression Gate** | > 10% degradation = fail |
| **Key Operations** | Checkpoint create/restore, event write/read, storage scan, policy eval, bridge dispatch |

### 2.6 Security Tests (M11+)
| Aspect | Standard |
|--------|----------|
| **Static Analysis** | `PSScriptAnalyzer` (all rules) |
| **Secret Scanning** | `gitleaks` / `trufflehog` |
| **Dependency Scan** | `dotnet list package --vulnerable` |
| **SAST** | CodeQL (future) |

### 2.7 Chaos Tests (M14+)
| Scenario | Validation |
|----------|------------|
| Checkpoint disk full | Graceful degradation, alert |
| Bridge message flood | Backpressure, no OOM |
| Concurrent mutations | Serialization, no corruption |
| Network partition (bridge) | Queue persistence, replay |
| Module load failure | Non-critical continue, critical fail |

---

## 3. Test Organization

```
tests/
├── fixtures/                    # Shared test data
│   ├── events.json
│   ├── memory.json
│   ├── checkpoints/
│   └── guardian_test_utils.psm1 # New-TestRoot, Get-TestEvent, etc.
├── Guardian.Foundation.Tests.ps1    # M0: 14 tests
├── Guardian.M2.Tests.ps1            # M2: 25 tests
├── Guardian.M3.Tests.ps1            # M3: 35 tests
├── Guardian.M4.Tests.ps1            # M4: 28 tests
├── Guardian.M5.Tests.ps1            # M5: 22 tests
├── Guardian.M6.Tests.ps1            # M6: 11 tests
├── Guardian.M7.Tests.ps1            # M7: 17 tests
├── Guardian.M8.Tests.ps1            # M8: 18 tests
├── Guardian.M9.Tests.ps1            # M9: 10 tests
├── Guardian.M10.Tests.ps1           # M10: 34 tests
├── Guardian.M11.Tests.ps1           # M11: CI/CD, secrets, contracts
├── pester.config.json               # Pester configuration
└── run_all.ps1                      # Orchestrated runner
```

### 3.1 Test Utilities (`tests/fixtures/guardian_test_utils.psm1`)
```powershell
function New-TestRoot { ... }        # Isolated temp directory
function Remove-TestRoot { ... }     # Cleanup
function Get-TestEvent { ... }       # Standardized test event
function Get-TestMemory { ... }      # Standardized test memory
function Get-TestCheckpoint { ... }  # Standardized checkpoint
```

---

## 4. Quality Gates

### 4.1 Pre-Commit (Local)
```bash
# Syntax check
pwsh -c "Import-Module ./core/Guardian_*.ps1"

# Foundation tests
./tests/run_foundation_tests.ps1
```

### 4.2 CI Pipeline (Per PR)
| Stage | Command | Blocking |
|-------|---------|----------|
| **Syntax** | `pwsh -c "Import-Module ./core/Guardian_*.ps1"` | ✅ |
| **Unit** | `Invoke-Pester tests/Guardian.Foundation.Tests.ps1 -Tag Unit` | ✅ |
| **Milestone** | `Invoke-Pester tests/Guardian.M<n>.Tests.ps1` (if applicable) | ✅ |
| **Architecture** | `Test-GuardianArchitectureDrift` | ✅ |
| **Policy** | `Test-GuardianPolicy` on changed files | ✅ |
| **Contracts** | JSON Schema validation (M11+) | ✅ |
| **Security** | PSScriptAnalyzer + secret scan (M11+) | ✅ |
| **Docs** | `Validate-GuardianDocLinks` | ⚠️ Warning |

### 4.3 Release Gates
| Gate | Criteria |
|------|----------|
| **All Tests Pass** | 214+ tests (M0-M10) + milestone-specific |
| **Architecture Clean** | Zero drift |
| **Policy Coverage** | 100% mutation gates |
| **Performance** | Within 10% of baseline |
| **Security** | No critical findings |
| **Documentation** | Sync check passed |

---

## 5. Test Data Management

### 5.1 Fixtures
- **Location:** `tests/fixtures/`
- **Format:** JSON, JSONL
- **Versioned:** Yes, with code
- **Types:** Events, memories, checkpoints, bridge messages

### 5.2 Test Isolation
- **Unit:** No shared state (mocks)
- **Integration:** Checkpoint per test (create → execute → restore)
- **E2E:** Dedicated test environment (future)

### 5.3 Cleanup
- **Checkpoint Auto-cleanup:** Emergency tier 30-day TTL
- **Test Roots:** Removed in `AfterEach` / `AfterAll`
- **No Persistent Test Artifacts** in repo

---

## 6. Test Maintenance Rules

| Rule | Enforcement |
|------|-------------|
| No skipped tests | Fix or delete; skip = technical debt |
| No flaky tests | Quarantine immediately; fix within 48h |
| Test data in fixtures | No inline data > 3 lines |
| One assertion per `It` | Multiple = unclear failures |
| Describe = user behavior | Not implementation detail |
| Tags required | Unit, Integration, Architecture, Governance, Performance |
| Coverage tracked | CI reports; < 90% = warning |

---

## 7. Test Execution Commands

```powershell
# Foundation only (fast)
./tests/run_foundation_tests.ps1

# Specific milestone
Invoke-Pester ./tests/Guardian.M8.Tests.ps1 -Output Detailed

# All tests (slow)
Invoke-Pester ./tests/ -ConfigurationFile ./tests/pester.config.json

# With coverage (M11+)
Invoke-Pester ./tests/ -EnableCoverage -CoverageThreshold 90 -CoverageOutputFile coverage.xml

# Performance baseline
Invoke-GuardianBenchmarks -SaveBaseline

# Chaos (future)
Invoke-GuardianChaos -Scenario 'disk-full'
```

---

## 8. Metrics & Reporting

### 8.1 Key Metrics (Dashboard)
| Metric | Target | Source |
|--------|--------|--------|
| Test Count (total) | Growing | CI |
| Pass Rate | 100% | CI |
| Coverage (public API) | ≥ 90% | Coverage tool |
| Architecture Drift | 0 | Drift test |
| Policy Compliance | 100% | Policy test |
| Performance Regression | ≤ 10% | Benchmarks |
| Flaky Test Count | 0 | CI history |

### 8.2 Reporting
- **Per PR:** CI summary (pass/fail, duration)
- **Nightly:** Full suite + benchmarks + security scan
- **Per Release:** Complete test report + baselines
- **Quarterly:** Test health review (flaky, coverage gaps, speed)

---

## 9. Future Enhancements

| Enhancement | Target | Description |
|-------------|--------|-------------|
| Parallel Test Execution | M11 | `Invoke-Pester -Parallel` for unit tests |
| Property-Based Testing | M12 | `FsCheck`-style generators for contracts |
| Mutation Testing | M12 | `Stryker`-style mutant survival rate |
| Visual Regression | M13 | Dashboard screenshots |
| Load Testing | M13 | Bridge message throughput |
| Contract Fuzzing | M14 | Schema fuzzing for bridge |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial testing strategy from M10 validated test suites |

---