# Risk Register — Nexus98 Guardian

**Version:** 1.0.0  
**Date:** 2026-07-26  
**Source:** Architecture Audit  
**Status:** Active — Review Quarterly  

---

## 📋 Risk Scoring

| Score | Likelihood × Impact | Action |
|-------|---------------------|--------|
| 🔴 **Critical** (15-25) | Immediate mitigation required |
| 🟠 **High** (10-14) | Mitigation plan within 30 days |
| 🟡 **Medium** (5-9) | Mitigation plan within 90 days |
| 🟢 **Low** (1-4) | Monitor; document workaround |

---

## 🎯 Risk Register

| ID | Risk | Likelihood | Impact | Score | Status | Mitigation | Owner | Review |
|----|------|------------|--------|-------|--------|------------|-------|--------|
| **RISK-001** | Bridge bypass — Nexus98 modified directly by Guardian | Medium (3) | Critical (5) | **15** 🔴 | **Active** | Governance gate on all writers; `Guardian_DriftGuard` detects unauthorized module changes; audit alert on policy deny | Guardian Team | Monthly |
| **RISK-002** | Checkpoint corruption — restore fails silently | Low (2) | Critical (5) | **10** 🟠 | **Active** | SHA256 manifest verification on every restore; tiered redundancy (4 tiers); test restores in CI (M11) | Guardian Team | Quarterly |
| **RISK-003** | Event store growth unbounded — disk exhaustion | Medium (3) | High (4) | **12** 🟠 | **Active** | Rotation policy (30d retention); size-based compaction; monitoring alert at 80% disk; `Guardian_StorageIntelligence` scans | Guardian Team | Monthly |
| **RISK-004** | Memory store growth unbounded — OOM | Medium (3) | Medium (3) | **9** 🟡 | **Active** | Lifecycle policies (short-term 7d, long-term 365d); compression on dedup; pattern merging; `Guardian_Memory` lifecycle job | Guardian Team | Quarterly |
| **RISK-005** | Pester 6 scope isolation breaks tests | Low (2) | Medium (3) | **6** 🟡 | **Resolved** | Pattern documented: use `$script:` scope in `BeforeAll`; all milestone tests updated; regression test in CI (M11) | Guardian Team | N/A |
| **RISK-006** | Legacy stubs accidentally loaded | Low (2) | Medium (3) | **6** 🟡 | **Mitigated** | Excluded from `Guardian_Loader`; archived in `archive/legacy_stubs/`; architecture baseline detects new modules | Guardian Team | Quarterly |
| **RISK-007** | Snapshot archive (2.1 GB) consumes disk | Medium (3) | Low (2) | **6** 🟡 | **Active** | M9 entropy remediation active; weekly scans; retention policy; archive tier (7yr); monitor `snapshots/` size | Guardian Team | Monthly |
| **RISK-008** | Single point of failure (Guardian process) | High (4) | High (4) | **16** 🔴 | **Planned** | M13: Multi-node with leader election (etcd/Consul); health endpoint for k8s liveness; graceful degradation | Guardian Team | M13 |
| **RISK-009** | Configuration drift undetected | Medium (3) | High (4) | **12** 🟠 | **Active** | `Guardian_Security` monitors config/permission changes; `Guardian_Integrity` scans on schedule; drift detection on load | Guardian Team | Monthly |
| **RISK-010** | AI explanation hallucination (future M14+) | Medium (3) | Medium (3) | **9** 🟡 | **Designed** | Structured output validation (schema); human-in-the-loop for critical decisions; confidence scoring; audit trail | Guardian Team | M14 |
| **RISK-011** | Secrets in config files (no vault) | Medium (3) | Critical (5) | **15** 🔴 | **Planned** | M11: SecretManagement + Vault/Azure Key Vault; never write secrets to disk; audit on access | Guardian Team | M11 |
| **RISK-012** | Bridge message schema drift | Medium (3) | High (4) | **12** 🟠 | **Planned** | M11: JSON Schema generation from contracts; contract testing in CI; versioned schemas | Guardian Team | M11 |
| **RISK-013** | No automated security scanning | Medium (3) | High (4) | **12** 🟠 | **Planned** | M11: CI integration with PSScriptAnalyzer, secret scanning, dependency audit | Guardian Team | M11 |
| **RISK-014** | Remediation action data loss | Low (2) | Critical (5) | **10** 🟠 | **Active** | Dry-run default; manifest-backed rollback; checkpoint before execution; `Guardian_Remediation` verified in M9 | Guardian Team | Monthly |
| **RISK-015** | Knowledge vault drift from code | Medium (3) | Medium (3) | **9** 🟡 | **Active** | Guardian Scribe auto-generates key docs; session checkpoints required; review cadence in standards | Guardian Team | Quarterly |

---

## 📊 Risk Heat Map

```
Impact
  5 │  RISK-001  RISK-011        RISK-002  RISK-014
  4 │            RISK-003  RISK-009  RISK-012  RISK-013
  3 │                    RISK-004  RISK-010  RISK-015
  2 │            RISK-007
  1 │
    └─────────────────────────────────────────
      1      2      3      4      5
            Likelihood
```

---

## 🔄 Risk Review Process

| Cadence | Participants | Artifacts |
|---------|--------------|-----------|
| **Monthly** | Guardian Team | Risk dashboard; metric trends; new risks |
| **Quarterly** | Guardian Team + Architect | Full register review; score recalibration; mitigation effectiveness |
| **Per Milestone** | Session Lead | Session checkpoint includes risk status |

---

## 🔗 Related Documents

- [[Architecture Audit/ARCHITECTURE_AUDIT]] — Source audit
- [[Gap Analysis/GAP_ANALYSIS]] — Gaps driving risks
- [[Technical Debt/DEBT_REGISTER]] — Debt items as risks
- [[Roadmap/ROADMAP]] — Mitigation timeline
- [[Components/GOVERNANCE]] — Policy engine (mitigates RISK-001)
- [[Components/CHECKPOINTS]] — Checkpoint system (mitigates RISK-002, 014)
- [[Components/STORAGE]] — Entropy management (mitigates RISK-003, 007)
- [[ADR/ADR-003]] — Checkpoint pattern

---

*Register Version: 1.0.0 — Update on each risk review.*