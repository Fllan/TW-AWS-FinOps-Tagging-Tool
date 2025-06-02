function Export-S3Buckets {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable] $Account,
        [Parameter(Mandatory = $true)][string[]] $Regions,
        [Parameter(Mandatory = $true)][string]   $LogFilePath,
        [Parameter(Mandatory = $true)][string]   $OutputCsvDir,
        [Parameter(Mandatory = $true)][string[]] $RequiredTagKeys
    )

    Write-Log -Message "Starting S3 bucket export for account '$($Account.name)' ($($Account.accountId)) in regions: $($Regions -join ', ')" `
        -Level INFO -LogFilePath $LogFilePath

    $ExportData = @()

    foreach ($Region in $Regions) {
        Write-Log -Message "Listing S3 buckets in region '$Region' using profile '$($Account.profileName)'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            # List all buckets (S3 is global, but we can still tag each with region context)
            $Buckets = Get-S3Bucket -ProfileName $Account.profileName -Region $Region -ErrorAction Stop

            $count = if ($Buckets) { $Buckets.Count } else { 0 }
            Write-Log -Message "Found $count S3 bucket(s) in '$Region'." `
                -Level INFO -LogFilePath $LogFilePath

            foreach ($B in $Buckets) {
                $bucketName = $B.BucketName
                $createDate = $B.CreationDate

                # Build base object
                $BktData = [PSCustomObject]@{
                    AccountId    = $Account.accountId
                    AccountName  = $Account.name
                    Region       = $Region
                    BucketName   = $bucketName
                    CreationDate = $createDate
                }

                # Stub out required tags
                foreach ($TagKey in $RequiredTagKeys) {
                    $BktData | Add-Member -MemberType NoteProperty -Name $TagKey -Value "" -Force
                }

                # Fetch and apply existing tags
                try {
                    $tagging = Get-S3BucketTagging -BucketName $bucketName `
                        -ProfileName $Account.profileName `
                        -Region $Region -ErrorAction Stop

                    foreach ($t in $tagging.TagSet) {
                        $BktData.$($t.Key) = $t.Value
                    }
                }
                catch [Amazon.S3.AmazonS3Exception] {
                    # No tags or access denied
                    Write-Log -Message "No tags or cannot retrieve tags for bucket '$bucketName': $($_.Exception.Message)" `
                        -Level WARN -LogFilePath $LogFilePath
                }

                $ExportData += $BktData
            }
        }
        catch {
            Write-Log -Message "Error listing S3 buckets in region '$Region' for account '$($Account.name)': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }

    if ($ExportData.Count -gt 0) {
        if (-not (Test-Path $OutputCsvDir)) {
            New-Item -Path $OutputCsvDir -ItemType Directory | Out-Null
        }

        $AccountNameForFilename = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
        $timestamp = (Get-Date).ToString('yyyyMMddHHmmss')
        $OutputFileName = "$($AccountNameForFilename)-S3-buckets-export-$timestamp.csv"
        $OutputFilePath = Join-Path $OutputCsvDir $OutputFileName

        Write-Log -Message "Exporting $($ExportData.Count) S3 buckets to '$OutputFilePath'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            $ExportData | Export-Csv -Path $OutputFilePath -NoTypeInformation -Force -ErrorAction Stop
            Write-Log -Message "Successfully exported S3 buckets to '$OutputFilePath'." `
                -Level INFO -LogFilePath $LogFilePath
        }
        catch {
            Write-Log -Message "Error exporting buckets to CSV '$OutputFilePath': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }
    else {
        Write-Log -Message "No S3 buckets collected for export from account '$($Account.name)'." `
            -Level INFO -LogFilePath $LogFilePath
    }
}
