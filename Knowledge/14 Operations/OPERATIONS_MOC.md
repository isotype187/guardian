# Operations MOC (Map of Content)

> **Navigation hub for runbooks, monitoring, maintenance, and troubleshooting.**

---

## 🏃 Runbooks

| Runbook | Purpose | Trigger |
|---------|---------|---------|
| [[RUNBOOK_HEALTH]] | Health check procedures, score interpretation | Scheduled / Alert |
| [[RUNBOOK_CHECKPOINT]] | Create,POINT]] | Create, list, verify, restore checkpoints | Scheduled / On-demand |
| [[RUNBOOK_REMEDIATION]] | Safe remediation execution, dry-run, rollback | Policy alert / Manual |
| [[RUNBOOK_BRIDGE]] | Bridge monitoring, message flow, DLQ processing | Scheduled / Alert |
| [[RUNBOOK_STORAGE]] | Entropy scans, deduplication, archive rotation | Scheduled / Alert |
| [[RUNBOOK_DRIFT]] | Architecture drift detection, classification, remediation | On-load / Scheduled |
| [[RUNBOOK_RECOVERY]] | Emergency restore, milestone rollback, disaster recovery | Incident |

---

## 📊 Monitoring

| Document | Purpose |
|----------|---------|
| [[MONITORING_OVERVIEW]] | Health scores, component thresholds, alerting rules |
| [[ALERT_CATALOG]] | All alerts: name, severity, runbook, escalation |
| [[DASHBOARDS]] | Grafana/PowerBI/Console dashboard definitions |
| [[SLI_SLO]] | Service Level Indicators / Objectives |

### Key Health Thresholds

| Component | Healthy | Degraded | Critical |
|-----------|---------|----------|----------|
| **Runtime** | All critical loaded | 1+ optional failed | Critical missing |
| **Storage** | > 80% | 60–80% | < 60% |
| **Memory** | > 70% coverage | 40–70% | < 40% |
| **Recovery** | CP < 2h old | 2–24h | > 24h or integrity fail |
| **Events** | No backlog, rotation OK | Backlog < 1000 | Backlog > 1000 or rotation failed |
| **Checkpoints** | All tiers current | Rolling > 4h | Any tier missing |

---

## 🔧 Maintenance

| Task | Frequency | Automation |
|------|-----------|------------|
| Rolling checkpoint | Hourly | ✅ `New-GuardianCheckpoint -Tier Rolling` |
| Event rotation (30d retention) | Daily 02:00 | ✅ `Invoke-GuardianEventRotation -KeepDays 30` |
| Storage health scan | Daily 03:00 | ✅ `Get-GuardianStorageHealth` + baseline |
| Memory lifecycle | Daily 04:00 | ✅ `Invoke-GuardianMemoryLifecycle` |
| Pattern detection | 6-hourly | ✅ `Get-GuardianPatterns` |
| Health report → Bridge | 15-min | ✅ `New-GuardianToNexus98HealthReport` |
| Drift check | On load + Daily | ✅ `Test-GuardianArchitectureDrift` |
| Entropy scan | Weekly | ✅ `Get-GuardianStorageEntropy` |
| Bridge dispatch | 30-sec | ✅ `Invoke-GuardianBridgeDispatch` |

---

## 🔧 Troubleshooting

| Guide | Common Issues |
|-------|---------------|
| [[TROUBLESHOOTING_GUIDE]] | Module load failures, bridge stalls, checkpoint corruption |
| [[DEBUGGING]] | PowerShell debugging, runspace inspection, audit log analysis |
| [[PERFORMANCE_TUNING]] | Slow checkpoints, event backlog, memory growth |

---

## 🚨 Incident Response

| Severity | Response Time | Escalation |
|----------|---------------|------------|
| **Critical** (system down, data loss) | 15 min | Page → Engineer → Lead |
| **High** (degraded, bridge down) | 1 hour | Alert → Engineer |
| **Medium** (warning, drift detected) | 4 hours | Ticket → Next business day |
| **Low** (info, entropy growth) | Next sprint | Backlog |

---

## 📋 Operational Checklists

### Daily
- [ ] Health score > 80%
- [ ] No critical alerts
- [ ] Bridge message flow healthy
- [ ] Checkpoint tiers current

### Weekly
- [ ] Entropy scan reviewed
- [ ] Drift scan clean
- [ ] Audit log integrity verified
- [ ] Backup/restore test (sample)

### Monthly
- [ ] Full disaster recovery drill
- [ ] Secret rotation (if manual)
- [ ] Dependency vulnerability scan
- [ ] Capacity planning review

---

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[ARCHITECTURE_MOC]] — Component operational details
- [[TESTING_MOC]] — Chaos testing, resilience validation
- [[SECURITY_MOC]] — Security operations, incident response
- [[RELEASE_MOC]] — Deployment operations

---

*Operations is where architecture meets reality. Automate everything.*