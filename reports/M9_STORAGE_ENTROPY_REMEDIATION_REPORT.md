# Guardian M9 Storage Entropy Remediation — Report

Generated: 2026-07-19   |   Author: Codex (Guardian Lead Architect)
Milestone: M9 (Storage Entropy Remediation)
Checkpoint: CK_20260719_120328_8960 (milestones tier)
Authorities preserved: M7 Drift Guard (checkpoint + self-mod gate), M8 Bridge (Nexus98 warning)

## 1. Architecture

M9 adds `core/Guardian_EntropyRemediation.ps1`, wired into `core/Guardian_Loader.ps1`,
and reuses `core/Guardian_StorageRules.ps1` (M1 hygiene), `core/Guardian_StorageIntelligence.ps1`
(M2 duplicate/nested detection), `core/Guardian_DriftGuard.ps1` (M7 governance), and
`core/Guardian_Bridge.ps1` (M8 comms).

```
Get-GuardianStorageEntropy      -> read-only analysis (sampled for 2.1GB archive)
        |
New-GuardianRemediationPlan    -> move-only actions, categorized
        |
Invoke-GuardianRemediationPlan -> DRY-RUN (preview) | EXECUTED (under gate)
        |                              requires checkpoint + governance chain
        +-> rollback_manifest.jsonl   (every move recorded)
Undo-GuardianRemediation        -> reverse all moves via manifest
Get-GuardianRemediationMetrics  -> before/after entropy + reduction %
```

## 2. Entropy Findings (live 2.1GB archive sample)

Sampled 800 files of the `snapshots/` archive (3,411 files / ~2.1GB):
- NAMING_ENTROPY_DIRECTORY: 9
- NAMING_ENTROPY_FILE: 40
- NESTED_COPY (depth >= 4): 128
- DUPLICATE_CONTENT (by SHA256): 177
- UNCONTROLLED_SNAPSHOT_GROUP: 9
- Total entropy items detected: 363

Dominant signals: duplicate content (49%) and deep nested project copies (35%).

## 3. Remediation Rules

- No deletion. Every action is a MOVE into `data/remediation/quarantine/<category>/`.
- Collision-safe: target names get a numeric suffix rather than overwrite.
- Every move is written to `rollback_manifest.jsonl` (source -> destination).
- Categories: naming_entropy, nested_copy, duplicate, uncontrolled_group, other.

## 4. Governance & Safety

- Dry-run is the default and never requires a gate (read-only preview).
- Real execution requires: emergency checkpoint + six-lock self-modification guard
  (M7) + four-stage change-governance chain (M7). Otherwise BLOCKED.
- Nexus98 is warned over the M8 governed bridge when a non-dry-run execution occurs.
- Rollback is a first-class, tested operation (revert every manifest move).

## 5. Testing

`tests/Guardian.M9.Tests.ps1` — 10 tests, all passing. Coverage:
- Entropy analysis detects + classifies (naming/nested).
- Move-only plan (no deletion, governance/checkpoint required).
- Dry-run previews without touching the filesystem.
- Real execution BLOCKED without checkpoint; EXECUTED under checkpoint.
- Rollback manifest written; Undo reverses moves.
- Observability metrics; all M9 functions load.

Full suite (M0-M9): **130/130 passing**.

## 6. Known Limitations

- Execution is OFF by default in practice (dry-run preview is the safe default); the
  live 2.1GB archive was NOT remediated here, only analyzed, per read-only-safe policy.
- Duplicate detection is hashed over a sampled subset (full-hash of 3,411 files is
  expensive); scaling to the full archive is a follow-up.
- Quarantine gathers entropy but does not retire it (retention policy applied later).

## 7. Future Improvements

- Promote dry-run findings into a scheduled entropy report.
- Full-archive duplicate scan with streaming hashing.
- Lifecycle expiration of quarantined items under M7 storage-governance rules.
- Auto-warn Nexus98 on every threshold breach via M8 bridge.
