# csv/README.md

This directory contains the CSV files used to apply tags to AWS resources.

---

## Input CSV Format for Tagging

When applying tags using `Set-ResourceTagsFromCsv.ps1`, the input CSV must follow this format:

### Structure

* **First column**: the AWS resource identifier

  * Examples:

    * `InstanceId` for EC2 instances
    * `VolumeId` for EC2 volumes
    * `BucketName` for S3 buckets
    * `FileSystemId` for EFS file systems
    * `DBInstanceIdentifier` for RDS instances

* **Remaining columns**: tag keys and their values

  * Each header (excluding the identifier) becomes a tag key
  * Tag keys are **case-sensitive** — exact spelling matters

### Rules

* Do **not** modify the header or values in the first (identifier) column
* Only non-empty cells will result in a tag being applied
* Empty cells will leave existing tags unchanged
* Invalid keys or unauthorized changes will be logged as errors

---

## Example Input CSV

```csv
InstanceId,Environment,Owner,CostCenter
i-0123456789abcdef0,Prod,jane.doe,12345
i-0fedcba9876543210,,john.smith,67890
```

In this example:

* The first row sets all three tags on `i-0123456789abcdef0`
* The second row will skip the `Environment` tag for `i-0fedcba9876543210`

---

## Applying Tags

To apply tags using your CSV:

1. Place the edited CSV in this `csv/input/` directory
2. Run the script and select `Apply`

The script will match resources by the ID in the first column and apply any non-empty tag values.

---

For export behavior and tagging logic, refer to the [core scripts README](../scripts/core/README.md).
