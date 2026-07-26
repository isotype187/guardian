# Release MOC (Map of Content)

> **Navigation hub for release management, versioning, and deployment.**

---

## 📦 Release Framework

| Document | Purpose |
|----------|---------|
| [[RELEASE_FRAMEWORK]] | Versioning strategy, release types, branching, migration procedures |
| [[VERSIONING_STRATEGY]] | Major.Minor.Patch, pre-release labels, breaking change policy |
| [[RELEASE_PROCESS]] | Checklist: tests → checkpoint → docs → tag → publish → verify |
| [[CHANGELOG_FORMAT]] | Keep a Changelog format, categories, migration notes |

---

## 🏷️ Versioning Scheme

```
Major.Minor.Patch[-label[.build]]

Examples:
  1.0.0           # Stable release
  1.1.0           # Minor: backward-compatible features
  1.0.1           # Patch: backward-compatible fixes
  2.0.0           # Major: breaking changes
  1.2.0-rc.1      # Release candidate
  1.2.0-beta.3    # Beta
  1.2.0-alpha.1   # Alpha (internal)
```

### Version Increment Rules
| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Breaking API change | Major | 1.0.0 → 2.0.0 |
| New feature (backward-compatible) | Minor | 1.0.0 → 1.1.0 |
| Bug fix (backward-compatible) | Patch | 1.0.0 → 1.0.1 |
| Security fix | Patch (+ advisory) | 1.0.0 → 1.0.1 |
| Pre-release | Label + build | 1.1.0-rc.1 |

---

## 🚀 Release Types

| Type | Branch | Trigger | Audience | Testing |
|------|--------|---------|----------|---------|
| **Major** | `release/vX.0` | Architecture shift | All | Full suite + migration test |
| **Minor** | `release/vX.Y` | Feature complete | All | Full suite |
| **Patch** | `release/vX.Y` / hotfix | Bug/security fix | All | Affected area + regression |
| **RC** | `release/vX.Y` | Feature freeze | Early adopters | Full suite + soak |
| **Beta** | `feature/*` | Feature preview | Opt-in | Integration only |
| **Alpha** | `main` (nightly) | Continuous | Internal | Smoke only |

---

## 📋 Release Checklist

### Pre-Release
- [ ] All milestone tests pass (214+)
- [ ] Architecture drift clean
- [ ] Policy compliance verified
- [ ] Performance benchmarks within 10% of baseline
- [ ] Security scan clean
- [ ] Documentation sync complete
- [ ] Changelog updated

### Release Creation
- [ ] Create release branch: `release/vX.Y`
- [ ] Update version in `config/guardian_runtime_config.json`
- [ ] Create milestone checkpoint: `New-GuardianCheckpoint -Tier Milestone -Label "Release vX.Y.Z"`
- [ ] Tag: `git tag -s vX.Y.Z -m "Release vX.Y.Z"`
- [ ] Push tag: `git push origin vX.Y.Z`

### Post-Release
- [ ] Publish release notes
- [ ] Update `Knowledge/20 Releases/RELEASE_vX.Y.Z.md`
- [ ] Merge release branch → `main`
- [ ] Deploy to staging → verify health
- [ ] Deploy to production → verify health
- [ ] Monitor 24h for regressions

---

## 🔄 Hotfix Procedure

1. Branch from release tag: `git checkout -b hotfix/vX.Y.Z+1 vX.Y.Z`
2. Apply minimal fix + test
3. Bump patch version
4. Tag: `vX.Y.Z+1`
5. Merge to `main` and active `release/vX.Y`
6. Deploy

---

## 📚 Release History

| Version | Date | Milestone | Type | Notes |
|---------|------|-----------|------|-------|
| 0.1.0 | 2026-07-19 | M0 | Alpha | Foundation & Governance |
| 0.2.0 | 2026-07-21 | M2 | Alpha | Event + Storage Intelligence |
| 0.3.0 | 2026-07-22 | M3 | Alpha | Memory + Observability |
| 0.4.0 | 2026-07-23 | M4 | Alpha | Resource/Agent/Security |
| 0.5.0 | 2026-07-23 | M5 | Alpha | Controlled Remediation |
| 0.6.0 | 2026-07-24 | M6 | Alpha | Communication Layer |
| 0.7.0 | 2026-07-24 | M7 | Beta | Self-Development Guard |
| 0.8.0 | 2026-07-25 | M8 | Beta | Governed Bridge Loop |
| 0.9.0 | 2026-07-25 | M9 | Beta | Entropy Remediation |
| **1.0.0** | **2026-07-26** | **M10** | **GA** | **Operations Complete** |

---

## 📦 Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| Release Notes | `Knowledge/20 Releases/RELEASE_vX.Y.Z.md` | Human-readable summary |
| Changelog | `CHANGELOG.md` | Machine + human history |
| Module Package | `dist/Guardian-X.Y.Z.zip` | Distribution |
| SBOM | `dist/sbom-vX.Y.Z.json` | Supply chain transparency |
| Checkpoint | `data/checkpoints/milestones/CK_XXXXXX` | Rollback anchor |

---

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[ROADMAP_MOC]] — Milestone → Release mapping
- [[DEVELOPMENT_MOC]] — Branch strategy, commit standards
- [[CI_CD_MOC]] — Pipeline automation
- [[DEPLOYMENT_MOC]] — Install, upgrade procedures
- [[OPERATIONS_MOC]] — Post-release monitoring

---

*Release discipline enables velocity. Automate the checklist.*