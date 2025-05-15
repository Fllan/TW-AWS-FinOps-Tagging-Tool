# scripts/core/README.md

Core PowerShell functions for exporting resource metadata and applying tags.

## Layout

```
apply/
└── Set-ResourceTagsFromCsv.ps1   # Reads a single CSV per service and applies non-empty tags

export/
├── Export-EC2Instances.ps1      # Instances
├── Export-EC2Volumes.ps1        # Volumes
├── Export-S3Buckets.ps1         # Buckets
├── Export-EFSFileSystems.ps1    # EFS
└── Export-RDSDBInstances.ps1    # RDS
```

## Function Signatures

**Export-<Service>**

```powershell
Export-<Service> \
  -Account <hashtable>        # @{ name; accountId; profileName; regions } \
  -Regions <string[]>         # AWS regions to query \
  -LogFilePath <string>       # Path to write logs \
  -OutputCsvDir <string>      # Directory for CSV output \
  -RequiredTagKeys <string[]> # List of tag keys to export
```

**Set-ResourceTagsFromCsv**

```powershell
Set-ResourceTagsFromCsv \
  -Service <string>       # ec2-instances, ec2-volumes, s3-buckets, efs, rds \
  -Account <hashtable>    # @{ name; accountId; profileName; regions } \
  -InputCsvDir <string>   # Directory with exactly one edited CSV \
  -LogFilePath <string>   # Path for logs
```

## How Exports Handle Tags

1. **Pre-populate** blank columns for each required tag key.
2. **Overlay**: any existing resource tags matching required keys replace blanks.

If you see blanks for tags that exist, check your `RequiredTagKeys` match AWS tag keys (watch for typos).

## Workflow

1. **Export** resources → CSV with existing tag values in place.
2. **Edit** CSV: fill missing tag values.
3. **Apply**: `Set-ResourceTagsFromCsv` writes back non-empty tags.

For CSV format details and examples, see the dedicated [CSV Format README](../csv-format/README.md).

For full project setup, refer to the [main README](../../README.md).
