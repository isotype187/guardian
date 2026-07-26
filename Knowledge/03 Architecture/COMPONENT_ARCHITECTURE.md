# Component Architecture

> **Component-level architecture specifications for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Architecture
> **Phase:** 0-2
> **Component:** Guardian_Components
> **Related:** [[ARCHITECTURE_OVERVIEW]], [[DATA_ARCHITECTURE]], [[SECURITY_ARCHITECTURE]], [[ADR-001]], [[ADR-003]]
> **Created:** 2026-07-19
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Foundation Layer (M0 — Complete)

### Guardian_Env
| Aspect | Details |
|--------|---------|
| **Responsibility** | Single source of truth for all filesystem paths; directory initialization |
| **Public API** | `$GuardianEnv` hashtable; `Initialize-GuardianEnvironment` |
| **State** | None (pure path resolution) |
| **Dependencies** | None |
| **Failure Modes** | Path resolution failure → hard error; dir creation failure → hard error |
| **Testing** | Unit: path resolution; Integration: dir creation |

### Guardian_Loader
| Aspect | Details |
|--------|---------|
| **Responsibility** | Module bootstrap; DAG-based dependency resolution; topological load order |
| **Public API** | `Import-Guardian`; `$GuardianLoaderModules`; `Get-GuardianModuleHealth` |
| **State** | `$GuardianLoadedModules` (global) |
| **Dependencies** | Guardian_Env (paths) |
| **Failure Modes** | Circular dependency → hard error; missing critical module → hard error; syntax error → log + continue (non-critical) / hard error (critical) |
| **Testing** | Unit: DAG sort; Integration: full load + health check |

### Guardian_Contracts
| Aspect | Details |
|--------|---------|
| **Responsibility** | Structured message types for all public APIs; JSON serialization |
| **Public API** | 15+ constructor functions: `New-GuardianHealthMessage`, `New-GuardianSystemEvent`, `New-GuardianTaskRequest`, `New-GuardianResponse`, `New-GuardianToNexus98HealthReport`, `New-Nexus98ToGuardianTaskContext`, etc. |
| **Types** | Hashtables with `type` discriminator; `@odata.type` for JSON |
| **Dependencies** | None |
| **Failure Modes** | Invalid parameters → validation error; serialization failure → audit + throw |
| **Testing** | Unit: all constructors; Integration: round-trip JSON |

### Guardian_Governance
| Aspect | Details |
|--------|---------|
| **Responsibility** | Risk tier definitions; policy evaluation engine; decision gates |
| **Public API** | `Test-GuardianPolicy`; `$GuardianRiskTiers` |
| **Decision Values** | `ALLOW`, `ALLOW_WITH_MONITORING`, `REQUIRE_CHECKPOINT`, `REQUIRE_REVIEW`, `BLOCK`, `DELAYED` |
| **Risk Tiers** | `low`, `medium`, `high`, `critical` |
| **Dependencies** | Guardian_Contracts (response types), Guardian_Audit |
| **Failure Modes** | Policy evaluation error → `BLOCK` + audit |
| **Testing** | Unit: all tier/decision combinations (4 tests) |

### Guardian_Audit
| Aspect | Details |
|--------|---------|
| **Responsibility** | Append-only audit trail; JSONL format |
| **Public API** | `Write-GuardianAudit`; `Get-GuardianAuditTrail`; `Export-GuardianAudit` |
| **State** | `logs/guardian_audit.jsonl` |
| **Record Schema** | `timestamp`, `auditId`, `actor`, `action`, `target`, `decision`, `policyId`, `riskTier`, `checkpointId`, `explanationRef`, `result`, `durationMs` |
| **Dependencies** | Guardian_Contracts, Guardian_Env (log path) |
| **Failure Modes** | Write failure → throw (audit is mandatory) |
| **Testing** | Unit: append + retrieve count |

### Guardian_Health
| Aspect | Details |
|--------|---------|
| **Responsibility** | Composite health scoring; subsystem coverage |
| **Public API** | `Get-GuardianHealthScore`; `Get-GuardianCoverage`; `Get-GuardianHealthReport` |
| **Scoring** | Runtime(20%) + Storage(20%) + Memory(15%) + Recovery(20%) + Events(10%) + Checkpoints(15%) |
| **Dependencies** | Guardian_Env, Guardian_StorageIntelligence, Guardian_Memory, Guardian_Checkpoint, Guardian_Events |
| **Failure Modes** | Subsystem unavailable → degraded score |
| **Testing** | Unit: score calculation; Integration: full report |

### Guardian_Checkpoint
| Aspect | Details |
|--------|---------|
| **Responsibility** | 4-tier checkpoint system with rotation |
| **Public API** | `New-GuardianCheckpoint`; `Get-GuardianCheckpoint`; `Restore-GuardianCheckpoint`; `Test-GuardianCheckpointIntegrity`; `Invoke-GuardianCheckpointRotation` |
| **Tiers** | `rolling` (hourly, 72h), `milestones` (per release, ∞), `emergency` (pre-risk, 30d), `archive` (monthly, 7yr) |
| **State** | `data/checkpoints/{tier}/CK_{id}/` with manifest (SHA256 per file) |
| **Dependencies** | Guardian_Env, Guardian_Audit, Guardian_Contracts |
| **Failure Modes** | Integrity failure → block restore + alert; disk full → rotation alert |
| **Testing** | Unit: create/retrieve/verify; Integration: restore + verify |

### Guardian_Integrity
| Aspect | Details |
|--------|---------|
| **Responsibility** | Architecture drift detection; storage entropy detection |
| **Public API** | `Get-GuardianIntegrityEvents`; `Test-GuardianArchitectureDrift`; `Get-GuardianStorageEntropy` |
| **Drift Classes** | `NEW_UNAPPROVED_DIRECTORY`, `NEW_UNAPPROVED_MODULE`, `CONFIGURATION_DRIFT`, `UNCONTROLLED_ARTIFACT`, `MODULE_MODIFIED`, `STRUCTURAL_DRIFT` |
| **Dependencies** | Guardian_Env, Guardian_StorageIntelligence |
| **Failure Modes** | Scan timeout → partial results + warning |
| **Testing** | Unit: drift classification; Integration: baseline compare |

### Guardian_Recovery
| Aspect | Details |
|--------|---------|
| **Responsibility** | Emergency snapshot; rollback levels |
| **Public API** | `New-GuardianEmergencySnapshot`; `Get-GuardianRecoveryLevels`; `Invoke-GuardianRollback` |
| **Dependencies** | Guardian_Checkpoint, Guardian_Audit |
| **Failure Modes** | No valid checkpoint → `BLOCK` + audit |
| **Testing** | Integration: emergency snapshot + rollback |

---

## 2. Observability & Intelligence Layer (M2–M3 — Complete)

### Guardian_Events
| Aspect | Details |
|--------|---------|
| **Responsibility** | Persistent event store + event bus (JSONL) |
| **Public API** | `New-GuardianEvent`; `Write-GuardianEvent`; `Get-GuardianEvents`; `Get-GuardianEventDuplicates`; `Invoke-GuardianEventRotation` |
| **Categories** | `SYSTEM`, `GOVERNANCE`, `SECURITY`, `STORAGE`, `RECOVERY`, `COMMUNICATION`, `REMEDIATION` |
| **Severities** | `INFO`, `WARNING`, `ERROR`, `CRITICAL` |
| **State** | `data/events/guardian_events.jsonl` + `archive/` |
| **Dedup** | 60-min window by source+category+description |
| **Rotation** | KeepDays configurable (default 30) |
| **Dependencies** | Guardian_Contracts, Guardian_Audit, Guardian_Env |
| **Testing** | 25 tests: model, storage, filtering, dedup, rotation |

### Guardian_StorageIntelligence
| Aspect | Details |
|--------|---------|
| **Responsibility** | Artifact classification; storage health; drift/duplicate/growth analysis |
| **Public API** | `Get-GuardianArtifactClass`; `Get-GuardianStorageHealth`; `Get-GuardianNestedDrift`; `Get-GuardianDuplicateGroups`; `Save-GuardianStorageBaseline`; `Get-GuardianStorageGrowth` |
| **Classifications** | `ACTIVE`, `OBSOLETE`, `ARCHIVE`, `UNKNOWN` |
| **Health Components** | DirectoryStructure(25%), DuplicateRisk(25%), GrowthControl(25%), ArtifactHygiene(25%) |
| **Dependencies** | Guardian_Env, Guardian_Events, Guardian_Audit |
| **Testing** | 16 tests: classification, health, scanning, growth |

### Guardian_Memory
| Aspect | Details |
|--------|---------|
| **Responsibility** | Short-term (7d), long-term (365d), pattern memory with lifecycle |
| **Public API** | `New-GuardianMemory`; `Write-GuardianMemory`; `Get-GuardianMemory`; `Search-GuardianMemory`; `Get-GuardianMemorySummary`; `Invoke-GuardianMemoryLifecycle`; `Compress-GuardianMemory` |
| **Categories** | `short_term`, `long_term`, `pattern` |
| **Importance** | `low`, `medium`, `high`, `critical` |
| **Retention Classes** | `ACTIVE`, `ARCHIVED`, `EXPIRED` |
| **Dependencies** | Guardian_Events (event→memory flow), Guardian_Audit |
| **Testing** | 12 tests: creation, retrieval, lifecycle, compression |

### Guardian_Patterns
| Aspect | Details |
|--------|---------|
| **Responsibility** | Pattern recognition from events/memory; recommendations |
| **Public API** | `Get-GuardianPatterns` |
| **Algorithm** | Frequency analysis (min occurrences configurable) |
| **Output** | Pattern objects with `recommendation` text |
| **Dependencies** | Guardian_Events, Guardian_Memory |
| **Testing** | 4 tests: detection, recommendation emission |

### Guardian_Observability
| Aspect | Details |
|--------|---------|
| **Responsibility** | Unified observability model aggregating all subsystems |
| **Public API** | `Get-GuardianObservability` |
| **Output** | `health`, `storage`, `memory`, `checkpoints`, `events`, `overallPct` |
| **Dependencies** | All health-providing modules |
| **Testing** | 4 tests: model composition, component presence |

### Guardian_Explanation
| Aspect | Details |
|--------|---------|
| **Responsibility** | WHAT/WHY/EVIDENCE/IMPACT/REC explanation engine |
| **Public API** | `Get-GuardianStorageExplanation`; `Get-GuardianDecisionExplanation`; `Export-GuardianExplanation` |
| **Format** | Structured: `what`, `why`, `evidence`, `impact`, `recommendation` |
| **Dependencies** | Guardian_StorageIntelligence, Guardian_Governance, Guardian_Contracts |
| **Testing** | 5 tests: storage explanation, decision explanation, serialization |

---

## 3. Operations & Remediation Layer (M4–M5 — Complete)

### Guardian_Resource
| Aspect | Details |
|--------|---------|
| **Responsibility** | CPU/memory/disk sampling; runaway detection; anomaly events |
| **Public API** | `Get-GuardianResourceSample`; `Get-GuardianResourceHealth`; `Start-GuardianResourceMonitor`; `Stop-GuardianResourceMonitor` |
| **Metrics** | CPU %, Memory MB, Disk %, Process count |
| **Anomaly** | Threshold-based + rate-of-change |
| **Dependencies** | Guardian_Events (anomaly events), Guardian_Audit |
| **Testing** | 7 tests: sampling, health, anomalies |

### Guardian_Agents
| Aspect | Details |
|--------|---------|
| **Responsibility** | Agent registry; supervision; health reporting |
| **Public API** | `Register-GuardianAgent`; `Get-GuardianAgent`; `Get-GuardianAgentHealth`; `Invoke-GuardianAgentAction` |
| **Agent Types** | `internal`, `external`, `plugin` |
| **Supervision** | Heartbeat monitoring; restart policy |
| **Dependencies** | Guardian_Events, Guardian_Audit, Guardian_Health |
| **Testing** | 6 tests: registry, health, supervision |

### Guardian_Security
| Aspect | Details |
|--------|---------|
| **Responsibility** | Config/permission change monitoring; security events |
| **Public API** | `Get-GuardianSecurityBaseline`; `Test-GuardianSecurityDrift`; `Get-GuardianSecurityEvents` |
| **Monitors** | File permissions, config file hashes, sensitive path access |
| **Dependencies** | Guardian_Events, Guardian_Audit, Guardian_Integrity |
| **Testing** | 6 tests: baseline, drift, events |

### Guardian_ActionPlanning
| Aspect | Details |
|--------|---------|
| **Responsibility** | Remediation plan builder (move-only, dry-run default) |
| **Public API** | `New-GuardianRemediationPlan`; `Get-GuardianRemediationPlan`; `Test-GuardianRemediationPlan` |
| **Plan Structure** | Actions array: `move`, `archive`, `quarantine`; manifest; impact estimate |
| **Dependencies** | Guardian_StorageIntelligence, Guardian_Governance |
| **Testing** | 3 tests: plan creation, validation, dry-run |

### Guardian_Remediation
| Aspect | Details |
|--------|---------|
| **Responsibility** | Controlled remediation executor with manifest rollback |
| **Public API** | `Invoke-GuardianRemediation`; `Undo-GuardianRemediation`; `Get-GuardianRemediationMetrics` |
| **Execution** | Dry-run default; checkpoint before execute; manifest per action |
| **Rollback** | `Undo-GuardianRemediation` uses manifest to restore |
| **Dependencies** | Guardian_Checkpoint, Guardian_Governance, Guardian_Audit, Guardian_ActionPlanning |
| **Testing** | 3 tests: execution, rollback, metrics |

### Guardian_GovernanceIntegration
| Aspect | Details |
|--------|---------|
| **Responsibility** | Decision → memory integration; policy outcome recording |
| **Public API** | `Record-GuardianGovernanceDecision`; `Get-GuardianGovernanceHistory` |
| **Dependencies** | Guardian_Governance, Guardian_Memory, Guardian_Audit |
| **Testing** | 2 tests: recording, retrieval |

---

## 4. Communication Layer (M6–M8 — Complete)

### Guardian_Comms
| Aspect | Details |
|--------|---------|
| **Responsibility** | JSONL outbox/inbox persistence; modulation helpers |
| **Public API** | `Write-GuardianOutbox`; `Read-GuardianInbox`; `New-GuardianToNexus98HealthReport`; `New-GuardianToNexus98Explanation` |
| **State** | `snapshots/communication/outbox/`, `inbox/` |
| **Dependencies** | Guardian_Contracts, Guardian_Env |
| **Testing** | 3 tests: persistence, modulation, contracts |

### Guardian_Bridge
| Aspect | Details |
|--------|---------|
| **Responsibility** | Governed runtime message bus: dispatcher, dedup, security, governance, retry, health |
| **Public API** | `Invoke-GuardianBridgeDispatch`; `Set-GuardianBridgeEnabled`; `Get-GuardianBridgeStatus`; `Get-GuardianBridgeMetrics` |
| **Queues** | `inbox/`, `outbox/`, `processing/`, `completed/`, `failed/`, `archive/` |
| **Security** | Schema validation, sender auth, permission check |
| **Governance** | `Test-GuardianPolicy` on every inbound command |
| **Retry** | Exponential backoff (max 5), dead-letter to `failed/` |
| **Dependencies** | Guardian_Comms, Guardian_Governance, Guardian_Audit, Guardian_Events, Guardian_Memory, Guardian_Health |
| **Testing** | 18 tests: transport, security, recovery, integration, observability, disable-safety |

### Guardian_DriftGuard
| Aspect | Details |
|--------|---------|
| **Responsibility** | Architecture baseline; 6-class drift detection; change governance chain; 6-lock self-mod guard; storage governance |
| **Public API** | `New-GuardianArchitectureBaseline`; `Save-GuardianArchitectureBaseline`; `Get-GuardianArchitectureBaseline`; `Get-GuardianDrift`; `Test-GuardianChangeGovernance`; `Test-GuardianSelfModification`; `New-GuardianSelfModificationCheckpoint`; `Invoke-GuardianDriftGuard`; `Get-GuardianStorageGovernance` |
| **Protected Surfaces** | `Guardian Core`, `Bridge`, `Checkpoint`, `Governance`, `Storage` |
| **Self-Mod Locks** | EmergencyCheckpoint, ChangeProposal, ImpactAnalysis, AutomatedTests, HealthComparison, RollbackAvailable |
| **Storage Governance Rules** | `UNCONTROLLED_SNAPSHOTS`, `BACKUP_MULTIPLICATION`, `ABANDONED_REPORTS`, `DUPLICATE_ARTIFACTS`, `NESTED_COPIES` |
| **Dependencies** | Guardian_Env, Guardian_Checkpoint, Guardian_Governance, Guardian_Integrity, Guardian_StorageIntelligence, Guardian_Audit |
| **Testing** | 17 tests: baseline, allowed changes, drift detection, governance, self-mod, rollback, storage governance, orchestrator |

### Guardian_StorageRules
| Aspect | Details |
|--------|---------|
| **Responsibility** | M1 hygiene rules wired into storage intelligence |
| **Rules** | 8 rules: SR-001 through SR-008 (classification, retention, cleanup) |
| **Dependencies** | Guardian_StorageIntelligence, Guardian_Env |
| **Testing** | Integrated in M2 storage tests |

### Guardian_EntropyRemediation
| Aspect | Details |
|--------|---------|
| **Responsibility** | M9 entropy analysis + governed remediation |
| **Public API** | `Get-GuardianStorageEntropy`; `New-GuardianRemediationPlan`; `Invoke-GuardianRemediation`; `Undo-GuardianRemediation`; `Get-GuardianRemediationMetrics` |
| **Flow** | Sample → Plan (move-only) → Dry-run → Checkpoint → Policy Gate → Execute → Manifest → Verify → Metrics |
| **Dependencies** | Guardian_StorageIntelligence, Guardian_Checkpoint, Guardian_Governance, Guardian_Remediation, Guardian_Bridge (Nexus98 warning) |
| **Testing** | 10 tests: analysis, planning, execution, rollback, metrics |

### Guardian_Operations
| Aspect | Details |
|--------|---------|
| **Responsibility** | M10 full integration orchestration: scheduling, reporting, cross-cutting concerns |
| **Public API** | `Start-GuardianOperations`; `Stop-GuardianOperations`; `Get-GuardianOperationalStatus`; `Invoke-GuardianOperationalCycle` |
| **Scheduled Jobs** | Checkpoint rotation, event rotation, storage scan, memory lifecycle, pattern detection, health report, drift check, entropy scan, bridge dispatch |
| **Dependencies** | All preceding modules |
| **Testing** | 34 tests: scheduling, integration, reporting, health, drift, entropy |

---

## 5. Documentation Layer (Scribe — Complete)

### Nexus98_Scribe Modules
| Module | Responsibility |
|--------|----------------|
| `Nexus98_Scribe_Core` | Generation engine, template processing |
| `Nexus98_Scribe_Roadmap` | Roadmap document generation from milestone data |
| `Nexus98_Scribe_TOC` | Table of contents generation |
| `Nexus98_Scribe_Status` | Status report generation |
| `Nexus98_Scribe_History` | Milestone history generation |
| `Nexus98_Scribe_Sync` | Cross-repo synchronization |
| `Nexus98_Scribe` | Main entry point, orchestration |

---

## 6. Component Interaction Matrix

| From → To | Contracts | Governance | Audit | Checkpoint | Events | Memory | Bridge | DriftGuard |
|-----------|-----------|------------|-------|------------|--------|--------|--------|------------|
| **Loader** | ✅ | | | | | | | |
| **Env** | | | | | | | | |
| **Governance** | ✅ | | ✅ | | | | ✅ | ✅ |
| **Audit** | ✅ | | | | | | | |
| **Health** | ✅ | | | ✅ | ✅ | ✅ | | |
| **Checkpoint** | ✅ | ✅ | ✅ | | | | ✅ | |
| **Integrity** | ✅ | | | | ✅ | | | ✅ |
| **Recovery** | ✅ | ✅ | ✅ | ✅ | | | | |
| **Events** | ✅ | | ✅ | | | ✅ | | |
| **StorageIntel** | ✅ | | | | ✅ | | | ✅ |
| **Memory** | ✅ | | ✅ | | ✅ | | | |
| **Patterns** | ✅ | | | | ✅ | ✅ | | |
| **Observability** | ✅ | | | ✅ | ✅ | ✅ | | |
| **Explanation** | ✅ | ✅ | | | | | | |
| **Resource** | ✅ | | ✅ | | ✅ | | | |
| **Agents** | ✅ | | ✅ | | ✅ | | | |
| **Security** | ✅ | | ✅ | | ✅ | | | |
| **ActionPlanning** | ✅ | ✅ | ✅ | ✅ | | | | |
| **Remediation** | ✅ | ✅ | ✅ | ✅ | | | | |
| **GovIntegration** | ✅ | ✅ | ✅ | | | ✅ | | |
| **Comms** | ✅ | | | | | | ✅ | |
| **Bridge** | ✅ | ✅ | ✅ | | ✅ | ✅ | | |
| **DriftGuard** | ✅ | ✅ | ✅ | ✅ | | | | |
| **EntropyRemediation** | ✅ | ✅ | ✅ | ✅ | | | ✅ | |
| **Operations** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | |

---

## 7. Failure Modes by Component

| Component | Primary Failure Mode | Detection | Recovery |
|-----------|---------------------|-----------|----------|
| Loader | Circular dependency | Startup error | Fix DAG |
| Governance | Policy eval error | Audit `BLOCK` | Default deny |
| Checkpoint | Integrity failure | `Test-GuardianCheckpointIntegrity` | Use prior tier |
| Events | Disk full | Write failure alert | Rotation + alert |
| Bridge | Dispatch stall | Queue depth metric | Manual flush + investigate |
| DriftGuard | Baseline corruption | Load-time validation | Recreate from git |
| Remediation | Partial execution | Manifest mismatch | `Undo-GuardianRemediation` |
| Bridge Security | Schema bypass | Validation gate | Block + audit |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial component architecture from M10 validated state |

---