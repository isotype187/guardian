# M10 Continuous Operations Engine - Completion Report

Date: 2026-07-20
Status: VALIDATED (commit-ready)

## Scope
Guardian M10 Scheduler Engine + operational validation. Transforms Guardian from
on-demand analysis into a continuously operating supervisory platform:
scheduler execution, configurable job intervals, persistent scheduler state,
job registration, enable/disable controls, per-job execution tracking, failure
recording, recovery behavior, restart persistence, and operational reporting.

## Recovery from prior interruption
- `tests/Guardian.M10.Tests.ps1` was partially written and corrupted: every `$`
  variable sigil had been lost (e.g. ` = Get-GuardianJob` instead of
  `$jobs = Get-GuardianJob`). The file was rewritten in full with a PowerShell
  here-string so all sigils are preserved.
- All prior milestone implementations (M0-M9) were intact and untouched.

## Bugs found and fixed during M10 completion (root-cause, not surface)
1. `Invoke-GuardianSchedulerCycle` built the cycle result object `$fresh` but
   never returned it, so every cycle returned `$null` and `*.jobsRun` was
   inaccessible to callers/tests. Added `return $fresh`.
   File: `core/Guardian_Operations.ps1`
2. `Get-GuardianHeartbeatStatus` indexed the heartbeat log by line, but a
   single-line JSONL file returns a `[string]` (indexing chars) so the latest
   record was never parsed. Wrapped the candidates in `@(...)` so a one-line
   file is still an array. File: `core/Guardian_Operations.ps1`
3. Duplicate `Send-GuardianHealthReportToNexus98Bridge` defined in
   `Guardian_Operations.ps1` shadowed the canonical bridge version in
   `Guardian_Bridge.ps1`. The Operations copy returned a different contract
   (`{sent,message_id,kind}`) and broke M8's "Guardian sends a health report to
   Nexus98" test, and diverged the M10 heartbeat from the bridge message schema.
   Removed the duplicate so the bridge contract is the single source of truth.
   File: `core/Guardian_Operations.ps1`
4. Scheduler/heartbeat/job-failure paths created events with
   `New-GuardianEvent ... | Out-Null`, which discarded them without persisting
   (persistence requires `Write-GuardianEvent`). Operational event logging was
   effectively dead. Now all 5 M10 event emitters persist via
   `Write-GuardianEvent`. File: `core/Guardian_Operations.ps1`
5. `Write-GuardianEvent` did not bind pipeline input by value, so the pipeline
   fix above failed to bind. Added `[Parameter(ValueFromPipeline=$true)]`.
   File: `core/Guardian_Events.ps1`

## Preserved behavior (no regression)
`Invoke-GuardianSchedulerCycle` retains the required load -> execute -> reload
fresh state -> update only cycle metadata -> save flow. It does NOT clobber
job-level state written by `Invoke-GuardianJob` or by external
`Register-GuardianJob` updates that occur between cycles.

## Validation
- Full Guardian Pester suite (M2-M10): 127 tests, 0 failures.
- M10 specific checks (all pass):
  - scheduler state survives a fresh load / restart
  - failed jobs are recorded (`lastStatus=failed`) without corrupting sibling jobs
  - scheduler never overwrites newer job information (reload-fresh path verified)
  - checkpoints remain available (rolling tier populated)
  - event logging persists (GUARDIAN_ALIVE + JOB_FAILURE written)
  - heartbeat stays stable (`status=ALIVE`)
- M8 regression from the duplicate bridge function is fixed (18/18).

## Remaining risks / notes
- `Invoke-GuardianSchedulerCycle` and the real job scans (HEALTH_SCAN touches the
  live subsystem graph) are slow in this environment (~11s per full cycle,
  ~18s for a MEMORY_MAINTENANCE cycle). The M10 tests are deterministic and pass,
  but they are not fast. No correctness impact.
- `Health`/`Communication` scores reflect the live Nexus98 tree and may vary
  between runs; tests assert structural contracts, not fixed scores.
- The Git/Repository Preservation Authority design amendment is intentionally
  NOT implemented here (out of scope per task instructions). Guardian remains the
  operational supervisory layer; Git management is untouched.
- `guardian_dev/` is an untracked directory in the parent Nexus98 repo; no
  tracked files were modified. Changes are commit-ready but intentionally not
  committed (per task instructions).
