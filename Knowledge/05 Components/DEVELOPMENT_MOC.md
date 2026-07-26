# Development MOC (Map of Content)

> **Navigation hub for development workflow, standards, and practices.**

---

## 📐 Coding Standards

| Document | Description |
|----------|-------------|
| [[CODING_STANDARDS]] | Naming, structure, error handling, logging, testing requirements |
| [[POWERSHELL_STYLE_GUIDE]] | PowerShell-specific conventions (parameters, pipeline, modules) |
| [[ERROR_HANDLING_PATTERNS]] | Try/catch, -ErrorAction, sentinel values, audit integration |

---

## 🌳 Branch Strategy

| Document | Description |
|----------|-------------|
| [[BRANCH_STRATEGY]] | Main, feature, release, hotfix branches; naming conventions |
| [[COMMIT_STANDARDS]] | Conventional commits, milestone discipline, signing |
| [[MERGE_POLICY]] | Fast-forward, squash, rebase rules; protected branches |

---

## 👀 Review Process

| Document | Description |
|----------|-------------|
| [[CODE_REVIEW_RULES]] | Required reviewers, checklist, automation gates |
| [[DOCUMENTATION_REVIEW]] | When docs required, review criteria, staleness detection |
| [[ARCHITECTURE_REVIEW]] | When ADR required, review panel, decision log |

---

## 🧪 Testing Requirements

| Document | Description |
|----------|-------------|
| [[TESTING_STRATEGY]] | Pyramid, conventions, coverage, CI gates |
| [[TEST_FIXTURES]] | Shared factories, builders, test data management |
| [[PERFORMANCE_TESTING]] | Benchmarks, regression detection, baselines |
| [[CHAOS_TESTING]] | Failure injection scenarios, resilience validation |

---

## 🔧 Development Workflows

| Workflow | Trigger | Steps |
|----------|---------|-------|
| **Feature Development** | New capability | Branch → Implement → Test → Doc → Review → Merge |
| **Bug Fix** | Regression/defect | Branch → Reproduce → Fix → Test → Doc → Review → Merge |
| **Milestone Completion** | Phase gate | All tests pass → Architecture drift clean → Checkpoint → Release |
| **Hotfix** | Production critical | Branch from release → Fix → Test → Release patch → Backport |

---

## 📋 Quick Reference

### Naming Conventions
```powershell
# Functions: Verb-Noun (PascalCase)
New-GuardianCheckpoint
Test-GuardianPolicy

# Variables: PascalCase for globals, camelCase for locals
$GuardianEnv.Root
$checkpointId

# Types: PascalCase with module prefix
[GuardianCheckpointManifest]
[GuardianEvent]

# Private functions: underscore prefix
_Internal-HelperFunction
```

### Module Structure
```
Guardian_ModuleName/
├── Guardian_ModuleName.psd1      # Manifest
├── Guardian_ModuleName.psm1      # Root module
├── Public/
│   ├── Verb-Noun.ps1             # One file per public function
│   └── ...
├── Private/
│   └── _Helper.ps1               # Internal functions
├── Types/
│   └── ModuleTypes.ps1xml        # Type extensions
├── Formats/
│   └── ModuleFormat.ps1xml       # Format definitions
├── Tests/
│   └── Guardian.ModuleName.Tests.ps1
└── Docs/
    └── Guardian_ModuleName.md
```

### Error Handling Template
```powershell
function Verb-Noun {
    param([Parameter(Mandatory)][string]$Input)
    
    try {
        # 1. Policy gate
        $policy = Test-GuardianPolicy -Action "verb-noun" -Context @{Input=$Input}
        if ($policy.decision -ne 'ALLOW') { return $policy }
        
        # 2. Safety checkpoint
        $cp = New-GuardianCheckpoint -Tier Emergency -Label "Pre-Verb-Noun"
        
        # 3. Execute
        $result = Do-The-Work -Input $Input
        
        # 4. Success audit
        Write-GuardianAudit -Action "verb-noun" -Decision "SUCCESS" -CheckpointId $cp.CheckpointId
        return $result
    }
    catch {
        # 5. Automatic rollback
        Restore-GuardianCheckpoint -Checkpoint $cp -Confirm:$false
        Write-GuardianAudit -Action "verb-noun" -Decision "ROLLED_BACK" -Error $_.Exception.Message
        throw
    }
}
```

---

## 🔗 Related MOCs

- [[PROJECT_MOC]] — Project central hub
- [[ARCHITECTURE_MOC]] — System architecture
- [[TESTING_MOC]] — Deep-dive testing
- [[ROADMAP_MOC]] — Development phases
- [[OPERATIONS_MOC]] — Runbooks, monitoring

---

*Development standards are the guardrails. Follow them.*