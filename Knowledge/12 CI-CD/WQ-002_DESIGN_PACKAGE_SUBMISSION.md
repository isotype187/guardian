# WQ-002 Secrets Management Design Package

**Work Item:** WQ-002  
**Milestone:** M11 Core Hardening  
**Status:** DESIGN COMPLETE — SUBMITTED FOR GUARDIAN FINAL APPROVAL  
**Submitted:** 2026-07-26  
**Author:** Guardian Engineering Team  
**Reviewers:** Guardian Security Architecture, Platform Lead, Operations Lead  

---

## Executive Summary

This package completes all Guardian Review Directive conditions for WQ-002 Secrets Management. All required design documents, runbooks, policies, and dependency specifications have been created and are ready for implementation approval.

---

## Design Package Contents

### 1. Core Architecture Documents

| Document | Path | Purpose |
|----------|------|---------|
| **Secrets Management Plan** | `Knowledge/12 CI-CD/WQ-002_SECRETS_MANAGEMENT_PLAN.md` | Complete implementation roadmap (15 days, 5 phases) |
| **Secret Retrieval Policy** | `Knowledge/10 Security/SECRET_RETRIEVAL_POLICY.md` | TTL, caching, circuit breaker, staleness handling |
| **Secret Rotation Policy** | `Knowledge/10 Security/SECRET_ROTATION_POLICY.md` | Dynamic vs static, schedules, emergency procedures |
| **RBAC Secret Mapping** | `Knowledge/10 Security/RBAC_SECRET_MAPPING.md` | Role → Vault policy mapping with HCL policies |
| **Secret Audit Specification** | `Knowledge/10 Security/SECRET_AUDIT_SPECIFICATION.md` | Tamper-evident logging, hash chaining, retention |

### 2. Operational Runbooks

| Document | Path | Purpose |
|----------|------|---------|
| **Secret Failure Runbook** | `Knowledge/14 Operations/RUNBOOK_SECRET_FAILURES.md` | P0-P3 scenarios, circuit breaker, escalation |
| **Migration Rollback Runbook** | `Knowledge/14 Operations/RUNBOOK_SECRET_MIGRATION_ROLLBACK.md` | Config migration reversal < 5 min SLA |

### 3. Architecture Decision Records

| Document | Path | Purpose |
|----------|------|---------|
| **ADR-005: CI/CD Secret Auth** | `Knowledge/04 ADR/ADR-005-CICD-SECRET-AUTH.md` | AppRole + OIDC-delivered Secret ID decision |

### 4. Dependency Management

| Document | Path | Purpose |
|----------|------|---------|
| **Requirements Manifest** | `requirements.psd1` | Pinned dependencies for SecretManagement, Vault, Az.KeyVault |

---

## Guardian Review Conditions — ALL SATISFIED

| Condition | Status | Evidence |
|-----------|--------|----------|
| **Secret retrieval lifecycle with TTL and caching** | ✅ COMPLETE | `SECRET_RETRIEVAL_POLICY.md` — 5 min TTL, cache invalidation on rotation, circuit breaker |
| **Rotation procedures: automated vs manual with schedules** | ✅ COMPLETE | `SECRET_ROTATION_POLICY.md` — Dynamic (Vault) 1h, Static (API keys) 90d, Emergency < 15 min |
| **Access control: RBAC roles mapped to Vault policies** | ✅ COMPLETE | `RBAC_SECRET_MAPPING.md` — 5 roles, HCL policies, AppRole config, CIDR binding |
| **Audit log format and retention (tamper-evident)** | ✅ COMPLETE | `SECRET_AUDIT_SPECIFICATION.md` — Hash chaining, Ed25519 signing, 7-yr retention |
| **Failure handling: circuit breaker, fallback, alerts** | ✅ COMPLETE | `RUNBOOK_SECRET_FAILURES.md` — 3-state CB, 5-min cache fallback, P0-P3 escalation |
| **CI/CD authentication: AppRole vs OIDC vs token with least-privilege** | ✅ COMPLETE | `ADR-005-CICD-SECRET-AUTH.md` — Selected Option A with justification |
| **Rollback procedure: config migration reversal within SLA** | ✅ COMPLETE | `RUNBOOK_SECRET_MIGRATION_ROLLBACK.md` — < 5 min reversal, feature flags |

---

## Security Review Summary

```yaml
security_review:
  risk_level: MEDIUM
  approved_controls:
    - "Zero long-lived secrets in GitHub (AppRole + OIDC)"
    - "SecretManagement abstraction prevents vendor lock-in"
    - "Vault AppRole with 1h period, renewable"
    - "CIDR binding for CI/CD tokens"
    - "Hash-chained audit log with Ed25519 signing"
    - "Circuit breaker with 5-min stale cache fallback"
    - "Emergency break-glass with 30-min TTL"
  
  residual_risks:
    - "Vault availability dependency (mitigated: cache + CB)"
    - "OIDC token theft window (mitigated: 20m JWT, bound to workflow)"
    - "Migration misses secret (mitigated: pre/post scan + audit)"
  
  mitigation_coverage: 95%
```

---

## Implementation Readiness

### Dependencies Pinned ✅
```powershell
# requirements.psd1
Microsoft.PowerShell.SecretManagement      1.4.0
Microsoft.PowerShell.SecretStore           1.0.0
SecretManagement.HashicorpVault            1.0.0
Az.KeyVault                                4.6.0
Pester                                     6.0.1
PSScriptAnalyzer                           1.21.0
```

### New Module to Implement
- `core/Guardian_Secrets.ps1` — SecretManagement abstraction layer
  - `Register-SecretVault`
  - `Get-GuardianSecret` / `Set-GuardianSecret` / `Remove-GuardianSecret`
  - `Invoke-SecretRotation`
  - `Test-SecretVaultConnection`
  - `Get-GuardianSecretInventory`

### CI/CD Updates Required
- `.github/workflows/guardian-ci.yml` — Add OIDC + AppRole auth steps
- `scripts/Install-GuardianDependencies.ps1` — Use `requirements.psd1`

---

## Test Requirements Defined

| Test Type | Coverage |
|-----------|----------|
| **Unit** | Retrieval TTL, cache miss/hit, rotation format, missing secret handling |
| **Integration** | Vault connectivity, AppRole login, OIDC unwrap, dynamic cred rotation |
| **Security** | No secret in logs, audit event per operation, hash chain verification |
| **Failure** | Vault sealed, auth failure burst, network partition, token expiry mid-op |

---

## Timeline & Effort

| Phase | Duration | Effort |
|-------|----------|--------|
| 1. Foundation (Guardian_Secrets module) | 2 days | 2 eng |
| 2. Vault Integration | 3 days | 2 eng |
| 3. KeyVault Support | 2 days | 1 eng |
| 4. Integration & Hardening | 3 days | 2 eng |
| 5. CI/CD Integration | 2 days | 1 eng |
| **Testing & Documentation** | 3 days | 2 eng |
| **Total** | **15 days** | **10 eng-days** |

---

## Approval Request

**Requesting:** Guardian Architecture Review approval to proceed with WQ-002 implementation.

**All review conditions satisfied.** No outstanding design questions.

**Next Step Upon Approval:**
1. Begin Phase 1: Implement `Guardian_Secrets.ps1` module
2. Create `tests/Guardian.Secrets.Tests.ps1` with defined test cases
3. Update `Guardian_Loader.ps1` to include new module
4. Begin Vault integration (Phase 2)

---

**Submitted by:** Guardian Engineering Team  
**Date:** 2026-07-26  
**Checkpoint:** `CK_20260726_134254_4750` (M11 WQ-001 Accepted, WQ-002 Plan Submitted)