# ADR-005: CI/CD Secret Authentication Strategy

**Status:** Proposed  
**Date:** 2026-07-26  
**Author:** Guardian Engineering Team  
**Reviewers:** Guardian Security Architecture, Platform Lead  

---

## 1. Context

Guardian CI/CD pipelines (GitHub Actions) need authenticated access to HashiCorp Vault for:
- Retrieving bridge tokens for Nexus98 communication
- Reading API keys for integration tests
- Accessing database credentials for integration tests
- Writing audit events to Vault

Current state: No CI/CD secret access implemented. Pipelines run without Vault authentication.

---

## 2. Decision Required

Select the authentication method for GitHub Actions workflows to access Vault:

| Option | Method | Credential Storage | Token Lifetime | Complexity |
|--------|--------|-------------------|----------------|------------|
| **A** | AppRole | Role ID (repo secret) + Secret ID (OIDC-wrapped) | 1h (renewable) | Medium |
| **B** | OIDC (Workload Identity) | None (ephemeral) | 20m (auto-refresh) | High |
| **C** | Userpass | Username + password (repo secrets) | 1h | Low |
| **D** | Static Token | Vault token (repo secret) | Configurable | Lowest |

---

## 3. Option Analysis

### Option A: AppRole with OIDC-Delivered Secret ID

**Architecture:**
```
GitHub Action
    │
    ├─► OIDC Token (GitHub-provided JWT)
    │
    ▼
Vault OIDC Auth Method (role: guardian-ci)
    │
    ├─► Validates JWT claims (repo, branch, actor)
    │
    ▼
Returns wrapped Secret ID for guardian-system AppRole
    │
    ▼
Action unwraps Secret ID
    │
    ▼
Login with Role ID + Secret ID
    │
    ▼
Client token (1h TTL, renewable)
```

**Pros:**
- No long-lived secrets in GitHub secrets
- Secret ID delivered just-in-time, single-use
- Role ID can be public (not sensitive)
- AppRole token renewable (1h period)
- Bound to GitHub context (repo, branch, actor)
- Supports short-lived Secret ID (24h TTL, 1 use)

**Cons:**
- More configuration steps
- Requires Vault OIDC auth method setup
- Slightly longer workflow setup

**Security:**
- Attack surface: OIDC token theft (short-lived, bound to workflow run)
- No stored credentials to rotate
- Audit trail: every CI run gets unique token

---

### Option B: OIDC Workload Identity (Direct)

**Architecture:**
```
GitHub Action
    │
    ├─► OIDC Token (JWT)
    │
    ▼
Vault JWT/OIDC Auth Method
    │
    ├─► Maps claims → policies directly
    │
    ▼
Client token (20m TTL, auto-renewable)
```

**Pros:**
- Zero secrets in GitHub
- Simplest runtime (no unwrap step)
- Native workload identity pattern
- Token auto-renewal via GitHub Actions `actions/id-token-request`

**Cons:**
- Requires Vault 1.12+ JWT auth method
- Policy mapping complex (claims → policies)
- Token TTL limited (20m default)
- No AppRole period for long-running jobs
- Harder to audit which workflow got which policy

**Security:**
- Best: no stored credentials at all
- Risk: OIDC token theft (same as Option A)

---

### Option C: Username/Password (Userpass Auth Method)

**Pros:**
- Simple to configure
- Familiar pattern

**Cons:**
- Password stored in GitHub secrets (rotation required)
- No bound CIDR for GitHub Actions IPs (dynamic)
- Audit shows generic "userpass" auth
- Password complexity requirements

**Security:** Low — static credentials are anti-pattern

---

### Option D: Static Vault Token

**Pros:**
- Simplest implementation

**Cons:**
- Token in GitHub secrets (high risk if leaked)
- No automatic rotation
- Full token permissions if not carefully scoped
- Audit shows token, not workflow identity

**Security:** Unacceptable for production

---

## 4. Recommendation

### **Selected: Option A — AppRole with OIDC-Delivered Secret ID**

**Justification:**
1. **Zero long-lived secrets in GitHub** — Role ID public, Secret ID delivered ephemerally
2. **Workload identity** — OIDC validates GitHub context before releasing Secret ID
3. **Renewable tokens** — AppRole period supports long-running jobs (up to 24h with renewal)
4. **Auditability** — Each workflow run gets unique client token, traceable to run ID
4. **Least privilege** — AppRole policy scoped to CI needs only
5. **Failure isolation** — Compromised Secret ID usable once, 24h max
6. **Industry standard** — HashiCorp recommended pattern for CI/CD

---

## 5. Implementation Plan

### 5.1 Vault Configuration

```hcl
# 1. Enable OIDC auth method for GitHub
path "auth/oidc" {
  type = "oidc"
}

# 2. Configure GitHub as OIDC provider
# Provider URL: https://token.actions.githubusercontent.com
# Allowed audiences: vault
# Claim mappings: repository → github_repo, ref → github_ref, actor → github_actor

# 3. Create OIDC role for CI
path "auth/oidc/role/guardian-ci" {
  bound_audiences = ["vault"]
  allowed_redirect_uris = ["https://github.com/<org>/<repo>"]
  user_claim = "repository"
  role_type = "jwt"
  policies = ["guardian-ci-oidc"]  # Policy that grants unwrap permission
  ttl = "20m"
}

# 4. Policy for CI: can only unwrap Secret ID for guardian-system
path "sys/wrapping/unwrap" {
  capabilities = ["update"]
}

# 5. AppRole for runtime operations
path "auth/approle/role/guardian-system" {
  token_policies = ["guardian-system"]
  token_ttl = "1h"
  token_max_ttl = "4h"
  token_period = "1h"
  bind_secret_id = true
  secret_id_ttl = "24h"
  secret_id_num_uses = 1
  bound_cidr_list = ["10.0.0.0/8", "172.16.0.0/12"]
}

# 6. Policy to allow unwrapping for CI
path "sys/wrapping/unwrap" {
  capabilities = ["update"]
}

# (Attached to guardian-ci-oidc policy)
```

### 5.2 GitHub Actions Workflow

```yaml
# .github/workflows/guardian-ci.yml
permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Get OIDC Token
        id: oidc
        uses: actions/github-script@v7
        with:
          script: |
            const token = await core.getIDToken('vault');
            core.setOutput('token', token);
      
      - name: Unwrap Secret ID
        id: unwrap
        env:
          VAULT_ADDR: ${{ secrets.VAULT_ADDR }}
          OIDC_TOKEN: ${{ steps.oidc.outputs.token }}
        run: |
          $response = Invoke-RestMethod -Method Post `
            -Uri "$env:VAULT_ADDR/v1/sys/wrapping/unwrap" `
            -Headers @{ "X-Vault-Token" = $env:OIDC_TOKEN } `
            -ContentType 'application/json'
          $secretId = $response.data.secret_id
          echo "SECRET_ID=$secretId" >> $env:GITHUB_OUTPUT
      
      - name: Login to Vault
        id: vault-login
        env:
          VAULT_ADDR: ${{ secrets.VAULT_ADDR }}
          ROLE_ID: ${{ secrets.VAULT_ROLE_ID }}
          SECRET_ID: ${{ steps.unwrap.outputs.SECRET_ID }}
        run: |
          $login = @{
            role_id = $env:ROLE_ID
            secret_id = $env:SECRET_ID
          } | ConvertTo-Json
          $response = Invoke-RestMethod -Method Post `
            -Uri "$env:VAULT_ADDR/v1/auth/approle/login" `
            -Body $login -ContentType 'application/json'
          $token = $response.auth.client_token
          echo "VAULT_TOKEN=$token" >> $env:GITHUB_OUTPUT
      
      - name: Run Tests with Vault
        env:
          VAULT_ADDR: ${{ secrets.VAULT_ADDR }}
          VAULT_TOKEN: ${{ steps.vault-login.outputs.VAULT_TOKEN }}
        run: |
          # Tests can now use Vault via VAULT_TOKEN
          ./scripts/Run-GuardianTests.ps1 -Mode Integration
```

### 5.3 GitHub Repository Secrets

| Secret | Value | Rotation |
|--------|-------|----------|
| `VAULT_ADDR` | `https://vault.example.com:8200` | N/A (public) |
| `VAULT_ROLE_ID` | `<guardian-system-role-id>` | Annual |

**NOT stored:** Secret ID (delivered at runtime), Vault token (ephemeral)

---

## 6. Security Properties

| Property | Implementation |
|----------|----------------|
| **Secret rotation** | Secret ID: 24h TTL, 1-use; Client token: 1h TTL, renewable |
| **Least privilege** | AppRole policy `guardian-system` scoped to CI needs |
| **Network controls** | CIDR binding to Guardian subnets |
| **Audit** | Every CI run: OIDC auth → unwrap → AppRole login → operations |
| **Revocation** | Disable AppRole or delete Secret ID instantly |
| **Compromise blast radius** | Single workflow run (Secret ID 1-use, token 1h) |

---

## 7. Failure Scenarios

| Scenario | Behavior | Mitigation |
|----------|----------|------------|
| OIDC token expired | Workflow fails at unwrap step | Token TTL 20m > workflow init time |
| Vault unavailable | All steps fail fast | Circuit breaker in Guardian modules |
| AppRole disabled | Login fails | Alert on auth failure rate |
| Secret ID used twice | Second unwrap fails | Alert on unwrap failure |
| Role ID leaked | Not sensitive alone | Requires Secret ID + CIDR |

---

## 8. Migration Path

| Phase | Action |
|-------|--------|
| 1 | Deploy Vault OIDC + AppRole config (staging) |
| 2 | Test workflow in feature branch |
| 3 | Validate audit logs, token lifecycle |
| 4 | Deploy to production Vault |
| 5 | Update production workflows |
| 6 | Remove any legacy static tokens |

---

## 9. Related Documents

- `SECRET_RETRIEVAL_POLICY.md` — Runtime secret access
- `RBAC_SECRET_MAPPING.md` — `guardian-system` policy definition
- `RUNBOOK_SECRET_FAILURES.md` — Circuit breaker, fallback
- `PROJECT_INDEX.md` — WQ-002 tracking

---

## 10. Decision Record

| Item | Value |
|------|-------|
| **Decision** | AppRole with OIDC-delivered Secret ID (Option A) |
| **Decided By** | Guardian Security Architecture |
| **Date** | 2026-07-26 |
| **Review Date** | 2026-10-26 |
| **Supersedes** | None (new capability) |

---

*This ADR authorizes implementation of CI/CD Vault authentication per the above specification.*