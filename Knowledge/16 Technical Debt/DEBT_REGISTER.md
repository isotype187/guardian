# Technical Debt Register — Nexus98 Guardian

**Version:** 1.0.0  
**Date:** 2026-07-26  
**Source:** Architecture Audit  
**Status:** Active — Review Per Milestone  

---

## 📋 Debt Scoring

| Score | Effort × Interest | Action |
|-------|-------------------|--------|
| 🔴 **Critical** | Pay down immediately |
| 🟠 **High** | Schedule in next 2 milestones |
| 🟡 **Medium** | Schedule in next 4 milestones |
| 🟢 **Low** | Track; pay down opportunistically |

---

## 🎯 Debt Register

| ID | Debt Item | Origin | Category | Effort | Interest | Score | Status | Target | Owner |
|----|-----------|--------|----------|--------|----------|-------|--------|--------|-------|
| **DEBT-001** | Legacy stubs in `archive/legacy_stubs/` (26 files) | Pre-M0 | Dead Code | Low | Low | 🟢 | **Quarantined** | M1 (Done) | — |
| **DEBT-002** | Pester v5 → v6 syntax migration | M1-M8 | Test Infrastructure | Medium | High | 🟢 | **Complete** | M1-M8 (Done) | — |
| **DEBT-003** | No module manifest (`Guardian_Manifest.psd1`) | M1 | Infrastructure | Low | Medium | 🟢 | **Planned** | M11 | Guardian Team |
| **DEBT-004** | Hard-coded paths in modules | M0-M10 | Portability | Medium | High | 🟡 | **In Progress** | M12 | Guardian Team |
| **DEBT-005** | No JSON Schema for contracts | M0 | Interoperability | Medium | High | 🟠 | **Planned** | M11 | Guardian Team |
| **DEBT-006** | No CI/CD pipeline | M10 | Automation | High | Critical | 🔴 | **Planned** | M11 | Guardian Team |
| **DEBT-007** | No secrets management | M0 | Security | High | Critical | 🔴 | **Planned** | M11 | Guardian Team |
| **DEBT-008** | No hot module reload | M1 | Developer Experience | High | Medium | 🟢 | **Planned** | M14+ | Guardian Team |
| **DEBT-009** | Linux/WSL path abstraction incomplete | M3 | Platform | High | High | 🟠 | **In Progress** | M12 | Guardian Team |
| **DEBT-010** | No contract testing (bridge) | M6 | Testing | Medium | High | 🟠 | **Planned** | M11 | Guardian Team |
| **DEBT-011** | No performance baselines | M10 | Observability | Medium | Medium | 🟡 | **Planned** | M11 | Guardian Team |
| **DEBT-012** | Audit log not hash-chained | M0 | Security | Medium | High | 🟡 | **Planned** | M13 | Guardian Team |
| **DEBT-013** | No RBAC implementation | M6 | Security | High | High | 🟠 | **Planned** | M13 | Guardian Team |
| **DEBT-014** | No API service layer | M6 | Enterprise | High | High | 🟠 | **Planned** | M13 | Guardian Team |
| **DEBT-015** | No structured logging framework | M10 | Observability | Medium | Medium | 🟡 | **Planned** | M11 | Guardian Team |
| **DEBT-016** | Circular dependency detection missing | M1 | Infrastructure | Low | Medium | 🟢 | **Planned** | M12 | Guardian Team |
| **DEBT-017** | No shared test fixtures | M2 | Testing | Medium | Medium | 🟡 | **Planned** | M11 | Guardian Team |
| **DEBT-018** | macOS support not implemented | M3 | Platform | High | Low | 🟢 | **Planned** | M14+ | Guardian Team |
| **DEBT-019** | Container health probes missing | M5 | Platform | Low | Medium | 🟢 | **Planned** | M12 | Guardian Team |
| **DEBT-020** | Prometheus metrics export missing | M10 | Observability | Medium | Medium | 🟡 | **Planned** | M13 | Guardian Team |

---

## 📊 Debt by Category

| Category | Count | Critical | High | Medium | Low |
|----------|-------|----------|------|--------|-----|
| Infrastructure | 4 | 0 | 1 | 1 | 2 |
| Security | 3 | 0 | 2 | 1 | 0 |
| Testing | 2 | 0 | 0 | 2 | 0 |
| Observability | 3 | 0 | 0 | 3 | 0 |
| Platform | 4 | 0 | 1 | 1 | 2 |
| Automation | 1 | 0 | 1 | 0 | 0 |
| Enterprise | 1 | 0 | 1 | 0 | 0 |
| Developer Experience | 1 | 0 | 0 | 0 | 1 |
| **Total** | **20** | **0** | **6** | **8** | **6** |

---

## 📈 Debt Trend

```
Milestone:  M0  M1  M2  M3  M4  M5  M6  M7  M8  M9  M10 M11 M12 M13
Critical:   0   0   0   0   0   0   0   0   0   0   0   0   0   0
High:       0   0   0   1   1   2   2   3   3   3   3   6   5   4
Medium:     0   0   2   2   3   4   4   5   5   5   5   8   7   6
Low:        1   0   0   1   1   1   1   1   1   1   1   6   5   5
```

---

## 💰 Paydown Plan

### M11: Core Hardening (Target: 6 items)
- DEBT-003: Module manifest
- DEBT-005: JSON Schema for contracts
- DEBT-006: CI/CD pipeline
- DEBT-007: Secrets management
- DEBT-010: Contract testing
- DEBT-011: Performance baselines
- DEBT-015: Structured logging
- DEBT-016: Circular dependency detection
- DEBT-017: Shared test fixtures
- DEBT-018: Hard-coded paths audit

### M12: SDK + Platform (Target: 5 items)
- DEBT-004: Hard-coded paths (complete)
- DEBT-009: Linux/WSL abstraction (complete)
- DEBT-016: Circular dependency detection
- DEBT-019: Container health probes
- DEBT-008: Hot reload (design only)

### M13: Enterprise Foundation (Target: 5 items)
- DEBT-012: Audit hash chain
- DEBT-013: RBAC implementation
- DEBT-014: API service layer
- DEBT-020: Prometheus metrics
- DEBT-011: Performance baselines (historical tracking)

### M14+: Advanced (Target: 2 items)
- DEBT-008: Hot module reload
- DEBT-018: macOS support

---

## 🔗 Related Documents

- [[Architecture Audit/ARCHITECTURE_AUDIT]] — Source audit
- [[Gap Analysis/GAP_ANALYSIS]] — Gaps driving debt
- [[Risks/RISK_REGISTER]] — Risks from debt
- [[Roadmap/ROADMAP]] — Paydown timeline
- [[ADR/ADR-004]] — Platform abstraction (DEBT-004, 009)
- [[ADR/ADR-005]] — Secrets management (DEBT-007)

---

*Register Version: 1.0.0 — Update on each debt paydown or new discovery.*