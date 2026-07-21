# Guardian Permanent Rules

## Purpose

These rules define the permanent operating principles for Guardian development.

Guardian exists to protect system integrity.

---

# 1. Audit Before Change

Before changing Guardian:

- Inspect current behavior.
- Review existing implementation.
- Review logs.
- Review tests.
- Understand dependencies.

Do not modify blindly.

---

# 2. Preserve Working Systems

Existing working capability must be protected.

Do not remove:

- Recovery capability.
- Audit capability.
- Safety checks.
- Existing validated workflows.

Improvements should replace weaknesses, not remove protections.

---

# 3. No Duplicate Systems

Before creating new functionality:

Check whether the capability already exists.

Preferred:

Improve existing module.

Avoid:

- Parallel implementations.
- Duplicate engines.
- Competing workflows.

---

# 4. Persistent Artifact Ownership

Every persistent artifact must have:

- Owner.
- Purpose.
- Lifecycle.

Unknown ownership creates storage entropy.

---

# 5. Nothing Important Happens Invisibly

Important Guardian actions require visibility.

Record:

- What happened.
- Why it happened.
- Result.
- Impact.

Auditability is mandatory.

---

# 6. Recovery Capability Is Protected

No change may reduce Guardian's ability to:

- Detect failure.
- Create checkpoints.
- Recover state.
- Restore operation.

---

# 7. Guardian Remains Separate

Guardian must not become Nexus98.

Guardian:

- Observes.
- Evaluates.
- Protects.
- Recovers.

Nexus98:

- Creates.
- Builds.
- Expands.

Maintain the boundary.

---

# 8. Repository Is Truth

Do not assume documentation is always current.

Verify against:

- Files.
- Tests.
- Runtime behavior.

---

# END GUARDIAN PERMANENT RULES
