# Configuration Files

Client-specific configuration files (.psd1 format) define:

- **SSO connection:** `startUrl`, `ssoRegion`, `roleName`, `sessionName`
- **Accounts:** `name`, `accountId`, `profileName`, `regions[]`
- **Required tags:** `requiredTagKeys[]`

## Setup

```powershell
# 1. Copy template
cp ClientTemplate.psd1 MyOrg.psd1

# 2. Edit MyOrg.psd1
#    - Set SSO portal URL and role
#    - List AWS accounts and regions
#    - Define required tag keys (case-sensitive)

# 3. Run tool
pwsh ..\FinOpsTaggingTool.ps1
```

## Example Structure

```powershell
@{
  ssoConnectionDetails = @{
    startUrl    = 'https://myorg.awsapps.com/start/'
    ssoRegion   = 'eu-west-1'
    roleName    = 'FinOpsRole'
    sessionName = 'Tagging Session'
  }

  accounts = @(
    @{
      name        = 'Prod'
      accountId   = '111111111111'
      profileName = 'sso-prod'
      regions     = @('us-east-1', 'eu-west-1')
    }
  )

  requiredTagKeys = @('Environment', 'Owner', 'CostCenter')
}
```

**Notes:**
- Per-account `roleName` overrides global SSO role if specified
- Tag keys are case-sensitive and must match AWS exactly
- Multiple regions per account are supported
