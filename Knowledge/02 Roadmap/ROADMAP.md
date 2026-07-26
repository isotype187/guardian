# Nexus98 Guardian — Development Roadmap

**Version:** 1.0.0  
**Status:** **ACTIVE — M0-M10 COMPLETE, M11+ PLANNING**  
**Last Updated:** 2026-07-26  
**Owner:** Guardian Engineering Team  

---

## 📋 Roadmap Overview

This roadmap is **dependency-driven** — each phase builds on verified foundations from prior phases. Milestones are gated by test validation, architecture drift checks, and governance approval.

```
PHASE 0 ────► PHASE 1 ────► PHASE 2 ────► PHASE 3 ────► PHASE 4 ────► PHASE 5 ────► PHASE 6 ────► PHASE 7
 Foundation    Core         Provisioning   Platform       DevX          Automation    Enterprise    Intelligence
 (M0)          (M1-M3)      (M4-M6)        (M3-M5)        (M4+)         (M5+)         (M6+)         (M7+)
   ✅            ✅            ✅             ✅             🔄            🔄             📋            📋
```

**Legend:** ✅ Complete | 🔄 In Progress / Planned | 📋 Designed / Future

---

## 🎯 Phase 0: Vision & Foundation (M0)

**Purpose:** Establish the foundational contract between Guardian and Nexus98, core governance, and operational primitives.

### Goals
- Define Guardian's role, boundaries, and communication contract with Nexus98
- Implement core governance: policy engine, audit trail, risk tiers
- Build checkpoint/rollback system with 4-tier retention
- Create health scoring and integrity monitoring
- Validate with test suite

### Deliverables
| Deliverable | Module | Status |
|-------------|--------|--------|
| Path contract & directory init | `Guardian_Env` | ✅ |
| Module bootstrap loader | `Guardian_Loader` | ✅ |
| Structured message types (bridge) | `Guardian_Contracts` | ✅ |
| Risk tiers + policy decisions | `Guardian_Governance` | ✅ |
| Append-only audit trail | `Guardian_Audit` | ✅ |
| Coverage + health score | `Guardian_Health` | ✅ |
| Rolling checkpoint system (4 tiers) | `Guardian_Checkpoint` | ✅ |
| Drift + storage entropy detection | `Guardian_Integrity` | ✅ |
| Emergency snapshot + rollback levels | `Guardian_Recovery` | ✅ |
| Foundation test suite (14 tests) | `Guardian.Foundation.Tests` | ✅ |

### Dependencies
- PowerShell 7.4+
- Pester 6.x (migrated from v5)

### Risks
- **Broken legacy stubs** — Mitigated: quarantined to `archive/legacy_stubs/`, excluded from loader
- **Snapshot archive entropy (2.1 GB)** — Mitigated: read-only in M0; addressed in M9

### Testing Requirements
- 14 unit/integration tests covering all 9 foundation modules
- All tests pass with Pester 6 syntax (`-Be`, `-Match`, `BeforeAll`)

### Exit Criteria
- ✅ All 14 foundation tests pass
- ✅ Architecture baseline established
- ✅ Milestone checkpoint created
- ✅ Communication contracts defined

### Technical Debt
- None at M0 (greenfield)

---

## 🎯 Phase 1: Core Framework (M1-M3)

### M1: Repository Hygiene & Version Control

**Purpose:** Place Guardian under version control with clean history and operational standards.

| Deliverable | Status |
|-------------|--------|
| `git init` Guardian (vcs/.git worktree) | ✅ |
| Milestone commit discipline | ✅ |
| `.gitignore` tuned for ops (state, logs, snapshots) | ✅ |
| Retire broken legacy stubs from loader | ✅ |
| Document legacy mapping | ✅ |
| Clean `git status`, reproducible import | ✅ |

**Complexity:** Low  
**Duration:** 1 session  
**Exit:** Clean repo, M1 checkpoint

---

### M2: Event Intelligence + Storage Intelligence

**Purpose:** Persistent event store with bus semantics; storage classification, health, and drift detection.

| Deliverable | Module | Tests |
|-------------|--------|-------|
| Structured event model (id, category, severity) | `Guardian_Events` | 8 |
| Event persistence + retrieval + filtering | `Guardian_Events` | 4 |
| Duplicate detection within time window | `Guardian_Events` | 2 |
| Event rotation to archive | `Guardian_Events` | 2 |
| Artifact classification (ACTIVE/OBSOLETE/ARCHIVE/UNKNOWN) | `Guardian_StorageIntelligence` | 4 |
| Storage health score (4 components) | `Guardian_StorageIntelligence` | 2 |
| Nested folder drift detection | `Guardian_StorageIntelligence` | 2 |
| Duplicate content group detection | `Guardian_StorageIntelligence` | 2 |
| Growth baseline capture + comparison | `Guardian_StorageIntelligence` | 2 |

**Dependencies:** M0 (Contracts, Audit, Checkpoint)  
**Complexity:** Medium  
**Duration:** 2-3 sessions  
**Risks:** Event store performance at scale; addressed by rotation + indexing  
**Exit:** 25 tests pass; integrity test on entropy reduction; no silent delete

---

### M3: Memory Intelligence + Observability + Explanation

**Purpose:** Operational memory (short/long/pattern) with lifecycle; unified observability; plain-language explanation engine.

| Deliverable | Module | Tests |
|-------------|--------|-------|
| Memory entry model (category, importance, confidence) | `Guardian_Memory` | 5 |
| Memory persistence + retrieval + search | `Guardian_Memory` | 4 |
| Memory lifecycle (expiration, compression) | `Guardian_Memory` | 3 |
| Pattern recognition from events | `Guardian_Patterns` | 4 |
| Unified observability model (health, storage, memory, checkpoints, events) | `Guardian_Observability` | 4 |
| Health report with components | `Guardian_Health` | 4 |
| Explanation engine (WHAT/WHY/EVIDENCE/IMPACT/REC) | `Guardian_Explanation` | 5 |
| Event→Memory and Storage→Memory flows | Integration | 4 |
| Nexus98 communication contracts (M3) | `Guardian_Contracts` | 4 |

**Dependencies:** M0, M2 (events feed memory)  
**Complexity:** Medium-High  
**Duration:** 3-4 sessions  
**Risks:** Memory growth unbounded; mitigated by lifecycle + compression  
**Exit:** 35 tests pass; Guardian explains a decision in plain language

---

## 🎯 Phase 2: Provisioning Engine (M4-M6)

### M4: Resource Management + Agent Coordination + Security Layer

**Purpose:** Runtime resource telemetry; agent registry/supervision; config/permission change monitoring.

| Deliverable | Module | Tests |
|-------------|--------|-------|
| CPU/memory/disk sampling | `Guardian_Resource` | 4 |
| Runaway detection + anomaly events | `Guardian_Resource` | 3 |
| Agent registry + supervision | `Guardian_Agents` | 3 |
| Config change monitoring | `Guardian_Security` | 3 |
| Permission change monitoring | `Guardian_Security` | 3 |

**Dependencies:** M0, M2, M3 (events, memory, observability)  
**Complexity:** Medium  
**Duration:** 2-3 sessions  
**Exit:** 13 tests pass; anomaly event emitted on runaway resource

---

### M5: Controlled Remediation + Governance Integration

**Purpose:** Safe remediation planning and execution with checkpoint gates; decision→memory integration.

| Deliverable | Module | Tests |
|-------------|--------|-------|
| Remediation plan builder (move-only, dry-run default) | `Guardian_ActionPlanning` | 3 |
| Controlled remediation executor | `Guardian_Remediation` | 3 |
| Manifest-backed rollback | `Guardian_Remediation` | 3 |
| Governance decision → memory integration | `Guardian_GovernanceIntegration` | 2 |

**Dependencies:** M0 (checkpoint, governance), M3 (memory), M4 (resource)  
**Complexity:** High (safety-critical)  
**Duration:** 3-4 sessions  
**Risks:** Destructive actions; mitigated by dry-run default + checkpoint gate + governance  
**Exit:** 11 tests pass; rollback verified; no deletion without manifest

---

### M6: Nexus98 Communication Layer (Runtime Bridge)

**Purpose:** Activate M3 contracts into runtime bridge: persistent outbox/inbox, modulation helpers, intake, risk escalation.

| Deliverable | Module | Tests |
|-------------|--------|-------|
| JSONL outbox/inbox persistence | `Guardian_Comms` | 3 |
| Guardian→Nexus98 modulation helpers | `Guardian_Comms` | 3 |
| Nexus98→Guardian intake + validation | `Guardian_Comms` | 2 |
| Risk escalation for destructive inbound | `Guardian_Comms` | 3 |

**Dependencies:** M0 (contracts), M3 (contracts), M5 (governance)  
**Complexity:** Medium  
**Duration:** 2 sessions  
**Risks:** Bridge bypass; mitigated by schema validation + governance gate  
**Exit:** 11 tests pass; Guardian never modifies Nexus98

---

## 🎯 Phase 3: Platform Support (M3-M5 overlap)

### M3 Platform Foundations (Partial)
- Path abstraction in `Guardian_Env` — ✅ Windows native

### M4 Platform Expansion
- Linux path support in `Guardian_Env` — 🔄
- WSL detection + path translation — 🔄
- Cross-platform resource sampling — 🔄

### M5 Platform Hardening
- Container environment detection — 📋
- macOS path support (future) — 📋
- Platform capability matrix — 📋

**Status:** Windows complete; Linux/WSL partially implemented; container/macOS planned

---

## 🎯 Phase 4: Developer Experience (M4+)

### M7 Self-Development Guard & Drift Gate (Completed in M7)

| Deliverable | Module | Tests |
|-------------|--------|-------|
| Architecture baseline (approved dirs/modules/data/config/generated) | `Guardian_DriftGuard` | 3 |
| Drift detection (6 classes) | `Guardian_DriftGuard` | 5 |
| Change governance chain gate (checkpoint→plan→validate→compare) | `Guardian_DriftGuard` | 2 |
| Six-lock self-modification guard (5 protected surfaces) | `Guardian_DriftGuard` | 3 |
| Storage governance integration (5 lifecycle rules) | `Guardian_DriftGuard` | 4 |

**Dependencies:** M0-M6 complete  
**Complexity:** High (meta-governance)  
**Exit:** 17 tests pass; unsafe self-mod and drift blocked with explanations

---

### M8 Nexus98 Governed Communication Loop

| Deliverable | Module | Tests |
|-------------|--------|-------|
| Local JSONL message bus (inbox/outbox/processing/completed/failed/archive) | `Guardian_Bridge` | 4 |
| Dispatcher with dedup | `Guardian_Bridge` | 3 |
| Security validation (schema/sender/permission) | `Guardian_Bridge` | 3 |
| Governance gating via `Test-GuardianPolicy` | `Guardian_Bridge` | 3 |
| Failure recovery + retry | `Guardian_Bridge` | 2 |
| Observability health score | `Guardian_Bridge` | 2 |
| Event/memory integration | `Guardian_Bridge` | 1 |

**Dependencies:** M6 (contracts), M7 (governance authority)  
**Complexity:** High  
**Exit:** 18 tests pass (scope isolation fix for Pester 6); checkpoint created; bridge disable-safe; no governance bypass

---

### Plugin SDK (M4+ — Future)

| Deliverable | Target |
|-------------|--------|
| Plugin manifest schema | M11 |
| Isolated runspace loading | M11 |
| Extension points (health probes, event handlers, remediation actions, policy packs, bridge transports) | M11 |
| Module templates (`New-GuardianModuleTemplate`) | M11 |
| Documentation generator (`New-GuardianModuleHelp`) | M12 |

---

## 🎯 Phase 5: Automation Layer (M5+)

| Capability | Module | Target |
|------------|--------|--------|
| Scheduling engine (cron/interval/one-shot) | `Guardian_Scheduler` | M11 |
| Remote execution (PSRemoting, SSH, WinRM) | `Guardian_Remote` | M11 |
| Parallel provisioning (ThreadJob, throttle) | `Guardian_Parallel` | M11 |
| Policy engine (JSON rules, approval workflow) | `Guardian_PolicyEngine` | M11 |
| Secrets management (SecretManagement integration) | `Guardian_Secrets` | M11 |

**Dependencies:** M5 (remediation patterns), M4 (resource/agents)  
**Complexity:** High  
**Risks:** Remote execution security; mitigated by JEA, mTLS, audit

---

## 🎯 Phase 6: Enterprise Features (M6+)

| Capability | Module | Target |
|------------|--------|--------|
| Multi-node orchestration | `Guardian_Orchestrator` | M12 |
| Inventory management (CMDB) | `Guardian_Inventory` | M12 |
| Compliance reporting (SOX, HIPAA, PCI) | `Guardian_Compliance` | M13 |
| Audit log enhancements (hash chain, SIEM) | `Guardian_Audit` | M12 |
| RBAC (Operator/Engineer/Admin/Auditor/System) | `Guardian_RBAC` | M12 |
| API service layer (REST/gRPC) | `Guardian_API` | M13 |

**Dependencies:** Phase 5 complete; external state store (etcd/Consul/SQL)  
**Complexity:** Very High  
**Risks:** Distributed consensus; scope creep

---

## 🎯 Phase 7: Advanced Intelligence (M7+)

| Capability | Description | Target |
|------------|-------------|--------|
| AI-assisted troubleshooting | LLM-powered root cause analysis from events + memory | M14 |
| Intelligent dependency resolution | ML-based conflict prediction for module updates | M14 |
| Self-healing deployments | Autonomous remediation within policy bounds | M15 |
| Predictive maintenance | Failure forecasting from pattern + resource trends | M14 |
| Distributed execution | Cross-node task orchestration with consensus | M15 |

**Dependencies:** Phase 6 (data platform); ML infrastructure  
**Complexity:** Research  
**Risks:** Hallucination in explanations; requires human-in-the-loop

---

## 📊 Milestone Summary Table

| ID | Name | Phase | Tests | Status | Completed |
|----|------|-------|-------|--------|-----------|
| M0 | Foundation & Governance Contract | 0 | 14 | ✅ | 2026-07-19 |
| M1 | Repository Hygiene & Version Control | 1 | — | ✅ | 2026-07-20 |
| M2 | Event & Storage Intelligence | 1 | 25 | ✅ | 2026-07-21 |
| M3 | Memory Observability | 1 | 35 | ✅ | 2026-07-22 |
| M4 | Resource/Agent/Security | 2 | 13 | ✅ | 2026-07-23 |
| M5 | Controlled Remediation | 2 | 11 | ✅ | 2026-07-23 |
| M6 | Communication Layer | 2 | 11 | ✅ | 2026-07-24 |
| M7 | Self-Development Guard | 4 | 17 | ✅ | 2026-07-24 |
| M8 | Governed Loop | 4 | 18 | ✅ | 2026-07-25 |
| M9 | Storage Entropy Remediation | 2/5 | 10 | ✅ | 2026-07-25 |
| M10 | Operations | 1-5 | 34 | ✅ | 2026-07-25 |
| **M11** | **Core Hardening + CI/CD** | **1/5** | **TBD** | **📋 PLANNING** | — |
| **M12** | **Plugin SDK + Platform Parity** | **4/3** | **TBD** | **📋 PLANNING** | — |
| **M13** | **Enterprise Foundation** | **6** | **TBD** | **📋 PLANNING** | — |

---

## 🎯 M11+ Immediate Priorities (Next 3 Milestones)

### M11: Core Hardening + CI/CD
**Purpose:** Production-hardening the foundation; automated validation pipeline.

| Goal | Deliverable | Complexity |
|------|-------------|------------|
| Health scoring enhancements | Per-component thresholds, trend detection, alerting | Medium |
| Governance coverage expansion | Policy packs for storage, security, bridge, remediation | Medium |
| CI/CD pipeline | GitHub Actions: syntax → unit → integration → architecture drift → policy | High |
| Contract testing | Bridge message schema validation in CI | Medium |
| Documentation sync | Auto-generate `ARCHITECTURE_MAP.md`, `ROADMAP.md` from code | Low |

**Dependencies:** M10 complete  
**Exit Criteria:** CI passes on every PR; health trends visible; policy coverage > 80%

---

### M12: Plugin SDK + Platform Parity
**Purpose:** Extensibility and cross-platform equivalence.

| Goal | Deliverable | Complexity |
|------|-------------|------------|
| Plugin SDK v1 | Manifest, isolated load, extension points, templates | High |
| Linux full support | Path abstraction, resource sampling, scheduling (systemd) | High |
| WSL first-class | Bridge across Windows/WSL boundary, shared data | Medium |
| Container support | Health endpoint, volume mounts, k8s probe compatibility | Medium |

**Dependencies:** M11 (CI/CD for plugin tests)  
**Exit Criteria:** Plugin example works; Linux test suite parity; container health checks pass

---

### M13: Enterprise Foundation
**Purpose:** Multi-node, compliance, RBAC, API.

| Goal | Deliverable | Complexity |
|------|-------------|------------|
| Multi-node orchestrator | Leader election, fleet health, rolling updates | Very High |
| Inventory/CMDB | Asset discovery, module inventory, checkpoint catalog | High |
| RBAC implementation | Roles, permissions, approval workflows | High |
| API service (REST) | Health, checkpoints, events, remediation, policy eval | High |
| Audit hash chain | Tamper-evident audit log | Medium |

**Dependencies:** M12 (platform parity), external state store decision  
**Exit Criteria:** 3-node cluster demo; compliance report generated; API authenticated

---

## 🔗 Dependency Graph (Critical Path)

```
M0 ──► M1 ──► M2 ──► M3 ──► M4 ──► M5 ──► M6
                    │        │        │
                    │        │        └──► M8 (needs M6 + M7)
                    │        └────────────► M7 (needs M0-M6)
                    └────────────────────► M9 (needs M1, M2, M7, M8)
                                             │
                                             ▼
                                          M10 (integration)
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    ▼                        ▼                        ▼
               M11: CI/CD              M12: SDK/Platform         M13: Enterprise
                    │                        │                        │
                    └────────────────────────┼────────────────────────┘
                                             ▼
                                        M14+: Intelligence
```

---

## ⚠️ Risk Register (Roadmap-Level)

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Pester scope isolation (M8) | High | Medium | ✅ Resolved: pattern documented, applied to all tests |
| Snapshot archive entropy | Medium | High | M9 active; weekly scans; retention policy |
| No CI/CD pipeline | High | High | M11 top priority |
| Platform gaps (Linux/macOS/Container) | Medium | Medium | M12 dedicated; abstraction layer in `Guardian_Env` |
| Secrets management | Medium | High | Phase 5; SecretManagement module integration |
| Distributed consensus (M13) | Low | Very High | Evaluate etcd/Consul/SQL; spike in M12 |
| AI hallucination in explanations | Medium | Medium | Human-in-the-loop; structured output validation |

---

## 📈 Technical Debt Register (Roadmap-Level)

| Debt | Origin | Phase to Address | Effort |
|------|--------|------------------|--------|
| Legacy stubs in archive | Pre-M0 | M1 (done — quarantined) | — |
| Pester v5 → v6 migration | M1-M8 | M1-M8 (done per-milestone) | — |
| Hash-chained audit log | M0 | M13 | Medium |
| Hot module reload | M1 | M14+ | High |
| JSON Schema for contracts | M0 | M11 | Low |
| Module manifest (`Guardian_Manifest.psd1`) | M1 | M11 | Low |
| Cross-platform path abstraction | M3 | M12 | Medium |

---

## 🔗 Related Documents

- [[Vision/VISION]] — Mission, principles, success metrics
- [[Architecture/OVERVIEW]] — System architecture
- [[Components/PROVISIONING]] — Provisioning engine design
- [[Components/AUTOMATION]] — Automation layer design
- [[Components/ENTERPRISE]] — Enterprise features design
- [[Future Ideas/AI_ASSISTED]] — Intelligence research
- [[ADR/ADR-001]] — Separation of concerns
- [[ADR/ADR-002]] — Pester 6 migration
- [[ADR/ADR-003]] — Checkpoint-before-change pattern

---

*Roadmap is a living document. Updates require ADR for architectural changes; milestone status auto-synced by Guardian Scribe.*