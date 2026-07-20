# Canonical Drift Review (pre-sync gate)

Authoritative source: `D:\Nexus98\guardian_dev` (M0-M10 complete, 127 tests passing).
Canonical repo: `D:\Nexus98_Guardian` (HEAD `daa8356` = M9).
Canonical Git: `D:\Nexus98_Guardian\vcs\.git`.

This review classifies the working-tree drift detected against committed HEAD
`daa8356` so the synchronization commit stages ONLY approved M10 changes and
never sweeps runtime/volatile artifacts via `git add -A`.

## Method

- Git diff/read performed read-only against `D:\Nexus98_Guardian\vcs\.git`.
- Each drifted file compared byte-for-byte (SHA-256) against the dev source.
- Classifications:
  - KEEP    - intended M10 state, stage in sync commit.
  - REPLACE - canonical copy is wrong/corrupted; take dev copy instead.
  - ARCHIVE - preserve canonical copy separately before replacing.
  - IGNORE  - runtime/volatile artifact; do not commit.

## Findings

| File | Status vs HEAD | Classification | Action |
|------|---------------|---------------|--------|
| `core/Guardian_Loader.ps1` | modified | KEEP | Already identical to dev (adds `Guardian_Operations.ps1` to module list). Stage. |
| `core/Guardian_Operations.ps1` | untracked | REPLACE | Canonical copy is CORRUPTED (1442 lines with duplicate `function Initialize-GuardianOperations`/`Get-GuardianJob`/`Invoke-GuardianJob`/`Invoke-GuardianSchedulerCycle`/`Start-GuardianOperations`/`Stop-GuardianOperations` defs -> PowerShell dot-source error). Dev copy is clean 623-line validated M10 module. ARCHIVE corrupted copy, then REPLACE with dev. Stage dev copy. |
| `config/guardian_runtime_config.json` | untracked | IGNORE | M10 runtime config; volatile. Sync copies it to the working tree but it stays untracked. Do NOT stage. |
| `data/` | untracked (dir) | IGNORE | Checkpoints, comms, events, memory, ops runtime, baselines, agents. All gitignored (`data/*`). Preservation-authority evidence. Preserve, never commit. |
| `m10_cyc.ps1` | untracked | IGNORE | M10 ops script; IDENTICAL to dev (SHA-256 matched). Convenience runner, not imported by `Guardian_Loader`. Do not stage. |
| `m10_e2e.ps1` | untracked | IGNORE | As above. |
| `m10_hs.ps1` | untracked | IGNORE | As above. |
| `m10_sched.ps1` | untracked | IGNORE | As above. |
| `m10_smoke.ps1` | untracked | IGNORE | As above. |
| `m10_ss.ps1` | untracked | IGNORE | As above. |

## Additional sync payloads (from dev, part of intended M10 canonical state)

Staged by the sync commit:

- `core/Guardian_*.ps1` (dev -> canonical; e.g. `Guardian_Events.ps1`,
  `Guardian_Health.ps1` newer in dev; `Guardian_Operations.ps1` REPLACE).
- `tests/Guardian.M10.Tests.ps1` (new; the 127-test M10 suite source).
- `reports/*.md` (M10 + architecture/alignment/completion audit docs).
- `.gitignore` (dev newer; adds `vcs/` exclusion).
- `config/*` except `guardian_architecture_baseline.json` (SKIPPED by sync,
  preserved) and `guardian_runtime_config.json` (IGNORE, not staged).
- `Nexus98.ps1` (dev newer).
- `archive/legacy_stubs/*` (additive preserve).

## Preservation (never touched by sync)

- `vcs/.git` (canonical history store).
- `data/checkpoints/**` (rolling/emergency/milestone/archive).
- `guardian_architecture_baseline.json` (SKIPPED unless `-ForceBaseline`).
- `archive/`, `reports/` (pre-existing), runtime evidence (`logs/`,
  `data/events`, `data/comms`, `data/memory`, `data/ops`, `snapshots`,
  `communication/*` - gitignored).

## Commit staging plan (write-enabled context only)

    git add core tests reports .gitignore Nexus98.ps1
    git add config
    git reset -- guardian_architecture_baseline.json config/guardian_runtime_config.json
    git reset -- m10_cyc.ps1 m10_e2e.ps1 m10_hs.ps1 m10_sched.ps1 m10_smoke.ps1 m10_ss.ps1
    git commit -m "chore: synchronize canonical Guardian state after M10 audit"

NOTE: `m10_*.ps1` are untracked; they are listed in the reset only as a guard.
`config/guardian_runtime_config.json` and `guardian_architecture_baseline.json`
are excluded from the commit; the working tree still receives them via the sync.

## Script hardening requirement

`sync_guardian_to_canonical.ps1` `SafeCopy` previously logged `COPIED` even on
failed `Copy-Item` (non-terminating error not caught). Fixed to use
`-ErrorAction Stop` and to throw/log `ERROR` accurately. The commit step no
longer uses `git add -A`; it stages explicit approved paths per the plan above.
