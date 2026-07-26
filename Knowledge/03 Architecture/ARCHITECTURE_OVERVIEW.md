# System Architecture Overview

> **Authoritative system architecture for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Architecture
> **Phase:** 0
> **Milestone:** M10
> **Component:** Guardian_System
> **Related:** [[ARCHITECTURE_MOC]], [[COMPONENT_ARCHITECTURE]], [[DATA_ARCHITECTURE]], [[SECURITY_ARCHITECTURE]], [[ADR-001]], [[ADR-003]]
> **Created:** 2026-07-19
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Purpose

Nexus98 Guardian is the **operational supervisory intelligence layer** for the Nexus98 creation engine. It observes, evaluates, protects, and recovers Nexus98 — without ever becoming the system it protects.

---

## 2. Scope

| In Scope | Out of Scope |
|----------|--------------|
| Health monitoring & scoring | Code generation / build pipelines |
| Architecture drift detection | Feature development |
| Checkpoint / rollback system | Business logic |
| Event store & message bus | User-facing applications |
| Memory intelligence (short/long/pattern) | Database schema management |
| Storage classification & entropy remediation | External API integrations |
| Governance policy engine | Deployment execution |
| Nexus98 communication bridge (advisory only) | Infrastructure provisioning |

---

## 3. Major Components

### System Context

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
│  ┌──────────────┬──────────────┬────┴────────┬──────────────┬────────────┐  │
│  │   OBSERVE    │   EVALUATE   │  PROTECT    │  RECOVER     │  COMMUNICATE│ │
│  ├──────────────┼──────────────┼─────────────┼──────────────┼────────────┤  │
│  │ Health       │ Integrity    │ Checkpoint  │ Recovery     │ Bridge     │  │
│  │ Events       │ Drift        │ Rollback    │ Restore      │ Message Bus│  │
│  │ Memory       │ Storage      │ Remediation │ Verify       │ Contracts  │  │
│  │ Patterns     │ Entropy      │ Guard       │ Snapshots    │ In/Outbox  │  │
│  └──────────────┴──────────────┴─────────────┴──────────────┴────────────┘  │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │ GOVERNED BRIDGE (JSONL)
                                  │ GUARDIAN_TO_NEXUS98: Advisory only
                                  │ NEXUS98_TO_GUARDIAN: Validated intake
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          NEXUS98 (READ-ONLY TO GUARDIAN)                     │
│              Creation Engine • Build • Deploy • Execute                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Module Taxonomy (33 Modules)

| Layer | Modules | Count |
|-------|---------|-------|
| **Foundation (M0)** | Env, Loader, Contracts, Governance, Audit, Health, Checkpoint, Integrity, Recovery | 9 |
| **Observability & Intelligence (M2–M3)** | Events, StorageIntelligence, Memory, Patterns, Observability, Explanation | 6 |
| **Operations & Remediation (M4–M5)** | Resource, Agents, Security, ActionPlanning, Remediation, GovernanceIntegration | 6 |
| **Communication (M6–M8)** | Comms, Bridge, DriftGuard, StorageRules, EntropyRemediation, Operations | 6 |
| **Documentation (Scribe)** | Scribe_Core, Scribe_Roadmap, Scribe_TOC, Scribe_Status, Scribe_History, Scribe_Sync, Scribe | 7 |

---

## 4. Data Flow Architecture

### Bootstrap Sequence
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

### Mutation Flow (Any State Change)
```
Request Mutation
    │
    ▼
Test-GuardianPolicy -Action $action -Context $context
    │
    ├─► DENY ──► Block + Audit + Explanation
    │
    ├─► ALLOW ──► New-GuardianCheckpoint -Tier Emergency
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

### Drift Detection Flow
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
         ▼
    Test-GuardianPolicy -Action "remediate_drift" -Context $drift
         │
         ▼
    Governed Remediation (Plan → Checkpoint → Execute → Verify → Rollback)
```

### Entropy Remediation Flow (M9)
```
Get-GuardianStorageEntropy (sampled)
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

## 5. Communication Architecture

### Guardian ↔ Nexus98 Bridge

```
┌──────────────────┐     JSONL (GUARDIAN_TO_NEXUS98)      ┌──────────────────┐
│    GUARDIAN      │ ─────────────────────────────────────► │     NEXUS98      │
│   (Outbox)       │  • GUARDIAN_HEALTH_REPORT              │    (Inbox)       │
│                  │  • GUARDIAN_EXPLANATION                │                  │
│                  │  • GUARDIAN_ALERT                      │                  │
└──────────────────┘                                         └────────┬─────────┘
        ▲                                                               │
        │                                                               ▼
        │ JSONL (NEXUS98_TO_GUARDIAN)                    ┌──────────────────┐
        │  • NEXUS98_TASK_CONTEXT                ┌────────┤  VALIDATION GATE │
        │  • NEXUS98_COMMAND                     │        │  Schema + Perms  │
        │  • NEXUS98_QUERY                       │        └────────┬─────────┘
        └────────────────────────────────────────┘                 │
                                                                     ▼
                                                          ┌──────────────────┐
                                                          │  GOVERNANCE GATE │
                                                          │ Test-GuardianPolicy│
                                                          └────────┬─────────┘
                                                                   │
                                               ┌───────────────────┼───────────────────┐
                                               ▼                   ▼                   ▼
                                          ALLOW               DENY              APPROVAL
                                         Execute           Block + Audit     Queue + Notify
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

## 6. Security Architecture

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

### RBAC Model (Planned M13)

| Role | Permissions | Scope |
|------|-------------|-------|
| **Operator** | Read health, view audit, request remediation | Assigned nodes |
| **Engineer** | Operator + approve remediation, modify policy | Assigned nodes |
| **Admin** | Engineer + manage checkpoints, configure bridge | All nodes |
| **Auditor** | Read-only: audit, health, compliance reports | All nodes |
| **System** | Automated: write events, create checkpoints, execute approved plans | Local node only |

---

## 7. Failure Domains & Isolation

| Domain | Isolation Mechanism |
|--------|---------------------|
| **Module Load** | Try/Catch per module; continue on non-critical failure |
| **Event Processing** | Independent runspaces per consumer |
| **Checkpoint I/O** | Separate tiered directories; no cross-tier dependencies |
| **Bridge Transport** | Inbox/outbox queues; retry with backoff; dead-letter archive |
| **Remediation** | Dry-run mandatory; manifest-backed rollback |

---

## 8. Health Scoring Model

### Composite Score (0–100)
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
| **Storage** | > 80% | 60–80% | < 60% |
| **Memory** | > 70% coverage | 40–70% | < 40% |
| **Recovery** | CP < 2h old | 2–24h | > 24h or integrity fail |
| **Events** | No backlog, rotation OK | Backlog < 1000 | Backlog > 1000 or rotation failed |
| **Checkpoints** | All tiers current | Rolling > 4h old | Any tier missing |

### Health Actions
- **Critical:** Auto-create emergency checkpoint; alert; bridge notification
- **Degraded:** Schedule remediation; increase monitoring frequency
- **Healthy:** Normal operations

---

## 9. Scalability Limits (Current)

| Dimension | Current Limit | Bottleneck | Mitigation |
|-----------|---------------|------------|------------|
| Event ingestion | ~500/s | JSONL append | Batch writes, async |
| Checkpoint create | ~30s | File copy | Incremental, parallel |
| Storage scan | ~5min/100k files | Recursive enumeration | Sampling, indexing |
| Memory entries | ~10k | JSONL search | Pattern compression, indexing |
| Bridge messages | ~100/s | File polling | Event-driven (M12) |

---

## 10. Related Documents

- [[ARCHITECTURE_MOC]] — Navigation hub
- [[COMPONENT_ARCHITECTURE]] — Component deep-dive
- [[DATA_ARCHITECTURE]] — Storage, state, config, logs
- [[SECURITY_ARCHITECTURE]] — Threat model, RBAC, secrets
- [[ADR-001]] — Separation of concerns (Guardian ≠ Nexus98)
- [[ADR-003]] — Checkpoint-before-change pattern
- [[BRIDGE_ARCHITECTURE]] — Communication deep-dive
- [[HEALTH_SCORING]] — Health model details

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial architecture documentation from M10 validated state |

---