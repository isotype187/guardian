# Guardian Dashboard

**Status:** 🟢 **ACTIVE — All Systems Operational**  
**Last Updated:** 2026-07-26  
**Session:** M11+ Planning  

---

## 🏥 System Health (Live)

| Component | Status | Score | Last Check |
|-----------|--------|-------|------------|
| **Runtime** | 🟢 Healthy | 100% | 2026-07-26 |
| **Storage** | 🟢 Healthy | 87% | 2026-07-26 |
| **Memory** | 🟢 Healthy | 78% | 2026-07-26 |
| **Recovery** | 🟢 Healthy | 95% | 2026-07-26 |
| **Events** | 🟢 Healthy | 92% | 2026-07-26 |
| **Checkpoints** | 🟢 Healthy | 100% | 2026-07-26 |
| **Bridge** | 🟢 Healthy | 89% | 2026-07-26 |
| **Overall** | 🟢 **Healthy** | **91%** | **2026-07-26** |

> Run `Get-GuardianHealthReport` for live data

---

## ✅ Test Status

| Suite | Tests | Status | Last Run |
|-------|-------|--------|----------|
| Foundation (M0) | 14 | ✅ PASS | 2026-07-26 |
| M2 Event/Storage | 15 | ✅ PASS | 2026-07-25 |
| M3 Memory/Obs | 21 | ✅ PASS | 2026-07-25 |
| M4 Resource/Agent/Sec | 13 | ✅ PASS | 2026-07-25 |
| M5 Remediation/Gov | 11 | ✅ PASS | 2026-07-25 |
| M6 Communication | 11 | ✅ PASS | 2026-07-25 |
| M7 Self-Dev Guard | 17 | ✅ PASS | 2026-07-25 |
| M8 Governed Loop | 15 | ✅ PASS | 2026-07-25 |
| M9 Entropy Remediation | 10 | ✅ PASS | 2026-07-25 |
| M10 Operations | 34 | ✅ PASS | 2026-07-25 |
| **TOTAL** | **161+** | ✅ **ALL PASS** | — |

---

## 📦 Repository Status

| Metric | Value |
|--------|-------|
| **Git Root** | `vcs/.git` (worktree: project root) |
| **HEAD** | `2944740` (M10 sync complete) |
| **Working Tree** | Clean |
| **Branches** | `main` only |
| **Commits (this session)** | 2 (M8 fix, INDEX update) |
| **Core Modules** | 33 (loaded via `Guardian_Loader`) |
| **Test Files** | 10 milestone suites + foundation |

---

## 🎯 Current Focus

### Immediate (This Session)
- [ ] Complete Engineering Specification review
- [ ] Populate Knowledge Vault structure
- [ ] Define M11+ roadmap priorities
- [ ] Create ADR template and first ADRs

### Near Term (M11)
- [ ] Improve health scoring granularity
- [ ] Expand governance policy packs
- [ ] Add CI/CD pipeline integration
- [ ] Continue storage entropy reduction

### Strategic (M12+)
- [ ] Multi-node orchestration (Phase 6)
- [ ] API service layer (Phase 6)
- [ ] RBAC implementation (Phase 6)
- [ ] Plugin SDK v1 (Phase 4)

---

## 🔗 Quick Commands

```powershell
# Validate foundation
.\tests\run_foundation_tests.ps1

# Load Guardian
. .\core\Guardian_Loader.ps1
Import-Guardian

# Health check
Get-GuardianHealthReport

# Architecture drift check
Test-GuardianArchitectureDrift

# Storage entropy scan
Get-GuardianStorageEntropy

# Bridge status
Get-GuardianBridgeStatus

# Run milestone tests
Invoke-Pester .\tests\Guardian.M8.Tests.ps1
```

---

## 📋 Session Checklist

- [ ] Read latest session checkpoint
- [ ] Run foundation tests (14/14)
- [ ] Verify architecture baseline
- [ ] Check for uncommitted changes
- [ ] Review current roadmap priorities
- [ ] Update Knowledge Vault as needed
- [ ] Create session checkpoint at end

---

## ⚠️ Active Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Pester 6 scope isolation | 🟢 Resolved | Pattern documented in M8 session |
| Snapshot archive entropy (2.1 GB) | 🟡 Medium | M9 remediation active; continue weekly scans |
| No CI/CD pipeline | 🟡 Medium | M11 priority: GitHub Actions integration |
| macOS/Container support incomplete | 🟡 Medium | Phase 3 planning; architecture supports |
| Secrets management not implemented | 🟡 Medium | Phase 5: SecretManagement module integration |

---

## 📚 Key Links

| Document | Path |
|----------|------|
| Engineering Spec | `../docs/GUARDIAN_ENGINEERING_SPEC.md` |
| Architecture Map | `../docs/ARCHITECTURE_MAP.md` |
| Capability Report | `../docs/CAPABILITY_REPORT.md` |
| Roadmap | `../docs/ROADMAP.md` |
| Operating Rules | `../HERMES.md` |
| Knowledge Index | `./INDEX.md` |
| Session Checkpoints | `./Sessions/` |

---

*Dashboard auto-refreshed by Guardian Scribe. Manual updates welcome.*