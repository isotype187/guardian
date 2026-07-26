# Nexus98 Guardian — Master Project Index

> **Project Status:** Active — M10 Operations Complete
> **Last Updated:** 2026-07-26
> **Current Phase:** Post-M10 / Pre-M11 (Roadmap Planning)
> **Document Version:** 1.0.0

---

## 📋 Project Overview

**Nexus98 Guardian** is the operational supervisory intelligence layer for the Nexus98 ecosystem. It observes, evaluates, protects, and recovers the Nexus98 creation engine without ever becoming the system it protects.

### Core Principle
> **Guardian observes. Nexus98 creates. They are separate but cooperative.**

### Repository Identity
- **Root:** `D:\Nexus98_Guardian`
- **Git Worktree:** `vcs/.git` (core.worktree → project root)
- **Primary Branch:** `main`
- **Language:** PowerShell 7+ (cross-platform)

---

## 🏗️ Current Architecture Snapshot

### Module Inventory (33 Core Modules)

| Module | Category | Status | Lines | Tests |
|--------|----------|--------|-------|-------|
| `Guardian_Env.ps1` | Foundation | ✅ Active | ~170 | — |
| `Guardian_Loader.ps1` | Foundation | ✅ Active | ~85 | — |
| `Guardian_Contracts.ps1` | Foundation | ✅ Active | ~216 | — |
| `Guardian_Governance.ps1` | Foundation | ✅ Active | ~58 | — |
| `Guardian_Audit.ps1` | Foundation | ✅ Active | ~40 | — |
| `Guardian_Health.ps1` | Foundation | ✅ Active | ~61 | — |
| `Guardian_Checkpoint.ps1` | Foundation | ✅ Active | ~120 | — |
| `Guardian_Integrity.ps1` | Foundation | ✅ Active | ~80 | — |
| `Guardian_Recovery.ps1` | Foundation | ✅ Active | ~45 | — |
| `Guardian_Events.ps1` | M2 | ✅ Active | ~150 | 15 |
| `Guardian_StorageIntelligence.ps1` | M2 | ✅ Active | ~200 | — |
| `Guardian_Memory.ps1` | M3 | ✅ Active | ~180 | — |
| `Guardian_Patterns.ps1` | M3 | ✅ Active | ~100 | — |
| `Guardian_Observability.ps1` | M3 | ✅ Active | ~90 | — |
| `Guardian_Explanation.ps1` | M3 | ✅ Active | ~85 | — |
| `Guardian_Resource.ps1` | M4 | ✅ Active | ~120 | — |
| `Guardian_Agents.ps1` | M4 | ✅ Active | ~100 | — |
| `Guardian_Security.ps1` | M4 | ✅ Active | ~110 | — |
| `Guardian_ActionPlanning.ps1` | M5 | ✅ Active | ~110 | — |
| `Guardian_Remediation.ps1` | M5 | ✅ Active | ~120 | — |
| `Guardian_GovernanceIntegration.ps1` | M5 | ✅ Active | ~80 | — |
| `Guardian_Comms.ps1` | M6 | ✅ Active | ~200 | — |
| `Guardian_DriftGuard.ps1` | M7 | ✅ Active | ~700 | 17 |
| `Guardian_Bridge.ps1` | M8 | ✅ Active | ~700 | 15 |
| `Guardian_StorageRules.ps1` | M1 | ✅ Active | ~70 | — |
| `Guardian_EntropyRemediation.ps1` | M9 | ✅ Active | ~450 | 10 |
| `Guardian_Operations.ps1` | M10 | ✅ Active | ~1200 | 34 |
| `Nexus98_Scribe*.ps1` (7) | Docs | ✅ Active | ~6500 total | — |

### Data Architecture
```
$GuardianEnv.Root
├── config/                    # Runtime state (git-ignored)
├── data/
│   ├── checkpoints/           # 4-tier: rolling/milestones/emergency/archive
│   ├── events/                # JSONL event store
│   ├── memory/                # Short/long/pattern memory
│   ├── ops/                   # Operational state
│   └── remediation/           # Quarantine + manifests
├── logs/
│   └── guardian_audit.jsonl   # Append-only audit trail
├── snapshots/                 # Legacy archive (2.1 GB, 3,411 files)
│   └── communication/         # M8 governed message bus
├── plugins/                   # Future: plugin SDK
├── scripts/                   # Operational scripts
└── tests/                     # Pester v6 test suites
```

---

## ✅ Milestone Status (M0–M10 Complete)

| Milestone | Description | Tests | Status |
|-----------|-------------|-------|--------|
| **M0** | Foundation & Governance Contract | 14 | ✅ COMPLETE |
| **M1** | Repository Hygiene & Version Control | — | ✅ COMPLETE |
| **M2** | Event & Storage Intelligence | 15 | ✅ COMPLETE |
| **M3** | Memory Observability | 21 | ✅ COMPLETE |
| **M4** | Resource/Agent/Security | 13 | ✅ COMPLETE |
| **M5** | Controlled Remediation | 11 | ✅ COMPLETE |
| **M6** | Communication Layer | 11 | ✅ COMPLETE |
| **M7** | Self-Development Guard | 12 (6 pre-existing) | ✅ COMPLETE |
| **M8** | Nexus98 Governed Loop | 15 | ✅ COMPLETE |
| **M9** | Storage Entropy Remediation | 10 | ✅ COMPLETE |
| **M10** | Operations | 34 | ✅ COMPLETE |

**Total Validated Tests: 161+ (155 passing, 6 pre-existing M7 failures)**

---

## 🎯 Current Development Priorities

### Immediate (M11)
- [x] **CI/CD Pipeline** — GitHub Actions: syntax → unit → integration → arch drift → policy → contracts → docs
- [ ] **Secrets Management** — Microsoft.PowerShell.SecretManagement + Vault/Azure Key Vault [📋 DESIGN COMPLETE — SUBMITTED FOR APPROVAL]
- [ ] **Contract Testing** — JSON Schema generation from `Guardian_Contracts`, bridge message validation
- [ ] **Structured Logging** — Serilog-style structured logging framework
- [ ] **Performance Baselines** — Benchmark suite for checkpoint, event, storage, policy operations

### Near Term (M12)
- [ ] **Plugin SDK** — Manifest, isolated load, extension points, templates
- [ ] **Linux/WSL Full Support** — Path abstraction, systemd timers, cross-boundary bridge
- [ ] **Container Support** — Health endpoint, volume mounts, k8s probes
- [ ] **Decompose `Guardian_Operations`** — Split orchestration, scheduling, reporting

### Medium-term (M13)
- [ ] **API Service Layer** — REST/gRPC with authZ, health, checkpoints, events, remediation, policy
- [ ] **Multi-node Orchestration** — Leader election, fleet health, rolling updates
- [ ] **RBAC Implementation** — Roles, permissions, approval workflows
- [ ] **Audit Hash Chaining** — Tamper-evident audit log
- [ ] **Compliance Reporting** — SOX/PCI/HIPAA report templates

---

## 🔗 Key Documentation Links

| Document | Path | Purpose |
|----------|------|---------|
| **Engineering Specification** | `docs/GUARDIAN_ENGINEERING_SPEC.md` | Authoritative technical reference |
| **Architecture Map** | `docs/ARCHITECTURE_MAP.md` | Current module topology |
| **Capability Report** | `docs/CAPABILITY_REPORT.md` | Gap analysis + milestone history |
| **Roadmap (Auto-generated)** | `docs/ROADMAP.md` | Milestone status |
| **Operating Rules** | `HERMES.md` | Agent operating policies |
| **Knowledge Vault** | `Knowledge/INDEX.md` | Obsidian knowledge graph |

---

## ⚠️ Active Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| No CI/CD pipeline | 🔴 Critical | M11 top priority |
| Secrets in plaintext config | 🔴 Critical | M11: SecretManagement integration |
| Single-node architecture | 🟠 High | M13: Multi-node orchestration |
| No RBAC | 🟠 High | M13: Role-based access |
| Bridge transport hardcoded to JSONL | 🟡 Medium | M12: Pluggable transport interface |
| Audit log not tamper-evident | 🟡 Medium | M13: Hash chaining |
| Linux/WSL parity incomplete | 🟡 Medium | M12: Platform abstraction module |

---

## 📦 Technical Debt Register (Top 10)

| ID | Debt | Origin | Effort | Target |
|----|------|--------|--------|--------|
| DEBT-001 | No module manifest (`Guardian_Manifest.psd1`) | M1 | Low | M11 |
| DEBT-002 | No JSON Schema for contracts | M0 | Medium | M11 |
| DEBT-003 | Hardcoded paths in some modules | M0–M10 | Medium | M12 |
| DEBT-004 | No circular dependency detection in Loader | M1 | Low | M12 |
| DEBT-005 | No hot module reload | M1 | High | M14+ |
| DEBT-006 | Bridge transport hardcoded to JSONL files | M6 | Medium | M12 |
| DEBT-007 | `Guardian_Operations` monolithic (37K lines) | M10 | High | M12 |
| DEBT-007 | No structured logging framework | M10 | Medium | M11 |
| DEBT-008 | Health weights hardcoded | M0 | Low | M11 |
| DEBT-009 | Duplicate test fixtures across milestone tests | M2–M10 | Medium | M11 |

---

## 🤖 AI Collaboration Context

This project uses **Hermes Agent** with:
- **Operating Rules:** `HERMES.md`
- **Guardian-specific Rules:** `GUARDIAN_OPERATING_RULES.md`
- **Skills Loaded:** `hermes-agent`, `github-*`, `systematic-debugging`, `plan`
- **Knowledge Persistence:** `Knowledge/` vault (Obsidian-compatible)

### Recent Sessions
- `Knowledge/Sessions/M1_COMPLETION_20260725.md` — M1 repo hygiene
- `Knowledge/Sessions/M8_BRIDGE_VALIDATION_20260725.md` — M8 Pester v6 scope fix
- `Knowledge/Sessions/M9_M10_VALIDATION_20260725.md` — M9/M10 validation

---

## 🚀 Quick Start Commands

```powershell
# Load Guardian modules
. .\core\Guardian_Loader.ps1
Import-Guardian

# Run foundation tests
.\tests\run_foundation_tests.ps1

# Health check
Get-GuardianHealthReport

# Check architecture drift
Test-GuardianArchitectureDrift

# Bridge status
Get-GuardianBridgeStatus

# Storage entropy scan
Get-GuardianStorageEntropy
```

---

## 📂 Vault Navigation

```
Knowledge/
├── 00 Dashboard/           # DASHBOARD.md — System status
├── 01 Vision/              # VISION.md — Mission, principles, metrics
├── 02 Roadmap/             # ROADMAP.md — Phased M0–M13+ plan
├── 03 Architecture/        # OVERVIEW.md — System architecture
├── 04 ADR/                 # Architecture Decision Records
├── 05 Components/          # Component specs
├── 06 Modules/             # Module specs
├── 07 Features/            # Feature specs
├── 08 Research/            # Research notes
├── 09 Standards/           # Documentation, testing, coding standards
├── 10 Security/            # Threat model, RBAC, secrets
├── 11 Testing/             # Test strategy, fixtures
├── 12 CI-CD/               # Pipeline design
├── 13 Deployment/          # Install, config, upgrade guides
├── 14 Operations/          # Runbooks, monitoring
├── 15 Troubleshooting/     # Common issues, debugging
├── 16 Technical Debt/      # Audit, gaps, debt register
├── 17 Risks/               # Risk register
├── 18 Backlog/             # Prioritized work items
├── 19 Future Ideas/        # Innovation research
├── 20 Releases/            # Release notes, changelog
├── 21 Meetings/            # Session checkpoints
├── 22 Reference/           # CLI, function, config, event refs
├── 23 Glossary/            # Terminology
├── 24 Templates/           # Document templates (10 types)
├── 25 Attachments/         # Diagrams, exports
└── 99 Archive/             # Superseded content
```

---

*This index is the front door to the project. Update on every milestone.*