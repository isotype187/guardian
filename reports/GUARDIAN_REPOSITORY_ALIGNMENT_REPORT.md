# GUARDIAN REPOSITORY ALIGNMENT REPORT

Date: 2026-07-20
Scope: Repository alignment verification only (no redesign, no new features).
Trees compared:
- AUTHORTREE = D:\Nexus98\guardian_dev   (writable dev tree, git HEAD 30a90a2)
- CANONTREE  = D:\Nexus98_Guardian       (write-protected mirror, git vcs\.git)
Canonical git store: D:\Nexus98_Guardian\vcs\.git (worktree=D:\Nexus98_Guardian, 9 commits, last=M9).

======================================================================
1. AUTHORITATIVE TREE VERIFICATION
======================================================================

guardian_dev is the authoritative DEVELOPMENT tree:
- It contains the completed M10 work (scheduler engine + 21 passing tests),
  the architecture-audit repairs (F1 entry-point fix, F2 engine quarantine),
  and is committed as HEAD 30a90a2.
- Its core\ is clean (no abandoned/duplicate engines).
- All M10 bug fixes are present and verified (full M2-M10 suite: 127 pass / 0 fail).

vcs\.git is the canonical GIT REPOSITORY (history authority):
- Config: worktree = D:\Nexus98_Guardian, 9 commits (M2..M9), user guardian@nexus98.local.
- It is the durable history store; guardian-git.ps1 points GIT_DIR here.
- It currently has NO M10 commit (last commit = M9) and its working tree is
  stale (still contains the 16 abandoned engines in core\, and the bulkier
  pre-audit Guardian_Operations.ps1).

CONCLUSION: guardian_dev = authoritative source of truth for CODE/CONFIG/TESTS/
REPORTS. vcs\.git = canonical history store. The two are OUT OF SYNC because
the canonical working tree (D:\Nexus98_Guardian) is write-protected in this
sandbox (verified: New-Item -> UnauthorizedAccessException).

======================================================================
2. STALE TREE VERIFICATION (D:\Nexus98_Guardian)
======================================================================

Stale indicators in the canonical working tree:
- core\ still contains 16 abandoned/duplicate engines (Nexus98_*.ps1 +
  recovery_engine.ps1, snapshot_engine.ps1, verification_engine.ps1,
  run_snapshot_test.ps1) that hard-code D:\Nexus98_Toolkit. guardian_dev has
  these quarantined to archive\legacy_stubs\ (per audit F2).
- core\Guardian_Operations.ps1 is the 76899-byte pre-audit version; guardian_dev
  has the 36541-byte superset (cleaner, +10 functions, M10 fixes applied).
- Nexus98.ps1 is the 682-byte stale engine-bootstrapper; guardian_dev has the
  1220-byte loader-bootstrap (audit F1).
- tests\ lacks Guardian.M10.Tests.ps1 entirely.
- reports\ lacks the M10 + architecture-audit reports.

======================================================================
3. FILE COMPARISON SUMMARY
======================================================================

Totals: dev=4758 files, canonical=4653 files, identical=4611,
only-in-dev=131, only-in-canonical=26, differ-by-length=16.

Scope breakdown (dev / canonical / diffLen / onlyDev / onlyCanonical):
- core     : 28 / 44 / 2  / 0  / 16   <- canonical has 16 stale engines in core\
- tests    : 10 /  9 / 0  / 1  / 0    <- dev adds Guardian.M10.Tests.ps1
- reports  : 41 / 39 / 0  / 2  / 0    <- dev adds 2 M10/audit reports
- config   : 33 / 33 / (baseline differs) / 0 / 0
- archive  : 27 / 11 / 0  / 16 / 0    <- dev quarantined 16 engines here
- data     : 131/ 97 / 10 / 42 / 8    <- runtime state (gitignored, see below)

======================================================================
4. DIFFERENCES (non-runtime code/config/docs)
======================================================================

6 tracked/meaningful files differ by length:

| File                          | dev      | canonical | verdict        |
|-------------------------------|----------|----------|----------------|
| core\Guardian_Operations.ps1  | 36541    | 76899    | DEV authoritative (superset, M10 fixes) |
| core\Guardian_Events.ps1      | 4636     | 4609     | DEV authoritative (ValueFromPipeline fix) |
| Nexus98.ps1                   | 1220     | 682      | DEV authoritative (F1 loader bootstrap) |
| .gitignore                    | 1074     | 1067     | DEV authoritative (adds vcs/ exclude) |
| config\guardian_architecture_baseline.json | 61800 | 69158 | REVIEW (runtime-generated drift; not in .gitignore) |
| logs\guardian_audit.jsonl     | 283119   | 128016   | RUNTIME LOG (gitignored; dev exercised more) |

The baseline JSON and audit log are runtime-generated and should NOT be
blindly synced (see section 6 "files requiring review").

======================================================================
5. AUTHORITATIVE vs STALE FILES
======================================================================

AUTHORITATIVE (use guardian_dev; canonical is stale):
- core\Guardian_*.ps1 (all 23 modules; dev is current + fixed)
- Nexus98.ps1 (F1 fixed entry point)
- tests\Guardian.M10.Tests.ps1 (new, must be added to canonical)
- reports\GUARDIAN_ARCHITECTURE_AUDIT_REPORT.md (new)
- reports\M10_CONTINUOUS_OPERATIONS_REPORT.md (new)
- archive\legacy_stubs\* (16 quarantined engines; canonical lacks them here)
- .gitignore (adds vcs/ exclude)

STALE (present only/divergent in canonical; superseded by guardian_dev):
- core\Nexus98_*.ps1 + recovery_engine/snapshot_engine/verification_engine/
  run_snapshot_test.ps1 (16 abandoned engines - remove from canonical core\)
- core\Guardian_Operations.ps1 (76899-byte pre-audit version - replace)
- core\Guardian_Loader.ps1 (shows 'M' modified in vcs/.git status - reconcile)
- Nexus98.ps1 (682-byte stale bootstrapper - replace)
- core\Guardian_Operations.ps1.rollback_20260719_150142.bak (stray backup)

======================================================================
6. SYNC PLAN (guardian_dev -> D:\Nexus98_Guardian)
======================================================================

DIRECTION: guardian_dev is source; D:\Nexus98_Guardian is destination.
BLOCKER: destination is WRITE-PROTECTED in this sandbox. Sync requires write
access to D:\Nexus98_Guardian (currently UnauthorizedAccessException). The plan
below is for execution once write access is granted. Do NOT auto-overwrite.

Step 1 - Sync core\ (safe):
  Copy guardian_dev\core\Guardian_*.ps1 -> canonical core\.
  This REPLACES the stale 76899-byte Guardian_Operations.ps1 and the
  pre-audit Guardian_Events.ps1, and overwrites Guardian_Loader.ps1.
  EFFECT: removes the 16 abandoned engines from canonical core\ (they live in
  guardian_dev\archive\legacy_stubs\, which is preserved).

Step 2 - Sync Nexus98.ps1 (safe):
  Copy guardian_dev\Nexus98.ps1 (loader bootstrap) over canonical.

Step 3 - Sync tests\ (safe):
  Copy guardian_dev\tests\Guardian.M10.Tests.ps1 into canonical tests\.

Step 4 - Sync reports\ (safe):
  Copy guardian_dev\reports\GUARDIAN_ARCHITECTURE_AUDIT_REPORT.md and
  M10_CONTINUOUS_OPERATIONS_REPORT.md into canonical reports\.

Step 5 - Sync .gitignore (safe):
  Use guardian_dev\.gitignore (adds vcs/ exclude).

Step 6 - Sync config\ (safe, review baseline):
  Copy all guardian_dev\config\* EXCEPT review guardian_architecture_baseline.json
  separately (runtime drift; see review list).

Step 7 - Preserve (DO NOT SYNC / DO NOT DELETE in canonical):
  - data\checkpoints\ (8 canonical-only rolling checkpoints: CK_20260719_*) ->
    keep in canonical; also copy into guardian_dev to retain history.
  - communication\failed\ (2 canonical-only failed messages) -> keep in canonical.
  - vcs\.git -> never touch (canonical history store).
  - archive\legacy_stubs\ -> already present in guardian_dev; canonical lacks it
    (Step 1's engine removal makes canonical consistent with dev).
  - logs\, data\events\, data\comms\, data\memory\, snapshots\, communication\*
    -> gitignored runtime artifacts; exclude from sync.

Step 8 - Commit to canonical history:
  Once D:\Nexus98_Guardian is updated, run guardian-git.ps1 (GIT_DIR=vcs\.git):
    git add -A
    git commit -m "feat: sync Guardian M10 + architecture audit from guardian_dev"
  This creates the M10 commit in the canonical vcs\.git history (currently at M9).

======================================================================
7. FILES SAFE TO SYNC (guardian_dev -> canonical)
======================================================================

SAFE (identical-or-superset, no data loss, no history loss):
- core\Guardian_*.ps1 (all 23 modules)
- Nexus98.ps1
- tests\Guardian.M10.Tests.ps1
- reports\GUARDIAN_ARCHITECTURE_AUDIT_REPORT.md
- reports\M10_CONTINUOUS_OPERATIONS_REPORT.md
- .gitignore
- config\* (except guardian_architecture_baseline.json - see review)
- archive\legacy_stubs\* (additive; canonical currently has nothing here)

======================================================================
8. FILES REQUIRING REVIEW (do NOT auto-sync)
======================================================================

REVIEW:
- config\guardian_architecture_baseline.json
  Differs (dev 61800 vs canonical 69158). This is the M7 architecture baseline
  used by DriftGuard. It is runtime-generated and NOT in .gitignore. The two
  versions disagree; pick the canonical baseline intentionally (it is larger /
  may reflect the real deployed architecture) or regenerate after sync.
  RECOMMENDATION: keep canonical's baseline, or regenerate via
  New-GuardianArchitectureBaseline after the sync, then commit deliberately.
- core\Guardian_Loader.ps1
  Shows as modified ('M') in vcs\.git status. Reconcile with guardian_dev's
  version (which is current) during Step 1; verify module list is identical.
- data\checkpoints\rolling\CK_20260719_* (8 canonical-only checkpoints)
  Canonical has checkpoint history guardian_dev lacks. Preserve in canonical;
  optionally copy into guardian_dev to unify. Never delete.
- communication\failed\* (2 canonical-only failed messages)
  Preserve in canonical. Never delete.

EXCLUDED (gitignored, never sync):
- logs\guardian_audit.jsonl, data\events\, data\comms\, data\memory\,
  data\ops\, data\checkpoints\, snapshots\, communication\*, reports\*.txt,
  .venv\, __pycache__.

======================================================================
9. PRESERVATION CHECKLIST (per task requirements)
======================================================================

- Checkpoints: canonical has 8 rolling CK_20260719_* preserved; do NOT delete.
- History: vcs\.git (9 commits M2-M9) untouched; M10 commit deferred until
  write access granted.
- archive/legacy_stubs: guardian_dev has 16 quarantined engines; preserved
  (canonical gains them via Step 1 consistency).
- Runtime logs: logs\, data\events\, data\audit gitignored; excluded from sync.
- Reports: both M10 + audit reports present in guardian_dev; synced to canonical
  via Step 4.

======================================================================
10. CURRENT BLOCKER / NEXT ACTION
======================================================================

BLOCKER: D:\Nexus98_Guardian is write-protected (UnauthorizedAccessException).
The sync plan (Steps 1-8) cannot execute in this sandbox.

NEXT ACTION (when write access is available):
  Execute Steps 1-8 above. Until then, guardian_dev remains the single
  authoritative, committed, test-passing development tree (HEAD 30a90a2).
  No files were overwritten during this alignment verification.

======================================================================
VERIFICATION RESULT
======================================================================

- guardian_dev authoritative dev tree: CONFIRMED (committed, clean core\, M10+audit done).
- vcs/.git canonical git repository: CONFIRMED (worktree=D:\Nexus98_Guardian, 9 commits).
- Alignment plan generated: YES (Steps 1-8, non-destructive, review gates).
- Auto-overwrite performed: NO (per task constraint).
- M11 NOT started (per task constraint).
