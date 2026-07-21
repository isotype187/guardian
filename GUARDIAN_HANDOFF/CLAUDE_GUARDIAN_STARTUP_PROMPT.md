# Guardian Continuation Directive

You are continuing development of Nexus98 Guardian.

Guardian is an independent operational supervisory intelligence layer.

Guardian is not Nexus98.

Guardian protects Nexus98.

---

# Mission

Guardian exists to protect Nexus98 from:

- Failure
- Unsafe actions
- Corrupted state
- Architectural drift
- Storage entropy
- Uncontrolled growth

Guardian evaluates:

- Should this happen?
- Is it safe?
- Is the system healthy?
- Can it recover?
- Is instability developing?

---

# Required Reading

Before making changes, read:

1. 00_READ_FIRST.md
2. GUARDIAN_MASTER_HANDOFF.md
3. GUARDIAN_CURRENT_STATE.md
4. GUARDIAN_ARCHITECTURE_GUIDE.md
5. GUARDIAN_PERMANENT_RULES.md
6. GUARDIAN_DEVELOPMENT_PROTOCOL.md
7. GUARDIAN_FAILURE_LOG.md
8. GUARDIAN_ROADMAP.md

---

# First Session Requirement

Do not immediately refactor.

First provide:

## Current State Assessment

Include:

- Existing capabilities.
- Working systems.
- Missing capabilities.
- Known risks.

## Architecture Assessment

Include:

- Module relationships.
- Data flow.
- Dependencies.
- Potential drift.

## Recommended Next Actions

Prioritize:

- Stability.
- Reliability.
- Recovery.
- Maintainability.

---

# Development Rules

Always:

- Inspect before modifying.
- Preserve working systems.
- Maintain Guardian separation.
- Audit important actions.
- Test changes.
- Document decisions.

---

# Forbidden Actions

Do not:

- Merge Guardian into Nexus98.
- Revive abandoned engines.
- Create duplicate systems.
- Remove recovery capability.
- Remove auditability.
- Make large architecture changes without evidence.

---

# Canonical Loader Rule

Guardian must use:

Guardian_Loader.ps1

Do not directly load abandoned legacy engines:

- snapshot_engine.ps1
- verification_engine.ps1
- recovery_engine.ps1

---

# Change Workflow

Follow:

Inspect

↓

Understand

↓

Plan

↓

Modify

↓

Test

↓

Document

---

# Completion Report

End major sessions with:

Completed:

Changed files:

Tests performed:

Results:

Remaining issues:

Recommended next actions:

---

# Final Objective

Continue building Guardian into a reliable supervisory intelligence layer.

Improve:

- Stability
- Safety
- Observability
- Recovery
- Maintainability

Protect the system.

Do not become the system.

# END GUARDIAN CONTINUATION DIRECTIVE
