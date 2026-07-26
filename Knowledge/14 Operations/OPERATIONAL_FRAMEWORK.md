# Operational Framework

> **Installation, configuration, operations, maintenance, and troubleshooting for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, operations, runbook, monitoring, maintenance
> **Related:** [[OPERATIONS_MOC]], [[ARCHITECTURE_OVERVIEW]], [[DATA_ARCHITECTURE]], [[SECURITY_ARCHITECTURE]], [[RELEASE_FRAMEWORK]], [[RUNBOOKS]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Installation

### 1.1 Prerequisites
| Requirement | Version | Notes |
|-------------|---------|-------|
| PowerShell | 7.4+ | Cross-platform (Core) |
| .NET Runtime | 8.0 LTS | Required by PowerShell 7.4+ |
| Git | 2.40+ | For version control |
| Pester | 6.x | Test framework (installed via module) |

### 1.2 Quick Install
```powershell
# 1. Clone repository
git clone <repo-url> D:\Nexus98_Guardian
cd D:\Nexus98_Guardian

# 2. Initialize Guardian
. .\core\Guardian_Loader.ps1
Import-Guardian

# 3. Verify installation
Get-GuardianHealthReport
Test-GuardianArchitectureDrift

# 4. Run foundation tests
.\tests\run_foundation_tests.ps1
```

### 1.3 Directory Structure Created
```
D:\Nexus98_Guardian\
├── config/                 # Runtime config (git-ignored)
├── data/
│   ├── checkpoints/        # 4-tier checkpoint system
│   ├── events/             # JSONL event store
│   ├── memory/             # Short/long/pattern memory
│   ├── ops/                # Operational state
│   └── remediation/        # Quarantine + manifests
├── logs/
│   └── guardian_audit.jsonl
├── snapshots/
│   └── communication/      # Bridge message bus
├── plugins/                # Future: plugin SDK
└── tests/                  # Pester test suites
```

### 1.4 Configuration
Edit `config/guardian_runtime_config.json`:
```json
{
  "core": { "logLevel": "Info", "parallelism": 4 },
  "checkpoints": { "rollingIntervalHours": 1, "rollingRetentionHours": 72 },
  "events": { "retentionDays": 30, "maxSizeMB": 500 },
  "memory": { "shortTermDays": 7, "longTermDays": 365 },
  "bridge": { "enabled": true, "pollIntervalSeconds": 30 }
}
```

---

## 2. Configuration Management

### 2.1 Configuration Layers
| Layer | Source | Precedence |
|-------|--------|------------|
| Default | Embedded in modules | 1 (lowest) |
| System | `/etc/guardian/` (Linux) / `HKLM` (Windows) | 2 |
| User | `config/guardian_runtime_config.json` | 3 |
| Session | `GUARDIAN_*` env vars | 4 |
| Runtime | `Set-GuardianConfig` | 5 (highest) |

### 2.2 Key Configuration Files
| File | Purpose | Managed By |
|------|---------|------------|
| `guardian_runtime_config.json` | Tunable parameters | Admin |
| `guardian_architecture_baseline.json` | Drift detection baseline | Auto (DriftGuard) |
| `guardian_state.json` | Runtime state | Auto (Operations) |
| `policy_packs/*.json` | Governance policies | Admin |

---

## 3. Runbooks

### 3.1 Health Monitoring
**Runbook:** `RUNBOOK_HEALTH`
- **Trigger:** Scheduled (15 min) / Alert / Manual
- **Command:** `Get-GuardianHealthReport`
- **Thresholds:**
  - Overall < 70% → Alert
  - Any component Critical → Page
- **Output:** Health score, component breakdown, recommendations

### 3.2 Checkpoint Operations
**Runbook:** `RUNBOOK_CHECKPOINT_CREATE`
- **Trigger:** Scheduled (hourly) / Pre-mutation / Manual
- **Command:** `New-GuardianCheckpoint -Tier Rolling -Label "Scheduled"`
- **Verification:** `Test-GuardianCheckpointIntegrity -CheckpointId $id`

**Runbook:** `RUNBOOK_CHECKPOINT_RESTORE`
- **Trigger:** Incident / Regression / Manual
- **Steps:**
  1. List checkpoints: `Get-GuardianCheckpoint -Tier Milestone`
  2. Verify: `Test-GuardianCheckpointIntegrity -CheckpointId $target`
  3. Safety checkpoint: `New-GuardianCheckpoint -Tier Emergency -Label "Pre-restore"`
  4. Restore: `Restore-GuardianCheckpoint -CheckpointId $target -Confirm`
  5. Verify: `Get-GuardianHealthReport`

### 3.3 Remediation Operations
**Runbook:** `RUNBOOK_REMEDIATION_PLAN`
- **Trigger:** Entropy alert / Storage health < 60% / Manual
- **Command:** `Get-GuardianStorageEntropy -SamplePercent 10`

**Runbook:** `RUNBOOK_REMEDIATION_EXECUTE`
- **Prerequisite:** Approved plan from `New-GuardianRemediationPlan`
- **Steps:**
  1. Dry-run: `Invoke-GuardianRemediation -Plan $plan -DryRun`
  2. Review manifest + impact
  3. Execute: `Invoke-GuardianRemediation -Plan $plan`
  4. Verify: `Get-GuardianRemediationMetrics`
  5. Rollback if needed: `Undo-GuardianRemediation -ManifestId $id`

### 3.4 Bridge Operations
**Runbook:** `RUNBOOK_BRIDGE_STATUS`
- **Command:** `Get-GuardianBridgeStatus`
- **Checks:** Inbox/outbox depth, DLQ size, retry rate, last dispatch

**Runbook:** `RUNBOOK_BRIDGE_DISPATCH`
- **Schedule:** Every 30 seconds
- **Command:** `Invoke-GuardianBridgeDispatch`
- **Monitoring:** Dispatch latency, success rate, DLQ growth

**Runbook:** `RUNBOOK_BRIDGE_RECOVERY`
- **Trigger:** DLQ growth > 100 / Dispatch failure rate > 10%
- **Steps:** Inspect `failed/`, replay from `processing/`, check Nexus98 health

### 3.5 Storage Operations
**Runbook:** `RUNBOOK_STORAGE_HEALTH`
- **Command:** `Get-GuardianStorageHealth`
- **Thresholds:** Overall < 60% → Alert; Duplicate risk > 25% → Schedule dedup

**Runbook:** `RUNBOOK_ENTROPY_SCAN`
- **Schedule:** Weekly
- **Command:** `Get-GuardianStorageEntropy -SamplePercent 10`
- **Output:** Entropy items, categories, recommended actions

**Runbook:** `RUNBOOK_DRIFT_DETECTION`
- **Triggers:** On load / Daily / Manual
- **Command:** `Test-GuardianArchitectureDrift`
- **Response:** Classify drift → Policy gate → Governed remediation

---

## 4. Monitoring & Alerting

### 4.1 Key Metrics

| Metric | Source | Healthy | Degraded | Critical | Alert |
|--------|--------|---------|----------|----------|-------|
| Overall Health | `Guardian_Health` | > 80% | 60-80% | < 60% | ✅ |
| Checkpoint Age (rolling) | `Guardian_Checkpoint` | < 2h | 2-4h | > 4h | ✅ |
| Event Backlog | `Guardian_Events` | 0 | < 1000 | > 1000 | ✅ |
| Bridge Dispatch Latency | `Guardian_Bridge` | < 5s | 5-30s | > 30s | ✅ |
| DLQ Size | `Guardian_Bridge` | 0 | < 10 | > 10 | ✅ |
| Storage Health | `Guardian_StorageIntelligence` | > 80% | 60-80% | < 60% | ✅ |
| Memory Coverage | `Guardian_Memory` | > 70% | 40-70% | < 40% | ✅ |

### 4.2 Alert Channels
| Severity | Channel | Escalation |
|----------|---------|------------|
| **Critical** | Page → Engineer → Lead | 15 min |
| **Warning** | Slack/Email → Engineer | 1 hour |
| **Info** | Log only | Daily digest |

### 4.3 Dashboard Panels (Target)
- **Overview:** Health score, component status, active alerts
- **Checkpoints:** Tier status, ages, sizes, rotation
- **Events:** Ingestion rate, backlog, categories, severities
- **Bridge:** Message flow, latency, retries, DLQ
- **Storage:** Health trend, entropy, duplicates, growth
- **Memory:** Entries by category, compression ratio, patterns
- **Resources:** CPU, memory, disk, process count

---

## 5. Maintenance Procedures

### 5.1 Scheduled Maintenance

| Task | Frequency | Automation | Runbook |
|------|-----------|------------|---------|
| Rolling checkpoint | Hourly | ✅ `New-GuardianCheckpoint -Tier Rolling` | RUNBOOK_CHECKPOINT_CREATE |
| Event rotation (30d) | Daily 02:00 | ✅ `Invoke-GuardianEventRotation -KeepDays 30` | — |
| Storage health scan | Daily 03:00 | ✅ `Get-GuardianStorageHealth` + baseline | RUNBOOK_STORAGE_HEALTH |
| Memory lifecycle | Daily 04:00 | ✅ `Invoke-GuardianMemoryLifecycle` | — |
| Pattern detection | 6-hourly | ✅ `Get-GuardianPatterns` | — |
| Health report → Bridge | 15-min | ✅ `New-GuardianToNexus98HealthReport` | — |
| Drift check | On load + Daily | ✅ `Test-GuardianArchitectureDrift` | RUNBOOK_DRIFT_DETECTION |
| Entropy scan | Weekly | ✅ `Get-GuardianStorageEntropy -SamplePercent 10` | RUNBOOK_ENTROPY_SCAN |
| Bridge dispatch | 30-sec | ✅ `Invoke-GuardianBridgeDispatch` | RUNBOOK_BRIDGE_DISPATCH |

### 5.2 Monthly
- [ ] Full disaster recovery drill (restore from milestone checkpoint)
- [ ] Secret rotation (if manual)
- [ ] Dependency vulnerability scan
- [ ] Capacity planning review (storage growth, event volume)
- [ ] Documentation currency review

### 5.3 Quarterly
- [ ] Architecture review (drift, debt, risks)
- [ ] Security audit (RBAC, secrets, audit log integrity)
- [ ] Performance baseline recalibration
- [ ] Runbook accuracy validation
- [ ] Team knowledge transfer

---

## 6. Backup & Recovery

### 6.1 What Gets Backed Up
| Data | Method | Frequency | Retention |
|------|--------|-----------|-----------|
| Milestone checkpoints | Included in tier | Per milestone | Forever |
| Audit log | Checkpointed | Per checkpoint | 7 years |
| Configuration | Config files in checkpoints | Per checkpoint | 7 years |
| Bridge messages | Checkpointed | Per checkpoint | 30 days |

### 6.2 Recovery Procedures

| Scenario | RTO | RPO | Procedure |
|----------|-----|-----|-----------|
| **Single module failure** | < 5 min | 0 | Disable module, restart Guardian |
| **Config corruption** | < 15 min | 0 | Restore config from latest checkpoint |
| **Checkpoint corruption** | < 30 min | < 1h | Use prior tier (Rolling → Emergency → Milestone) |
| **Full system loss** | < 2 hours | < 24h | Reinstall → Restore from milestone checkpoint → Verify health |
| **Bridge message loss** | < 1 hour | < 30 min | Replay from `processing/` + `completed/`; check Nexus98 |

### 6.3 Disaster Recovery Drill (Monthly)
```powershell
# 1. Simulate config loss
Remove-Item config/guardian_runtime_config.json

# 2. Restore from latest milestone
$cp = Get-GuardianCheckpoint -Tier Milestone -Latest
Restore-GuardianCheckpoint -CheckpointId $cp.CheckpointId -Confirm:$false

# 3. Verify
Get-GuardianHealthReport
Test-GuardianArchitectureDrift
```

---

## 7. Troubleshooting

### 7.1 Common Issues

| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
| `Import-Guardian` fails | Syntax error in module | Check `Import-Module ./core/Guardian_*.ps1` for error |
| Health score drops suddenly | Checkpoint rotation failed | Check `data/checkpoints/rolling/` permissions |
| Bridge messages stuck | Schema validation failure | Check `snapshots/communication/failed/` for details |
| Drift detected on load | Manual file edit outside Guardian | Run `Test-GuardianArchitectureDrift` to classify → remediate |
| Remediation fails | Permission denied on target | Check ACL on `data/remediation/quarantine/` |
| Memory growth unbounded | Lifecycle not running | Verify `Invoke-GuardianMemoryLifecycle` in scheduler |

### 7.2 Debugging Commands
```powershell
# Module load diagnostics
. .\core\Guardian_Loader.ps1
Import-Guardian -Verbose

# Architecture drift details
$drift = Get-GuardianDrift
$drift | Format-Table type, path, severity

# Bridge queue inspection
Get-ChildItem snapshots/communication/inbox/
Get-ChildItem snapshots/communication/failed/

# Audit log search
Get-GuardianAuditTrail -Filter @{Actor='Guardian_Remediation'; Since='2026-07-26'}

# Checkpoint verification
Test-GuardianCheckpointIntegrity -CheckpointId CK_20260726_140000_abc123
```

---

## 8. Security Operations

### 8.1 Security Runbooks
- **RUNBOOK_SECRET_ROTATION** — M11+
- **RUNBOOK_INCIDENT_RESPONSE** — Security-specific
- **RUNBOOK_VULNERABILITY_PATCH** — Dependency updates

### 8.2 Audit Log Review
- **Daily:** `Get-GuardianAuditTrail -Severity Critical,Error`
- **Weekly:** Policy decision review (`DELAYED`, `BLOCK`, `REQUIRE_REVIEW`)
- **Monthly:** Full audit integrity check (`Test-GuardianAuditIntegrity` - M13+)

---

## 9. Capacity Planning

### 9.1 Growth Projections (Current)
| Resource | Current | Monthly Growth | 12-Month Projection |
|----------|---------|----------------|---------------------|
| Event Store | ~50 MB | +10 MB | ~170 MB |
| Checkpoints (Rolling) | ~200 MB | +50 MB | ~800 MB |
| Checkpoints (Milestone) | ~50 MB/release | +50 MB/release | Linear |
| Audit Log | ~10 MB | +5 MB | ~70 MB |
| Memory Store | ~5 MB | +2 MB | ~29 MB |
| Bridge Messages | ~5 MB | +2 MB | ~29 MB |

### 9.2 Scaling Triggers
| Metric | Threshold | Action |
|--------|-----------|--------|
| Event store > 500 MB | Archive older events | Increase rotation frequency |
| Checkpoint storage > 5 GB | Archive old tiers | Increase archive tier frequency |
| Audit log > 1 GB | Compress + cold storage | Implement log rotation |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial operational framework from M10 validated state |

---