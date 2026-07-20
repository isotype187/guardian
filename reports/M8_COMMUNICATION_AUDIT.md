# Guardian M8 Communication Foundation Audit

Generated: 2026-07-19 | Author: Codex (Guardian Lead Architect)

## 1. Existing Communication Contracts (reused, not reinvented)

- M3 contracts (core/Guardian_Contracts.ps1): message-type builders for Guardian->Nexus98
  (health report, warning, explanation, recommendation) and Nexus98->Guardian
  (task context, operation status, analysis request).
- M6 runtime bridge (core/Guardian_Comms.ps1): outbox/inbox JSONL persistence,
  modulation helpers, and Invoke-GuardianModulation (risk escalation).
- M4 Security (core/Guardian_Security.ps1): config/permission integrity + events.
- M3 Memory (core/Guardian_Memory.ps1): short/long/pattern memory + Write-GuardianMemory.
- M2 Events (core/Guardian_Events.ps1): New-GuardianEvent + duplicate detection.
- M5 Governance (core/Guardian_Governance.ps1): Test-GuardianPolicy decisions.
- M7 Drift Guard (core/Guardian_DriftGuard.ps1): architecture authority + checkpoint gate.

## 2. Reusable Concepts Adopted

- Message schema: identity (message_id, correlation_id, timestamp), communication
  (sender, receiver, message_type), governance (risk_level, permission_required,
  authorization_status, checkpoint_reference), payload (content, metadata), tracking
  (status, attempt_count, times).
- GOVERNANCE_DECISION / health-report payloads reuse M3 builders.
- Event + Memory integration reuse Write-GuardianEvent / Write-GuardianMemory.
- Governance gating reuses Test-GuardianPolicy (no competing protocol).

## 3. Missing Components (added in M8)

- Transport: file-based JSONL message bus under communication/{inbox,outbox,
  processing,completed,failed,archive} (no delete, no overwrite).
- Dispatcher: Invoke-GuardianBridgeDispatch (validate, route, dedup, observe).
- Retry/recovery: Repair-GuardianBridgeFailures (retry then archive).
- Monitoring: Get-GuardianCommunicationHealth (success rate, queue size, score).
- Security: Test-GuardianBridgeSecurity (schema + sender + permission).

## 4. Deprecated / De-duplicated Paths

- Legacy stray outbox/inbox (data/comms) from M6 is superseded by the governed
  communication/ bus; M6 helpers remain as modulation utilities.
- No competing protocol introduced; the M8 bridge is the single transport.

## 5. Conclusion

All reusable contracts were adopted. M8 adds only the missing transport, dispatcher,
retry, monitoring, and security layers, fully subordinate to the M7 Drift Guard authority.
