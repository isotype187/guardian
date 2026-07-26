# Remaining Work Queue

> **Prioritized backlog of all remaining work for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Reference
> **Scope:** Project
> **Tags:** reference, backlog, queue, planning
> **Related:** [[ROADMAP]], [[ROADMAP_MANAGEMENT]], [[GAP_ANALYSIS]], [[DEBT_REGISTER]], [[RISK_REGISTER]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 🎯 Queue Overview

| Priority | Count | Description |
|----------|-------|-------------|
| **P0 (Critical)** | 4 | Blockers for scaling, security, automation |
| **P1 (High)** | 8 | Core capabilities for M11-M13 |
| **P2 (Medium)** | 12 | Platform parity, SDK, operations |
| **P3 (Low)** | 8 | Intelligence, optimization, polish |
| **TOTAL** | **32** | |

---

## 🔴 P0 — Critical (Do First)

| ID | Title | Phase | Milestone | Effort | Dependencies | Description |
|----|-------|-------|-----------|--------|--------------|-------------|
| **WQ-001** | CI/CD Pipeline (GitHub Actions) | 1/5 | M11 | High | — | ✅ **COMPLETE** - Pipeline live, all gates passing |
| **WQ-002** | Secrets Management (SecretManagement + Vault) | 1/5 | M11 | High | WQ-001 | 🟢 **READY_FOR_GUARDIAN_REVIEW** - Azure Key Vault / HashiCorp Vault integration; never write secrets to disk |
| **WQ-003** | JSON Schema Contract Testing | 1/5 | M11 | Medium | WQ-001 | Generate schemas from `Guardian_Contracts`; validate all bridge messages in CI |
| **WQ-004** | Structured Logging Framework | 1/5 | M11 | Medium | — | Serilog-style structured logs; correlation IDs; log levels; JSON output |

---

## 🟠 P1 — High (M11-M13 Core)

| ID | Title | Phase | Milestone | Effort | Dependencies | Description |
|----|-------|-------|-----------|--------|--------------|-------------|
| **WQ-005** | Performance Benchmark Suite | 1/5 | M11 | Medium | WQ-001 | `Invoke-GuardianBenchmarks`; baseline storage; regression gate (10%) |
| **WQ-006** | Module Manifest (`Guardian_Manifest.psd1`) | 1 | M11 | Low | — | Version, dependencies, exports, category, criticality for Loader |
| **WQ-006** | Circular Dependency Detection in Loader | 1 | M11 | Low | WQ-006 | DAG validation on load; fail fast |
| **WQ-008** | Hardcoded Path Audit & Remediation | 1-5 | M11-M12 | Medium | — | Scan all modules; replace with `$GuardianEnv` contracts |
| **WQ-009** | Plugin SDK v1 (Manifest, Isolated Runspace, Permissions) | 4 | M12 | High | WQ-006, WQ-010 | `New-GuardianPluginTemplate`; extension points; sandbox |
| **WQ-010** | Platform Abstraction Layer (`Guardian_Platform`) | 3 | M12 | High | — | Path translation, process mgmt, scheduling, FS ops for Win/Linux/WSL/Container |
| **WQ-011** | Linux/WSL Full Parity | 3 | M12 | High | WQ-010 | systemd timers, `/proc` sampling, cross-boundary bridge |
| **WQ-012** | Container Support (Health endpoint, volumes, k8s probes) | 3 | M12 | Medium | WQ-010 | `Get-GuardianHealthReport` as HTTP endpoint; config via env |

---

## 🟡 P2 — Medium (M12-M13 Platform/Enterprise)

| ID | Title | Phase | Milestone | Effort | Dependencies | Description |
|----|-------|-------|-----------|--------|--------------|-------------|
| **WQ-013** | Decompose `Guardian_Operations` Monolith | 1/5 | M12 | High | — | Split into: Orchestration, Scheduling, Reporting, Maintenance |
| **WQ-014** | Pluggable Bridge Transport Interface | 2/5 | M12 | High | — | JSONL → HTTP/gRPC/MQTT; factory pattern; config-driven |
| **WQ-015** | REST/gRPC API Service Layer | 6 | M13 | Very High | WQ-002, WQ-018 | AuthZ, rate limiting, OpenAPI, health, checkpoints, events, remediation, policy eval |
| **WQ-016** | Multi-Node Orchestration (Leader election, fleet health, rolling updates) | 6 | M13 | Very High | WQ-015, WQ-017 | etcd/Consul/SQL backend; RAFT; distributed checkpoint catalog |
| **WQ-017** | Inventory/CMDB (Assets, modules, checkpoints, policies) | 6 | M13 | High | WQ-015 | Discovery, reconciliation, drift detection at fleet level |
| **WQ-018** | RBAC Implementation (Operator/Engineer/Admin/Auditor/System) | 6 | M13 | High | WQ-002, WQ-015 | Claims-based; AD/OIDC/GitHub integration; approval workflows |
| **WQ-019** | Audit Hash Chaining + Anchoring | 6 | M13 | Medium | — | SHA256 chain per entry; periodic git commit anchor; `Test-GuardianAuditIntegrity` |
| **WQ-020** | Compliance Reporting Templates (SOX, PCI, HIPAA) | 6 | M13 | Medium | WQ-019 | Evidence packages; policy decision logs; access reviews |
| **WQ-021** | Container Health Probes (Liveness/Readiness/Startup) | 3 | M12 | Low | WQ-010 | k8s `livenessProbe`, `readinessProbe`, `startupProbe` endpoints |

---

## 🟢 P3 — Low (M14+ Intelligence & Polish)

| ID | Title | Phase | Milestone | Effort | Dependencies | Description |
|----|-------|-------|-----------|--------|--------------|-------------|
| **WQ-022** | Hot Module Reload (Zero-downtime updates) | 1 | M14+ | Very High | WQ-006 | Versioned modules; state migration; graceful swap |
| **WQ-023** | macOS Full Support | 3 | M14+ | High | WQ-010 | Launchd, paths, code signing, notarization |
| **WQ-024** | AI-Assisted Troubleshooting | 7 | M14+ | Very High | WQ-015, WQ-028 | LLM root cause from events+memory+patterns; confidence scoring |
| **WQ-025** | Predictive Maintenance (Failure forecasting) | 7 | M14+ | Very High | WQ-005, WQ-028 | ML on resource trends + patterns + entropy |
| **WQ-026** | Self-Healing Policies (Autonomous remediation within bounds) | 7 | M15+ | Very High | WQ-015, WQ-024 | Policy: "if storage < 60% and entropy > threshold → auto-remediate" |
| **WQ-027** | Intelligent Dependency Resolution (ML conflict prediction) | 7 | M14+ | Very High | WQ-006, WQ-028 | Predict module update conflicts from history |
| **WQ-028** | Distributed Execution (Cross-node task orchestration) | 7 | M15+ | Very High | WQ-016, WQ-024 | Consensus-based task distribution; idempotency |
| **WQ-029** | Visual Architecture Diagram Generator | 1 | M14+ | Medium | WQ-006 | Auto-generate `ARCHITECTURE_DIAGRAM.drawio` from Loader DAG |

---

## 📋 Work Item Template

```markdown
# WQ-XXX: [Title]

**Priority:** P0|P1|P2|P3
**Phase:** 0-7
**Target Milestone:** M11-M18
**Effort:** Low|Medium|High|Very High
**Owner:** [Name]
**Status:** Not Started|In Progress|Blocked|Done

## Description
[What, why, success criteria]

## Dependencies
- WQ-XXX

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Notes
[Architecture, APIs, data models]

## Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Contract tests
- [ ] Performance baseline

## Documentation
- [ ] Architecture doc
- [ ] Module spec
- [ ] Runbook
- [ ] ADR (if architectural)

## Related
- [[ADR-XXX]]
- [[FEATURE_XXX]]
- [[ROADMAP]]
```

---

## 📊 Queue Visualization

```
P0: ████████████████████████████ 4 items (12%)
P1: ████████████████████████████████████ 8 items (25%)
P2: ████████████████████████████████████████████ 12 items (38%)
P3: ████████████████████████ 8 items (25%)
```

---

## 🔄 Queue Management Rules

| Rule | Enforcement |
|------|-------------|
| **WIP Limit** | Max 3 P0/P1 items in progress per engineer |
| **Blocker Escalation** | P0 blocked > 4h → Team lead; P1 blocked > 1 day → Architect |
| **Reprioritization** | Weekly at sprint planning; emergency re-prio by Architect |
| **Definition of Ready** | Spec complete, deps resolved, tests defined, docs planned |
| **Definition of Done** | Code + tests + docs + CI pass + architecture clean + ADR if needed |

---

## 📅 Suggested Sprint Allocation (M11-M13)

| Sprint | Focus | Target |
|--------|-------|--------|
| Sprint 1 (Week 1) | WQ-001, WQ-002, WQ-006, WQ-006 | CI/CD, Secrets, Manifest, Circular dep |
| Sprint 2 (Week 2) | WQ-003, WQ-004, WQ-005, WQ-008 | Contracts, Logging, Benchmarks, Path audit |
| Sprint 3 (Week 3) | WQ-009, WQ-010, WQ-011, WQ-012 | Plugin SDK, Platform layer, Linux, Container |
| Sprint 4 (Week 4) | WQ-013, WQ-014, WQ-021 | Decompose Operations, Bridge transport, Container probes |
| Sprint 5-6 | WQ-015, WQ-017, WQ-019, WQ-020 | API, Inventory, Audit chain, Compliance |
| Sprint 7-8 | WQ-016, WQ-018 | Multi-node, RBAC |

---

*Queue is living. Update at every sprint planning and milestone retrospective.*