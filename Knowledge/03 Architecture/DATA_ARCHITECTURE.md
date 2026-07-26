# Data Architecture

> **Data storage, state management, configuration, and information flow for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Architecture
> **Component:** Data_Architecture
> **Phase:** 0-2
> **Related:** [[ARCHITECTURE_OVERVIEW]], [[COMPONENT_ARCHITECTURE]], [[SECURITY_ARCHITECTURE]], [[CHECKPOINT_SYSTEM]], [[EVENT_STORE]], [[MEMORY_SYSTEM]], [[AUDIT_LOG]]
> **Created:** 2026-07-19
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Storage Topology

```
$GuardianEnv.Root
├── config/                              # Runtime configuration (git-ignored)
│   ├── guardian_state.json              # Primary runtime state
│   ├── guardian_architecture_baseline.json  # Drift detection baseline
│   ├── guardian_runtime_config.json     # Tunable parameters
│   └── policy_packs/                    # Governance policy packs (JSON)
│
├── data/                                # Operational data (checkpointed)
│   ├── checkpoints/                     # 4-tier checkpoint system
│   │   ├── rolling/                     # Hourly, 72h retention
│   │   ├── milestones/                  # Per-release, forever
│   │   ├── emergency/                   # Pre-risky-op, 30d
│   │   └── archive/                     # Monthly compaction, 7yr
│   ├── events/                          # JSONL event store
│   │   ├── guardian_events.jsonl        # Active event log
│   │   └── archive/                     # Rotated events (30d default)
│   ├── memory/                          # Memory intelligence stores
│   │   ├── short_term.jsonl             # 7-day retention
│   │   ├── long_term.jsonl              # 365-day retention
│   │   └── pattern.jsonl                # Compressed patterns
│   ├── ops/                             # Operational state
│   │   ├── operational_state.json       # Operations module state
│   │   ├── runtime_state.json           # Runtime state
│   │   └── scheduler_state.json         # Scheduler state
│   ├── remediation/                     # Remediation workspace
│   │   ├── quarantine/                  # Staged files (move-only)
│   │   └── manifest_*.json              # Rollback manifests
│   ├── resource_baseline.json           # Resource sampling baseline
│   ├── security_baseline.json           # Security monitoring baseline
│   └── storage_baseline.json            # Storage growth baseline
│
├── logs/                                # Immutable logs
│   └── guardian_audit.jsonl             # Append-only audit trail
│
├── snapshots/                           # Legacy archive (git-ignored, 2.1 GB)
│   ├── communication/                   # M8 governed message bus
│   │   ├── inbox/outbox/processing/completed/failed/archive/
│   │   └── data/remediation/
│   └── ... (3,411 historical snapshots)
│
└── plugins/                             # Future: plugin SDK
```

---

## 2. Data Classification & Retention

| Class | Retention | Backup | Encryption | Examples |
|-------|-----------|--------|------------|----------|
| **ACTIVE** | Indefinite | Every checkpoint | At rest | Core modules, config, checkpoints |
| **OBSOLETE** | 90 days | Checkpoint only | At rest | Old logs, rotated events |
| **ARCHIVE** | 7 years | Milestone only | At rest + transit | Milestone checkpoints, audit |
| **QUARANTINE** | 30 days | Emergency only | At rest + transit | Remediation staging, failed bridge msgs |
| **EPHEMERAL** | Session | None | Memory only | In-memory caches, runspace state |

---

## 3. Configuration Storage

### 3.1 Configuration Layers (Precedence Order)

| Layer | Source | Scope | Mutable |
|-------|--------|-------|---------|
| **Default** | Embedded in modules | System | No |
| **System** | `/etc/guardian/config.json` (Linux) / `HKLM` (Windows) | Machine | Admin |
| **User** | `$GuardianEnv.Config/guardian_state.json` | User | Yes |
| **Session** | `GUARDIAN_*` environment variables | Process | Yes |
| **Runtime** | `Set-GuardianConfig` | In-memory | Yes |

### 3.2 Key Configuration Files

#### `guardian_runtime_config.json`
```json
{
  "core": {
    "root": "",
    "logLevel": "Info",
    "parallelism": 4
  },
  "checkpoints": {
    "rollingIntervalHours": 1,
    "rollingRetentionHours": 72,
    "milestoneRetention": "forever",
    "emergencyRetentionDays": 30,
    "archiveRetentionYears": 7
  },
  "events": {
    "retentionDays": 30,
    "maxSizeMB": 500,
    "dedupWindowMinutes": 60
  },
  "memory": {
    "shortTermDays": 7,
    "longTermDays": 365,
    "patternMinOccurrences": 3
  },
  "storage": {
    "scanIntervalHours": 24,
    "duplicateThresholdBytes": 1024,
    "nestingDepthThreshold": 6
  },
  "bridge": {
    "enabled": true,
    "pollIntervalSeconds": 30,
    "maxRetries": 5
  },
  "governance": {
    "defaultRiskTier": "medium",
    "requireCheckpoint": true,
    "requireExplanation": true
  },
  "health": {
    "weights": {
      "runtime": 0.20,
      "storage": 0.20,
      "memory": 0.15,
      "recovery": 0.20,
      "events": 0.10,
      "checkpoints": 0.15
    }
  },
  "security": {
    "monitorConfigChanges": true,
    "monitorPermissions": true,
    "alertOnDrift": true
  }
}
```

#### `guardian_architecture_baseline.json`
```json
{
  "version": "1.0.0",
  "created": "2026-07-26T...",
  "approvedDirectories": ["core", "config", "data", "logs", "snapshots", "plugins", "scripts", "docs", "tests", "governance", "monitoring", "memory", "storage", "communication", "recovery", "archive"],
  "approvedModules": ["Guardian_Env.ps1", "Guardian_Loader.ps1", ...],
  "approvedDataLocations": ["data/checkpoints", "data/events", "data/memory", "data/ops", "data/remediation"],
  "approvedConfigFiles": ["guardian_state.json", "guardian_architecture_baseline.json", "guardian_runtime_config.json"],
  "approvedGeneratedArtifacts": ["*.jsonl", "*.json", "*.log"],
  "approvedTopLevelFiles": ["README.md", "HERMES.md", "PROJECT_INDEX.md"],
  "protectedSurfaces": ["Guardian Core", "Bridge", "Checkpoint", "Governance", "Storage"]
}
```

---

## 4. State Management

### 4.1 State Stores by Module

| Module | Store | Format | Consistency |
|--------|-------|--------|-------------|
| `Guardian_Env` | `$GuardianEnv` hashtable | In-memory | N/A |
| `Guardian_Loader` | `$GuardianLoadedModules` | In-memory | N/A |
| `Guardian_Governance` | Policy decisions | In-memory + Audit | Eventual |
| `Guardian_Audit` | `logs/guardian_audit.jsonl` | JSONL append-only | Sequential |
| `Guardian_Checkpoint` | `data/checkpoints/{tier}/` | Directory + manifest | Strong (immutable after write) |
| `Guardian_Events` | `data/events/guardian_events.jsonl` | JSONL | Sequential |
| `Guardian_Memory` | `data/memory/{short,long,pattern}.jsonl` | JSONL | Eventual |
| `Guardian_StorageIntelligence` | Baselines in `data/*.json` | JSON | Eventual |
| `Guardian_Resource` | In-memory samples + baseline | In-memory + JSON | Eventual |
| `Guardian_Bridge` | `snapshots/communication/{inbox,outbox,...}/` | JSONL | Sequential per queue |
| `Guardian_Remediation` | `data/remediation/quarantine/`, `manifest_*.json` | Files + JSON | Strong (transactional via checkpoint) |
| `Guardian_Operations` | `data/ops/*.json` | JSON | Eventual |

### 4.2 Concurrency Control

| Store | Mechanism |
|-------|-----------|
| Config files | File lock (`Guardian_Lock` utility) |
| Event store | Append-only; single writer per process |
| Checkpoints | Directory per checkpoint; atomic rename on commit |
| Memory | Single writer (memory manager); readers snapshot |
| Bridge queues | File-based queue; atomic move between directories |
| Remediation | Checkpoint gate ensures single execution |

---

## 5. Checkpoint System (Deep Dive)

### 5.1 Tier Definitions

| Tier | Trigger | Retention | Restore Target | Use Case |
|------|---------|-----------|----------------|----------|
| **Rolling** | Hourly timer | 72 hours | < 30 sec | Routine rollback |
| **Milestone** | Milestone gate | Forever | < 60 sec | Release rollback |
| **Emergency** | Pre-risky-op | 30 days | < 30 sec | Failed remediation |
| **Archive** | Monthly compaction | 7 years | < 5 min | Compliance, forensics |

### 5.2 Checkpoint Structure
```
data/checkpoints/{tier}/CK_{timestamp}_{guid}/
├── manifest.json              # SHA256 per file, metadata
├── core/                      # Core modules (copied)
├── config/                    # Config files (copied)
├── data/                      # Operational data (copied)
│   ├── checkpoints/           # Other tiers (referenced)
│   ├── events/                # Event store
│   ├── memory/                # Memory stores
│   └── ops/                   # Operational state
├── logs/                      # Audit log (copied)
└── plugins/                   # Plugin modules (if any)
```

### 5.3 Manifest Schema
```json
{
  "checkpointId": "CK_20260726_143000_abc123",
  "tier": "rolling",
  "created": "2026-07-26T14:30:00.000Z",
  "label": "Hourly rolling",
  "sizeBytes": 12451844,
  "fileCount": 342,
  "files": [
    { "path": "core/Guardian_Env.ps1", "sha256": "...", "size": 1696 },
    { "path": "config/guardian_state.json", "sha256": "...", "size": 2048 }
  ],
  "parentCheckpoint": "CK_20260726_133000_xyz789",
  "guardianVersion": "1.0.0"
}
```

### 5.4 Rotation Policies

| Tier | Rotation Trigger | Action |
|------|------------------|--------|
| Rolling | Count > 72 (1 per hour) | Delete oldest |
| Milestone | Never | Retain forever |
| Emergency | Age > 30 days | Delete |
| Archive | Monthly | Compress + cold storage |

---

## 6. Event Store (JSONL)

### 6.1 Event Schema
```json
{
  "event_id": "EV_abc123",
  "timestamp": "2026-07-26T14:30:00.000Z",
  "source": "Guardian_Remediation",
  "category": "REMEDIATION",
  "severity": "INFO",
  "description": "Remediation plan executed",
  "resolution_status": "resolved",
  "related_checkpoints": ["CK_20260726_143000_abc123"],
  "correlation_id": "CORR_xyz789",
  "payload": { "planId": "RP_...", "actions": 3 }
}
```

### 6.2 Categories & Severities
| Category | Description |
|----------|-------------|
| `SYSTEM` | Bootstrap, module load, health |
| `GOVERNANCE` | Policy decisions, approvals |
| `SECURITY` | Config/perm changes, auth |
| `STORAGE` | Scans, entropy, classification |
| `RECOVERY` | Checkpoints, rollbacks, snapshots |
| `COMMUNICATION` | Bridge messages, dispatch |
| `REMEDIATION` | Plans, execution, rollback |

| Severity | Use Case |
|----------|----------|
| `INFO` | Normal operations |
| `WARNING` | Degraded, policy delay |
| `ERROR` | Operation failed, auto-recovered |
| `CRITICAL` | Data loss risk, manual intervention |

### 6.3 Transport Guarantees
| Property | Guarantee | Mechanism |
|----------|-----------|-----------|
| Ordering | Per-source FIFO | Sequence numbers in JSONL |
| Deduplication | Exactly-once | Event ID + processed log |
| Retry | Exponential backoff (max 5) | Bridge dispatcher |
| Dead Letter | Failed → `failed/` | Max retries exceeded |
| Replay | From checkpoint + offset | `Get-GuardianEvents -SinceCheckpoint` |

---

## 7. Memory System

### 7.1 Memory Categories
| Category | Retention | Use Case |
|----------|-----------|----------|
| `short_term` | 7 days | Active warnings, transient state |
| `long_term` | 365 days | Milestone decisions, recovery notes |
| `pattern` | Indefinite (compressed) | Recurring patterns, recommendations |

### 7.2 Memory Entry Schema
```json
{
  "memory_id": "MEM_abc123",
  "source": "Guardian_DriftGuard",
  "category": "long_term",
  "importance": "high",
  "confidence": 0.95,
  "description": "Architecture drift blocked: unauthorized module added",
  "retention_class": "ACTIVE",
  "related_events": ["EV_abc123", "EV_def456"],
  "tags": ["drift", "governance", "blocked"],
  "created": "2026-07-26T14:30:00.000Z",
  "expires": "2027-07-26T14:30:00.000Z"
}
```

### 7.3 Lifecycle Operations
| Operation | Trigger | Action |
|-----------|---------|--------|
| Expiration | Daily 04:00 | `Invoke-GuardianMemoryLifecycle` moves expired to `ARCHIVED` |
| Compression | Daily 04:00 | `Compress-GuardianMemory` merges similar entries |
| Pattern Detection | 6-hourly | `Get-GuardianPatterns` emits recommendations |

---

## 8. Audit Log

### 8.1 Audit Entry Schema
```json
{
  "timestamp": "2026-07-26T14:30:00.123Z",
  "auditId": "AUD_abc123",
  "actor": "Guardian_Remediation",
  "action": "Invoke-GuardianRemediation",
  "target": "data/checkpoints/rolling/CK_20260726_140000",
  "decision": "ALLOWED",
  "policyId": "POL-REMEDIATION-003",
  "riskTier": "medium",
  "checkpointId": "CK_20260726_142500",
  "explanationRef": "EXP_xyz789",
  "result": "SUCCESS",
  "durationMs": 1250
}
```

### 8.2 Integrity (Planned M13)
- **Hash Chaining:** Each entry includes `prevHash = SHA256(previousEntry)`
- **Anchoring:** Periodic anchor to git commit hash
- **Verification:** `Test-GuardianAuditIntegrity` validates chain

### 8.3 Retention
- **Audit Log:** 7 years (ARCHIVE class)
- **Never rotated** — append-only
- **Archived** via milestone checkpoints

---

## 9. Bridge Message Store

### 9.1 Queue Structure
```
snapshots/communication/
├── inbox/                    # Nexus98 → Guardian
├── outbox/                   # Guardian → Nexus98
├── processing/               # Currently dispatching
├── completed/                # Successfully delivered
├── failed/                   # Max retries exceeded
└── archive/                  # Historical (30d)
```

### 9.2 Message Schema (All Types)
```json
{
  "type": "GUARDIAN_HEALTH_REPORT",
  "target": "Nexus98",
  "overallPct": 91,
  "health": {...},
  "storage": {...},
  "memory": {...},
  "checkpoints": {...},
  "timestamp": "2026-07-26T14:30:00.000Z"
}
```

### 9.3 Message Types
| Type | Direction | Purpose |
|------|-----------|---------|
| `GUARDIAN_HEALTH_REPORT` | G→N | Periodic status (15 min) |
| `GUARDIAN_EXPLANATION` | G→N | Decision rationale |
| `GUARDIAN_ALERT` | G→N | Anomaly notification |
| `NEXUS98_TASK_CONTEXT` | N→G | Work request |
| `NEXUS98_COMMAND` | N→G | Control request (validated) |
| `NEXUS98_QUERY` | N→G | Read-only inquiry |

---

## 10. Data Flow Summary

### 10.1 Write Paths
| Operation | Writer | Store | Gates |
|-----------|--------|-------|-------|
| Config change | Any module | `config/*.json` | Policy + checkpoint |
| Event emission | Any module | `data/events/*.jsonl` | None (append-only) |
| Checkpoint | `Guardian_Checkpoint` | `data/checkpoints/{tier}/` | Policy (emergency) |
| Memory write | `Guardian_Memory` | `data/memory/*.jsonl` | None |
| Audit write | `Guardian_Audit` | `logs/guardian_audit.jsonl` | None (mandatory) |
| Bridge send | `Guardian_Comms` | `snapshots/communication/outbox/` | Policy |
| Remediation | `Guardian_Remediation` | `data/remediation/` | Policy + checkpoint |

### 10.2 Read Paths
| Operation | Reader | Store | Cache |
|-----------|--------|-------|-------|
| Health report | `Guardian_Health` | All health subsystems | In-memory (15s TTL) |
| Drift detection | `Guardian_Integrity` | Filesystem + baseline | Baseline cached |
| Event query | `Guardian_Events` | `data/events/*.jsonl` | None (streaming) |
| Memory search | `Guardian_Memory` | `data/memory/*.jsonl` | In-memory index |
| Bridge receive | `Guardian_Bridge` | `snapshots/communication/inbox/` | Polling (30s) |
| Checkpoint restore | `Guardian_Checkpoint` | `data/checkpoints/{tier}/` | Manifest verified |

---

## 11. Migration & Upgrade Procedures

### 11.1 Configuration Migration
1. New version reads old `guardian_runtime_config.json`
2. Missing keys → defaults from new version
3. Deprecated keys → logged warning, ignored
4. Write migrated config atomically

### 11.2 Checkpoint Compatibility
- Checkpoints are **forward-compatible only**
- Restore to same or newer Guardian version
- `Test-GuardianCheckpointIntegrity` validates manifest before restore
- Schema changes require new checkpoint tier

### 11.3 Event Store Migration
- JSONL format is self-describing
- New fields added as optional
- Old readers ignore unknown fields
- No migration needed for additive changes

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial data architecture from M10 validated state |

---