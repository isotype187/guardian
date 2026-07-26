# Resource Governance and Failure Prevention Protocol

## Purpose

Guardian maintains ecosystem reliability by monitoring resource consumption, detecting approaching limits, and ensuring systems transition safely before failures occur.

Guardian prevents resource failures from becoming operational failures.

---

# RESOURCE OVERSIGHT

Guardian monitors:

- API utilization
- Worker capacity
- Token consumption trends
- Context pressure
- Retry behavior
- Failed requests
- Session duration
- Memory growth
- Processing bottlenecks

---

# EARLY WARNING SYSTEM

Guardian identifies approaching limits through continuous metric evaluation:

```yaml
resource_governance:
  warning_thresholds:
    api_usage_percent: 80
    token_usage_percent: 75
    context_usage_percent: 75
    retry_count: 2
    failed_request_rate: 0.05
    session_duration_hours: 4
    memory_growth_rate_mb_per_hour: 100
  
  critical_thresholds:
    api_usage_percent: 90
    token_usage_percent: 90
    context_usage_percent: 90
    retry_count: 3
    failed_request_rate: 0.10
    session_duration_hours: 6
    memory_growth_rate_mb_per_hour: 250
```

Guardian evaluates these metrics continuously and triggers preemptive actions before limits are reached.

---

# PREEMPTIVE CHECKPOINT PROTOCOL

When warning thresholds are breached:

1. **Halt new work initiation** — Complete only the current atomic operation
2. **Create session checkpoint** — Record full state
3. **Evaluate recovery options** — Continue, checkpoint + restart, or abort

**Checkpoint Format:**
```markdown
SESSION CHECKPOINT

Directive ID: [from execution record]
Current Objective: [active task]
Current Iteration: [number]
Completed: [what was finished]
In Progress: [what was interrupted]
Pending: [what remains]
Files Changed: [list with paths]
Decisions Made: [key architectural/design choices]
Memory Updates: [vault changes]
Next Action: [specific next step on resume]
Resource State: [metrics at checkpoint]
Failure Risk: [assessed level]
Restart Required: true/false
```

---

# CONTROLLED SESSION RESET

When critical thresholds are reached or ResourceExhausted errors occur:

**Immediate Actions:**
1. **Stop all execution** — No new operations, no retries
2. **Preserve state** — Write checkpoint to persistent storage
3. **Record failure intelligence** — Log failure type, cause, context
4. **Request fresh session** — Initiate controlled transition

**Reset Procedure:**
```powershell
# Guardian-controlled reset sequence
1. Save checkpoint to Knowledge/21 Meetings/SESSION_YYYYMMDD_CHECKPOINT.md
2. Update Knowledge/INDEX.md with session status
3. Update Knowledge/02 Roadmap/ROADMAP.md with progress
4. Update Knowledge/18 Backlog/WORK_QUEUE.md with task status
4. Flush all pending writes
5. Signal session end
```

---

# RETRY MANAGEMENT POLICY

Guardian enforces intelligent retry behavior:

| Failure Type | Retry Allowed | Max Retries | Backoff |
|--------------|---------------|-------------|---------|
| Transient network | Yes | 3 | Exponential (2s, 4s, 8s) |
| Rate limit | Yes | 3 | Respect Retry-After header |
| ResourceExhausted | **No** | 0 | Checkpoint + reset |
| Authentication | No | 0 | Alert human |
| Validation error | No | 0 | Fix required |
| Timeout | Yes | 2 | Linear (5s, 10s) |

**Never retry on ResourceExhausted** — This indicates systemic capacity issues requiring session reset.

---

# FAILURE INTELLIGENCE SYSTEM

Every resource failure generates intelligence:

```yaml
failure_record:
  id: FAIL_YYYYMMDD_HHMMSS
  type: "ResourceExhausted|RateLimit|Timeout|AuthFailure|ValidationError"
  resource: "api|tokens|context|workers|memory"
  limit_reached: "percentage|absolute_value"
  timestamp: "ISO8601"
  session_id: "SESSION_YYYYMMDD"
  active_task: "directive_or_objective"
  cause: "root_cause_analysis"
  prevention: "threshold_adjustment|architecture_change|capacity_increase"
  future_threshold: "adjusted_value"
  checkpoint_id: "CHK_YYYYMMDD_HHMMSS"
  recovery_time_seconds: "measured"
```

Guardian uses this intelligence to:
- Dynamically adjust warning/critical thresholds
- Identify systemic capacity issues
- Recommend architectural improvements
- Prevent recurrence

---

# RECOVERY PROCESS

After session reset, Guardian orchestrates recovery:

1. **Load latest checkpoint** — Verify integrity (checksums, completeness)
2. **Confirm failure cause** — Cross-reference failure record
3. **Validate state** — Ensure no data corruption
4. **Resume from next valid action** — Skip failed operation, continue iteration
5. **Continue iteration numbering** — No reset to zero
6. **Report recovery** — Log recovery time, completeness

---

# RESOURCE GOVERNANCE METRICS

Guardian reports on:

```yaml
governance_metrics:
  sessions_before_reset: "target: > 10"
  checkpoint_creation_rate: "target: > 1 per iteration"
  failure_detection_latency: "target: < 30 seconds"
  recovery_time: "target: < 60 seconds"
  progress_preservation: "target: 100%"
  false_positive_warnings: "target: < 10%"
```

---

# INTEGRATION WITH ECOSYSTEM

This protocol integrates with:

- **Focus Control System** — Prevents scope drift during resource pressure
- **Hermes Oversight** — Guardian monitors Hermes resource usage
- **Checkpoint System** — Uses Guardian's 4-tier checkpoint infrastructure
- **Memory Management** — Preserves Obsidian vault integrity
- **Roadmap Management** — Preserves iteration progress
- **Failure Intelligence** — Feeds ADR process for architectural decisions

---

# CORE PRINCIPLES

1. **Prevention over recovery** — Detect early, act early
2. **Controlled restart is success** — Uncontrolled crash is failure
3. **Progress preservation over session continuity** — Long-term progress matters
4. **Intelligence over reaction** — Every failure improves the system
5. **Human operator awareness** — Critical events escalate immediately

---

# INTEGRATION POINTS

This protocol is enforced by Guardian and executed by Hermes. It references:

- `HERMES.md` — Operating rules
- `GUARDIAN_OPERATING_RULES.md` — Governance principles
- `Knowledge/09 Standards/RESOURCE_GOVERNANCE.md` — This document
- `Knowledge/21 Meetings/` — Session checkpoints
- `Knowledge/00 Dashboard/PROJECT_HEALTH_DASHBOARD.md` — Resource metrics
- `Knowledge/16 Technical Debt/DEBT_REGISTER.md` — Resource-related debt

---

*This protocol ensures the Nexus98 ecosystem maintains continuous progress regardless of resource constraints.*