
==================================================
SOURCE FILE: GUARDIAN_FAILURE_LOG.md
==================================================
# Guardian Failure Log

## Purpose

Records important failures, fixes, and lessons learned.

This prevents repeated mistakes.

---

# Entry Format

## Problem

Describe the issue.

## Cause

Describe the root cause.

## Resolution

Describe the fix.

## Prevention

Describe how recurrence is avoided.

---

# Known Lessons

## Storage Entropy

Problem:

Persistent artifacts accumulated without clear ownership.

Cause:

Insufficient lifecycle management.

Resolution:

Storage rules and entropy remediation were introduced.

Lesson:

Every artifact requires ownership and purpose.

---

## Architecture Drift

Problem:

Systems can slowly diverge from intended architecture.

Cause:

Changes occur without enforcement.

Resolution:

DriftGuard baseline introduced.

Lesson:

Architecture requires active protection.

---

## Duplicate Engines

Problem:

Legacy engines existed alongside the M0 foundation.

Cause:

Old systems remained after replacement.

Resolution:

Canonical loader path established.

Lesson:

Superseded systems must be clearly retired.

---

# END GUARDIAN FAILURE LOG


==================================================
SOURCE FILE: CLAUDE_GUARDIAN_STARTUP_PROMPT.md
==================================================
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


