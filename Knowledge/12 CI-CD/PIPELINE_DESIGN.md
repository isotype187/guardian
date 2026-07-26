# CI/CD Pipeline Design — Nexus98 Guardian

> **Authoritative CI/CD pipeline specification for the Guardian project.**
> **Version:** 2.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, ci, cd, pipeline, automation
> **Related:** [[BRANCH_STRATEGY]], [[RELEASE_FRAMEWORK]], [[TESTING_STRATEGY]], [[CODING_STANDARDS]], [[REVIEW_PROCESS]], [[RESOURCE_GOVERNANCE]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Pipeline Philosophy

| Principle | Implementation |
|-----------|----------------|
| **Fail Fast** | Syntax → Unit → Integration → Architecture → Policy → Contracts → Security → Performance |
| **Immutable Artifacts** | Versioned, signed, reproducible builds |
| **Self-Service** | Engineers trigger/debug without ops |
| **Observability** | Structured logs, metrics, dashboards |
| **Security by Default** | Secret scanning, dependency audit, signed releases |

---

## 2. Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         CI PIPELINE (Per PR / Push)                              │
├─────────────┬─────────────┬─────────────┬─────────────┬─────────────┬───────────┤
│  SYNTAX     │   UNIT      │ INTEGRATION │ ARCHITECTURE│   POLICY    │ CONTRACTS │
│  CHECK      │   TESTS     │   TESTS     │   DRIFT     │ COMPLIANCE  │  TESTING  │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┼───────────┤
│  < 30s      │  < 2 min    │  < 5 min    │  < 1 min    │  < 1 min    │  < 2 min  │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────┴───────────┘
                                    │
                                    ▼
┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────────────────┤
│  SECURITY   │  PERFORMANCE│  DOCUMENT   │  BUILD      │     RELEASE (Tag)       │
│   SCAN      │  BASELINE   │   SYNC      │  ARTIFACTS  │                         │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────────────────┤
│  < 3 min    │  < 10 min   │  < 30s      │  < 2 min    │       Manual            │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────────────────┘
```

---

## 3. Pipeline Stages Detail

### 3.1 Stage 1: Syntax Check
**Trigger:** Every push / PR
**Timeout:** 30 seconds
**Runner:** `ubuntu-latest` (fastest cold start)

| Step | Command | Purpose |
|------|---------|---------|
| Checkout | `actions/checkout@v4` | Fetch code |
| Syntax Validation | `pwsh -c "Import-Module ./core/Guardian_*.ps1"` | Verify all modules load without syntax errors |
| Module Discovery | `Get-ChildItem ./core/Guardian_*.ps1 \| Measure-Object` | Verify expected module count (33) |

**Failure Action:** Block merge, immediate feedback

---

### 3.2 Stage 2: Unit Tests
**Trigger:** Every push / PR (after syntax passes)
**Timeout:** 2 minutes
**Runner:** `ubuntu-latest` + `windows-latest` (matrix)

| Step | Command | Purpose |
|------|---------|---------|
| Setup | `actions/setup-powershell@v1` | PowerShell 7.4+ |
| Install Pester | `Install-Module Pester -MinimumVersion 6.0` | Test framework |
| Run Foundation | `Invoke-Pester ./tests/Guardian.Foundation.Tests.ps1 -Tag Unit` | M0: 14 tests |
| Run Milestone Units | `Invoke-Pester ./tests/Guardian.M*.Tests.ps1 -Tag Unit` | M2-M10 unit tests |

**Parallelization:** Run M2-M10 in parallel (each milestone independent)

**Failure Action:** Block merge, show specific test failures

---

### 3.3 Stage 3: Integration Tests
**Trigger:** Every push / PR (after unit passes)
**Timeout:** 5 minutes
**Runner:** `windows-latest` (requires full Guardian runtime)

| Step | Command | Purpose |
|------|---------|---------|
| Checkpoint Setup | `New-GuardianCheckpoint -Tier Emergency -Label "CI-Integration"` | Safe state |
| Run Integration | `Invoke-Pester ./tests/Guardian.M*.Tests.ps1 -Tag Integration` | Cross-module flows |
| Checkpoint Restore | `Restore-GuardianCheckpoint -Confirm:$false` | Clean state |

**Checkpoint Pattern:** Each integration test creates emergency checkpoint, restores after

---

### 3.4 Stage 4: Architecture Drift Check
**Trigger:** Every push / PR (after integration passes)
**Timeout:** 1 minute
**Runner:** `ubuntu-latest`

| Step | Command | Purpose |
|------|---------|---------|
| Load Guardian | `Import-Guardian` | Initialize modules |
| Drift Test | `Test-GuardianArchitectureDrift` | Zero drift required |

**Failure Action:** Block merge — architecture drift prevents merge

---

### 3.5 Stage 6: Contract Testing (M11+)
**Trigger:** Bridge/message changes (after policy passes)
**Timeout:** 2 minutes
**Runner:** `ubuntu-latest`

| Step | Tool | Purpose |
|------|------|---------|
| Schema Gen | Custom script | Generate JSON Schema from `Guardian_Contracts` classes |
| Validate | `jsonschema` / `python -m jsonschema` | Validate all bridge messages |
| Diff Check | `git diff` on schemas | Detect breaking changes |

**Schema Location:** `docs/schemas/bridge-messages/`

---

### 3.6 Stage 7: Security Scan
**Trigger:** Every push / PR + Nightly
**Timeout:** 3 minutes
**Runner:** `ubuntu-latest`

| Scan Type | Tool | Config |
|-----------|------|--------|
| Static Analysis | `PSScriptAnalyzer` | All rules, severity: Warning+ |
| Secret Scanning | `gitleaks` / `trufflehog` | `.gitleaks.toml` |
| Dependency Audit | `dotnet list package --vulnerable` | NuGet packages |

**Failure Threshold:** Any `Error` severity → Block merge

---

### 3.6 Stage 7: Performance Baseline (M11+)
**Trigger:** Nightly + Pre-release
**Timeout:** 10 minutes
**Runner:** `windows-latest` (dedicated runner recommended)

| Benchmark | Target | Regression Gate |
|-----------|--------|-----------------|
| Checkpoint Create | < 30s | > 10% slower = fail |
| Checkpoint Restore | < 60s | > 10% slower = fail |
| Event Write/Read | > 1000/s | > 10% slower = fail |
| Storage Scan (100k files) | < 5 min | > 10% slower = fail |
| Policy Evaluation | < 10ms | > 10% slower = fail |
| Bridge Dispatch | < 5s | > 10% slower = fail |

**Baseline Storage:** `data/benchmarks/baseline.json`

---

### 3.7 Stage 8: Documentation Sync Check
**Trigger:** Every push / PR
**Timeout:** 30 seconds
**Runner:** `ubuntu-latest`

| Check | Method |
|-------|--------|
| Frontmatter Valid | `Validate-GuardianDocFrontmatter` |
| Links Resolve | `Validate-GuardianDocLinks` |
| No Orphans | `Index-GuardianDocs` |
| MOC Current | Compare MOC links to actual files |

**Failure:** Warning (not blocking — allows doc-fix PR)

---

### 3.8 Stage 9: Build Artifacts (Release Tags Only)
**Trigger:** `git tag -s v*.*.*` pushed
**Timeout:** 2 minutes
**Runner:** `windows-latest`

| Artifact | Location | Purpose |
|----------|----------|---------|
| Module Package | `dist/Guardian-X.Y.Z.zip` | Distribution |
| SBOM | `dist/sbom-vX.Y.Z.json` | Supply chain |
| Checksums | `dist/SHA256SUMS` | Integrity |
| Release Notes | `dist/RELEASE_vX.Y.Z.md` | Communication |

---

## 4. Branch-Specific Pipeline Behavior

| Branch | Pipeline | Deploy Target |
|--------|----------|---------------|
| `main` | Full CI + Deploy Alpha | Alpha environment |
| `develop` | Full CI | Staging |
| `release/v*` | Full CI + Release Build | Staging → Production |
| `feature/*` | Syntax + Unit + Integration + Drift | None |
| `hotfix/*` | Full CI | Production (immediate) |

---

## 5. Matrix Testing Strategy

### 5.1 Platform Matrix (Future M12+)
| OS | PowerShell | Status |
|----|------------|--------|
| `ubuntu-latest` | 7.4+ | Planned M12 |
| `windows-latest` | 7.4+ | Active |
| `macos-latest` | 7.4+ | Planned M14 |

### 5.2 PowerShell Version Matrix (Future)
| Version | Status |
|---------|--------|
| 7.4 LTS | Minimum required |
| 7.5 LTS | Target |
| 8.0 (preview) | Experimental |

---

## 6. Quality Gates Summary

| Gate | Blocking | Metric | Threshold |
|------|----------|--------|-----------|
| Syntax | ✅ | Module load errors | 0 |
| Unit Tests | ✅ | Pass rate | 100% |
| Integration | ✅ | Pass rate | 100% |
| Architecture Drift | ✅ | Drift items | 0 |
| Policy Compliance | ✅ | Mutation gates | 100% |
| Contract Tests | ✅ | Schema valid | 100% |
| Security Scan | ✅ | Errors | 0 |
| Performance | ⚠️ Warning | Regression | < 10% |
| Doc Sync | ⚠️ Warning | Broken links | 0 |

---

## 7. Required GitHub Repository Settings

### 7.1 Branch Protection Rules
```yaml
main:
  required_reviews: 2
  required_status_checks:
    - "Syntax Check"
    - "Unit Tests (ubuntu)"
    - "Unit Tests (windows)"
    - "Integration Tests"
    - "Architecture Drift"
    - "Policy Compliance"
    - "Contract Tests"
    - "Security Scan"
  require_linear_history: true
  require_signed_commits: true

develop:
  required_reviews: 1
  required_status_checks: [same as main minus signed commits]
```

### 7.2 Required Secrets
| Secret | Purpose | Rotation |
|--------|---------|----------|
| `AZURE_KEYVAULT_URL` | SecretManagement | 90 days |
| `GITLEAKS_LICENSE` | Secret scanning | Annual |
| `CODESIGN_CERT` | Module signing | Annual |
| `GH_TOKEN` | Release automation | 90 days |

### 7.3 Environments
| Environment | Protection Rules |
|-------------|------------------|
| `alpha` | Auto-deploy from `main` |
| `staging` | Manual approval |
| `production` | Required reviewers (2), manual approval |

---

## 8. Monitoring & Observability

### 8.1 Pipeline Metrics (Dashboard)
| Metric | Target | Alert |
|--------|--------|-------|
| Pipeline Duration (Full) | < 15 min | > 20 min |
| Pipeline Success Rate | > 95% | < 90% |
| Flaky Test Rate | < 1% | > 2% |
| Mean Time to Recovery | < 30 min | > 60 min |

### 8.2 Artifact Retention
| Artifact | Retention |
|----------|-----------|
| Test Results | 30 days |
| Security Scan Reports | 90 days |
| Performance Baselines | Forever |
| Release Artifacts | Forever |
| SBOMs | Forever |

---

## 9. Migration Plan (Current → Target)

| Phase | Action | Timeline |
|-------|--------|----------|
| **Phase 1** | Enhance existing workflow with missing gates | Week 1 |
| **Phase 2** | Add contract testing, security scan | Week 2 |
| **Phase 3** | Add performance baselines, doc sync | Week 3 |
| **Phase 4** | Add matrix testing (Linux), SBOM | M12 |
| **Phase 5** | Add CD (alpha/staging/prod environments) | M13 |

---

## 10. Pipeline-as-Code Location

| File | Purpose |
|------|---------|
| `.github/workflows/guardian-ci.yml` | Main CI pipeline |
| `.github/workflows/guardian-release.yml` | Release pipeline |
| `.github/workflows/guardian-nightly.yml` | Nightly benchmarks + security |
| `.github/actions/guardian-setup/` | Composite action for Guardian setup |
| `.github/actions/guardian-checkpoint/` | Composite action for checkpoint management |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-25 | Team | Initial workflow (M10) |
| 2.0.0 | 2026-07-26 | Team | Full quality gates, matrix, security, contracts, performance |

---