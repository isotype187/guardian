# Pester tests for Guardian Secrets module (WQ-002 Secrets Management)

BeforeAll {
    . (Join-Path $PSScriptRoot '..\core\Guardian_Loader.ps1')
    Import-Guardian -Root (Resolve-Path (Join-Path $PSScriptRoot '..'))
    
    # Load the Secrets module
    . (Join-Path $PSScriptRoot '..\core\Guardian_Secrets.ps1')
    
    # Initialize with a local test vault
    $testVaultParams = @{
        Name = 'TestVault'
        ModuleName = 'Microsoft.PowerShell.SecretStore'
        VaultParameters = @{}
    }
    try {
        Register-SecretVault @testVaultParams -ErrorAction SilentlyContinue
    }
    catch {
        # Vault might already exist
    }
}

Describe 'Guardian Secrets Module - Registration' {
    It 'registers a local test vault' {
        $result = Register-GuardianSecretVault -Name 'TestVault2' -Provider 'Local' -VaultParameters @{} -SetAsDefault
        $result | Should -Be $true
    }
    
    It 'rejects invalid vault names' {
        { Register-GuardianSecretVault -Name 'invalid<name>' -Provider 'Local' -VaultParameters @{} } | Should -Throw
    }
}

Describe 'Guardian Secrets Module - Secret CRUD Operations' {
    BeforeEach {
        # Clean up test secrets
        Remove-Secret -Name 'test/secret1' -Vault 'TestVault' -ErrorAction SilentlyContinue
        Remove-Secret -Name 'test/secret2' -Vault 'TestVault' -ErrorAction SilentlyContinue
        Remove-Secret -Name 'test/secret3' -Vault 'TestVault' -ErrorAction SilentlyContinue
    }
    
    It 'stores and retrieves a plain text secret' {
        Set-GuardianSecret -Name 'test/secret1' -Value 'my-secret-value' -Vault 'TestVault'
        $secret = Get-GuardianSecret -Name 'test/secret1' -Vault 'TestVault'
        
        $secret | Should -Not -BeNullOrEmpty
        $secret.Metadata.Name | Should -Be 'test/secret1'
        $secret.Vault | Should -Be 'TestVault'
        $secret.Stale | Should -Be $false
        $secret.CacheHit | Should -Be $false
        
        # Verify value
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.Value)
        try { 
            $value = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
            $value | Should -Be 'my-secret-value'
        }
        finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
    
    It 'stores and retrieves a SecureString secret' {
        $secure = ConvertTo-SecureString -String 'secure-value' -AsPlainText -Force
        Set-GuardianSecret -Name 'test/secret2' -Value $secure -Vault 'TestVault'
        $secret = Get-GuardianSecret -Name 'test/secret2' -Vault 'TestVault'
        
        $secret.Value | Should -Not -BeNullOrEmpty
        $secret.Value | Should -BeOfType [System.Security.SecureString]
    }
    
    It 'caches secret on first read' {
        Set-GuardianSecret -Name 'test/secret3' -Value 'cache-test' -Vault 'TestVault'
        
        # First read - cache miss
        $secret1 = Get-GuardianSecret -Name 'test/secret3' -Vault 'TestVault'
        $secret1.CacheHit | Should -Be $false
        
        # Second read - cache hit
        $secret2 = Get-GuardianSecret -Name 'test/secret3' -Vault 'TestVault'
        $secret2.CacheHit | Should -Be $true
    }
    
    It 'bypasses cache with ForceVault' {
        Set-GuardianSecret -Name 'test/secret4' -Value 'force-test' -Vault 'TestVault'
        $secret1 = Get-GuardianSecret -Name 'test/secret4' -Vault 'TestVault'
        $secret2 = Get-GuardianSecret -Name 'test/secret4' -Vault 'TestVault' -ForceVault
        
        $secret2.CacheHit | Should -Be $false
    }
    
    It 'returns stale secret with AllowStale' {
        Set-GuardianSecret -Name 'test/secret5' -Value 'stale-test' -Vault 'TestVault'
        $secret1 = Get-GuardianSecret -Name 'test/secret5' -Vault 'TestVault'
        
        # Manually expire cache by manipulating timestamp
        $cacheKey = 'TestVault/test/secret5'
        $script:SecretCache[$cacheKey].Timestamp = (Get-Date).AddMinutes(-10)
        
        # Without AllowStale - should throw
        { Get-GuardianSecret -Name 'test/secret5' -Vault 'TestVault' } | Should -Throw
        
        # With AllowStale - should return stale
        $secret = Get-GuardianSecret -Name 'test/secret5' -Vault 'TestVault' -AllowStale -MaxStalenessSeconds 600
        $secret.Stale | Should -Be $true
        $secret.CacheHit | Should -Be $true
    }
    
    It 'rejects empty secret values' {
        { Set-GuardianSecret -Name 'test/empty' -Value '' -Vault 'TestVault' } | Should -Throw
        { Set-GuardianSecret -Name 'test/empty2' -Value '   ' -Vault 'TestVault' } | Should -Throw
    }
    
    It 'rejects invalid secret paths' {
        { Get-GuardianSecret -Name 'invalid<path>' -Vault 'TestVault' } | Should -Throw
        { Set-GuardianSecret -Name 'bad|path' -Value 'test' -Vault 'TestVault' } | Should -Throw
    }
}

Describe 'Guardian Secrets Module - Secret Rotation' {
    BeforeEach {
        Remove-Secret -Name 'test/rotate1' -Vault 'TestVault' -ErrorAction SilentlyContinue
        Remove-Secret -Name 'test/rotate2' -Vault 'TestVault' -ErrorAction SilentlyContinue
    }
    
    It 'rotates secret with Base64 format' {
        Set-GuardianSecret -Name 'test/rotate1' -Value 'original' -Vault 'TestVault'
        $result = Invoke-SecretRotation -Name 'test/rotate1' -Vault 'TestVault' -Format 'Base64' -Length 32
        
        $result.Name | Should -Be 'test/rotate1'
        $result.Format | Should -Be 'Base64'
        $result.Length | Should -Be 32
        
        # Verify new value
        $secret = Get-GuardianSecret -Name 'test/rotate1' -Vault 'TestVault' -ForceVault
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.Value)
        try { 
            $value = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
            $value | Should -Match '^[A-Za-z0-9+/]+={0,2}$'
        }
        finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
    
    It 'rotates secret with Alphanumeric format' {
        Set-GuardianSecret -Name 'test/rotate2' -Value 'original' -Vault 'TestVault'
        $result = Invoke-SecretRotation -Name 'test/rotate2' -Vault 'TestVault' -Format 'Alphanumeric' -Length 20
        
        $result.Format | Should -Be 'Alphanumeric'
        
        $secret = Get-GuardianSecret -Name 'test/rotate2' -Vault 'TestVault' -ForceVault
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret.Value)
        try { 
            $value = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
            $value | Should -Match '^[a-z]+$'
            $value.Length | Should -Be 20
        }
        finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
}

Describe 'Guardian Secrets Module - Vault Connectivity' {
    It 'tests vault connection' {
        $result = Test-SecretVaultConnection -Vault 'TestVault'
        
        $result.Connected | Should -Be $true
        $result.VaultName | Should -Be 'TestVault'
        $result.LatencyMs | Should -BeGreaterThan 0
    }
}

Describe 'Guardian Secrets Module - Audit Event Generation' {
    BeforeEach {
        Remove-Secret -Name 'test/audit1' -Vault 'TestVault' -ErrorAction SilentlyContinue
    }
    
    It 'generates audit event on secret read' {
        Set-GuardianSecret -Name 'test/audit1' -Value 'audit-test' -Vault 'TestVault'
        $secret = Get-GuardianSecret -Name 'test/audit1' -Vault 'TestVault' -ForceVault
        
        # Verify audit log was written
        $auditPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'logs' 'guardian_audit.jsonl'
        $auditContent = Get-Content $auditPath -Raw
        $auditContent | Should -Match 'SECRET_READ'
        $auditContent | Should -Match 'test/audit1'
    }
    
    It 'generates audit event on secret write' {
        $auditPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'logs' 'guardian_audit.jsonl'
        $beforeCount = ($auditContent = Get-Content $auditPath -Raw) -split '\n' | Where-Object { $_ -match 'SECRET_WRITE' } | Measure-Object | Select-Object -ExpandProperty Count
        
        Set-GuardianSecret -Name 'test/audit2' -Value 'audit-write' -Vault 'TestVault'
        
        $afterCount = (Get-Content $auditPath -Raw) -split '\n' | Where-Object { $_ -match 'SECRET_WRITE' } | Measure-Object | Select-Object -ExpandProperty Count
        $afterCount | Should -BeGreaterThan $beforeCount
    }
    
    It 'generates audit event on secret rotation' {
        Set-GuardianSecret -Name 'test/audit3' -Value 'rotate-test' -Vault 'TestVault'
        Invoke-SecretRotation -Name 'test/audit3' -Vault 'TestVault' -Format 'Base64' -Length 16
        
        $auditPath = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')).Path 'logs' 'guardian_audit.jsonl'
        $auditContent = Get-Content $auditPath -Raw
        $auditContent | Should -Match 'SECRET_ROTATE'
        $auditContent | Should -Match 'test/audit3'
    }
}

Describe 'Guardian Secrets Module - Health Checks' {
    It 'reports vault health' {
        $report = Test-GuardianSecretHealth -Vault 'TestVault'
        
        $report.VaultConnected | Should -Be $true
        $report.OverallStatus | Should -BeIn @('Healthy', 'Degraded')
        $report.SecretsTotal | Should -BeGreaterOrEqual 0
    }
    
    It 'lists secret inventory' {
        $inventory = Get-GuardianSecretInventory -Vault 'TestVault'
        
        $inventory | Should -Not -BeNullOrEmpty
        $inventory[0].Name | Should -Not -BeNullOrEmpty
    }
}

Describe 'Guardian Secrets Module - Cache and Circuit Breaker' {
    It 'increments circuit breaker on failures' {
        # This test verifies the circuit breaker state machine
        # We can't easily simulate a real vault failure without a real vault
        # but we can verify the state machine logic
        
        $cb = $script:CircuitBreaker
        $cb.State = 'Closed'
        $cb.FailureCount = 0
        
        Record-CircuitBreakerFailure
        $script:CircuitBreaker.FailureCount | Should -Be 1
        $script:CircuitBreaker.State | Should -Be 'Closed'
        
        Record-CircuitBreakerFailure
        Record-CircuitBreakerFailure
        $script:CircuitBreaker.State | Should -Be 'Open'
    }
    
    It 'resets circuit breaker on success' {
        $script:CircuitBreaker.State = 'HalfOpen'
        $script:CircuitBreaker.FailureCount = 2
        
        Record-CircuitBreakerSuccess
        $script:CircuitBreaker.State | Should -Be 'Closed'
        $script:CircuitBreaker.FailureCount | Should -Be 0
    }
}

Describe 'Guardian Secrets Module - Configuration' {
    It 'retrieves configuration' {
        $config = Get-GuardianSecretsConfig
        
        $config.DefaultVault | Should -Be 'GuardianVault'
        $config.CacheTTLSeconds | Should -Be 300
        $config.CircuitBreakerThreshold | Should -Be 3
    }
    
    It 'updates configuration' {
        Set-GuardianSecretsConfig -Key 'CacheTTLSeconds' -Value 600
        $config = Get-GuardianSecretsConfig
        $config.CacheTTLSeconds | Should -Be 600
    }
    
    It 'rejects invalid configuration keys' {
        { Set-GuardianSecretsConfig -Key 'InvalidKey' -Value 'test' } | Should -Throw
    }
}

Describe 'Guardian Secrets Module - Initialization' {
    It 'initializes with SecretManagement available' {
        $result = Initialize-GuardianSecrets
        $result | Should -Be $true
    }
}