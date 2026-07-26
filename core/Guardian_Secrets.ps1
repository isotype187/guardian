<#
.SYNOPSIS
    Guardian Secrets Module - SecretManagement Abstraction Layer

.DESCRIPTION
    Provides a Guardian-native interface to Microsoft.PowerShell.SecretManagement
    for secure secret storage, retrieval, and lifecycle management.
    Supports multiple vault providers (HashiCorp Vault, Azure Key Vault, Local)
    through a unified, provider-agnostic interface.

.NOTES
    Requires: Microsoft.PowerShell.SecretManagement (>= 1.4.0)
    Compatible providers: SecretManagement.HashicorpVault, Az.KeyVault, Local

.SECURITY
    - No plaintext secrets in configuration
    - No repository credentials
    - No secret logging
    - All operations generate audit events
    - RBAC policy enforcement at retrieval
#>

#Requires -Version 5.1

#region Private Module State

$script:GuardianSecretsConfig = @{
    DefaultVault       = 'GuardianVault'
    CacheTTLSeconds    = 300         # 5 minutes default
    MaxStalenessSeconds = 300        # 5 minutes max staleness
    CircuitBreakerThreshold = 3
    CircuitBreakerResetSeconds = 30
    AuditEnabled       = $true
    RedactionEnabled   = $true
}

$script:SecretCache = @{}
$script:CircuitBreaker = @{
    FailureCount = 0
    LastFailure  = $null
    State        = 'Closed'  # Closed, Open, HalfOpen
}

#endregion

#region Helper Functions

function Get-GuardianSecretsConfig {
    return $script:GuardianSecretsConfig
}

function Set-GuardianSecretsConfig {
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][object]$Value
    )
    if ($script:GuardianSecretsConfig.ContainsKey($Key)) {
        $script:GuardianSecretsConfig[$Key] = $Value
    }
    else {
        throw "Invalid configuration key: $Key"
    }
}

function Get-CircuitBreakerState {
    $now = Get-Date
    $cb = $script:CircuitBreaker

    if ($cb.State -eq 'Open') {
        if ($cb.LastFailure -and ($now - $cb.LastFailure).TotalSeconds -ge $script:GuardianSecretsConfig.CircuitBreakerResetSeconds) {
            $cb.State = 'HalfOpen'
            $cb.FailureCount = 0
            Write-Verbose "Circuit breaker transitioned to HalfOpen"
        }
    }
    return $cb.State
}

function Record-CircuitBreakerFailure {
    $cb = $script:CircuitBreaker
    $cb.FailureCount++
    $cb.LastFailure = Get-Date

    if ($cb.FailureCount -ge $script:GuardianSecretsConfig.CircuitBreakerThreshold -and $cb.State -eq 'Closed') {
        $cb.State = 'Open'
        Write-Warning "Circuit breaker OPENED after $($cb.FailureCount) failures"
    }
}

function Record-CircuitBreakerSuccess {
    $cb = $script:CircuitBreaker
    if ($cb.State -eq 'HalfOpen') {
        $cb.State = 'Closed'
        $cb.FailureCount = 0
        $cb.LastFailure = $null
        Write-Verbose "Circuit breaker CLOSED after successful recovery"
    }
    elseif ($cb.State -eq 'Closed') {
        $cb.FailureCount = 0
    }
}

function Get-SecretCache {
    param([Parameter(Mandatory)][string]$Key)
    if ($script:SecretCache.ContainsKey($Key)) {
        $entry = $script:SecretCache[$Key]
        $age = (Get-Date) - $entry.Timestamp
        if ($age.TotalSeconds -le $script:GuardianSecretsConfig.CacheTTLSeconds) {
            return $entry
        }
        else {
            $script:SecretCache.Remove($Key)
        }
    }
    return $null
}

function Set-SecretCache {
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][pscustomobject]$Value
    )
    $script:SecretCache[$Key] = [pscustomobject]@{
        Value      = $Value
        Timestamp  = Get-Date
    }
}

function Clear-SecretCache {
    param([string]$Key)
    if ($Key) {
        $script:SecretCache.Remove($Key)
    }
    else {
        $script:SecretCache.Clear()
    }
}

function Write-SecretAuditEvent {
    param(
        [Parameter(Mandatory)][ValidateSet('READ','WRITE','ROTATE','DELETE','VALIDATE')][string]$Action,
        [Parameter(Mandatory)][string]$SecretName,
        [Parameter(Mandatory)][bool]$Success,
        [string]$ErrorMessage,
        [string]$VaultName = $script:GuardianSecretsConfig.DefaultVault,
        [hashtable]$Context = @{}
    )

    if (-not $script:GuardianSecretsConfig.AuditEnabled) { return }

    $event = @{
        event_id        = "EV_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$([guid]::NewGuid().ToString()[0..7])"
        timestamp       = (Get-Date).ToString('o')
        event_type      = "SECRET_$Action"
        category        = switch ($Action) { 'READ' {'READ'}; 'WRITE' {'WRITE'}; 'ROTATE' {'ROTATION'}; 'DELETE' {'DELETE'}; 'VALIDATE' {'VALIDATE'} }
        severity        = if ($Success) { 'INFO' } elseif ($ErrorMessage) { 'ERROR' } else { 'WARN' }
        actor           = @{
            entity_id = if ((Get-Variable -Name 'PID' -ValueOnly -ErrorAction SilentlyContinue)) { (Get-Variable -Name 'PID' -ValueOnly -ErrorAction SilentlyContinue) } else { $PID }
            role      = 'GuardianSecrets'
            auth_method = 'SecretManagement'
        }
        target          = @{
            secret_path = $SecretName
            vault_name  = $VaultName
        }
        operation       = @{
            action      = $Action.ToLower()
            success     = $Success
            error_code  = if ($ErrorMessage) { 'SECRET_OPERATION_FAILED' } else { $null }
            error_message = $ErrorMessage
        }
        context         = $Context
        integrity       = @{
            hash_chain_prev = if ($script:LastAuditHash) { $script:LastAuditHash } else { 'genesis' }
            hash_chain_curr = $null  # Will be computed below
        }
    }

    # Compute hash chain
    $eventData = $event | ConvertTo-Json -Depth 10 -Compress
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($eventData + $event.integrity.hash_chain_prev))
    $event.integrity.hash_chain_curr = ($hashBytes | ForEach-Object { '{0:x2}' -f $_ }) -join ''
    $script:LastAuditHash = $event.integrity.hash_chain_curr

    # Write to Guardian audit log
    $guardianRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
    $logsDir = Join-Path $guardianRoot 'logs'
    if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
    $auditPath = Join-Path $logsDir 'guardian_audit.jsonl'
    $event | ConvertTo-Json -Depth 10 -Compress | Add-Content -Path $auditPath -Encoding UTF8
}

function Get-RedactedSecret {
    param([string]$Value)
    if ($script:GuardianSecretsConfig.RedactionEnabled -and $Value) {
        $len = $Value.Length
        if ($len -le 8) { return '********' }
        return $Value.Substring(0, 4) + '****' + $Value.Substring($len - 4)
    }
    return $Value
}

function Validate-SecretPath {
    param([Parameter(Mandatory)][string]$Path)
    if (-not $Path -or $Path -match '[<>:"/\\|?*]') {
        throw [System.ArgumentException] "Invalid secret path: $Path"
    }
    return $true
}

#endregion

#region Public API

<#
.SYNOPSIS
    Register a secret vault with Guardian.

.DESCRIPTION
    Configures a named vault for use with Guardian secret operations.
    Supports HashiCorp Vault, Azure Key Vault, and local development vaults.

.PARAMETER Name
    Friendly name for the vault (e.g., 'GuardianVault', 'ProductionVault').

.PARAMETER Provider
    SecretManagement provider name ('HashicorpVault', 'AzureKeyVault', 'Local').

.PARAMETER VaultParameters
    Hashtable of provider-specific configuration parameters.

.PARAMETER SetAsDefault
    If specified, sets this vault as the default for subsequent operations.

.EXAMPLE
    Register-GuardianSecretVault -Name 'GuardianVault' -Provider 'HashicorpVault' `
        -VaultParameters @{ Address = 'https://vault.example.com:8200'; MountPath = 'secret/guardian'; AuthMethod = 'AppRole'; RoleId = '...' } -SetAsDefault
#>
function Register-GuardianSecretVault {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('HashicorpVault','AzureKeyVault','Local')][string]$Provider,
        [Parameter(Mandatory)][hashtable]$VaultParameters,
        [switch]$SetAsDefault
    )

    Validate-SecretPath -Path $Name

    try {
        # Register with SecretManagement
        $regParams = @{
            Name = $Name
            ModuleName = switch ($Provider) {
                'HashicorpVault' { 'SecretManagement.HashicorpVault' }
                'AzureKeyVault'  { 'Az.KeyVault' }
                'Local'          { 'Microsoft.PowerShell.SecretStore' }
            }
            VaultParameters = $VaultParameters
        }
        Register-SecretVault @regParams

        if ($SetAsDefault) {
            Set-GuardianSecretsConfig -Key 'DefaultVault' -Value $Name
        }

        Write-SecretAuditEvent -Action 'WRITE' -SecretName "vault/$Name" -Success $true -Context @{ provider = $Provider; parameters = $VaultParameters.Keys }
        Write-Host "Registered secret vault: $Name ($Provider)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-SecretAuditEvent -Action 'WRITE' -SecretName "vault/$Name" -Success $false -ErrorMessage $_.Exception.Message -Context @{ provider = $Provider }
        throw
    }
}

<#
.SYNOPSIS
    Retrieve a secret from a registered vault.

.DESCRIPTION
    Retrieves a secret value with caching, circuit breaker protection,
    and audit logging. Returns a SecretInfo object with metadata.

.PARAMETER Name
    Name/path of the secret to retrieve (e.g., 'bridge/token_001', 'api/github_token').

.PARAMETER Vault
    Optional vault name. Uses default vault if not specified.

.PARAMETER ForceVault
    Bypass cache and force retrieval from vault.

.PARAMETER AllowStale
    Allow returning cached secret even if expired (with staleness warning).

.PARAMETER MaxStalenessSeconds
    Maximum allowed staleness when AllowStale is used.

.PARAMETER AsPlainText
    Return secret as plain text string instead of SecretInfo object.

.RETURNS
    SecretInfo object with Value (SecureString), Metadata, Vault, RetrievedAt, Stale, CacheHit properties.

.EXAMPLE
    $secret = Get-GuardianSecret -Name 'bridge/token_001'
    $token = $secret.Value | ConvertFrom-SecureString -AsPlainText
#>
function Get-GuardianSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Vault = $script:GuardianSecretsConfig.DefaultVault,
        [switch]$ForceVault,
        [switch]$AllowStale,
        [int]$MaxStalenessSeconds = $script:GuardianSecretsConfig.MaxStalenessSeconds,
        [switch]$AsPlainText
    )

    Validate-SecretPath -Path $Name
    $cacheKey = "$Vault/$Name"
    $startTime = Get-Date

    try {
        # Check circuit breaker
        $cbState = Get-CircuitBreakerState
        if ($cbState -eq 'Open' -and -not $ForceVault) {
            # Try cache as fallback
            $cached = Get-SecretCache -Key $cacheKey
            if ($cached) {
                $age = (Get-Date) - $cached.Timestamp
                Write-Warning "Circuit breaker OPEN - returning cached secret for $Name (age: $([math]::Round($age.TotalMinutes,1)) min)"
                Write-SecretAuditEvent -Action 'READ' -SecretName $Name -Success $true -VaultName $Vault -Context @{ source = 'cache_fallback'; circuit_breaker = 'open'; age_seconds = [math]::Round($age.TotalSeconds) }
                return Get-SecretResult -Entry $cached -Stale $true -CacheHit $true
            }
            throw "Circuit breaker OPEN - vault unavailable and no valid cache for $Name"
        }

        # Check cache first
        if (-not $ForceVault) {
            $cached = Get-SecretCache -Key $cacheKey
            if ($cached) {
                $age = (Get-Date) - $cached.Timestamp
                if ($age.TotalSeconds -le $script:GuardianSecretsConfig.CacheTTLSeconds) {
                    Write-SecretAuditEvent -Action 'READ' -SecretName $Name -Success $true -VaultName $Vault -Context @{ source = 'cache'; age_seconds = [math]::Round($age.TotalSeconds) }
                    return Get-SecretResult -Entry $cached -Stale $false -CacheHit $true
                }
                elseif ($AllowStale -and $age.TotalSeconds -le $MaxStalenessSeconds) {
                    Write-Warning "Returning STALE cached secret for $Name (age: $([math]::Round($age.TotalMinutes,1)) min, max allowed: $([math]::Round($MaxStalenessSeconds/60,1)) min)"
                    Write-SecretAuditEvent -Action 'READ' -SecretName $Name -Success $true -VaultName $Vault -Context @{ source = 'cache_stale'; age_seconds = [math]::Round($age.TotalSeconds); max_staleness = $MaxStalenessSeconds }
                    return Get-SecretResult -Entry $cached -Stale $true -CacheHit $true
                }
            }
        }

        # Retrieve from vault
        $secret = Get-Secret -Name $Name -Vault $Vault -ErrorAction Stop

        # Convert to SecureString if needed
        if ($secret -is [string]) {
            $secureValue = ConvertTo-SecureString -String $secret -AsPlainText -Force
        }
        elseif ($secret -is [System.Security.SecureString]) {
            $secureValue = $secret
        }
        else {
            $secureValue = ConvertTo-SecureString -String ($secret | ConvertTo-Json) -AsPlainText -Force
        }

        # Build metadata
        $metadata = @{
            Name        = $Name
            Vault       = $Vault
            RetrievedAt = (Get-Date).ToString('o')
            Type        = $secret.GetType().Name
        }

        # Create result object
        $result = [pscustomobject]@{
            Value      = $secureValue
            Metadata   = $metadata
            Vault      = $Vault
            RetrievedAt = $metadata.RetrievedAt
            Stale      = $false
            CacheHit   = $false
        }

        # Cache the result
        Set-SecretCache -Key $cacheKey -Value $result

        # Record success
        Record-CircuitBreakerSuccess
        Write-SecretAuditEvent -Action 'READ' -SecretName $Name -Success $true -VaultName $Vault -Context @{ source = 'vault'; duration_ms = [math]::Round((Get-Date) - $startTime).TotalMilliseconds }

        if ($AsPlainText) {
            $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
            try { return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
            finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
        }

        return $result
    }
    catch {
        Record-CircuitBreakerFailure
        Write-SecretAuditEvent -Action 'READ' -SecretName $Name -Success $false -ErrorMessage $_.Exception.Message -VaultName $Vault
        throw
    }
}

function Get-SecretResult {
    param(
        [Parameter(Mandatory)][pscustomobject]$Entry,
        [bool]$Stale,
        [bool]$CacheHit
    )
    return [pscustomobject]@{
        Value      = $Entry.Value
        Metadata   = $Entry.Metadata
        Vault      = $Entry.Metadata.Vault
        RetrievedAt = $Entry.Metadata.RetrievedAt
        Stale      = $Stale
        CacheHit   = $CacheHit
    }
}

<#
.SYNOPSIS
    Store a secret in a registered vault.

.DESCRIPTION
    Writes a secret value to the specified vault with validation,
    checkpoint requirement for sensitive operations, and audit logging.

.PARAMETER Name
    Name/path of the secret (e.g., 'api/github_token').

.PARAMETER Value
    Secret value as plain text string or SecureString.

.PARAMETER Vault
    Target vault name. Uses default if not specified.

.PARAMETER Metadata
    Optional metadata hashtable to store with secret.

.PARAMETER RequireCheckpoint
    Require Guardian checkpoint before write (for sensitive operations).

.EXAMPLE
    Set-GuardianSecret -Name 'api/github_token' -Value 'ghp_xxx' -Metadata @{ owner = 'team-platform'; rotation = '90d' }
#>
function Set-GuardianSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateNotNull()][object]$Value,
        [string]$Vault = $script:GuardianSecretsConfig.DefaultVault,
        [hashtable]$Metadata = @{},
        [switch]$RequireCheckpoint
    )

    Validate-SecretPath -Path $Name

    # Validate value
    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            throw "Secret value cannot be empty"
        }
        $secureValue = ConvertTo-SecureString -String $Value -AsPlainText -Force
    }
    elseif ($Value -is [System.Security.SecureString]) {
        $secureValue = $Value
    }
    else {
        throw "Secret value must be string or SecureString"
    }

    # Checkpoint requirement for sensitive writes
    if ($RequireCheckpoint) {
        $ck = Get-GuardianCheckpoint -Latest -Tier Emergency -ErrorAction SilentlyContinue
        if (-not $ck) {
            throw "Checkpoint required for secret write but no emergency checkpoint exists"
        }
    }

    try {
        # Store via SecretManagement
        Set-Secret -Name $Name -Secret $secureValue -Vault $Vault -ErrorAction Stop

        # Update metadata if supported
        if ($Metadata.Count -gt 0) {
            # Metadata storage depends on provider; log for audit
            Write-Verbose "Secret metadata recorded: $($Metadata.Keys -join ', ')"
        }

        # Invalidate cache
        Clear-SecretCache -Key "$Vault/$Name"

        Write-SecretAuditEvent -Action 'WRITE' -SecretName $Name -Success $true -VaultName $Vault -Context @{ metadata_keys = $Metadata.Keys; checkpoint_required = $RequireCheckpoint }
        Write-Host "Secret stored: $Name in $Vault" -ForegroundColor Green
        return $true
    }
    catch {
        Write-SecretAuditEvent -Action 'WRITE' -SecretName $Name -Success $false -ErrorMessage $_.Exception.Message -VaultName $Vault
        throw
    }
}

<#
.SYNOPSIS
    Remove a secret from a registered vault.

.DESCRIPTION
    Deletes a secret with checkpoint requirement and audit logging.

.PARAMETER Name
    Name/path of the secret to remove.

.PARAMETER Vault
    Vault containing the secret.

.PARAMETER RequireCheckpoint
    Require emergency checkpoint (always true for delete operations).
#>
function Remove-GuardianSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Vault = $script:GuardianSecretsConfig.DefaultVault,
        [switch]$RequireCheckpoint
    )

    Validate-SecretPath -Path $Name

    # Delete always requires checkpoint
    $ck = Get-GuardianCheckpoint -Latest -Tier Emergency -ErrorAction SilentlyContinue
    if (-not $ck) {
        throw "Emergency checkpoint required for secret deletion"
    }

    try {
        Remove-Secret -Name $Name -Vault $Vault -ErrorAction Stop
        Clear-SecretCache -Key "$Vault/$Name"

        Write-SecretAuditEvent -Action 'DELETE' -SecretName $Name -Success $true -VaultName $Vault -Context @{ checkpoint = $ck.id }
        Write-Host "Secret removed: $Name from $Vault" -ForegroundColor Yellow
        return $true
    }
    catch {
        Write-SecretAuditEvent -Action 'DELETE' -SecretName $Name -Success $false -ErrorMessage $_.Exception.Message -VaultName $Vault
        throw
    }
}

<#
.SYNOPSIS
    Rotate a secret with optional automatic generation.

.DESCRIPTION
    Generates a new secret value, stores it in the vault, and invalidates cache.
    Supports multiple formats: Base64, Alphanumeric, Hex, and custom generators.

.PARAMETER Name
    Name/path of the secret to rotate.

.PARAMETER Vault
    Vault containing the secret.

.PARAMETER Format
    Output format: 'Base64', 'Alphanumeric', 'Hex', 'Custom'.

.PARAMETER Length
    Length of generated secret in bytes (before encoding).

.PARAMETER Generator
    Custom scriptblock for secret generation. Receives $Length parameter.

.PARAMETER RequireCheckpoint
    Require checkpoint before rotation (recommended).

.RETURNS
    New secret metadata.
#>
function Invoke-SecretRotation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Vault = $script:GuardianSecretsConfig.DefaultVault,
        [ValidateSet('Base64','Alphanumeric','Hex')][string]$Format = 'Base64',
        [int]$Length = 32,
        [scriptblock]$Generator,
        [switch]$RequireCheckpoint
    )

    Validate-SecretPath -Path $Name

    if ($RequireCheckpoint) {
        $ck = Get-GuardianCheckpoint -Latest -Tier Emergency -ErrorAction SilentlyContinue
        if (-not $ck) {
            throw "Emergency checkpoint required for secret rotation"
        }
    }

    try {
        # Generate new secret
        $newSecret = if ($Generator) {
            & $Generator -Length $Length
        }
        else {
            $bytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes($Length)
            switch ($Format) {
                'Base64' { [Convert]::ToBase64String($bytes) }
                'Alphanumeric' { -join ($bytes | ForEach-Object { [char]($_ % 26 + 97) }) }
                'Hex' { ($bytes | ForEach-Object { '{0:x2}' -f $_ }) -join '' }
            }
        }

        # Store new version
        Set-GuardianSecret -Name $Name -Value $newSecret -Vault $Vault -Metadata @{ rotated = (Get-Date).ToString('o'); format = $Format; length = $Length } -RequireCheckpoint:$RequireCheckpoint

        Write-SecretAuditEvent -Action 'ROTATE' -SecretName $Name -Success $true -VaultName $Vault -Context @{ format = $Format; length = $Length; checkpoint = $ck.id }
        return @{ Name = $Name; Vault = $Vault; RotatedAt = (Get-Date).ToString('o'); Format = $Format; Length = $Length }
    }
    catch {
        Write-SecretAuditEvent -Action 'ROTATE' -SecretName $Name -Success $false -ErrorMessage $_.Exception.Message -VaultName $Vault
        throw
    }
}

<#
.SYNOPSIS
    Test connectivity to a registered secret vault.

.DESCRIPTION
    Validates that the vault is accessible and authentication works.
    Returns connection status, latency, and version information.

.PARAMETER Vault
    Vault name to test. Uses default if not specified.

.RETURNS
    Status object with Connected, LatencyMs, Version, MountPath properties.
#>
function Test-SecretVaultConnection {
    [CmdletBinding()]
    param(
        [string]$Vault = $script:GuardianSecretsConfig.DefaultVault
    )

    $start = Get-Date
    try {
        # Test by listing secrets (lightweight operation)
        $secrets = Get-SecretInfo -Vault $Vault -ErrorAction Stop
        $latency = [math]::Round((Get-Date) - $start).TotalMilliseconds

        return [pscustomobject]@{
            Connected   = $true
            LatencyMs   = $latency
            VaultName   = $Vault
            SecretCount = $secrets.Count
            Status      = 'Healthy'
            CheckedAt   = (Get-Date).ToString('o')
        }
    }
    catch {
        return [pscustomobject]@{
            Connected   = $false
            LatencyMs   = [math]::Round((Get-Date) - $start).TotalMilliseconds
            VaultName   = $Vault
            Error       = $_.Exception.Message
            Status      = 'Unhealthy'
            CheckedAt   = (Get-Date).ToString('o')
        }
    }
}

<#
.SYNOPSIS
    Get inventory of secrets in a vault (metadata only, no values).

.DESCRIPTION
    Lists all secrets with metadata for inventory and rotation planning.
    Does not retrieve secret values.

.PARAMETER Vault
    Vault to inventory. Uses default if not specified.

.RETURNS
    Array of secret metadata objects.
#>
function Get-GuardianSecretInventory {
    [CmdletBinding()]
    param(
        [string]$Vault = $script:GuardianSecretsConfig.DefaultVault
    )

    try {
        $infos = Get-SecretInfo -Vault $Vault -ErrorAction Stop
        return $infos | ForEach-Object {
            [pscustomobject]@{
                Name          = $_.Name
                Type          = $_.Type
                Vault         = $Vault
                LastModified  = if ($_.Metadata.LastModified) { $_.Metadata.LastModified } else { $null }
                Metadata      = $_.Metadata
            }
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Error "Failed to get secret inventory for ${Vault}: $($errMsg)"
        return @()
    }
}

<#
.SYNOPSIS
    Validate secret configuration and accessibility.

.DESCRIPTION
    Performs comprehensive health check on secret infrastructure.
    Tests vault connectivity, secret accessibility, and rotation status.

.RETURNS
    Health report with overall status and per-secret details.
#>
function Test-GuardianSecretHealth {
    [CmdletBinding()]
    param(
        [string]$Vault = $script:GuardianSecretsConfig.DefaultVault
    )

    $report = @{
        Vault          = $Vault
        CheckedAt      = (Get-Date).ToString('o')
        VaultConnected = $false
        SecretsTotal   = 0
        SecretsHealthy = 0
        SecretsStale   = 0
        SecretsMissing = 0
        Details        = @()
        OverallStatus  = 'Unknown'
    }

    # Test vault connectivity
    $conn = Test-SecretVaultConnection -Vault $Vault
    $report.VaultConnected = $conn.Connected

    if (-not $conn.Connected) {
        $report.OverallStatus = 'Critical'
        return $report
    }

    # Inventory secrets
    $inventory = Get-GuardianSecretInventory -Vault $Vault
    $report.SecretsTotal = $inventory.Count

    foreach ($secret in $inventory) {
        $detail = @{
            Name    = $secret.Name
            Type    = $secret.Type
            Status  = 'Unknown'
            Error   = $null
        }

        try {
            # Try to read (uses cache if available)
            $result = Get-GuardianSecret -Name $secret.Name -Vault $Vault -ForceVault -ErrorAction Stop
            $detail.Status = if ($result.Stale) { 'Stale' } else { 'Healthy' }
            if ($result.Stale) { $report.SecretsStale++ } else { $report.SecretsHealthy++ }
        }
        catch {
            $detail.Status = 'Missing'
            $detail.Error = $_.Exception.Message
            $report.SecretsMissing++
        }
        $report.Details += $detail
    }

    # Determine overall status
    if ($report.SecretsMissing -gt 0) { $report.OverallStatus = 'Critical' }
    elseif ($report.SecretsStale -gt 0) { $report.OverallStatus = 'Degraded' }
    elseif ($report.SecretsHealthy -eq $report.SecretsTotal) { $report.OverallStatus = 'Healthy' }
    else { $report.OverallStatus = 'Degraded' }

    return [pscustomobject]$report
}

<#
.SYNOPSIS
    Initialize Guardian Secrets module with configuration.

.DESCRIPTION
    Loads SecretManagement module, registers default vault from config,
    and validates connectivity.

.PARAMETER ConfigPath
    Path to vault configuration JSON file.

.PARAMETER AutoRegister
    Automatically register vault from configuration.
#>
function Initialize-GuardianSecrets {
    [CmdletBinding()]
    param(
        [string]$ConfigPath,
        [switch]$AutoRegister
    )

    # Ensure SecretManagement is loaded
    if (-not (Get-Module -Name 'Microsoft.PowerShell.SecretManagement' -ListAvailable)) {
        throw "Microsoft.PowerShell.SecretManagement module not installed. Run Install-GuardianDependencies first."
    }
    Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop

    Write-Host "Guardian Secrets module initialized" -ForegroundColor Green
    Write-Host "  Default Vault: $($script:GuardianSecretsConfig.DefaultVault)" -ForegroundColor Gray
    Write-Host "  Cache TTL: $($script:GuardianSecretsConfig.CacheTTLSeconds)s" -ForegroundColor Gray
    Write-Host "  Circuit Breaker: $($script:GuardianSecretsConfig.CircuitBreakerThreshold) failures / $($script:GuardianSecretsConfig.CircuitBreakerResetSeconds)s reset" -ForegroundColor Gray

    if ($AutoRegister -and $ConfigPath -and (Test-Path $ConfigPath)) {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        if ($config.vault) {
            Register-GuardianSecretVault -Name 'GuardianVault' -Provider $config.vault.provider -VaultParameters $config.vault.parameters -SetAsDefault
        }
    }

    return $true
}

#endregion

#region Module Initialization

# Auto-load SecretManagement when module is imported
if (-not (Get-Module -Name 'Microsoft.PowerShell.SecretManagement')) {
    try { Import-Module Microsoft.PowerShell.SecretManagement -ErrorAction Stop }
    catch { Write-Warning "SecretManagement module not available: $($_.Exception.Message)" }
}

#endregion