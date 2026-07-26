# Branch Strategy — Nexus98 Guardian

> **Git workflow for the Guardian project.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, git, branching
> **Related:** [[CODING_STANDARDS]], [[COMMIT_STANDARDS]], [[REVIEW_PROCESS]], [[RELEASE_FRAMEWORK]], [[ROADMAP]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Branch Hierarchy

```
main (protected)
  │
  ├── release/vX.Y (protected, long-lived)
  │     │
  │     ├── hotfix/vX.Y.Z-description (short-lived)
  │     │
  │     └── feature/description (from release branch)
  │
  ├── develop (protected, integration branch)
  │     │
  │     ├── feature/JIRA-123-description (short-lived)
  │     ├── bugfix/JIRA-456-description (short-lived)
  │     └── chore/JIRA-789-description (short-lived)
  │
  └── experiment/description (ad-hoc, no CI)
```

---

## 2. Branch Definitions

### `main` (Production)
- **Protection:** Required reviews (2), status checks, signed commits
- **Source of truth:** Only release branches and hotfixes merge here
- **Tags:** Every commit on `main` is a release candidate or release
- **Deploy:** Automatic to production (when implemented)

### `develop` (Integration)
- **Protection:** Required reviews (1), status checks
- **Purpose:** Integration branch for next release
- **Merges:** Feature, bugfix, chore branches merge here
- **CI:** Full test suite + architecture drift + policy compliance

### `release/vX.Y` (Release Preparation)
- **Created from:** `develop` at feature freeze
- **Protection:** Required reviews (2), status checks
- **Allowed commits:** Version bumps, release notes, critical bugfixes only
- **Merge target:** `main` (after validation) + backmerge to `develop`

### `hotfix/vX.Y.Z-description` (Production Fixes)
- **Created from:** `main` (at release tag)
- **Naming:** `hotfix/v1.2.3-fix-bridge-stall`
- **Merge targets:** `main` (immediate) + `develop` (backport)
- **CI:** Full test suite required

### `feature/JIRA-123-description` (New Capabilities)
- **Created from:** `develop`
- **Naming:** `feature/M11-ci-cd-pipeline`, `feature/M12-plugin-sdk`
- **Lifetime:** < 2 weeks ideal
- **Rebase:** Onto `develop` before PR
- **Merge:** Squash merge to `develop`

### `bugfix/JIRA-456-description` (Defect Fixes)
- **Created from:** `develop` (or `release/vX.Y` for release bugs)
- **Naming:** `bugfix/bridge-message-dedup`
- **Merge:** Squash merge to `develop`

### `chore/JIRA-789-description` (Maintenance)
- **Created from:** `develop`
- **Naming:** `chore/update-dependencies`, `chore/refactor-loader`
- **Merge:** Squash merge to `develop`

### `experiment/description` (Research/Spikes)
- **Created from:** `develop` or `main`
- **No CI required** (opt-in)
- **No merge to protected branches** without conversion to feature/bugfix
- **Lifetime:** < 1 week, then delete or convert

---

## 3. Commit Standards

### 3.1 Conventional Commits (Mandatory)

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types
| Type | Description | Triggers |
|------|-------------|----------|
| `feat` | New feature | Minor version bump |
| `fix` | Bug fix | Patch version bump |
| `docs` | Documentation only | — |
| `style` | Formatting, no logic change | — |
| `refactor` | Code restructure, no behavior change | — |
| `perf` | Performance improvement | Patch |
| `test` | Test additions/changes | — |
| `chore` | Build, deps, tooling | — |
| `ci` | CI/CD changes | — |
| `build` | Build system, packaging | — |
| `revert` | Reverts previous commit | — |

#### Scope
Module or component affected: `loader`, `bridge`, `checkpoint`, `policy`, `health`, `events`, `memory`, `storage`, `remediation`, `drift`, `operations`, `scribe`, `docs`, `tests`, `ci`, `deps`

#### Examples
```
feat(bridge): add message deduplication with 60-min window

Implements exactly-once semantics for inbox processing.

Closes #123
```

```
fix(checkpoint): resolve manifest corruption on concurrent create

Race condition when two emergency checkpoints created simultaneously.
Added file lock via Guardian_Lock utility.

Fixes #456
```

```
refactor(loader): extract DAG resolution to private module

No behavior change. Improves testability and enables circular dep detection.

Refs #789
```

---

### 3.2 Milestone Commits (Mandatory per Milestone)

```
milestone: M11 Core Hardening Complete

All M11 deliverables validated:
- CI/CD pipeline operational
- Secrets management integrated
- Contract testing in CI
- Structured logging framework
- Performance baselines established

Tests: 14 foundation + 25 M2 + 35 M3 + 28 M4 + 22 M5 + 11 M6 + 17 M7 + 18 M8 + 10 M9 + 34 M10 + 15 M11 = 229 passing
Architecture: drift-free
Policy: 100% gate coverage

Milestone checkpoint: CK_20260726_M11_COMPLETE
```

---

## 4. Workflow Procedures

### 4.1 Feature Development
```bash
# 1. Start from develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/M11-ci-cd-pipeline

# 3. Develop with frequent commits
git add -A
git commit -m "feat(ci): add GitHub Actions workflow skeleton"

# 4. Push and open PR
git push origin feature/M11-ci-cd-pipeline
# PR targets: develop
```

### 4.2 PR Requirements
- [ ] Targets correct branch (`develop` for features, `release/vX.Y` for release prep)
- [ ] Conventional commit messages (squashed on merge)
- [ ] All CI checks pass (syntax, unit, integration, arch drift, policy)
- [ ] Required reviewers approve (1 for `develop`, 2 for `release`/`main`)
- [ ] Documentation updated (code + docs in same PR)
- [ ] No merge conflicts

### 4.3 Release Process
```bash
# 1. Feature freeze - create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/v1.1
git push origin release/v1.1

# 2. Release preparation (on release branch)
# - Version bump in configs
# - Release notes generation
# - Critical bugfixes only

# 3. Release validation
# PR: release/v1.1 → main (2 reviewers, all checks)

# 4. Tag release on main
git checkout main
git pull origin main
git tag -s v1.1.0 -m "Release v1.1.0"
git push origin v1.1.0

# 5. Backmerge to develop
git checkout develop
git merge main --no-ff -m "chore: backmerge release v1.1.0"
git push origin develop

# 6. Cleanup
git branch -d release/v1.1
git push origin --delete release/v1.1
```

### 4.4 Hotfix Process
```bash
# 1. From main at release tag
git checkout main
git pull origin main --tags
git checkout -b hotfix/v1.1.1-fix-bridge-stall v1.1.0

# 2. Fix + test
git commit -m "fix(bridge): resolve stall under high load"

# 3. PR to main (fast-track)
# 4. Tag patch release
git tag -s v1.1.1 -m "Hotfix v1.1.1"
git push origin v1.1.1

# 5. Backport to develop
git checkout develop
git merge hotfix/v1.1.1-fix-bridge-stall --no-ff
git push origin develop
```

---

## 5. Branch Protection Rules

| Branch | Reviews | Status Checks | Signed Commits | Linear History |
|--------|---------|---------------|----------------|----------------|
| `main` | 2 | All CI | Required | Required |
| `release/*` | 2 | All CI | Required | Required |
| `develop` | 1 | All CI | Required | Required |
| `feature/*` | 0 | All CI | Optional | Optional |

### Required Status Checks (All Protected Branches)
- `syntax-check` — `Import-Module` all core modules
- `unit-tests` — Foundation + milestone unit tests
- `integration-tests` — Cross-module integration tests
- `architecture-drift` — `Test-GuardianArchitectureDrift`
- `policy-compliance` — `Test-GuardianPolicy` on changed files
- `doc-sync` — Documentation sync check

---

## 6. Versioning Strategy

### Semantic Versioning (SemVer 2.0)
```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

MAJOR — Breaking changes (ADR required)
MINOR — New features, backward compatible
PATCH — Bug fixes, backward compatible
PRERELEASE — alpha, beta, rc (e.g., 1.2.0-rc.1)
BUILD — Git commit hash (CI metadata)
```

### Version Sources
| Artifact | Version Source |
|----------|----------------|
| Git tag | `v1.2.3` |
| Module manifests | `ModuleVersion = '1.2.3'` |
| Release notes | `RELEASE_v1.2.3.md` |
| CI build | `1.2.3+abc1234` |

---

## 7. Repository Configuration

### `.gitignore` (Project Root)
```gitignore
# Runtime state
config/guardian_*.json
data/checkpoints/
data/events/
data/memory/
data/ops/
data/remediation/
logs/*.jsonl
snapshots/communication/

# IDE
.vscode/
.codex/
*.code-workspace

# OS
.DS_Store
Thumbs.db

# Secrets (never commit)
*.key
*.pem
*.pfx
.env
.secrets/

# Build artifacts
*.nupkg
*.snupkg
```

### `.gitattributes`
```gitattributes
*.ps1 text eol=lf
*.psd1 text eol=lf
*.psm1 text eol=lf
*.md text eol=lf
*.json text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
*.xml text eol=lf
```

---

## 8. Emergency Procedures

### Force Push to Protected Branch (Last Resort)
```bash
# Requires: Admin approval, documented in incident
git push origin main --force-with-lease
# Audit log entry mandatory
```

### Recover Deleted Branch
```bash
# Within 30 days (GitHub default)
git reflog
git checkout -b recovered-branch <commit-hash>
```

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial branch strategy from M10 validated workflow |

---