# Guardian M8 Nexus98 Governed Communication Loop — Report

Generated: 2026-07-19   |   Author: Codex (Guardian Lead Architect)
Milestone: M8 (final live-loop milestone)
Checkpoint: CK_20260719_113846_5335 (milestones tier)
Prerequisite authority: M7 Drift Guard (unchanged, remains the authority)

## 1. Architecture

M8 adds `core/Guardian_Bridge.ps1`, wired into `core/Guardian_Loader.ps1`, and a
file-based message bus under `communication/`:

```
Guardian
  Governance  -> Test-GuardianPolicy (M5)
  Transport   -> core/Guardian_Bridge.ps1 (M8)
  Recovery    -> Checkpoint/Rollback (M0/M5)
       |
  Guardian Dispatcher (Invoke-GuardianBridgeDispatch)
       |
  Message Validation (Test-GuardianBridgeSecurity: schema+sender+permission)
       |
  -----------------------------------
  |                                 |
Guardian Inbox                Guardian Outbox
  |                                 |
  -----------------------------------
       |
  Nexus98 Communication Layer (message files)
```

Folders (observability + recovery, never deleted):
`communication/{inbox,outbox,processing,completed,failed,archive}/`.

## 2. Message Protocol

Standard (identity / communication / governance / payload / tracking):

- `message_id`, `correlation_id`, `timestamp`
- `sender`, `receiver`, `message_type`
- `risk_level`, `permission_required`, `authorization_status`, `checkpoint_reference`
- `content`, `metadata`
- `status`, `attempt_count`, `created_time`, `updated_time`

Lifecycle: CREATED -> VALIDATING -> ACCEPTED -> PROCESSING -> COMPLETED;
failure path FAILED -> RETRY_PENDING -> (ARCHIVED after max retries).
Every transition emits a Guardian event + audit record.

Message types: SYSTEM_HEALTH_REPORT, SYSTEM_HEALTH_REQUEST, ANALYSIS_REQUEST,
ANALYSIS_RESPONSE, WORKFLOW_STATUS_UPDATE, EVENT_NOTIFICATION, RECOVERY_STATUS,
GOVERNANCE_DECISION. Payloads reuse M3 contract builders (no competing protocol).

## 3. Security Model

- Schema validation: required fields + enumerations (sender/receiver/type/status/auth).
- Sender validation: only known agents (Guardian, Nexus98) accepted; unknown senders BLOCKED.
- Permission verification: permission_required messages must carry GRANTED authorization.
- Governance gating: every inbound Nexus98 request passes identity -> permission ->
  risk -> checkpoint -> policy (Test-GuardianPolicy), yielding ALLOW /
  ALLOW_WITH_MONITORING / REQUIRE_CHECKPOINT / REQUIRE_REVIEW / BLOCK.
- No execution bypass: the bridge transports structured messages only; Guardian
  never executes Nexus98 actions, and Nexus98 never modifies Guardian.

## 4. Testing

`tests/Guardian.M8.Tests.ps1` — 18 tests, all passing. Coverage:
- Transport: create/send/receive (persisted to outbox/inbox).
- Validation: malformed rejected, unknown sender blocked, unauthorized action blocked.
- Recovery: failed messages preserved; retries promote failed -> outbox.
- Integration: health report sent, analysis request reaches inbox, dispatcher completes,
  governance decision produced.
- Security: unknown sender / unauthorized action blocked at send+receive.
- Observability: communication health score computed.
- Disable safety: bridge refuses to send when disabled.
- Import check: all M8 functions load.

Full suite (M0-M8): **120/120 passing**.

## 5. Known Limitations

- Local JSONL transport only (Phase 2 scope); no network/socket transport yet.
- Nexus98 is modeled as the known counterpart; the live Nexus98 process is not
  running in this environment, so "receipt" is verified by file placement in the
  bus, not by an active Nexus98 consumer.
- Dispatcher is on-demand (function call), not a continuous daemon; a scheduler can
  invoke it for a live cadence.
- No silent deletion: failed messages accumulate until retry/archive; archive growth
  is bounded by the max-retry rule.

## 6. Future Improvements

- Add a scheduled dispatcher driver (loop/cron) with back-pressure.
- Implement a real Nexus98 consumer that reads the bus and emits responses.
- Add end-to-end latency tracking (created -> completed timestamps).
- Extend security to signed messages / HMAC integrity beyond schema checks.

## 7. Post-M8 Direction

Next: M9 Storage Entropy Remediation. Guardian can now communicate warnings and
recommendations; M9 reduces accumulated system entropy (the 3,411-file / 2.1 GB
snapshot archive) under the governance + checkpoint chain.
