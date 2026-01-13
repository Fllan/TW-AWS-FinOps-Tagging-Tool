# Utility Functions

Reusable functions for SSO authentication, logging, menus, and module management.

## Functions

| Function | Purpose |
|----------|---------|
| `Get-MenuSelection.ps1` | Interactive numbered menu, returns selected indices |
| `Import-RequiredModules.ps1` | Verify and import AWS PowerShell modules |
| `Initialize-AndConnectAwsAccount.ps1` | Establish/validate AWS SSO session |
| `Write-Log.ps1` | Console and file logging with color output |

## Usage

### Menu Selection
```powershell
$indices = Get-MenuSelection -Prompt 'Choose services:' -Options @('EC2', 'S3', 'RDS')
```

### Module Import
```powershell
. ./Import-RequiredModules.ps1  # Loads AWS.Tools.* modules
```

### SSO Authentication
```powershell
Initialize-AndConnectAwsAccount `
  -ProfileName 'sso-prod' `
  -AccountId   '123456789012' `
  -RoleName    'FinOpsRole' `
  -StartUrl    'https://myorg.awsapps.com/start/' `
  -SSORegion   'eu-west-1' `
  -LogFilePath $logPath
```

### Logging
```powershell
Write-Log -Message 'Export started' -Level INFO -LogFilePath $logPath

# Shortcuts
Write-LogInformation 'Info message'
Write-LogWarning 'Warning message'
Write-LogError 'Error message'
```

**Log levels:** INFO, WARN, ERROR (with color-coded console output)
