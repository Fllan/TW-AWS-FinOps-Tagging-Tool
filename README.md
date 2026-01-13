# TW-AWS-FinOps-Tagging-Tool

PowerShell solution for AWS resource tagging at scale. Export tags to CSV, edit in spreadsheets, apply back to AWS.

**Created by Florent Lanternier at TeamWork**

## Quick Start

```powershell
# 1. Clone repository
git clone https://github.com/Fllan/TW-AWS-FinOps-Tagging-Tool.git
cd TW-AWS-FinOps-Tagging-Tool

# 2. Install AWS modules (requires admin)
Install-Module -Name AWS.Tools.Common, AWS.Tools.EC2, AWS.Tools.S3, AWS.Tools.ElasticFileSystem, AWS.Tools.RDS, AWS.Tools.SavingsPlans, AWS.Tools.Pricing -Force

# 3. Run tool
pwsh .\FinOpsTaggingTool.ps1
```

**Prerequisites:** Windows 10+, PowerShell 7+, AWS SSO configured

## Configuration

1. Copy `config/ClientTemplate.psd1` to `config/MyOrg.psd1`
2. Edit SSO details, account IDs, regions, and required tag keys
3. Run tool and select your config file

See [config/README.md](config/README.md) for details.

## Workflow

### Export
```powershell
pwsh .\FinOpsTaggingTool.ps1
```
Select config → Choose accounts/services → Export → CSVs saved to `csv/output/`

### Edit
Open CSV in Excel → Fill missing tag values → Save to `csv/input/`

Format details: [csv/README.md](csv/README.md)

### Apply
```powershell
pwsh .\FinOpsTaggingTool.ps1
```
Select config → Choose accounts/services → Apply → Tags updated in AWS

## Supported Services

- EC2 instances, volumes, snapshots
- EC2 Savings Plans and pricing data
- S3 buckets
- EFS file systems
- RDS database instances
- SUSE Marketplace Agreements

## Repository Structure

```
config/                 # Client configurations (.psd1 files)
csv/input/             # Edited CSVs for tag application
csv/output/            # Exported CSVs from AWS
logs/                  # Execution logs
scripts/functions/     # Reusable utilities (SSO, logging, menus)
scripts/core/export/   # Service-specific export functions
scripts/core/apply/    # Tag application logic
FinOpsTaggingTool.ps1  # Main entry point
```

## Extending

To add new AWS services:
1. Create `scripts/core/export/Export-<Service>.ps1`
2. Add service to `$services` array in main script
3. Add switch case for export and apply logic
4. Update `Set-ResourceTagsFromCsv.ps1` with service tagging cmdlet

See [scripts/core/README.md](scripts/core/README.md) and [scripts/functions/README.md](scripts/functions/README.md) for implementation details.

## Troubleshooting

**Logs:** Check `logs/` folder for detailed execution output
**Blank tags:** Verify `requiredTagKeys` in config match AWS tag keys exactly (case-sensitive)
**SSO issues:** Ensure `aws sso login` works before running tool
