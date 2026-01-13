# CSV Files

Export CSVs → `csv/output/`
Input CSVs → `csv/input/`

## Format

**First column:** Resource identifier (service-specific)
- `InstanceId` - EC2 instances
- `VolumeId` - EBS volumes
- `BucketName` - S3 buckets
- `FileSystemId` - EFS
- `DBInstanceIdentifier` - RDS

**Remaining columns:** Tag keys (case-sensitive)

## Rules

- **Do not modify** first column (resource IDs)
- **Non-empty cells** = tags will be applied
- **Empty cells** = existing tags unchanged
- Tag keys must match AWS exactly (case-sensitive)

## Example

```csv
InstanceId,Environment,Owner,CostCenter
i-0123456789abcdef0,Prod,jane.doe,12345
i-0fedcba9876543210,,john.smith,67890
```

**Result:**
- First instance: All 3 tags applied
- Second instance: Only `Owner` and `CostCenter` applied (Environment skipped)

## Workflow

### Export
1. Run tool → Export
2. CSVs saved to `csv/output/` with existing tags populated

### Edit
1. Open CSV in Excel/editor
2. Fill missing tag values
3. Save to `csv/input/`

### Apply
1. Run tool → Apply
2. Only one CSV allowed in `csv/input/`
3. Tags updated in AWS

**Note:** Input CSVs must use `Identifier` as first column header when applying tags.
