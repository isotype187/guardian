# Template: Module Specification

**Type:** Module  
**Status:** Draft  
**Version:** 1.0.0  

---

```yaml
---
title: "[Module Name] Specification"
version: "1.0.0"
status: "Active|Draft|Deprecated"
type: "Module"
module: "Guardian_[ModuleName]"
milestone: "[M-Number]"
tags:
  - module
  - [module-name]
related:
  - "[[Architecture/OVERVIEW]]"
  - "[[Components/[Component]]]"
  - "[[ADR-XXX]]"
dependencies:
  - "Guardian_[Dependency]"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
owner: "Team Name"
critical: true|false
---
```

---

# [Module Name] Specification

## 1. Purpose
Single-sentence description of what this module does.

## 2. Responsibility Boundary
What this module owns exclusively. What it does NOT own.

## 3. Public API

### Functions
| Function | Parameters | Returns | Description |
|----------|------------|---------|-------------|
| `FunctionName` | `-Param Type` | `Type` |  |

### Types
| Type | Properties | Description |
|------|------------|-------------|
| `TypeName` | `Prop: Type` |  |

### Events Emitted
| Event | Category | Severity | Payload |
|-------|----------|----------|---------|
|  |  |  |  |

## 4. Private API
Functions/types not for external use (prefixed with `_` or in `Private/`).

## 5. State Model
### Persistent State
| Store | Path | Format | Retention |
|-------|------|--------|-----------|
|  |  |  |  |

### In-Memory State
| Variable | Scope | Lifetime |
|----------|-------|----------|
|  |  |  |

## 6. Configuration
| Setting | Default | Description |
|---------|---------|-------------|
|  |  |  |

## 7. Dependencies
| Module | Type | Version | Purpose |
|--------|------|---------|---------|
|  | Internal/External |  |  |

## 8. Initialization
```powershell
# Called by Guardian_Loader
function Initialize-[ModuleName] {
    # Setup
}
```

## 9. Operational Flows

### Flow: [Name]
```
Trigger → Validation → Checkpoint → Execute → Verify → Audit
```

## 10. Failure Modes
| Failure | Detection | Mitigation | Recovery |
|---------|-----------|------------|----------|
|  |  |  |  |

## 11. Testing
| Test File | Coverage | Scenarios |
|-----------|----------|-----------|
| `Guardian.[Module].Tests.ps1` |  |  |

## 12. Security
- Policy gates:
- Audit events:
- Secrets accessed:

## 13. Performance
| Metric | Target | Current |
|--------|--------|---------|
| Load time |  |  |
| Memory |  |  |
| Latency (p99) |  |  |

## 14. Related ADRs
- [[ADR-XXX]]

## 15. Future Enhancements
- 

---

*Template Version: 1.0.0*