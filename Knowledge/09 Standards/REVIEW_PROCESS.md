# Review Process — Nexus98 Guardian

> **Code review, documentation review, and approval standards.**
> **Version:** 1.0.0
> **Status:** Active
> **Type:** Standard
> **Scope:** Project
> **Tags:** standard, review, approval
> **Related:** [[CODING_STANDARDS]], [[BRANCH_STRATEGY]], [[COMMIT_STANDARDS]], [[DOCUMENTATION_STANDARDS]], [[TESTING_STANDARDS]], [[RELEASE_FRAMEWORK]]
> **Created:** 2026-07-26
> **Updated:** 2026-07-26
> **Owner:** Guardian Engineering Team
> **Review Date:** 2026-10-26

---

## 1. Code Review

### 1.1 When Review is Required
- **All PRs** to protected branches (`main`, `release/*`, `develop`)
- **Any mutation** of core modules (`core/Guardian_*.ps1`)
- **New modules** or public API changes
- **Architecture-affecting changes** (ADR scope)

### 1.2 Reviewer Requirements
| Target Branch | Minimum Reviewers | Required Expertise |
|---------------|-------------------|-------------------|
| `main` | 2 | 1 Lead Architect + 1 Module Owner |
| `release/*` | 2 | 1 Lead Architect + 1 Engineer |
| `develop` | 1 | Module Owner or Peer Engineer |

### 1.3 Review Checklist (Code)

#### Mandatory Gates (Auto-fail if missing)
- [ ] **Syntax Valid:** `Import-Module ./core/Guardian_*.ps1` succeeds
- [ ] **Unit Tests Pass:** `Invoke-Pester tests/Guardian.Foundation.Tests.ps1`
- [ ] **Milestone Tests Pass:** Relevant `Guardian.M<n>.Tests.ps1` (if touching milestone code)
- [ ] **Architecture Drift Clean:** `Test-GuardianArchitectureDrift` passes
- [ ] **Policy Compliance:** `Test-GuardianPolicy` on all mutated functions
- [ ] **Contract Testing:** JSON Schema validation on bridge messages (M11+)

#### Code Quality (Reviewer judgment)
- [ ] **Follows Coding Standards:** [[CODING_STANDARDS]] — naming, structure, error handling, logging
- [ ] **Policy Gate Present:** Every mutation calls `Test-GuardianPolicy`
- [ ] **Checkpoint Safety:** Every mutation creates emergency checkpoint before execute
- [ ] **Audit Trail:** Every mutation writes `Write-GuardianAudit`
- [ ] **No Hard-coded Paths:** Uses `$GuardianEnv` contracts
- [ ] **No Untyped Hashtables:** Public APIs use `Guardian_Contracts` types
- [ ] **Error Handling:** Try/catch with rollback, no silent swallowing
- [ ] **Documentation:** Comment-based help on all public functions
- [ ] **Test Coverage:** New functions have unit tests; integration tests for cross-module

#### Architecture (Reviewer judgment)
- [ ] **No Circular Dependencies:** Module DAG remains valid
- [ ] **Single Responsibility:** Module owns one domain
- [ ] **Interface Stability:** No breaking changes without ADR + version bump
- [ ] **Security:** No secrets, proper validation, least privilege

---

## 2. Documentation Review

### 2.1 When Review is Required
- **New ADR** — Architecture Review Board (2 architects)
- **New/Modified Component Spec** — Lead Architect + Module Owner
- **New/Modified Feature Spec** — Feature Owner + Lead Architect
- **Standard Changes** — Standards Owner + 1 Engineer
- **Architecture Doc Changes** — Lead Architect + 1 Engineer
- **Release Notes** — Release Manager + 1 Engineer

### 2.2 Documentation Review Checklist
- [ ] **Frontmatter Complete:** All required fields per [[DOCUMENTATION_STANDARDS]]
- [ ] **Wiki-links Valid:** All `[[LINKS]]` resolve
- [ ] **No Orphans:** Document linked from category MOC
- [ ] **Bidirectional:** If A links to B, B links back to A
- [ ] **Current:** Reflects implementation (not aspirational)
- [ ] **ADR References:** Architectural decisions linked
- [ ] **Change Log Updated:** Version, date, author, changes
- [ ] **Review Date Set:** Quarterly for standards/architecture/ADRs

---

## 3. Architecture Review

### 3.1 When Required
- **New ADR** (all)
- **New Component** (module group)
- **Breaking API Change** (major version)
- **Cross-cutting Concern** (security, observability, data)
- **Phase Gate** (end of each roadmap phase)

### 3.2 Architecture Review Board
- **Chair:** Lead Architect
- **Members:** Module Owners (rotating), Security Engineer, Operations Engineer
- **Quorum:** 3 (including Chair)

### 3.3 Architecture Review Checklist
- [ ] **ADR Complete:** Context, options, decision, consequences, alternatives
- [ ] **Consistent with Vision:** [[VISION]] principles upheld
- [ ] **No Hidden Coupling:** Explicit dependencies only
- [ ] **Failure Modes Documented:** Per component spec
- [ ] **Scalability Considered:** Limits documented
- [ ] **Security Reviewed:** Threat model updated
- [ ] **Observability Built-in:** Health, events, audit, explanation
- [ ] **Recoverability:** Checkpoint/rollback strategy defined
- [ ] **Test Strategy Defined:** Per [[TESTING_STRATEGY]]

---

## 4. Approval Matrix

| Artifact | Approvers | Quorum | Veto Power |
|----------|-----------|--------|------------|
| **Code PR (develop)** | 1 Engineer | 1 | Module Owner |
| **Code PR (release/main)** | 1 Lead Architect + 1 Engineer | 2 | Lead Architect |
| **ADR** | Architecture Review Board | 3 | Lead Architect |
| **Component Spec** | Lead Architect + Module Owner | 2 | Lead Architect |
| **Feature Spec** | Feature Owner + Lead Architect | 2 | Lead Architect |
| **Standard Change** | Standards Owner + 1 Engineer | 2 | Standards Owner |
| **Release** | Release Manager + Lead Architect | 2 | Lead Architect |
| **Hotfix** | Lead Architect + On-call Engineer | 2 | Lead Architect |

---

## 5. Review Tools & Automation

### 5.1 Automated Checks (Pre-merge)
```yaml
# GitHub Actions required status checks
- syntax-check
- unit-tests
- integration-tests (milestone tests)
- architecture-drift
- policy-compliance
- contract-testing (M11+)
- doc-sync
```

### 5.2 Review Assistants
| Tool | Purpose |
|------|---------|
| `PSScriptAnalyzer` | PowerShell best practices, style |
| `Validate-GuardianDocFrontmatter` | Frontmatter completeness |
| `Validate-GuardianDocLinks` | Wiki-link resolution |
| `Test-GuardianArchitectureDrift` | Structural integrity |
| `Test-GuardianPolicy` | Governance compliance |

### 5.3 Review Templates
**PR Description Template:**
```markdown
## Summary
One-paragraph description of changes.

## Type
- [ ] feat
- [ ] fix
- [ ] docs
- [ ] refactor
- [ ] test
- [ ] chore

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Milestone tests pass (specify: M__)
- [ ] Architecture drift clean
- [ ] Policy compliance verified

## Documentation
- [ ] Code comments updated
- [ ] Module docs updated
- [ ] Architecture docs updated
- [ ] ADR created/updated (if applicable)
- [ ] Changelog entry added

## Risk Assessment
- **Risk Level:** Low/Medium/High/Critical
- **Rollback Plan:** [Checkpoint tier / Manual]
- **Affected Modules:** [List]

## Checklist
- [ ] Conventional commit messages
- [ ] No merge conflicts
- [ ] All CI checks pass
- [ ] Required reviewers assigned
```

---

## 6. Escalation & Dispute Resolution

### 6.1 Disagreement Process
1. **Discuss in PR** — Threaded comments, reference standards
2. **Escalate to Module Owner** — Binding decision for module scope
3. **Escalate to Lead Architect** — Binding decision for cross-module/architecture
4. **Architecture Review Board** — Final authority for ADR/architecture disputes

### 6.2 Timeouts
| Review Type | Max Wait | Escalation |
|-------------|----------|------------|
| Code (develop) | 24 hours | Module Owner → Lead Architect |
| Code (release/main) | 4 hours | Lead Architect |
| Documentation | 48 hours | Standards Owner |
| Architecture | 1 week | Architecture Review Board |

---

## 7. Post-Merge Validation

### 7.1 Automated (CI)
- All checks re-run on merge commit
- Deploy to staging (when implemented)
- Smoke tests against staging

### 7.2 Manual (Release Engineer)
- [ ] Milestone checkpoint created
- [ ] Health report baseline captured
- [ ] Release notes generated
- [ ] Version bumped in manifests

---

## 8. Metrics & Continuous Improvement

### 8.1 Review Metrics (Tracked Monthly)
| Metric | Target |
|--------|--------|
| PR Cycle Time (open → merge) | < 24h (develop), < 4h (release) |
| Review Turnaround (request → first review) | < 4h |
| Rework Rate (commits after review) | < 20% |
| Defect Escape Rate (post-merge bugs) | < 5% |
| Documentation Debt (orphan/stale docs) | 0 |

### 8.2 Retrospective
- **Quarterly:** Review metrics, update standards
- **Per Milestone:** Review process effectiveness
- **Post-Incident:** Review missed review opportunities

---

## 📝 Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-07-26 | Team | Initial review process from M10 validated workflow |

---