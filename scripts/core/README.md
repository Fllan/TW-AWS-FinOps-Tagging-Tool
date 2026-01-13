# Core Scripts

Export AWS resource metadata and apply tags from CSV.

## Structure

```
export/
├── Export-EC2Instances.ps1              # EC2 instances
├── Export-EC2Volumes.ps1                # EBS volumes
├── Export-EC2OnDemandAndSPRates.ps1     # Pricing data
├── Export-EC2SavingsPlans.ps1           # Savings Plans
├── Export-S3Buckets.ps1                 # S3 buckets
├── Export-EFSFileSystems.ps1            # EFS file systems
├── Export-RDSDBInstances.ps1            # RDS databases
├── Export-SUSEMarketplaceAgreements.ps1 # SUSE agreements
└── Update-BadTagValuesOnSnapshots.ps1   # Snapshot tag fixes

apply/
└── Set-ResourceTagsFromCsv.ps1          # Apply tags from CSV
```

## Export Functions

**Signature:**
```powershell
Export-<Service> -Account <hashtable> -Regions <string[]> -LogFilePath <string> -OutputCsvDir <string> -RequiredTagKeys <string[]>
```

**Behavior:**
1. Query AWS API across all specified regions
2. Create CSV with columns for required tag keys
3. Populate existing tag values from AWS
4. Write to `csv/output/`

**Troubleshooting:** Blank columns mean AWS tag keys don't match `requiredTagKeys` (case-sensitive).

## Apply Function

**Signature:**
```powershell
Set-ResourceTagsFromCsv -Service <string> -Account <hashtable> -InputCsvDir <string> -LogFilePath <string>
```

**Behavior:**
1. Read single CSV from `csv/input/`
2. Apply non-empty tag values to AWS resources
3. Skip empty cells (leaves existing tags unchanged)

**Services:** `ec2-instances`, `ec2-volumes`, `s3-buckets`, `efs`, `rds`

## Adding New Services

1. Create `export/Export-<Service>.ps1` following existing patterns
2. Add service to `$services` in `FinOpsTaggingTool.ps1`
3. Add dot-source line to main script imports
4. Add switch cases for export and apply
5. Update `Set-ResourceTagsFromCsv.ps1` with service-specific tagging cmdlet

**AWS Tagging Cmdlets:**
- EC2: `New-EC2Tag`
- S3: `Write-S3BucketTagging`
- EFS: `Add-EFSResourceTag`
- RDS: `Add-RDSTagsToResource`

See [CSV format](../../csv/README.md) for input/output specifications.
