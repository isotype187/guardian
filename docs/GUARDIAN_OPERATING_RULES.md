# Nexus98 Guardian - Operating Rules

Adopted: Milestone M1 (2026-07-19). Supersedes ad-hoc Toolkit rules.

## 1. Before any change
- Audit current state (modules, tests, config, dependencies, docs).
- Map capabilities; preserve working systems.
- Create a checkpoint before risky changes (risk >= high).
- Write a plan; identify risks, tests, rollback, acceptance criteria.

## 2. Non-negotiable
- No subsystem creates persistent data without owner, purpose, location
  policy, retention policy, cleanup policy, and recovery policy.
- Every file has a reason to exist. Every directory has an owner.
- Every generated artifact has a lifecycle.
- Nothing important happens invisibly: every important action is audited.
- Recovery capability is never removed.

## 3. Communication contract
- Guardian <-> Nexus98 communicate via structured messages (HEALTH_MESSAGE,
  TASK_REQUEST, PERMISSION_REQUEST, RECOVERY_REQUEST, SYSTEM_EVENT) and
  GUARDIAN_RESPONSE states (APPROVED, APPROVED_WITH_WARNING, DELAYED, DENIED,
  RECOVERY_REQUIRED, HUMAN_REVIEW_REQUIRED).
- No direct filesystem manipulation, hidden imports, or shared mutable state.

## 4. Policy decision model
- ALLOW / ALLOW_WITH_MONITORING / REQUIRE_CHECKPOINT / REQUIRE_REVIEW / BLOCK.
- Critical actions (disable safeguards, modify Guardian, remove recovery) are
  blocked or require human review. High-risk requires a verified checkpoint.

## 5. Storage hygiene (anti-entropy)
- No recursive backup creation (backup1, backup2, backup_final...).
- No uncontrolled snapshots; checkpoints rotate automatically.
- No duplicate project copies; no random generated folders; no unmanaged logs.
- Classify every artifact: ACTIVE / ARCHIVE / TEMPORARY / EXPERIMENTAL /
  OBSOLETE / UNKNOWN. Unknown items are documented before any removal.

## 6. Development safety
- Do not rewrite functioning systems unnecessarily.
- Do not duplicate existing functionality.
- Add tests for every major subsystem.
- Validate after changes; compare health before/after.
- Do not proceed to next milestone until current milestone is validated.

## 7. Version control
- Use scripts/guardian-git.ps1 (GIT_DIR = vcs/.git).
- Commit per milestone with a clear message.
- Do not commit the snapshot archive, .venv, or logs.

## 8. Self-development guard
- Guardian must not modify itself without: checkpoint, validation, documented
  change, test execution, health comparison, and available rollback.
