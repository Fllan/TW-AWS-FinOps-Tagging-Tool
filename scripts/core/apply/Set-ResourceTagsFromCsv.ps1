function Set-ResourceTagsFromCsv {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('ec2-instances', 'ec2-volumes', 's3-buckets', 'efs', 'rds')]
        [string] $Service,

        [Parameter(Mandatory = $true)]
        [hashtable] $Account,

        [Parameter(Mandatory = $true)]
        [string] $InputCsvDir,

        [Parameter(Mandatory = $true)]
        [string] $LogFilePath
    )

    # Locate exactly one CSV in the input directory
    $csvFiles = Get-ChildItem -Path $InputCsvDir -Filter '*.csv' -File
    if ($csvFiles.Count -ne 1) {
        Write-Log -Message "Expected exactly one CSV in '$InputCsvDir' but found $($csvFiles.Count)." `
            -Level ERROR -LogFilePath $LogFilePath
        throw "Found $($csvFiles.Count) CSV files in input; need exactly one."
    }
    $csvPath = $csvFiles[0].FullName
    Write-Log -Message "Applying tags for service '$Service' from '$($csvFiles[0].Name)'." `
        -Level INFO -LogFilePath $LogFilePath

    $rows = Import-Csv -Path $csvPath

    foreach ($row in $rows) {
        $id = $row.Identifier
        if (-not $id) {
            Write-Log -Message "Skipping row with empty Identifier." `
                -Level WARN -LogFilePath $LogFilePath
            continue
        }

        # Build tag list from all columns except Identifier
        $tags = @()
        foreach ($col in $row.PSObject.Properties.Name) {
            if ($col -eq 'Identifier') { continue }
            $val = $row.$col
            if ($val -and $val.Trim()) {
                $tags += @{ Key = $col; Value = $val }
            }
        }

        if (-not $tags.Count) {
            Write-Log -Message "No tags to apply for '$id'; skipping." `
                -Level WARN -LogFilePath $LogFilePath
            continue
        }

        # Log what we're about to do
        $kvString = ($tags | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
        Write-Log -Message "[$Service] Tagging '$id': $kvString" `
            -Level INFO -LogFilePath $LogFilePath

        try {
            switch ($Service) {
                'ec2-instances' {
                    New-EC2Tag `
                        -Resources   $id `
                        -Tag         $tags `
                        -ProfileName $Account.profileName `
                        -Region      $Account.regions[0] `
                        -ErrorAction Stop
                }
                'ec2-volumes' {
                    New-EC2Tag `
                        -Resources   $id `
                        -Tag         $tags `
                        -ProfileName $Account.profileName `
                        -Region      $Account.regions[0] `
                        -ErrorAction Stop
                }
                's3-buckets' {
                    Write-S3BucketTagging `
                        -BucketName  $id `
                        -Tagging     @{ Tag = $tags } `
                        -ProfileName $Account.profileName `
                        -Region      $Account.regions[0] `
                        -ErrorAction Stop
                }
                'efs' {
                    Add-EFSResourceTag `
                        -FileSystemId $id `
                        -Tag           $tags `
                        -ProfileName   $Account.profileName `
                        -Region        $Account.regions[0] `
                        -ErrorAction   Stop
                }
                'rds' {
                    Add-RDSTagsToResource `
                        -ResourceName $id `
                        -Tag           $tags `
                        -ProfileName   $Account.profileName `
                        -Region        $Account.regions[0] `
                        -ErrorAction   Stop
                }
            }

            Write-Log -Message "Successfully tagged '$id'." `
                -Level INFO -LogFilePath $LogFilePath
        }
        catch {
            Write-Log -Message "Failed tagging '$id': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }
}
