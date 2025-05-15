# scripts/functions/README.md

This directory contains utility functions used by the main `FinOpsTaggingTool.ps1` and the core export/apply scripts:

| File                                  | Purpose                                                                                |
| ------------------------------------- | -------------------------------------------------------------------------------------- |
| `Get-MenuSelection.ps1`               | Presents a numbered menu to the user and returns selected option indices.              |
| `Import-RequiredModules.ps1`          | Verifies and imports all required AWS PowerShell modules, exiting on failure.          |
| `Initialize-AndConnectAwsAccount.ps1` | Establishes or validates an AWS SSO session for a given account/profile.               |
| `Write-Log.ps1`                       | Centralized logging function to write colored console output and append to a log file. |

---

## Usage Patterns

### 1. Menu Prompt

```powershell
# Display a prompt with options and capture selected indices
$indices = Get-MenuSelection -Prompt 'Choose services to export:' -Options @('EC2', 'S3', 'RDS')
```

### 2. Module Imports

```powershell
# Ensure AWS.Tools.* modules are loaded before any AWS API calls
. ./Import-RequiredModules.ps1
```

### 3. AWS SSO Initialization

```powershell
# Establish an SSO session or skip if already valid
Initialize-AndConnectAwsAccount \
  -ProfileName 'sso-myorg-prod' \
  -AccountId    '123456789012' \
  -RoleName     'Org-FinOpsRole' \
  -StartUrl     'https://myorg.awsapps.com/start/' \
  -SSORegion    'eu-west-1' \
  -SessionName  'MyOrg Tagging Session' \
  -LogFilePath  $logPath
```

### 4. Logging

```powershell
# Write a message to console and log file
Write-Log -Message 'Export started' -Level INFO -LogFilePath $logPath

# Aliases for common levels
Write-LogWarning 'This is a warning'  
Write-LogError   'This is an error'
```

---

For sequencing these functions within the main toolkit flow, see the [scripts/core README](../core/README.md) and the [main README](../../README.md).
