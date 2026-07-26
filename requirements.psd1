@{
    # Guardian PowerShell Module Dependencies
    # Version pinning for reproducible builds and security
    
    # Core PowerShell
    PowerShellVersion = '7.4'
    
    # Required Modules
    RequiredModules = @(
        @{
            ModuleName = 'Pester'
            ModuleVersion = '6.0.1'
            RequiredVersion = '6.0.1'
            MaximumVersion = '6.99.99'
            Repository = 'PSGallery'
        }
        @{
            ModuleName = 'PSScriptAnalyzer'
            ModuleVersion = '1.21.0'
            RequiredVersion = '1.21.0'
            MaximumVersion = '1.99.99'
            Repository = 'PSGallery'
        }
        @{
            ModuleName = 'Microsoft.PowerShell.SecretManagement'
            ModuleVersion = '1.4.0'
            RequiredVersion = '1.4.0'
            MaximumVersion = '1.99.99'
            Repository = 'PSGallery'
        }
        @{
            ModuleName = 'Microsoft.PowerShell.SecretStore'
            ModuleVersion = '1.0.0'
            RequiredVersion = '1.0.0'
            MaximumVersion = '1.99.99'
            Repository = 'PSGallery'
        }
        @{
            ModuleName = 'SecretManagement.HashicorpVault'
            ModuleVersion = '1.0.0'
            RequiredVersion = '1.0.0'
            MaximumVersion = '1.99.99'
            Repository = 'PSGallery'
        }
        @{
            ModuleName = 'Az.Accounts'
            ModuleVersion = '2.12.0'
            RequiredVersion = '2.12.0'
            MaximumVersion = '2.99.99'
            Repository = 'PSGallery'
        }
        @{
            ModuleName = 'Az.KeyVault'
            ModuleVersion = '4.6.0'
            RequiredVersion = '4.6.0'
            MaximumVersion = '4.99.99'
            Repository = 'PSGallery'
        }
    )
    
    # Optional Modules (for extended functionality)
    OptionalModules = @(
        @{
            ModuleName = 'ThreadJob'
            ModuleVersion = '2.0.0'
            Repository = 'PSGallery'
        }
        @{
            ModuleName = 'PSReadLine'
            ModuleVersion = '2.3.4'
            Repository = 'PSGallery'
        }
    )
    
    # Private Repository (if applicable)
    # PrivateRepositories = @(
    #     @{
    #         Name = 'GuardianInternal'
    #         SourceLocation = 'https://nuget.example.com/guardian'
    #         PublishLocation = 'https://nuget.example.com/guardian'
    #         Credential = (Get-Credential)
    #     }
    # )
    
    # Module Validation Rules
    ValidationRules = @{
        # Require signed modules in production
        RequireSignedModules = $true
        
        # Allowed publishers for unsigned modules (dev only)
        AllowedUnsignedPublishers = @(
            'Microsoft Corporation',
            'PowerShell Team',
            'Pester Team'
        )
        
        # Minimum TLS version for module downloads
        MinimumTlsVersion = 'TLS1.2'
        
        # Verify module integrity
        VerifyChecksums = $true
    }
    
    # Installation Behavior
    Installation = @{
        # Install to user scope by default
        Scope = 'CurrentUser'
        
        # Allow prerelease versions only when explicitly requested
        AllowPrerelease = $false
        
        # Force reinstall if version mismatch
        ForceReinstallOnMismatch = $true
        
        # Skip publisher verification in CI
        SkipPublisherCheckInCI = $true
    }
    
    # CI/CD Specific Overrides
    CI = @{
        # Use specific versions in CI (no floating)
        PinAllVersions = $true
        
        # Cache modules between runs
        CacheModules = $true
        CachePath = '$(Pipeline.Workspace)/.modules'
        
        # Fail build on vulnerable dependencies
        FailOnVulnerable = $true
        
        # Run PSScriptAnalyzer as part of install validation
        RunAnalyzerOnInstall = $true
    }
}