# Release Management Framework

> **Versioning, release process, branching, and deployment for Nexus98 Guardian.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, release, versioning, deployment
> **Related:** [[ROADMAP]], [[BRANCH_STRATEGY]], [[CI_CD_PIPELINE]], [[DEPLOYMENT_GUIDE]], [[CHANGELOG_FORMAT]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Versioning Strategy

### 1.1 Semantic Versioning (SemVer 2.0)
```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

Examples:
  1.0.0           # Stable release
  1.1.0           # Backward-compatible feature
  1.0.1           # Backward-compatible fix
  2.0.0           # Breaking change
  1.2.0-rc.1      # Release candidate
  1.2.0-beta.3    # Beta
  1.2.0-alpha.1   # Alpha (internal)
```

### 1.2 Version Increment Rules

| Change Type | Version Bump | Example |
|-------------|--------------|---------|
| Breaking API change | MAJOR | 1.0.0 → 2.0.0 |
| New feature (backward-compatible) | MINOR | 1.0.0 → 1.1.0 |
| Bug fix (backward-compatible) | PATCH | 1.0.0 → 1.0.1 |
| Security fix | PATCH (+ advisory) | 1.0.0 → 1.0.1 |
| Pre-release | Label + build | 1.1.0-rc.1 |

### 1.3 Pre-Release Labels
| Label | Meaning | Stability |
|-------|---------|-----------|
| `alpha` | Internal testing only | Unstable |
| `beta` | External preview, feature complete | May have bugs |
| `rc` | Release candidate, feature freeze | Near-stable |
| *(none)* | Stable release | Production-ready |

---

## 2. Release Types

| Type | Branch | Trigger | Audience | Testing |
|------|--------|---------|----------|---------|
| **Major** | `release/vX.0` | Architecture shift | All | Full suite + migration test |
| **Minor** | `release/vX.Y` | Feature complete | All | Full suite |
| **Patch** | `release/vX.Y` / hotfix | Bug/security fix | All | Affected area + regression |
| **RC** | `release/vX.Y` | Feature freeze | Early adopters | Full suite + soak |
| **Beta** | `feature/*` | Feature preview | Opt-in | Integration only |
| **Alpha** | `main` (nightly) | Continuous | Internal | Smoke only |

---

## 3. Branching Model

### 3.1 Branch Structure
```
main                    # Protected, always deployable (alpha)
  │
  ├── release/v1.0      # Release branch (minor/patch)
  │     ├── hotfix/v1.0.1
  │     └── hotfix/v1.0.2
  │
  ├── release/v1.1      # Next minor
  │     ├── feature/new-module
  │     └── feature/bridge-upgrade
  │
  └── feature/*         # Feature branches (short-lived)
        ├── feature/plugin-sdk
        └── feature/linux-support
```

### 3.2 Branch Policies

| Branch | Protection | Merge Policy | Deploy |
|--------|------------|--------------|--------|
| `main` | Required reviews (2), CI passing, linear history | Squash merge | Alpha (auto) |
| `release/vX.Y` | Required reviews (2), CI passing, signed commits | Squash or merge commit | Stable (manual) |
| `release/vX.0` (major) | Required reviews (3), CI passing, architecture review | Merge commit | Stable (manual) |
| `hotfix/*` | Required reviews (1), CI passing | Squash merge | Stable (immediate) |
| `feature/*` | CI passing | Squash merge | None |

---

## 4. Release Process

### 4.1 Pre-Release (Milestone Completion)
```bash
# 1. Verify all exit criteria
Test-GuardianArchitectureDrift          # 0 drift
./tests/run_foundation_tests.ps1        # 14/14
Invoke-Pester tests/Guardian.M<n>.Tests.ps1  # All milestone tests

# 2. Create milestone checkpoint
New-GuardianCheckpoint -Tier Milestone -Label "Release vX.Y.Z"

# 3. Verify checkpoint
Test-GuardianCheckpointIntegrity -CheckpointId CK_XXXXXX

# 4. Update version
# Edit config/guardian_runtime_config.json: "version": "X.Y.Z"
```

### 4.2 Release Creation
```bash
# 1. Create release branch
git checkout -b release/vX.Y main

# 2. Update version in code
# config/guardian_runtime_config.json → "version": "X.Y.Z"

# 3. Update CHANGELOG.md (see format below)

# 4. Commit
git add config/guardian_runtime_config.json CHANGELOG.md
git commit -m "chore(release): vX.Y.Z"

# 4. Tag (signed)
git tag -s vX.Y.Z -m "Release vX.Y.Z"

# 5. Push
git push origin release/vX.Y
git push origin vX.Y.Z
```

### 4.3 Post-Release
```bash
# 1. Create GitHub Release with notes from CHANGELOG.md
# 2. Merge release branch → main
git checkout main
git merge --no-ff release/vX.Y
git push origin main

# 3. Deploy to staging → verify health
# 4. Deploy to production → verify health
# 5. Monitor 24h for regressions
```

### 4.4 Hotfix Process
```bash
# 1. Branch from release tag
git checkout -b hotfix/vX.Y.Z+1 vX.Y.Z

# 2. Apply minimal fix + test

# 3. Bump PATCH version
# config/guardian_runtime_config.json → "version": "X.Y.Z+1"

# 4. Commit, tag, push
git commit -am "fix: description"
git tag -s vX.Y.Z+1 -m "Hotfix vX.Y.Z+1"
git push origin hotfix/vX.Y.Z+1
git push origin vX.Y.Z+1

# 5. Merge to release branch and main
git checkout release/vX.Y
git merge hotfix/vX.Y.Z+1
git checkout main
git merge release/vX.Y
```

---

## 5. Changelog Format

### 5.1 Keep a Changelog (v1.1.0)
Location: `CHANGELOG.md` at repo root

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Modified behavior description

### Deprecated
- Deprecated feature with alternative

### Removed
- Removed feature description

### Fixed
- Bug fix description

### Security
- Security fix description

## [X.Y.Z-1] - YYYY-MM-DD
...
```

### 5.2 Categories
| Category | Purpose |
|----------|---------|
| `Added` | New features |
| `Changed` | Changes in existing functionality |
| `Deprecated` | Soon-to-be removed features |
| `Removed` | Removed features |
| `Fixed` | Bug fixes |
| `Security` | Vulnerability fixes |

---

## 6. Release Artifacts

| Artifact | Location | Purpose |
|----------|----------|---------|
| **Source Tag** | `git tag vX.Y.Z` | Immutable reference |
| **Release Notes** | `Knowledge/20 Releases/RELEASE_vX.Y.Z.md` | Human-readable summary |
| **Module Package** | `dist/Guardian-X.Y.Z.zip` | Distribution |
| **SBOM** | `dist/sbom-vX.Y.Z.json` | Supply chain transparency |
| **Checkpoint** | `data/checkpoints/milestones/CK_XXXXXX` | Rollback anchor |
| **Checksums** | `dist/SHA256SUMS` | Integrity verification |

---

## 7. Migration Procedures

### 7.1 Breaking Changes (Major)
1. **Document** in `UPGRADE_vX.md`
2. **Provide** migration script if possible
3. **Maintain** previous major for 2 minor cycles
4. **Communicate** 30 days advance notice

### 7.2 Configuration Migration
- New version reads old config
- Missing keys → defaults (logged)
- Deprecated keys → warning logged, ignored
- Write migrated config atomically

### 7.3 Checkpoint Compatibility
- Checkpoints are **forward-compatible only**
- Restore to same or newer Guardian version
- `Test-GuardianCheckpointIntegrity` validates before restore

---

## 8. Release Checklist

```markdown
# Release vX.Y.Z Checklist

## Pre-Release
- [ ] All milestone tests passing
- [ ] Architecture drift: CLEAN
- [ ] Policy compliance: 100%
- [ ] Performance within 10% baseline
- [ ] Security scan: no critical
- [ ] Documentation synced
- [ ] Version bumped in config
- [ ] CHANGELOG.md updated
- [ ] Milestone checkpoint created & verified

## Release Creation
- [ ] Release branch created
- [ ] Signed tag pushed
- [ ] GitHub Release created with notes
- [ ] Release notes published to `Knowledge/20 Releases/`

## Post-Release
- [ ] Release branch merged to main
- [ ] Deployed to staging → health verified
- [ ] Deployed to production → health verified
- [ ] 24h monitoring for regressions
- [ ] Team retrospective scheduled
- [ ] Roadmap updated (milestone → DONE)
- [ ] Knowledge vault MOCs updated
```

---

## 9. Rollback Procedures

| Scenario | Procedure |
|----------|-----------|
| **Post-deploy regression** | `Restore-GuardianCheckpoint -CheckpointId CK_MILESTONE_LAST` |
| **Config corruption** | Restore config from milestone checkpoint |
| **Module failure** | Disable module via config, restart |
| **Bridge failure** | `Set-GuardianBridgeEnabled -Enabled $false` |

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial release framework from M10 validated state |

---