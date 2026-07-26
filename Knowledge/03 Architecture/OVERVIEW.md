# Nexus98 Guardian — Architecture Overview

**Version:** 1.0.0  
**Status:** **CURRENT — REFLECTS M10 STATE**  
**Last Updated:** 2026-07-26  
**Owner:** Guardian Engineering Team  

---

## 🏗️ System Context

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HUMAN OPERATOR                                  │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                                  GUARDIAN                                     │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        GOVERNANCE LAYER                              │    │
│  │  Policy Engine │ Audit │ Risk Tiers │ Decision Gates │ Explanation  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                    │                                         │
│  ┌──────────────┬──────────────┬────┴────────┬──────────────┬────────────┐ │
│  │   OBSERVE    │   EVALUATE   │  PROTECT    │  RECOVER     │  COMMUNICATE│ │
│  ├──────────────┼──────────────┼─────────────┼──────────────┼────────────┤ │
│  │ Health       │ Integrity    │ Checkpoint  │ Recovery     │ Bridge     │ │
│  │ Events       │ Drift        │ Rollback    │ Restore      │ Message Bus│ │
│  │ Memory       │ Storage      │ Remediation │ Verify       │ Contracts  │ │
│  │ Patterns     │ Entropy      │ Guard       │ Snapshots    │ In/Outbox  │ │
│  └──────────────┴──────────────┴─────────────┴──────────────┴────────────┘ │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │ GOVERNED BRIDGE (JSONL)
                                  │ GUARDIAN_TO_NEXUS98: Advisory only
                                  │ NEXUS98_TO_GUARDIAN: Validated intake
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                               NEXUS98 (READ-ONLY TO GUARDIAN)               │
│                    Creation Engine • Build • Deploy • Execute               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Module Architecture

### Foundation Layer (Core Runtime) — M0
| Module | Responsibility | Critical |
|--------|---------------|----------|
| `Guardian_Env` | Path contracts, directory initialization | ✅ |
| `Guardian_Loader` | Module bootstrap, dependency resolution | ✅ |
| `Guardian_Contracts` | Structured types for all public APIs | ✅ |
| `Guardian_Governance` | Risk tiers, policy decisions | ✅ |
| `Guardian_Audit` | Append-only audit trail | ✅ |
| `Guardian_Health` | Coverage + composite health score | ✅ |
| `Guardian_Checkpoint` | 4-tier rolling checkpoint system | ✅ |
| `Guardian_Integrity` | Drift + storage entropy detection | ✅ |
| `Guardian_Recovery` | Emergency snapshot + rollback levels | ✅ |

### Observability & Intelligence Layer — M2-M3
| Module | Responsibility | Critical |
|--------|---------------|----------|
| `Guardian_Events` | Event store + event bus (JSONL) | ✅ |
| `Guardian_StorageIntelligence` | Classification, health, drift, duplicates, growth | ✅ |
| `Guardian_Memory` | Short/long/pattern memory with lifecycle | ✅ |
| `Guardian_Patterns` | Pattern recognition from events/memory | ✅ |
| `Guardian_Observability` | Unified health dashboard model | ✅ |
| `Guardian_Explanation` | WHAT/WHY/EVIDENCE/IMPACT/REC engine | ✅ |

### Operations & Remediation Layer — M4-M5
| Module | Responsibility | Critical |
|--------|---------------|----------|
| `Guardian_Resource` | CPU/mem/disk sampling, anomaly detection | ✅ |
| `Guardian_Agents` | Agent registry + supervision | ✅ |
| `Guardian_Security` | Config/permission change monitoring | ✅ |
| `Guardian_ActionPlanning` | Remediation plan builder (move-only, dry-run) | ✅ |
| `Guardian_Remediation` | Controlled executor with manifest rollback | ✅ |
| `Guardian_GovernanceIntegration` | Decision→memory integration | ✅ |

### Communication Layer — M6-M8
| Module | Responsibility | Critical |
|--------|---------------|----------|
| `Guardian_Comms` | JSONL outbox/inbox, modulation helpers | ✅ |
| `Guardian_Bridge` | Governed message bus, dispatcher, security, retry | ✅ |
| `Guardian_DriftGuard` | Architecture baseline, drift detection, self-mod guard | ✅ |
| `Guardian_StorageRules` | M1 hygiene rules (wired) | ✅ |
| `Guardian_EntropyRemediation` | M9 entropy analysis + governed remediation | ✅ |
| `Guardian_Operations` | M10 integration orchestration | ✅ |

### Documentation Layer — Nexus98 Scribe
| Module | Responsibility |
|--------|---------------|
| `Nexus98_Scribe_Core` | Core generation engine |
| `Nexus98_Scribe_Roadmap` | Roadmap document generation |
| `Nexus98_Scribe_TOC` | Table of contents generation |
| `Nexus98_Scribe_Status` | Status report generation |
| `Nexus98_Scribe_History` | Milestone history generation |
| `Nexus98_Scribe_Sync` | Cross-repo synchronization |
| `Nexus98_Scribe` | Main entry point |

---

## 🔄 Data Architecture

### Directory Contract (`Guardian_Env`)
```
$GuardianEnv.Root
├── core/                          # Modules (git-tracked)
├── config/                        # State JSON (git-ignored; checkpointed)
│   ├── guardian_state.json
│   ├── guardian_architecture_baseline.json
│   └── policy_packs/
├── data/
│   ├── checkpoints/
│   │   ├── rolling/               # Hourly, 72h retention
│   │   ├── milestones/            # Per-milestone, forever
│   │   ├── emergency/             # Pre-risky-op, 30d retention
│   │   └── archive/               # Monthly compaction, 7y retention
│   ├── events/                    # JSONL event store
│   ├── memory/                    # Short/long/pattern stores
│   └── remediation/               # Plans, manifests, quarantine
├── logs/
│   └── guardian_audit.jsonl       # Append-only audit trail
├── snapshots/                     # Legacy archive (git-ignored, 2.1 GB)
│   ├── communication/             # M8 governed message bus
│   │   ├── inbox/outbox/processing/completed/failed/archive/
│   │   └── data/remediation/      # M9 quarantine
├── plugins/                       # External modules (submodule or path)
├── scripts/                       # Operational scripts
├── docs/                          # Generated + authored docs
├── tests/                         # Pester test suites
├── governance/                    # Policy packs, decisions
├── monitoring/                    # Health configs, alert rules
├── memory/                        # Operational memory exports
├── storage/                       # Storage intelligence exports
├── communication/                 # Bridge contracts
├── recovery/                      # Recovery procedures
└── archive/
    └── legacy_stubs/              # Quarantined legacy (NOT loaded)
```

### Data Classification & Retention

| Class | Retention | Backup | Encryption | Examples |
|-------|-----------|--------|------------|----------|
| **ACTIVE** | Indefinite | Every checkpoint | At rest | Core modules, config, checkpoints |
| **OBSOLETE** | 90 days | Checkpoint only | At rest | Old logs, rotated events |
| **ARCHIVE** | 7 years | Milestone only | At rest + transit | Milestone checkpoints, audit |
| **QUARANTINE** | 30 days | Emergency only | At rest + transit | Remediation staging, failed bridge msgs |
| **EPHEMERAL** | Session | None | Memory only | In-memory caches, runspace state |

---

## 🌉 Communication Architecture

### Guardian ↔ Nexus98 Bridge

```
┌──────────────────┐     JSONL (GUARDIAN_TO_NEXUS98)      ┌──────────────────┐
│    GUARDIAN      │ ─────────────────────────────────────► │     NEXUS98      │
│   (Outbox)       │  • GUARDIAN_HEALTH_REPORT              │    (Inbox)       │
│                  │  • GUARDIAN_EXPLANATION                │                  │
│                  │  • GUARDIAN_ALERT                      │                  │
└──────────────────┘                                         └────────┬─────────┘
        ▲                                                                   │
        │                                                                   ▼
        │ JSONL (NEXUS98_TO_GUARDIAN)                         ┌──────────────────┐
        │  • NEXUS98_TASK_CONTEXT                ┌────────────┤  VALIDATION GATE │
        │  • NEXUS98_COMMAND                     │            │  Schema + Perms  │
        │  • NEXUS98_QUERY                       │            └────────┬─────────┘
        └────────────────────────────────────────┘                     │
                                                                        ▼
                                                              ┌──────────────────┐
                                                              │  GOVERNANCE GATE │
                                                              │ Test-GuardianPolicy│
                                                              └────────┬─────────┘
                                                                       │
                                               ┌───────────────────────┼───────────────────────┐
                                               ▼                       ▼                       ▼
                                          ALLOW                   DENY                    APPROVAL
                                         Execute              Block + Audit           Queue + Notify
```

### Message Contracts (`Guardian_Contracts`)

| Type | Direction | Schema | Purpose |
|------|-----------|--------|---------|
| `GUARDIAN_HEALTH_REPORT` | G→N | Health + metrics | Periodic status (15 min) |
| `GUARDIAN_EXPLANATION` | G→N | WHAT/WHY/EVIDENCE/IMPACT/REC | Decision rationale |
| `GUARDIAN_ALERT` | G→N | Event + severity | Anomaly notification |
| `NEXUS98_TASK_CONTEXT` | N→G | Task + requested analysis | Work request |
| `NEXUS98_COMMAND` | N→G | Command + params | Control request (validated) |
| `NEXUS98_QUERY` | N→G | Query + scope | Read-only inquiry |

### Transport Guarantees

| Property | Guarantee | Mechanism |
|----------|-----------|-----------|
| **Ordering** | Per-sender FIFO | Sequence numbers in JSONL |
| **Deduplication** | Exactly-once | Event ID + processed log |
| **Retry** | Exponential backoff (max 5x) | `Guardian_Bridge` dispatcher |
| **Dead Letter** | Failed → archive | `failed/` subdirectory |
| **Replay** | From checkpoint + offset | `Get-GuardianEvents -SinceCheckpoint` |

---

## 🔒 Security Architecture

### Trust Boundaries

```
┌────────────────────────────────────────────────────────────────┐
│                      TRUSTED ZONE                               │
│  Guardian Core (Loader, Contracts, Governance, Audit)          │
└──────────────────────────┬─────────────────────────────────────┘
                           │ Policy Gate (Test-GuardianPolicy)
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                     CONTROLLED ZONE                             │
│  Observability, Memory, Storage, Recovery, Remediation         │
└──────────────────────────┬─────────────────────────────────────┘
                           │ Checkpoint Gate (New-GuardianCheckpoint)
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                     EXECUTION ZONE                              │
│  Agents, Bridge Dispatcher, Remediation Executor               │
└──────────────────────────┬─────────────────────────────────────┘
                           │ Validation Gate (Schema + Permissions)
                           ▼
┌────────────────────────────────────────────────────────────────┐
│                     EXTERNAL ZONE                               │
│  Nexus98 Bridge, File System, Network, User Input              │
└────────────────────────────────────────────────────────────────┘
```

### RBAC Model (Phase 6 — Designed)

| Role | Permissions | Scope |
|------|-------------|-------|
| **Operator** | Read health, view audit, request remediation | Assigned nodes |
| **Engineer** | Operator + approve remediation, modify policy | Assigned nodes |
| **Admin** | Engineer + manage checkpoints, configure bridge | All nodes |
| **Auditor** | Read-only: audit, health, compliance reports | All nodes |
| **System** | Automated: write events, create checkpoints, execute approved plans | Local node |

---

## ⚙️ Operational Flows

### 1. Bootstrap Sequence
```
Import-Guardian
    │
    ├─► Guardian_Env: Initialize paths, validate write access
    ├─► Guardian_Loader: Topological sort of module DAG
    │       ├─► Load Foundation (9 modules)
    │       ├─► Load Observability (6 modules)
    │       ├─► Load Operations (6 modules)
    │       ├─► Load Communication (5 modules)
    │       └─► Load Scribe (7 modules)
    ├─► Initialize-GuardianEnvironment: Create dirs, write .guardian_initialized
    └─► Test-GuardianArchitectureDrift: Validate against baseline
```

### 2. Mutation Flow (Any State Change)
```
Request Mutation
    │
    ▼
Test-GuardianPolicy -Action $action -Context $context
    │
    ├─► DENY ──► Block + Audit + Explanation
    │
    ├─► ALLOW ──► New-GuardianCheckpoint -Tier Emergency -Label "Pre-$action"
    │                │
    │                ▼
    │           Execute Mutation
    │                │
    │                ├─► SUCCESS ──► Audit + Explanation
    │                │
    │                └─► FAILURE ──► Restore-GuardianCheckpoint + Audit + Alert
    │
    └─► REQUIRES_APPROVAL ──► Queue + Notify Approvers ──► Wait ──► ALLOW/DENY
```

### 3. Drift Detection Flow
```
On Load / Scheduled / On Demand
    │
    ▼
Get-GuardianArchitectureBaseline
    │
    ▼
Get-GuardianDrift -Baseline $baseline
    │
    ├─► NO DRIFT ──► Healthy
    │
    └─► DRIFT DETECTED ──► Classify (6 types)
         │
         ├─► NEW_UNAPPROVED_DIRECTORY
         ├─► NEW_UNAPPROVED_MODULE
         ├─► CONFIGURATION_DRIFT
         ├─► UNCONTROLLED_ARTIFACT
         ├─► MODULE_MODIFIED
         └─► STRUCTURAL_DRIFT
         │
         ▼
Test-GuardianPolicy -Action "remediate_drift" -Context $drift
         │
         ▼
Governed Remediation (Plan → Checkpoint → Execute → Verify → Rollback if needed)
```

### 4. Entropy Remediation Flow (M9)
```
Get-GuardianStorageEntropy (sampled analysis)
    │
    ▼
New-GuardianRemediationPlan (move-only actions)
    │
    ├─► DRY RUN (default) ──► Show manifest, estimate impact
    │
    └─► EXECUTE (with approval)
         │
         ├─► New-GuardianCheckpoint -Tier Emergency
         ├─► Test-GuardianPolicy (governance gate)
         ├─► Invoke-GuardianRemediation -Plan $plan
         │       │
         │       ├─► Manifest created (data/remediation/manifest_*.json)
         │       ├─► Files moved to quarantine (data/remediation/quarantine/)
         │       └─► Verify integrity
         │
         ├─► SUCCESS ──► Get-GuardianRemediationMetrics + Audit
         │
         └─► FAILURE ──► Undo-GuardianRemediation (manifest-backed rollback)
```

---

## 📊 Health Scoring Model

### Composite Score (0-100)
```powershell
$weights = @{
    Runtime     = 0.20  # Module load success, no critical errors
    Storage     = 0.20  # Guardian_StorageHealth.overallPct
    Memory      = 0.15  # Coverage, compression ratio
    Recovery    = 0.20  # Checkpoint freshness, integrity
    Events      = 0.10  # Store health, no backlog, rotation current
    Checkpoints = 0.15  # All tiers current, rotation working
}
```

### Component Thresholds

| Component | Healthy | Degraded | Critical |
|-----------|---------|----------|----------|
| **Runtime** | All critical loaded | 1+ optional failed | Critical missing |
| **Storage** | > 80% | 60-80% | < 60% |
| **Memory** | > 70% coverage | 40-70% | < 40% |
| **Recovery** | CP < 2h old | 2-24h | > 24h or integrity fail |
| **Events** | No backlog, rotation OK | Backlog < 1000 | Backlog > 1000 or rotation failed |
| **Checkpoints** | All tiers current | Rolling > 4h old | Any tier missing |

### Health Actions
- **Critical:** Auto-create emergency checkpoint; alert; bridge notification
- **Degraded:** Schedule remediation; increase monitoring frequency
- **Healthy:** Normal operations

---

## 🧪 Testing Architecture

### Test Pyramid

```
                    ┌─────────────┐
                    │   E2E /     │  ← Milestone integration (M10: 34 tests)
                    │ Integration │
           ┌────────┴─────────────┴────────┐
           │      Integration Tests        │  ← Cross-module flows (M2-M9: 10-35 each)
           │  (Event→Memory, Bridge→Gov)   │
    ┌────────┴─────────────────────────────┴────────┐
    │            Unit Tests                         │  ← Per-module (Foundation: 14)
    │  (Contracts, Policy, Checkpoint, Health)      │
    └───────────────────────────────────────────────┘
```

### Test Conventions (Pester v6)

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
}

Describe 'Module - Function' -Tag 'Unit' {
    It 'does something specific' {
        $result = FunctionName -Param 'value'
        $result | Should -Be 'expected'      # Not "Should Be"
    }
    
    It 'validates input' {
        { FunctionName -Param 'invalid' } | Should -Throw  # Not "Should Throw"
    }
}

Describe 'Integration - Cross-Module Flow' -Tag 'Integration' {
    BeforeEach { $cp = New-GuardianCheckpoint -Tier Emergency -Label "Test-$([guid]::NewGuid())" }
    AfterEach  { Restore-GuardianCheckpoint -Checkpoint $cp -Confirm:$false }
    
    It 'integrates with Guardian_Events' { ... }
}
```

### Quality Gates (Per Milestone)
| Gate | Command | Blocking |
|------|---------|----------|
| Syntax | `pwsh -c "Import-Module ./core/Guardian_*.ps1"` | ✅ |
| Unit | `Invoke-Pester tests/Guardian.Foundation.Tests.ps1` | ✅ |
| Milestone | `Invoke-Pester tests/Guardian.M<n>.Tests.ps1` | ✅ |
| Architecture | `Test-GuardianArchitectureDrift` | ✅ |
| Policy | `Test-GuardianPolicy` on changed files | ✅ |
| Checkpoint | `New-GuardianCheckpoint -Tier Milestone` | ✅ (Release) |

---

## 🔗 Related Documents

- [[Vision/VISION]] — Mission, principles, success metrics
- [[Roadmap/ROADMAP]] — Phased development plan
- [[Components/GOVERNANCE]] — Policy engine deep dive
- [[Components/CHECKPOINTS]] — Checkpoint system design
- [[Components/BRIDGE]] — Nexus98 communication contract
- [[Components/STORAGE]] — Storage intelligence & entropy
- [[Components/MEMORY]] — Memory intelligence & patterns
- [[Components/REMEDIATION]] — Controlled remediation design
- [[ADR/ADR-001]] — Separation of concerns (Guardian ≠ Nexus98)
- [[ADR/ADR-002]] — Pester 6 migration
- [[ADR/ADR-003]] — Checkpoint-before-change pattern
- [[ADR/ADR-004]] — Bridge transport guarantees

---

*Architecture reflects M10 validated state. Changes require ADR and architecture review.*