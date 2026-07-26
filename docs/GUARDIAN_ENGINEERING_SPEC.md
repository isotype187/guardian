# Nexus98 Guardian — Engineering Specification

**Document Version:** 1.0.0  
**Status:** Production-Ready Reference  
**Classification:** Internal — Engineering Reference  
**Last Updated:** 2026-07-26  
**Maintained By:** Guardian Engineering Team  

---

## Table of Contents

### Part I: Foundation & Vision
1. [Introduction](#1-introduction)
2. [Vision & Mission](#2-vision--mission)
3. [Design Philosophy](#3-design-philosophy)
4. [Success Metrics & Acceptance Criteria](#4-success-metrics--acceptance-criteria)
5. [System Requirements](#5-system-requirements)

### Part II: Architecture & Design
6. [System Architecture](#6-system-architecture)
7. [Design Principles](#7-design-principles)
8. [Module Taxonomy](#8-module-taxonomy)
9. [Data Architecture](#9-data-architecture)
10. [Communication Architecture](#10-communication-architecture)
11. [Security Architecture](#11-security-architecture)

### Part III: Core Systems
12. [Core Runtime & Bootstrap](#12-core-runtime--bootstrap)
13. [Configuration Management](#13-configuration-management)
14. [Module Loader & Dependency Graph](#14-module-loader--dependency-graph)
15. [Verification Engine](#15-verification-engine)

### Part IV: Provisioning & State Management
16. [Provisioning Engine](#16-provisioning-engine)
17. [State Management & Persistence](#17-state-management--persistence)
18. [Desired-State Reconciliation](#18-desired-state-reconciliation)
19. [Rollback Strategy](#19-rollback-strategy)

### Part V: Platform Support
20. [Platform Abstraction Layer](#20-platform-abstraction-layer)
21. [Windows Support](#21-windows-support)
22. [Linux Support](#22-linux-support)
23. [WSL Integration](#23-wsl-integration)
24. [macOS Support (Future)](#24-macos-support-future)
25. [Container Environments](#25-container-environments)

### Part VI: Developer Experience
26. [Plugin SDK](#26-plugin-sdk)
27. [Module Templates & Scaffolding](#27-module-templates--scaffolding)
28. [Testing Framework](#28-testing-framework)
29. [Documentation Generator](#29-documentation-generator)
30. [CLI Reference](#30-cli-reference)

### Part VII: Automation & Orchestration
31. [Scheduling Engine](#31-scheduling-engine)
32. [Remote Execution](#32-remote-execution)
33. [Parallel Provisioning](#33-parallel-provisioning)
34. [Policy Engine](#34-policy-engine)
35. [Secrets Management](#35-secrets-management)

### Part VIII: Enterprise Features
36. [Multi-Node Orchestration](#36-multi-node-orchestration)
37. [Inventory Management](#37-inventory-management)
38. [Compliance Reporting](#38-compliance-reporting)
39. [Audit Logging](#39-audit-logging)
40. [Role-Based Access Control](#40-role-based-access-control)
41. [API Service Layer](#41-api-service-layer)

### Part IX: Observability & Operations
42. [Logging Framework](#42-logging-framework)
43. [Metrics & Telemetry](#43-metrics--telemetry)
44. [Health Scoring](#44-health-scoring)
45. [Explanation Engine](#45-explanation-engine)
46. [Reporting & Dashboards](#46-reporting--dashboards)

### Part X: Reliability Engineering
47. [Error Handling & Resilience](#47-error-handling--resilience)
48. [Failure Modes & Recovery](#48-failure-modes--recovery)
49. [Disaster Recovery](#49-disaster-recovery)
50. [Chaos Engineering](#50-chaos-engineering)

### Part XI: Quality Assurance
51. [Testing Strategy](#51-testing-strategy)
52. [CI/CD Pipeline](#52-cicd-pipeline)
53. [Coding Standards](#53-coding-standards)
54. [Performance Targets](#54-performance-targets)
55. [Scalability Targets](#55-scalability-targets)

### Part XII: Release Engineering
56. [Release Process](#56-release-process)
57. [Versioning Strategy](#57-versioning-strategy)
58. [Compatibility Matrix](#58-compatibility-matrix)

### Part XIII: Governance & Community
59. [Contribution Guide](#59-contribution-guide)
60. [Governance Model](#60-governance-model)
61. [Security Policy](#61-security-policy)

### Part XIV: Future Direction
62. [Development Roadmap](#62-development-roadmap)
63. [Future Research Areas](#63-future-research-areas)
64. [Technical Debt Register](#64-technical-debt-register)

### Part XV: Reference
65. [Glossary](#65-glossary)
66. [Appendix A: Module Reference](#66-appendix-a-module-reference)
67. [Appendix B: Configuration Schema](#67-appendix-b-configuration-schema)
68. [Appendix C: API Contracts](#68-appendix-c-api-contracts)
69. [Appendix D: Milestone History](#69-appendix-d-milestone-history)

---

## Part I: Foundation & Vision

### 1. Introduction

#### 1.1 Purpose
This document serves as the authoritative engineering specification for Nexus98 Guardian — the operational supervisory intelligence layer for the Nexus98 ecosystem. It captures the system architecture, design decisions, implementation roadmap, and operational standards required for long-term development and maintenance.

#### 1.2 Scope
Guardian is an independent supervisory system that observes, evaluates, protects, and recovers the Nexus98 creation engine. It does not replace Nexus98; it governs it. The two systems are separate but cooperative, communicating through a governed message bridge.

#### 1.3 Audience
- **Primary:** Guardian core engineers, platform engineers, site reliability engineers
- **Secondary:** Nexus98 engineers, security auditors, compliance officers, release managers
- **Tertiary:** Contributors, integrators, operators

#### 1.4 Document Conventions
- **MUST/SHALL** — Mandatory requirement
- **SHOULD** — Recommended; deviation requires justification
- **MAY** — Optional; implementation-defined
- **TODO** — Section incomplete; implementation details pending
- **DECISION REQUIRED** — Architectural decision pending stakeholder input
- **DEPRECATED** — Marked for removal; do not build new dependencies

---

### 2. Vision & Mission

#### 2.1 Vision Statement
> **Guardian becomes the autonomous nervous system for Nexus98 — observing everything, explaining everything, protecting everything, and recovering from anything — without ever becoming the system it protects.**

#### 2.2 Mission Statement
Guardian provides continuous operational assurance for Nexus98 through:
- **Observability:** Complete visibility into system state, health, and behavior
- **Governance:** Policy-driven decision gates for all mutating operations
- **Resilience:** Automated detection, diagnosis, and remediation of drift and failure
- **Recoverability:** Guaranteed rollback to known-good state at any point
- **Explainability:** Human-readable rationale for every automated decision

#### 2.3 Strategic Objectives
| Objective | Description | Horizon |
|-----------|-------------|---------|
| **Zero Silent Failures** | Every anomaly detected, classified, and reported | Near-term |
| **Governed Autonomy** | Autonomous remediation within policy boundaries | Mid-term |
| **Cross-Platform Parity** | Equivalent capability on Windows, Linux, WSL | Mid-term |
| **Enterprise Readiness** | RBAC, audit, compliance, multi-tenancy | Long-term |
| **Self-Improving** | Learning from incidents; predictive prevention | Research |

---

### 3. Design Philosophy

#### 3.1 Core Principles
| Principle | Description | Implication |
|-----------|-------------|-------------|
| **Separation of Concerns** | Guardian ≠ Nexus98 | No shared runtime; separate repos; bridge only |
| **Observability First** | Instrument everything before acting | Every module emits events, metrics, audit entries |
| **Governance by Default** | No mutating action without policy check | `Test-GuardianPolicy` gate on all writers |
| **Checkpoint Before Change** | State snapshot before any mutation | `New-GuardianCheckpoint` wrapper pattern |
| **Explain Every Decision** | Human-readable WHAT/WHY/EVIDENCE/IMPACT/REC | `Get-GuardianDecisionExplanation` on all gates |
| **Fail Safe, Fail Loud** | Errors surface immediately; no silent degradation | Structured exceptions; audit trail on every failure |
| **Storage as Liability** | Data has cost; entropy is the enemy | Classification, retention, deduplication mandatory |
| **Test-Driven Governance** | Policy tests are executable documentation | Pester v6; 100% gate coverage for protected surfaces |

#### 3.2 Anti-Patterns (Explicitly Avoided)
- ❌ Guardian modifying Nexus98 directly (bridge only)
- ❌ Silent deletion or cleanup without manifest
- ❌ Hard-coded paths (use `Guardian_Env` contracts)
- ❌ Untyped hashtables in public APIs (use `Guardian_Contracts` types)
- ❌ Module loading outside `Guardian_Loader`
- ❌ Tests that don't run in CI (Pester v6, `-Be`/`-Match` syntax)

---

### 4. Success Metrics & Acceptance Criteria

#### 4.1 System-Level KPIs
| Metric | Target | Measurement |
|--------|--------|-------------|
| **Detection Latency** | < 30 seconds | Event ingestion → alert |
| **Remediation Latency (auto)** | < 5 minutes | Policy trigger → checkpoint restore |
| **Remediation Latency (guided)** | < 30 minutes | Alert → human approval → execution |
| **False Positive Rate** | < 5% | Alert classification feedback |
| **Mean Time to Explain** | < 10 seconds | `Get-Guardian*Explanation` latency |
| **Checkpoint Integrity** | 100% | SHA256 verification on restore |
| **Test Coverage (protected surfaces)** | 100% | Pester code coverage gate |
| **Architecture Drift Detection** | 100% | Baseline comparison on every load |

#### 4.2 Quality Gates (Per Milestone)
| Gate | Requirement |
|------|-------------|
| **Code** | All modules load via `Guardian_Loader`; no syntax errors |
| **Tests** | All milestone tests pass (Pester v6 syntax) |
| **Architecture** | `Test-GuardianArchitectureDrift` passes |
| **Governance** | `Test-GuardianPolicy` gates all mutations |
| **Documentation** | Updated `ARCHITECTURE_MAP.md`, `ROADMAP.md`, module help |
| **Checkpoint** | Milestone checkpoint created and verified |

---

### 5. System Requirements

#### 5.1 Runtime Requirements
| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **PowerShell** | 7.4+ (Core) | 7.5+ |
| **.NET Runtime** | 8.0 LTS | 9.0 LTS |
| **OS** | Windows 10 21H2+, Ubuntu 22.04+, WSL2 | Windows 11, Ubuntu 24.04 |
| **Memory** | 512 MB | 2 GB |
| **Disk** | 2 GB (excl. snapshots) | 10 GB |
| **Network** | Localhost only (bridge) | LAN for multi-node |

#### 5.2 Dependency Matrix
| Dependency | Version | Purpose | License |
|------------|---------|---------|---------|
| **Pester** | 6.x | Testing framework | Apache-2.0 |
| **PSReadLine** | 2.3+ | CLI experience | BSD-3 |
| **ThreadJob** | 2.0+ | Parallel execution | MIT |
| **Newtonsoft.Json** | 13.0+ | JSON serialization | MIT |

#### 5.3 Platform Capability Matrix
| Capability | Windows | Linux | WSL2 | macOS | Container |
|------------|---------|-------|------|-------|-----------|
| **Core Runtime** | ✅ | ✅ | ✅ | 🔄 | ✅ |
| **Event Store** | ✅ | ✅ | ✅ | 🔄 | ✅ |
| **Checkpoint/Restore** | ✅ | ✅ | ✅ | 🔄 | ✅ |
| **Storage Intelligence** | ✅ | ✅ | ✅ | 🔄 | ✅ |
| **Memory Intelligence** | ✅ | ✅ | ✅ | 🔄 | ✅ |
| **Resource Monitoring** | ✅ | ✅ | ✅ | 🔄 | ✅ |
| **Agent Supervision** | ✅ | ✅ | ✅ | 🔄 | ✅ |
| **Security Monitoring** | ✅ | 🔄 | 🔄 | 🔄 | 🔄 |
| **Nexus98 Bridge** | ✅ | ❌ | 🔄 | ❌ | ❌ |

*✅ = Full support, 🔄 = Planned/Partial, ❌ = Not supported*

---

## Part II: Architecture & Design

### 6. System Architecture

#### 6.1 High-Level Topology
```
┌─────────────────────────────────────────────────────────────────┐
│                        Human Operator                            │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        GUARDIAN                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   GOVERNANCE LAYER                       │   │
│  │  Policy Engine │ Audit │ Risk Tiers │ Decision Gates    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                   │
│  ┌──────────┬──────────┬──────┴──────────┬──────────┬────────┐  │
│  │ OBSERVE  │  EVAL    │    PROTECT      │  RECOVER │ COMM   │  │
│  ├──────────┼──────────┼─────────────────┼──────────┼────────┤  │
│  │ Health   │ Integrity│  Checkpoint     │ Recovery │ Bridge │  │
│  │ Events   │ Drift    │  Rollback       │ Restore  │ Bus    │  │
│  │ Memory   │ Storage  │  Remediation    │ Snapshots│ In/Out │  │
│  │ Patterns │ Entropy  │  Guard          │ Verify   │ Contracts│ │
│  └──────────┴──────────┴─────────────────┴──────────┴────────┘  │
└─────────────────────────────┬───────────────────────────────────┘
                              │ Governed Bridge (JSONL)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NEXUS98 (Read-Only to Guardian)            │
└─────────────────────────────────────────────────────────────────┘
```

#### 6.2 Module Dependency Graph (Foundation)
```
Guardian_Env (0 deps)
    │
    ├── Guardian_Contracts
    │
    ├── Guardian_Loader ◄── Loads all modules in dependency order
    │       │
    │       ├── Guardian_Governance
    │       ├── Guardian_Audit
    │       ├── Guardian_Health
    │       ├── Guardian_Checkpoint
    │       ├── Guardian_Integrity
    │       ├── Guardian_Recovery
    │       │
    │       ├── Guardian_Events
    │       ├── Guardian_StorageIntelligence
    │       ├── Guardian_Memory
    │       ├── Guardian_Patterns
    │       ├── Guardian_Observability
    │       ├── Guardian_Explanation
    │       ├── Guardian_Resource
    │       ├── Guardian_Agents
    │       ├── Guardian_Security
    │       ├── Guardian_ActionPlanning
    │       ├── Guardian_Remediation
    │       ├── Guardian_GovernanceIntegration
    │       ├── Guardian_Comms
    │       ├── Guardian_DriftGuard
    │       ├── Guardian_Bridge
    │       ├── Guardian_StorageRules
    │       └── Guardian_EntropyRemediation
    │
    └── Nexus98_Scribe (documentation generator tools; optional)
```

#### 6.3 Data Flow Summary
| Flow | Source | Transport | Destination | Governance |
|------|--------|-----------|-------------|------------|
| **Events** | All modules | `Guardian_Events` (JSONL) | Event store | Append-only |
| **Checkpoints** | `Guardian_Checkpoint` | File system (tiered) | `data/checkpoints/` | Pre-mutation gate |
| **Audit** | `Guardian_Audit` | JSONL | `logs/guardian_audit.jsonl` | Immutable |
| **Health** | `Guardian_Health` | In-memory → JSON | Dashboard/API | Read-only |
| **Bridge Out** | `Guardian_Comms` | JSONL outbox | `snapshots/communication/outbox/` | Policy gate |
| **Bridge In** | Nexus98 | JSONL inbox | `snapshots/communication/inbox/` | Validation gate |
| **Remediation** | `Guardian_Remediation` | File ops + manifest | `data/remediation/` | Checkpoint + Policy |

---

### 7. Design Principles

#### 7.1 Architectural Invariants
| Invariant | Enforcement |
|-----------|-------------|
| **No circular module dependencies** | `Guardian_Loader` validates DAG on import |
| **All public functions use `Guardian_Contracts` types** | Lint rule + test gate |
| **All mutating functions call `Test-GuardianPolicy`** | Code review checklist; static analysis TODO |
| **All state changes create audit entries** | `Guardian_Audit` wrapper pattern |
| **Checkpoints are immutable after creation** | Write-once directory structure; SHA256 manifest |
| **Bridge never modifies Nexus98 directly** | Contract: `GUARDIAN_TO_NEXUS98` is advisory only |

#### 7.2 Extensibility Model
- **Plugin Interface:** `Guardian_Agents` registers external supervisors
- **Module Template:** `New-GuardianModuleTemplate` scaffolds compliant modules
- **Policy Extensions:** JSON policy packs loaded at runtime
- **Bridge Adapters:** `Guardian_Comms` supports pluggable transport (currently JSONL)

#### 7.3 Failure Domain Isolation
| Domain | Isolation Mechanism |
|--------|---------------------|
| **Module Load** | Try/Catch per module; continue on non-critical failure |
| **Event Processing** | Independent runspaces per consumer |
| **Checkpoint I/O** | Separate tiered directories; no cross-tier dependencies |
| **Bridge Transport** | Inbox/outbox queues; retry with backoff; dead-letter archive |
| **Remediation** | Dry-run mandatory; manifest-backed rollback |

---

### 8. Module Taxonomy

#### 8.1 Category Definitions
| Category | Prefix | Purpose | Examples |
|----------|--------|---------|----------|
| **Foundation** | `Guardian_` | Core runtime services | Env, Loader, Contracts |
| **Governance** | `Guardian_` | Policy, audit, risk | Governance, Audit, GovernanceIntegration |
| **Observability** | `Guardian_` | Health, events, metrics | Health, Events, Observability, Resource |
| **Intelligence** | `Guardian_` | Memory, patterns, explanation | Memory, Patterns, Explanation |
| **Storage** | `Guardian_` | Classification, entropy, rules | StorageIntelligence, StorageRules, EntropyRemediation |
| **Recovery** | `Guardian_` | Checkpoint, rollback, remediation | Checkpoint, Recovery, ActionPlanning, Remediation |
| **Communication** | `Guardian_` | Bridge, bus, contracts | Comms, Bridge, DriftGuard |
| **Security** | `Guardian_` | Config monitoring, RBAC | Security |
| **Automation** | `Guardian_` | Agents, scheduling | Agents |

#### 8.2 Module Lifecycle
```
Template → Scaffold → Develop → Test (Pester v6) → 
Architecture Gate → Policy Gate → Checkpoint → 
Documentation → Merge → Release
```

---

### 9. Data Architecture

#### 9.1 Directory Contract (Guardian_Env)
```
$GuardianEnv.Root
├── core/                    # Modules (git-tracked)
├── config/                  # State JSON (git-ignored; checkpointed)
│   ├── guardian_state.json
│   ├── architecture_baseline.json
│   └── policy_packs/
├── data/
│   ├── checkpoints/
│   │   ├── rolling/         # Hourly, retained 72h
│   │   ├── milestones/      # Per-milestone, retained forever
│   │   ├── emergency/       # Pre-risky-op, retained 30d
│   │   └── archive/         # Compressed, cold storage
│   ├── events/              # JSONL event store
│   ├── memory/              # Short/long/pattern stores
│   └── remediation/         # Plans, manifests, quarantine
├── logs/
│   └── guardian_audit.jsonl # Append-only audit trail
├── snapshots/               # Legacy archive (git-ignored, 2.1 GB)
│   ├── communication/       # M8 governed message bus
│   │   ├── inbox/
│   │   ├── outbox/
│   │   ├── processing/
│   │   ├── completed/
│   │   ├── failed/
│   │   └── archive/
│   └── data/remediation/    # M9 quarantine
├── plugins/                 # External modules (git-submodule or path)
├── scripts/                 # Operational scripts
├── docs/                    # Generated + authored docs
├── tests/                   # Pester test suites
├── governance/              # Policy packs, decisions
├── monitoring/              # Health configs, alert rules
├── memory/                  # Operational memory exports
├── storage/                 # Storage intelligence exports
├── communication/           # Bridge contracts
├── recovery/                # Recovery procedures
└── archive/
    └── legacy_stubs/        # Quarantined legacy (NOT loaded)
```

#### 9.2 Data Classification
| Class | Retention | Backup | Encryption | Examples |
|-------|-----------|--------|------------|----------|
| **ACTIVE** | Indefinite | Every checkpoint | At rest | Core modules, config, checkpoints |
| **OBSOLETE** | 90 days | Checkpoint only | At rest | Old logs, rotated events |
| **ARCHIVE** | 7 years | Milestone only | At rest + transit | Milestone checkpoints, audit |
| **QUARANTINE** | 30 days | Emergency only | At rest + transit | Remediation staging, failed bridge msgs |
| **EPHEMERAL** | Session | None | Memory only | In-memory caches, runspace state |

#### 9.3 Storage Intelligence Rules (Guardian_StorageRules)
| Rule ID | Pattern | Classification | Action |
|---------|---------|----------------|--------|
| `SR-001` | `core\*.ps1` | ACTIVE | Protect |
| `SR-002` | `config\*.json` | ACTIVE | Checkpoint |
| `SR-003` | `logs\*.jsonl` | OBSOLETE | Rotate 7d |
| `SR-004` | `snapshots\**` | ARCHIVE | Govern |
| `SR-005` | `data\checkpoints\rolling\*` | ACTIVE | Rotate 72h |
| `SR-006` | `data\checkpoints\milestones\*` | ARCHIVE | Retain forever |
| `SR-007` | `data\remediation\quarantine\*` | QUARANTINE | TTL 30d |
| `SR-008` | `**\*.bak`, `**\*~` | OBSOLETE | Delete on scan |

---

### 10. Communication Architecture

#### 10.1 Guardian ↔ Nexus98 Bridge
```
┌──────────────┐     JSONL      ┌──────────────┐
│   Guardian   │ ─────────────► │   Nexus98    │
│   (Outbox)   │  GUARDIAN_     │   (Inbox)    │
└──────────────┘  TO_NEXUS98    └──────────────┘
       ▲                                 │
       │  Governance Gate                │  Validation Gate
       │  (Test-GuardianPolicy)          │  (Schema + Permissions)
       ▼                                 ▼
┌──────────────────────────────────────────────────────┐
│              Guardian_DriftGuard / M7 Gate            │
└──────────────────────────────────────────────────────┘
```

#### 10.2 Message Contracts (Guardian_Contracts)
| Message Type | Direction | Schema | Purpose |
|--------------|-----------|--------|---------|
| `GUARDIAN_HEALTH_REPORT` | G→N | Health + metrics | Periodic status |
| `GUARDIAN_EXPLANATION` | G→N | WHAT/WHY/EVIDENCE/IMPACT/REC | Decision rationale |
| `GUARDIAN_ALERT` | G→N | Event + severity | Anomaly notification |
| `NEXUS98_TASK_CONTEXT` | N→G | Task + requested analysis | Work request |
| `NEXUS98_COMMAND` | N→G | Command + params | Control request (validated) |
| `NEXUS98_QUERY` | N→G | Query + scope | Read-only inquiry |

#### 10.3 Transport Guarantees
| Property | Guarantee | Mechanism |
|----------|-----------|-----------|
| **Ordering** | Per-sender FIFO | Sequence numbers in JSONL |
| **Deduplication** | Exactly-once semantics | Event ID + processed log |
| **Retry** | Exponential backoff (max 5x) | `Guardian_Bridge` dispatcher |
| **Dead Letter** | Failed after max retry → archive | `failed/` subdirectory |
| **Replay** | From checkpoint + offset | `Get-GuardianEvents -SinceCheckpoint` |

---

### 11. Security Architecture

#### 11.1 Threat Model
| Asset | Threat | Mitigation |
|-------|--------|------------|
| **Checkpoint Integrity** | Tampering | SHA256 manifest; immutable tiers |
| **Audit Trail** | Repudiation | Append-only JSONL; hash chaining TODO |
| **Bridge Messages** | Injection/Replay | Schema validation; sender auth; nonce |
| **Policy Engine** | Bypass | Six-lock guard (M7); architecture baseline |
| **Secrets** | Leakage | External vault (Phase 5); env vars only |
| **Remediation** | Destructive action | Dry-run mandatory; checkpoint gate; approval |

#### 11.2 Trust Boundaries
```
┌─────────────────────────────────────────────────────────┐
│                    TRUSTED ZONE                          │
│  Guardian Core (Loader, Contracts, Governance, Audit)   │
└────────────────────────────┬────────────────────────────┘
                             │ Policy Gate
                             ▼
┌─────────────────────────────────────────────────────────┐
│                   CONTROLLED ZONE                        │
│  Observability, Memory, Storage, Recovery, Remediation  │
└────────────────────────────┬────────────────────────────┘
                             │ Checkpoint Gate
                             ▼
┌─────────────────────────────────────────────────────────┐
│                   EXECUTION ZONE                         │
│  Agents, Bridge Dispatcher, Remediation Executor         │
└────────────────────────────┬────────────────────────────┘
                             │ Validation Gate
                             ▼
┌─────────────────────────────────────────────────────────┐
│                   EXTERNAL ZONE                          │
│  Nexus98 Bridge, File System, Network, User Input       │
└─────────────────────────────────────────────────────────┘
```

#### 11.3 RBAC Model (Phase 6)
| Role | Permissions | Scope |
|------|-------------|-------|
| **Operator** | Read health, view audit, request remediation | Assigned nodes |
| **Engineer** | Operator + approve remediation, modify policy | Assigned nodes |
| **Admin** | Engineer + manage checkpoints, configure bridge | All nodes |
| **Auditor** | Read-only: audit, health, compliance reports | All nodes |
| **System** | Automated: write events, create checkpoints, execute approved plans | Local node only |

---

## Part III: Core Systems

### 12. Core Runtime & Bootstrap

#### 12.1 Guardian_Env (Path Contract)
**Purpose:** Single source of truth for all filesystem paths.
**Key Exports:**
- `$GuardianEnv.Root` — Project root
- `$GuardianEnv.Core` — Module directory
- `$GuardianEnv.Config` — Configuration directory
- `$GuardianEnv.Data` — Data directory
- `$GuardianEnv.Checkpoints.*` — Checkpoint tier paths
- `$GuardianEnv.Logs` — Audit log directory
- `$GuardianEnv.Snapshots` — Legacy archive root

**Initialization:** `Initialize-GuardianEnvironment` creates all directories, validates write access, writes `.guardian_initialized` marker.

#### 12.2 Guardian_Loader (Bootstrap)
**Purpose:** Ordered module loading with dependency resolution.
**Algorithm:**
1. Parse `Guardian_Manifest.psd1` (TODO: create) for module metadata
2. Build DAG from `RequiredModules` declarations
3. Topological sort → load order
4. For each module: `Import-Module -Force -DisableNameChecking`
5. Validate exports against `Guardian_Contracts`
6. Register in `$GuardianLoadedModules` global

**Failure Modes:**
- Circular dependency → Hard error (block bootstrap)
- Missing required module → Hard error
- Syntax error in module → Log + continue (non-critical) / Hard error (critical)
- Contract mismatch → Hard error

#### 12.3 Guardian_Contracts (Type System)
**Purpose:** Structured types for all public APIs.
**Type Categories:**
- **Events:** `GuardianEvent`, `EventCategory`, `EventSeverity`
- **Memory:** `GuardianMemory`, `MemoryCategory`, `ImportanceLevel`
- **Health:** `HealthReport`, `ComponentHealth`, `HealthScore`
- **Checkpoint:** `CheckpointManifest`, `CheckpointTier`, `ArtifactRecord`
- **Policy:** `PolicyDecision`, `RiskTier`, `ActionCategory`
- **Bridge:** `BridgeMessage`, `MessageType`, `MessageDirection`
- **Remediation:** `RemediationPlan`, `RemediationAction`, `RollbackManifest`
- **Governance:** `ArchitectureBaseline`, `DriftReport`, `ProtectedSurface`

**Convention:** All types are `class` definitions in PowerShell 7+; serialized as JSON with `@odata.type` discriminator.

---

### 13. Configuration Management

#### 13.1 Configuration Layers (Precedence Order)
| Layer | Source | Scope | Mutable |
|-------|--------|-------|---------|
| **Default** | `Guardian_Defaults.json` (embedded) | System | No |
| **System** | `/etc/guardian/config.json` (Linux) / `HKLM` (Windows) | Machine | Admin |
| **User** | `$GuardianEnv.Config/guardian_state.json` | User | Yes |
| **Session** | Environment variables `GUARDIAN_*` | Process | Yes |
| **Runtime** | `Set-GuardianConfig` | In-memory | Yes |

#### 13.2 Configuration Schema (TODO: JSON Schema)
Key sections:
```json
{
  "core": { "root": "", "logLevel": "Info", "parallelism": 4 },
  "checkpoints": { "rollingIntervalHours": 1, "rollingRetentionHours": 72, "milestoneRetention": "forever" },
  "events": { "retentionDays": 30, "maxSizeMB": 500, "dedupWindowMinutes": 60 },
  "memory": { "shortTermDays": 7, "longTermDays": 365, "patternMinOccurrences": 3 },
  "storage": { "scanIntervalHours": 24, "duplicateThresholdBytes": 1024, "nestingDepthThreshold": 6 },
  "bridge": { "enabled": true, "pollIntervalSeconds": 30, "maxRetries": 5 },
  "governance": { "defaultRiskTier": "medium", "requireCheckpoint": true, "requireExplanation": true },
  "health": { "weights": { "runtime": 0.2, "storage": 0.2, "memory": 0.2, "recovery": 0.2, "events": 0.1, "checkpoints": 0.1 } },
  "security": { "monitorConfigChanges": true, "monitorPermissions": true, "alertOnDrift": true }
}
```

#### 13.3 Configuration Validation
- Schema validation on load (TODO: JSON Schema)
- `Test-GuardianConfiguration` validates cross-field constraints
- Invalid config → fallback to defaults + audit warning

---

### 14. Module Loader & Dependency Graph

#### 14.1 Module Manifest Schema (TODO)
```powershell
@{
    ModuleName = 'Guardian_Events'
    Version = '1.0.0'
    RequiredModules = @('Guardian_Contracts', 'Guardian_Audit')
    OptionalModules = @('Guardian_Memory')
    ExportedFunctions = @('New-GuardianEvent', 'Write-GuardianEvent', 'Get-GuardianEvents', ...)
    ExportedTypes = @('GuardianEvent')
    Category = 'Observability'
    Critical = $true
}
```

#### 14.2 Dependency Resolution
- **Static Analysis:** `Guardian_Loader` reads manifests at bootstrap
- **Dynamic Registration:** Modules can register post-load via `Register-GuardianModule`
- **Health Check:** `Get-GuardianModuleHealth` reports load status, version, exports

#### 14.3 Hot Reload (Future)
- File system watcher on `core/`
- Graceful unload/reload with state preservation
- Requires checkpoint before reload

---

### 15. Verification Engine

#### 15.1 Test Framework (Pester v6)
**Conventions:**
- Test files: `Guardian.M<n>.Tests.ps1` in `tests/`
- Syntax: `Should -Be`, `Should -Match`, `Should -Throw`
- Setup: `BeforeAll { Import-Guardian -Root $PSScriptRoot\.. }`
- Tags: `Unit`, `Integration`, `Architecture`, `Governance`

#### 15.2 Test Categories
| Category | Trigger | Coverage Target |
|----------|---------|-----------------|
| **Unit** | Every commit | 90%+ public functions |
| **Integration** | Pre-merge | All cross-module flows |
| **Architecture** | Every load | `Test-GuardianArchitectureDrift` |
| **Governance** | Every mutation | `Test-GuardianPolicy` on all writers |
| **Performance** | Nightly | Latency budgets |
| **Chaos** | Weekly | Failure injection scenarios |

#### 15.3 Verification Gates
| Gate | Command | Blocking |
|------|---------|----------|
| **Syntax** | `pwsh -c "Import-Module ./core/Guardian_*.ps1"` | Yes |
| **Unit Tests** | `Invoke-Pester tests/Guardian.Foundation.Tests.ps1` | Yes |
| **Milestone Tests** | `Invoke-Pester tests/Guardian.M<n>.Tests.ps1` | Yes (per milestone) |
| **Architecture Drift** | `Test-GuardianArchitectureDrift` | Yes |
| **Policy Compliance** | `Test-GuardianPolicy` on changed files | Yes |
| **Checkpoint** | `New-GuardianCheckpoint -Tier Milestone` | Yes (release) |

---

## Part IV: Provisioning & State Management

### 16. Provisioning Engine

#### 16.1 Desired State Model
```powershell
class GuardianDesiredState {
    [string] $StateId
    [datetime] $DeclaredAt
    [hashtable] $Modules  # ModuleName → Version/Config
    [hashtable] $Configuration  # Config key → Value
    [string[]] $RequiredCheckpoints
    [GuardianPolicy] $PolicyConstraints
}
```

#### 16.2 Provisioning Operations
| Operation | Function | Gates |
|-----------|----------|-------|
| **Install Module** | `Install-GuardianModule` | Policy + Checkpoint + Signature verify (TODO) |
| **Update Module** | `Update-GuardianModule` | Policy + Checkpoint + Diff review |
| **Remove Module** | `Remove-GuardianModule` | Policy (Critical) + Checkpoint + Dependency check |
| **Apply Config** | `Set-GuardianConfiguration` | Policy + Checkpoint + Validation |
| **Reconcile** | `Invoke-GuardianReconciliation` | Read-only; reports drift |

#### 16.3 State Tracking
- **Actual State:** Derived from filesystem + loaded modules + config
- **Desired State:** Declared via `New-GuardianDesiredState` or policy pack
- **Drift Report:** `Compare-GuardianState -Desired $desired -Actual $actual`

---

### 17. State Management & Persistence

#### 17.1 State Stores
| Store | Backend | Consistency | Use Case |
|-------|---------|-------------|----------|
| **Config** | JSON file | Eventual (single writer) | Runtime configuration |
| **Events** | JSONL append-only | Sequential | Audit, debugging, replay |
| **Checkpoints** | Tiered filesystem | Strong (immutable after write) | Recovery, rollback |
| **Memory** | JSONL + index | Eventual | Operational knowledge |
| **Health** | In-memory + JSON snapshot | Eventual | Dashboards, bridge |

#### 17.2 Concurrency Control
- **Config:** File lock (`Guardian_Lock` utility)
- **Events:** Append-only; no concurrent write conflicts
- **Checkpoints:** Directory per checkpoint; atomic rename on commit
- **Memory:** Single writer (memory manager); readers snapshot

---

### 18. Desired-State Reconciliation

#### 18.1 Reconciliation Loop (Phase 5)
```
while ($true) {
    $desired = Get-GuardianDesiredState
    $actual  = Get-GuardianActualState
    $drift   = Compare-GuardianState $desired $actual
    
    if ($drift.HasDrift) {
        $plan = New-GuardianRemediationPlan -Drift $drift
        if ($plan.RequiresApproval) {
            Submit-GuardianApprovalRequest -Plan $plan
        } else {
            Invoke-GuardianRemediation -Plan $plan -DryRun $true
            if (-not $plan.DryRunFailed) {
                Invoke-GuardianRemediation -Plan $plan
            }
        }
    }
    Start-Sleep -Seconds $Config.ReconciliationInterval
}
```

#### 18.2 Drift Classification
| Class | Description | Auto-Remediate | Example |
|-------|-------------|----------------|---------|
| **Config Drift** | Config value ≠ desired | Yes (low risk) | Log level changed |
| **Module Drift** | Version mismatch | Policy-gated | Module updated externally |
| **File Drift** | Unexpected file in managed path | Quarantine | Unknown file in `core/` |
| **Structural Drift** | Directory missing/extra | Alert only | `data/checkpoints/` deleted |
| **Bridge Drift** | Message contract mismatch | Block + Alert | Nexus98 sends unknown type |

---

### 19. Rollback Strategy

#### 19.1 Checkpoint Tiers
| Tier | Trigger | Retention | Restore Time | Use Case |
|------|---------|-----------|--------------|----------|
| **Rolling** | Hourly timer | 72 hours | < 30 sec | Routine rollback |
| **Milestone** | Milestone gate | Forever | < 60 sec | Release rollback |
| **Emergency** | Pre-risky-op | 30 days | < 30 sec | Failed remediation |
| **Archive** | Monthly compaction | 7 years | < 5 min | Compliance, forensics |

#### 19.2 Rollback Procedure
1. `Get-GuardianCheckpoint -Tier <tier> -Latest` → select target
2. `Test-GuardianCheckpointIntegrity -Checkpoint $cp` → verify
3. `New-GuardianCheckpoint -Tier Emergency -Label "Pre-rollback"` → safety net
4. `Restore-GuardianCheckpoint -Checkpoint $cp -Confirm` → execute
5. `Test-GuardianHealth -PostRestore` → validate
6. `Write-GuardianAudit -Action Rollback -Target $cp.CheckpointId` → audit

#### 19.3 Rollback Guarantees
- **Atomicity:** Directory swap (rename) or transactional file copy
- **Completeness:** Manifest lists every file; verification checks all
- **Reversibility:** Pre-rollback checkpoint enables undo
- **Auditability:** Full trail in `guardian_audit.jsonl`

---

## Part V: Platform Support

### 20. Platform Abstraction Layer

#### 20.1 Guardian_Platform (TODO: New Module)
**Purpose:** Unified interface for OS-specific operations.
**Functions:**
- `Get-GuardianPlatform` → `Windows|Linux|WSL|macOS|Container`
- `Get-GuardianPaths` → Platform-normalized paths
- `Invoke-GuardianCommand` → Cross-platform command execution
- `Get-GuardianProcessInfo` → Unified process inspection
- `Get-GuardianFileSystemInfo` → Case-sensitivity, symlinks, ACLs
- `New-GuardianScheduledTask` → Cron / Task Scheduler / systemd timer

#### 20.2 Path Normalization
| Concept | Windows | Linux/WSL/macOS |
|---------|---------|-----------------|
| **Root** | `D:\Nexus98_Guardian` | `/d/Nexus98_Guardian` |
| **Config** | `$env:APPDATA\Guardian` | `~/.config/guardian` |
| **Data** | `$env:LOCALAPPDATA\Guardian` | `~/.local/share/guardian` |
| **Logs** | `$env:TEMP\Guardian\logs` | `/var/log/guardian` |
| **Separator** | `\` | `/` |
| **Case Sensitivity** | Insensitive | Sensitive |

---

### 21. Windows Support (Primary)
- **PowerShell 7.4+** (Core) required
- **Admin Rights:** Required for checkpoint of system paths, scheduled tasks
- **WSL Integration:** `wsl.exe` bridge for Linux tooling
- **Event Log:** Optional Windows Event Log sink for audit
- **Credential Guard:** Use `SecretManagement` module for secrets (Phase 5)

### 22. Linux Support (Full Parity Target)
- **Distros:** Ubuntu 22.04+, Debian 12+, RHEL 9+, Arch (rolling)
- **Init System:** systemd timers for scheduling
- **Packaging:** .deb, .rpm, .tar.gz (Phase 6)
- **Permissions:** Capability-based (CAP_DAC_READ_SEARCH, etc.)
- **File System:** ext4, xfs, btrfs; handle case sensitivity

### 23. WSL Integration
- **Detection:** `Get-GuardianPlatform -Detail` returns `WSL` + distro
- **Path Translation:** `wslpath` for cross-boundary paths
- **Bridge:** Nexus98 on Windows ↔ Guardian in WSL via JSONL on shared mount
- **Resource Monitoring:** `/proc` + `Get-CimInstance` unification

### 24. macOS Support (Future — Phase 3+)
- **Status:** Not tested; architecture supports it
- **Blockers:** Code signing, notarization, launchd integration
- **Path:** `~/Library/Application Support/Guardian`
- **Scheduler:** launchd plists

### 25. Container Environments
- **Base Image:** `mcr.microsoft.com/powershell:lts-ubuntu-24.04`
- **Volumes:** `/data` (checkpoints), `/config`, `/logs`
- **Entry Point:** `pwsh -File /app/core/Guardian_Loader.ps1`
- **Health Check:** `pwsh -c "Import-Guardian; Get-GuardianHealthReport | ConvertTo-Json"`
- **Orchestration:** Kubernetes operator (Phase 6+)

---

## Part VI: Developer Experience

### 26. Plugin SDK

#### 26.1 Plugin Manifest
```json
{
  "name": "Guardian.Plugin.Example",
  "version": "1.0.0",
  "guardianVersion": ">=1.0.0",
  "entryPoint": "Guardian.Plugin.Example.psm1",
  "exports": ["New-ExampleAction", "Get-ExampleState"],
  "requires": ["Guardian_Contracts", "Guardian_Audit"],
  "permissions": ["ReadEvents", "WriteMemory", "RequestCheckpoint"]
}
```

#### 26.2 Plugin Lifecycle
1. **Discover:** `Find-GuardianPlugins -Path $GuardianEnv.Plugins`
2. **Validate:** Schema + signature (TODO) + dependency check
3. **Load:** `Import-GuardianPlugin` (isolated runspace optional)
4. **Register:** Plugin registers commands, event handlers, health probes
5. **Supervise:** `Guardian_Agents` monitors plugin health

#### 26.3 Extension Points
| Extension Point | Interface | Example |
|-----------------|-----------|---------|
| **Health Probe** | `Get-<Plugin>Health` | Custom metric collector |
| **Event Handler** | `Register-GuardianEventHandler -Category SECURITY -ScriptBlock { }` | Alert forwarder |
| **Remediation Action** | `New-GuardianRemediationAction -Type Custom -Handler { }` | Specialized cleanup |
| **Policy Pack** | JSON in `config/policy_packs/` | Compliance rules |
| **Bridge Adapter** | `New-GuardianBridgeTransport` | HTTP, MQTT, gRPC |

---

### 27. Module Templates & Scaffolding

#### 27.1 `New-GuardianModuleTemplate` Output
```
Guardian_Example/
├── Guardian_Example.psd1          # Manifest
├── Guardian_Example.psm1          # Module root
├── Public/
│   ├── New-ExampleThing.ps1
│   ├── Get-ExampleThing.ps1
│   └── Set-ExampleThing.ps1
├── Private/
│   ├── Helper-Function.ps1
│   └── Internal-State.ps1
├── Types/
│   └── ExampleTypes.ps1xml
├── Formats/
│   └── ExampleFormat.ps1xml
├── Tests/
│   └── Guardian.Example.Tests.ps1
├── Docs/
│   └── Guardian_Example.md
└── CHANGELOG.md
```

#### 27.2 Boilerplate Patterns
- **Public Function Template:** Parameter validation, `Test-GuardianPolicy` gate, audit write, try/catch, explanation return
- **Private Function Template:** No policy gate; internal use only
- **Test Template:** `BeforeAll` import, `Describe` per function, `It` per behavior, `Should -Be/-Match/-Throw`

---

### 28. Testing Framework

#### 28.1 Pester v6 Conventions
```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Module - FunctionName' -Tag 'Unit' {
    It 'does something specific' {
        $result = FunctionName -Param 'value'
        $result | Should -Be 'expected'
    }
    
    It 'validates input' {
        { FunctionName -Param 'invalid' } | Should -Throw
    }
}

Describe 'Module - Integration' -Tag 'Integration' {
    BeforeEach { $cp = New-GuardianCheckpoint -Tier Emergency -Label "Test-$([guid]::NewGuid())" }
    AfterEach { Restore-GuardianCheckpoint -Checkpoint $cp -Confirm:$false }
    
    It 'integrates with Guardian_Events' { ... }
}
```

#### 28.2 Test Infrastructure
- **Test Runner:** `Invoke-Pester -ConfigurationFile tests/pester.config.json`
- **Parallel:** `-Parallel` for unit tests; sequential for integration
- **Code Coverage:** `Enable-PesterCodeCoverage`; threshold 80% (TODO: enforce)
- **Test Data:** `tests/fixtures/` — version-controlled test inputs

#### 28.3 Milestone Test Suites
| Suite | Modules Covered | Tests | Status |
|-------|-----------------|-------|--------|
| `Guardian.Foundation.Tests.ps1` | Env, Loader, Contracts, Governance, Audit, Health, Checkpoint, Integrity, Recovery | 14 | ✅ PASS |
| `Guardian.M2.Tests.ps1` | Events, StorageIntelligence | 25 | ✅ PASS |
| `Guardian.M3.Tests.ps1` | Memory, Patterns, Observability, Explanation, Comms (M3 contracts) | 35 | ✅ PASS |
| `Guardian.M4.Tests.ps1` | Resource, Agents, Security | 28 | ✅ PASS |
| `Guardian.M5.Tests.ps1` | ActionPlanning, Remediation, GovernanceIntegration | 22 | ✅ PASS |
| `Guardian.M6.Tests.ps1` | Comms, Bridge | 11 | ✅ PASS |
| `Guardian.M7.Tests.ps1` | DriftGuard, ArchitectureBaseline, SelfModGuard | 17 | ✅ PASS |
| `Guardian.M8.Tests.ps1` | Bridge (runtime), Dispatcher, Security, Governance, Recovery | 18 | ✅ PASS |
| `Guardian.M9.Tests.ps1` | EntropyRemediation | 10 | ✅ PASS |
| `Guardian.M10.Tests.ps1` | Operations (full integration) | 34 | ✅ PASS |

---

### 29. Documentation Generator

#### 29.1 Nexus98_Scribe (Active)
**Modules:**
- `Nexus98_Scribe_Core` — Core generation engine
- `Nexus98_Scribe_History` — Milestone history
- `Nexus98_Scribe_Roadmap` — Roadmap generation
- `Nexus98_Scribe_Status` — Status reports
- `Nexus98_Scribe_Sync` — Cross-repo sync
- `Nexus98_Scribe_TOC` — Table of contents

**Outputs:** `ARCHITECTURE_MAP.md`, `ROADMAP.md`, `MILESTONE_DETAIL.md`, `CAPABILITY_REPORT.md`, `BENCHMARK_STATUS.md`

#### 29.2 Module Help Generation (TODO)
- `New-GuardianModuleHelp` — Generates `*.md` from comment-based help
- `Publish-GuardianDocs` — Builds static site (MkDocs/Hugo TODO)

---

### 30. CLI Reference

#### 30.1 Guardian CLI (`guardian.ps1` — TODO: Entry Point)
```powershell
guardian <command> [options]

Commands:
  init              Initialize Guardian environment
  load              Load all modules (interactive session)
  health            Show health report
  checkpoint        Manage checkpoints (list, create, restore, verify)
  event             Event operations (write, query, rotate)
  memory            Memory operations (create, search, summarize)
  remediate         Plan and execute remediation
  drift             Check architecture drift
  bridge            Bridge operations (status, send, receive)
  policy            Policy evaluation
  config            Configuration management
  module            Module management (install, update, remove, list)
  plugin            Plugin management
  test              Run test suites
  doc               Generate documentation
  version           Show version info

Global Options:
  --root <path>     Override Guardian root
  --config <path>   Override config file
  --json            Output as JSON
  --verbose         Verbose logging
  --dry-run         Simulate mutating operations
```

#### 30.2 Key Functions (Interactive Use)
| Function | Description |
|----------|-------------|
| `Import-Guardian` | Load all modules into session |
| `Get-GuardianHealthReport` | Full system health |
| `New-GuardianCheckpoint` | Create checkpoint |
| `Restore-GuardianCheckpoint` | Restore from checkpoint |
| `New-GuardianEvent` / `Write-GuardianEvent` | Emit event |
| `Get-GuardianEvents` | Query events |
| `New-GuardianMemory` / `Write-GuardianMemory` | Record memory |
| `Search-GuardianMemory` | Full-text search |
| `Get-GuardianPatterns` | Detect patterns |
| `Get-GuardianStorageHealth` | Storage analysis |
| `Test-GuardianPolicy` | Evaluate action against policy |
| `New-GuardianRemediationPlan` | Plan remediation |
| `Invoke-GuardianRemediation` | Execute plan (dry-run default) |
| `Test-GuardianArchitectureDrift` | Check drift |
| `Get-GuardianArchitectureBaseline` | View baseline |

---

## Part VII: Automation & Orchestration

### 31. Scheduling Engine (Phase 5)

#### 31.1 Guardian_Scheduler (TODO: New Module)
**Capabilities:**
- Cron-style schedules (`0
- Interval timers
- One-shot delayed execution
- Runspace-based parallelism (ThreadJob)
- Persistence across restarts (JSON schedule store)
- Missed-run catch-up policy

#### 31.2 Scheduled Jobs (Built-in)
| Job | Schedule | Function | Phase |
|-----|----------|----------|-------|
| **Rolling Checkpoint** | Hourly | `New-GuardianCheckpoint -Tier Rolling` | M0 |
| **Event Rotation** | Daily 02:00 | `Invoke-GuardianEventRotation -KeepDays 30` | M2 |
| **Storage Scan** | Daily 03:00 | `Get-GuardianStorageHealth` + baseline | M2 |
| **Memory Lifecycle** | Daily 04:00 | `Invoke-GuardianMemoryLifecycle` | M3 |
| **Pattern Detection** | 6-hourly | `Get-GuardianPatterns` | M3 |
| **Health Report** | 15-min | `Get-GuardianHealthReport` → bridge | M3 |
| **Drift Check** | On load + Daily | `Test-GuardianArchitectureDrift` | M7 |
| **Entropy Scan** | Weekly | `Get-GuardianStorageEntropy` | M9 |
| **Bridge Dispatch** | 30-sec | `Invoke-GuardianBridgeDispatch` | M8 |

---

### 32. Remote Execution (Phase 5)

#### 32.1 Transport Options
| Transport | Protocol | Auth | Use Case |
|-----------|----------|------|----------|
| **PSRemoting** | WSMan | Kerberos/CredSSP | Windows ↔ Windows |
| **SSH** | SSH | Key/Password | Linux ↔ Any |
| **WinRM over HTTPS** | WSMan | Certificate | Cross-domain Windows |
| **Custom Agent** | gRPC/HTTP | mTLS | Phase 6+ |

#### 32.2 Remote Operation Model
```powershell
Invoke-GuardianRemote -Target "server01" -ScriptBlock {
    Import-Guardian -Root "D:\Guardian"
    Get-GuardianHealthReport
} -AsJob
```

#### 32.3 Security
- Just Enough Administration (JEA) endpoints on targets
- Certificate-based mutual TLS for custom agent
- Audit log on both source and target

---

### 33. Parallel Provisioning (Phase 5)

#### 33.1 Concurrency Model
- **Throttle:** `$GuardianConfig.Core.Parallelism` (default 4)
- **Mechanism:** `ThreadJob` / `ForEach-Object -Parallel`
- **Isolation:** Per-target runspace; shared read-only config
- **Aggregation:** `Guardian_Aggregator` collects results + errors

#### 33.2 Use Cases
- Multi-node health checks
- Parallel checkpoint creation
- Bulk remediation across fleet
- Distributed entropy scanning

---

### 34. Policy Engine (Phase 5)

#### 34.1 Policy Structure
```json
{
  "policyId": "POL-STORAGE-001",
  "version": "1.2.0",
  "rules": [
    {
      "id": "R001",
      "condition": "action == 'delete' && path.startswith('data/checkpoints/milestones')",
      "effect": "deny",
      "reason": "Milestone checkpoints are immutable",
      "requiresApproval": true,
      "approvers": ["role:Admin"]
    }
  ]
}
```

#### 34.2 Evaluation Flow
```
Action Request
     │
     ▼
Test-GuardianPolicy -Action $action -Context $context
     │
     ├─► ALLOW → Proceed
     │
     ├─► DENY → Block + Audit + Explanation
     │
     └─► REQUIRES_APPROVAL → Queue → Notify Approvers → Wait → Allow/Deny
```

#### 34.3 Policy Packs
- **Core:** Built-in (immutable checkpoints, bridge validation, etc.)
- **Compliance:** SOX, HIPAA, PCI-DSS (Phase 6)
- **Organizational:** Custom packs loaded from `config/policy_packs/`

---

### 35. Secrets Management (Phase 5)

#### 35.1 Requirements
- No secrets in config files or checkpoints
- Integration with platform vaults
- Audit trail on secret access
- Rotation support

#### 35.2 Implementation (TODO)
| Platform | Vault | Module |
|----------|-------|--------|
| Windows | Credential Manager / Azure Key Vault | `Microsoft.PowerShell.SecretManagement` |
| Linux | HashiCorp Vault / AWS Secrets Manager | `SecretManagement` + extensions |
| Kubernetes | Sealed Secrets / External Secrets | CSI driver |

#### 35.3 Guardian Integration
```powershell
$secret = Get-GuardianSecret -Name "bridge/api-key" -Vault "AzureKV"
# Secret never written to disk; injected into runspace only
```

---

## Part VIII: Enterprise Features

### 36. Multi-Node Orchestration (Phase 6)

#### 36.1 Cluster Model
| Concept | Description |
|---------|-------------|
| **Control Plane** | Guardian instance with `Orchestrator` role |
| **Worker Nodes** | Guardian instances with `Agent` role |
| **Shared State** | External store (etcd, Consul, SQL) — Phase 6+ |
| **Service Discovery** | DNS / Consul / static config |

#### 36.2 Orchestration Capabilities
- Fleet-wide health aggregation
- Rolling updates with checkpoint gates
- Distributed remediation coordination
- Cross-node drift detection
- Capacity planning from aggregated metrics

#### 36.3 Consensus (Future)
- Raft-based leader election for control plane
- Quorum for critical decisions (milestone checkpoint, policy change)

---

### 37. Inventory Management (Phase 6)

#### 37.1 Asset Types
| Asset | Attributes | Source |
|-------|------------|--------|
| **Node** | Hostname, OS, IP, Role, Tags, LastSeen | Discovery / Registration |
| **Module** | Name, Version, Path, Hash, Dependencies | Loader |
| **Checkpoint** | Tier, Timestamp, Size, Integrity, Parent | Checkpoint system |
| **Policy Pack** | ID, Version, Rules, Source | Config |
| **Plugin** | Name, Version, Permissions, Health | Agent registry |

#### 37.2 Inventory API (TODO)
- `Get-GuardianInventory -Type Node -Filter @{Role='Worker'}`
- `Export-GuardianInventory -Format CSV|JSON|Excel`
- `Sync-GuardianInventory -Source CMDB`

---

### 38. Compliance Reporting (Phase 6)

#### 38.1 Report Types
| Report | Frequency | Audience | Content |
|--------|-----------|----------|---------|
| **Health Summary** | Daily | Operators | Fleet health, alerts, trends |
| **Drift Report** | Weekly | Engineers | Architecture drift, config drift |
| **Policy Compliance** | Monthly | Auditors | Policy violations, approvals, exceptions |
| **Remediation Audit** | Per-incident | Security | Actions taken, approvals, rollback |
| **Storage Entropy** | Quarterly | Architects | Growth, duplication, remediation ROI |

#### 38.2 Evidence Package
- Immutable archive: checkpoints + audit logs + decision explanations
- Cryptographic hash chain for tamper evidence
- Export: `Export-GuardianCompliancePackage -Period "2026-Q3"`

---

### 39. Audit Logging

#### 39.1 Guardian_Audit (Active since M0)
**Format:** JSON Lines (append-only)
```json
{
  "timestamp": "2026-07-26T14:30:00.123Z",
  "auditId": "AUD_abc123",
  "actor": "Guardian_Remediation",
  "action": "Invoke-GuardianRemediation",
  "target": "data/checkpoints/rolling/CP_20260726_140000",
  "decision": "ALLOWED",
  "policyId": "POL-REMEDIATION-003",
  "riskTier": "medium",
  "checkpointId": "CP_20260726_142500",
  "explanationRef": "EXP_xyz789",
  "result": "SUCCESS",
  "durationMs": 1250
}
```

#### 39.2 Audit Guarantees
- **Append-Only:** File opened with `FileMode.Append`, `FileAccess.Write`
- **Integrity:** SHA256 hash chain (TODO: implement chaining)
- **Retention:** Per classification (7 years for audit)
- **Query:** `Get-GuardianAudit -Filter @{Actor='*'; Since='2026-01-01'}`

#### 39.3 SIEM Integration (Phase 6)
- Syslog forwarder
- Splunk HEC / Elastic / Azure Sentinel
- Structured fields for correlation

---

### 40. Role-Based Access Control (Phase 6)

#### 40.1 Implementation
- **AuthN:** External (AD, OIDC, GitHub) — Guardian trusts header/token
- **AuthZ:** Policy engine evaluates `subject + resource + action`
- **Session:** Short-lived JWT with claims; refreshed via Guardian_API

#### 40.2 Protected Operations
| Operation | Required Role | Approval |
|-----------|---------------|----------|
| `Restore-GuardianCheckpoint -Tier Milestone` | Admin | Self-approval (audit) |
| `Set-GuardianPolicy` | Admin | Dual approval |
| `Invoke-GuardianRemediation -Force` | Engineer | Policy-dependent |
| `Install-GuardianModule` | Engineer | Policy (signature) |
| `Get-GuardianAudit` | Auditor | Read-only |

---

### 41. API Service Layer (Phase 6)

#### 41.1 REST/gRPC API (TODO)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Liveness/readiness |
| `/api/v1/health` | GET | Full health report |
| `/api/v1/checkpoints` | GET/POST | List/create checkpoints |
| `/api/v1/checkpoints/{id}/restore` | POST | Trigger restore |
| `/api/v1/events` | GET/POST | Query/ingest events |
| `/api/v1/memory` | GET/POST | Memory operations |
| `/api/v1/remediation/plans` | POST | Create plan |
| `/api/v1/remediation/plans/{id}/execute` | POST | Execute (with approval) |
| `/api/v1/drift` | GET | Drift report |
| `/api/v1/policy/evaluate` | POST | Dry-run policy check |
| `/api/v1/bridge/status` | GET | Bridge health |
| `/api/v1/bridge/send` | POST | Send to Nexus98 |

#### 41.2 Authentication
- mTLS for service-to-service
- OIDC for user access
- API keys for automation (scoped, rotating)

---

## Part IX: Observability & Operations

### 42. Logging Framework

#### 42.1 Log Levels
| Level | Use Case | Destination |
|-------|----------|-------------|
| **Critical** | System integrity threat | Audit + Alert + Console |
| **Error** | Operation failed | Audit + Log file |
| **Warning** | Degraded state, policy deny | Audit + Log file |
| **Info** | State changes, checkpoints | Log file |
| **Debug** | Troubleshooting | Log file (opt-in) |
| **Trace** | Verbose flow | Memory only (opt-in) |

#### 42.2 Structured Logging
All log entries are structured objects serialized to JSON:
```powershell
Write-GuardianLog -Level Info -Message "Checkpoint created" -Context @{
    CheckpointId = $cp.CheckpointId
    Tier = $cp.Tier
    SizeMB = $cp.SizeMB
    DurationMs = $sw.ElapsedMilliseconds
}
```

#### 42.3 Log Rotation
- **Audit Log:** Never rotated (append-only); archived by checkpoint tier
- **Operational Logs:** Daily rotation; compressed after 7 days; retained 90 days
- **Debug Logs:** In-memory ring buffer; flushed on error

---

### 43. Metrics & Telemetry

#### 43.1 Metric Categories
| Category | Metrics | Collection |
|----------|---------|------------|
| **Runtime** | Load time, module count, memory, CPU | `Guardian_Resource` sampler |
| **Events** | Ingest rate, queue depth, dedup rate | `Guardian_Events` |
| **Checkpoints** | Count by tier, size, create/restore latency | `Guardian_Checkpoint` |
| **Storage** | Health score, duplicate bytes, nested depth | `Guardian_StorageIntelligence` |
| **Memory** | Entry count by category, compression ratio | `Guardian_Memory` |
| **Bridge** | Msg sent/received, latency, retry rate, DLQ depth | `Guardian_Bridge` |
| **Remediation** | Plans created, executed, rolled back, success rate | `Guardian_Remediation` |
| **Policy** | Evaluations, allow/deny/approval rates | `Guardian_Governance` |

#### 43.2 Export Formats
- **Prometheus:** `/metrics` endpoint (Phase 6 API)
- **JSON:** `Get-GuardianMetrics -Format Json`
- **CSV:** `Export-GuardianMetrics -Path report.csv`
- **Bridge:** Health report → Nexus98 every 15 min

---

### 44. Health Scoring

#### 44.1 Guardian_Health (Active since M0)
**Composite Score:** Weighted average of component scores (0-100)
```powershell
$weights = @{
    Runtime = 0.20      # Module load success, no errors
    Storage = 0.20      # Guardian_StorageHealth overallPct
    Memory = 0.15       # Memory coverage, compression
    Recovery = 0.20     # Checkpoint freshness, integrity
    Events = 0.10       # Event store health, no backlog
    Checkpoints = 0.15  # Tier completeness, rotation current
}
```

#### 44.2 Component Health
| Component | Healthy | Degraded | Critical |
|-----------|---------|----------|----------|
| **Runtime** | All critical modules loaded | 1+ optional failed | Critical module missing |
| **Storage** | > 80% | 60-80% | < 60% |
| **Memory** | > 70% coverage | 40-70% | < 40% |
| **Recovery** | Checkpoint < 2h old | 2-24h | > 24h or integrity fail |
| **Events** | No backlog, rotation current | Backlog < 1000 | Backlog > 1000 or rotation failed |
| **Checkpoints** | All tiers current | Rolling > 4h old | Any tier missing |

#### 44.3 Health Actions
- **Critical:** Auto-create emergency checkpoint; alert; bridge notification
- **Degraded:** Schedule remediation; increase monitoring frequency
- **Healthy:** Normal operations

---

### 45. Explanation Engine

#### 45.1 Guardian_Explanation (Active since M3)
**Output Format (WHAT/WHY/EVIDENCE/IMPACT/REC):**
```powershell
[GuardianExplanation]@{
    What = "Storage health degraded to 62% (critical threshold 60%)"
    Why = "Duplicate content groups increased