# config/README.md

This folder contains **ClientTemplate.psd1**, a PowerShell data template for:

* **SSO connection** (`roleName`, `sessionName`, `startUrl`, `ssoRegion`)
* **Accounts** (`name`, `accountId`, `profileName`, `regions`)
* **Required tags** (`requiredTagKeys`)

## Usage

1. **Copy** `ClientTemplate.psd1` → `MyOrg.psd1`
2. **Edit** SSO details, account list, and tag keys
3. **Place** your file here
4. **Run** `FinOpsTaggingTool.ps1` and pick `MyOrg.psd1`

For full setup, see the [main README](../README.md).
