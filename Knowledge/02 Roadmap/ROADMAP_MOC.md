# Roadmap MOC (Map of Content)

> **Navigation hub for phased development roadmap, milestones, and feature tracking.**

---

## 🗺️ Phase Overview

| Phase | Theme | Milestones | Status |
|-------|-------|------------|--------|
| **Phase 0** | Vision & Foundation | M0 | ✅ Complete |
| **Phase 1** | Core Framework | M1–M3 | ✅ Complete |
| **Phase 2** | Provisioning Engine | M4–M6 | ✅ Complete |
| **Phase 3** | Platform Expansion | M3–M5 overlap | 🟡 Partial |
| **Phase 4** | Developer Experience | M7–M8 | ✅ Complete |
| **Phase 5** | Automation Layer | M9–M10 | ✅ Complete |
| **Phase 6** | Enterprise Capabilities | M11–M13 | 📋 Planned |
| **Phase 7** | Advanced Intelligence | M14+ | 📋 Research |

---

## ✅ Completed Milestones (M0–M10)

| Milestone | Focus | Tests | Key Deliverables |
|-----------|-------|-------|------------------|
| **M0** | Foundation & Governance | 14 | Env, Loader, Contracts, Governance, Audit, Health, Checkpoint, Integrity, Recovery |
| **M1** | Repo Hygiene & Version Control | — | Git init, milestone commits, legacy quarantine, .gitignore |
| **M2** | Event & Storage Intelligence | 25 | Event store+bus, classification, health, drift, duplicates, growth |
| **M3** | Memory Observability | 35 | Short/long/pattern memory, lifecycle, patterns, observability, explanation |
| **M4** | Resource/Agent/Security | 28 | CPU/mem/disk sampling, agent registry, config/permission monitoring |
| **M5** | Controlled Remediation | 22 | Plan builder, executor, manifest rollback, governance integration |
| **M6** | Communication Layer | 11 | JSONL outbox/inbox, modulation, intake, risk escalation |
| **M7** | Self-Development Guard | 17 | Architecture baseline, 6-class drift, change governance, 6-lock self-mod |
| **M8** | Governed Bridge Loop | 18 | JSONL bus, dispatcher, security, governance, retry, health, integration |
| **M9** | Storage Entropy Remediation | 10 | Entropy analysis, move-only plans, dry-run, checkpoint-gated execution |
| **M10** | Operations Integration | 34 | Full orchestration, scheduling, reporting, cross-cutting concerns |

**Total Tests: 214+**

---

## 📋 Planned Milestones (M11+)

### M11: Core Hardening + CI/CD (Immediate)
| Goal | Deliverable | Effort |
|------|-------------|--------|
| CI/CD Pipeline | GitHub Actions: syntax → unit → integration → arch drift → policy | High |
| Secrets Management | SecretManagement + Vault/Azure Key Vault | High |
| Contract Testing | JSON Schema from contracts, bridge validation in CI | Medium |
| Structured Logging | Serilog-style framework, correlation IDs | Medium |
| Performance Baselines | Benchmark suite + regression detection | Medium |

### M12: Plugin SDK + Platform Parity (Near-term)
| Goal | Deliverable | Effort |
|------|-------------|--------|
| Plugin SDK v1 | Manifest, isolated runspace, extension points, templates | High |
| Linux/WSL Full Support | Path abstraction, systemd timers, cross-boundary bridge | High |
| Container Support | Health endpoint, volume mounts, k8s probes | Medium |
| Decompose Guardian_Operations | Split orchestration, scheduling, reporting | High |

### M13: Enterprise Foundation (Medium-term)
| Goal | Deliverable | Effort |
|------|-------------|--------|
| API Service Layer | REST/gRPC + authZ, health, checkpoints, events, remediation, policy | Very High |
| Multi-node Orchestration | Leader election, fleet health, rolling updates | Very High |
| RBAC Implementation | Operator/Engineer/Admin/Auditor/System roles | High |
| Audit Hash Chaining | Tamper-evident audit log | Medium |
| Compliance Reporting | SOX/PCI/HIPAA templates | Medium |

---

## 🔗 Feature Tracking

### Feature Statuses
- **Idea** → **Researching** → **Planned** → **In Development** → **Testing** → **Released** → **Deprecated**

### Active Features
| Feature | Status | Milestone | Owner | Docs |
|---------|--------|-----------|-------|------|
| CI/CD Pipeline | Planned | M11 | — | [[CI_CD_PIPELINE]] |
| Secrets Management | Planned | M11 | — | [[SECRETS_MANAGEMENT]] |
| JSON Schema Contracts | Planned | M11 | — | [[CONTRACT_TESTING]] |
| Plugin SDK | Planned | M12 | — | [[PLUGIN_SDK]] |
| Linux Support | Partial | M12 | — | [[PLATFORM_ABSTRACTION]] |
| REST API | Planned | M13 | — | [[API_SERVICE]] |
| Multi-node | Planned | M13 | — | [[MULTI_NODE]] |
| RBAC | Planned | M13 | — | [[RBAC_MODEL]] |

---

## 📊 Dependency Graph

```
M0 ──► M1 ──► M2 ──► M3 ──► M4 ──► M5 ──► M6
                    │        │        │
                    │        │        └──► M8 (needs M6 + M7)
                    │        └────────────► M7 (needs M0–M6)
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

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[ARCHITECTURE_MOC]] — Architecture dependencies
- [[DEVELOPMENT_MOC]] — Dev workflow for milestones
- [[TESTING_MOC]] — Test gates per milestone
- [[RELEASE_MOC]] — Release management per milestone
- [[RESEARCH_MOC]] — Research feeding milestones

---

*Roadmap is a living document. Update at every milestone.*