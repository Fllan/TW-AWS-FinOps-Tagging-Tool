function Export-EFSFileSystems {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable] $Account,
        [Parameter(Mandatory = $true)][string[]]  $Regions,
        [Parameter(Mandatory = $true)][string]    $LogFilePath,
        [Parameter(Mandatory = $true)][string]    $OutputCsvDir,
        [Parameter(Mandatory = $true)][string[]]  $RequiredTagKeys
    )

    Write-Log -Message "Starting EFS file system export for account '$($Account.name)' ($($Account.accountId)) in regions: $($Regions -join ', ')" `
        -Level INFO -LogFilePath $LogFilePath

    $ExportData = @()

    foreach ($Region in $Regions) {
        Write-Log -Message "Describing EFS file systems in region '$Region' using profile '$($Account.profileName)'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            # Auto-pagination will fetch all file systems
            $FileSystems = Get-EFSFileSystem `
                -ProfileName $Account.profileName `
                -Region      $Region `
                -ErrorAction Stop

            $count = if ($FileSystems) { $FileSystems.Count } else { 0 }
            Write-Log -Message "Found $count EFS file system(s) in '$Region'." `
                -Level INFO -LogFilePath $LogFilePath

            foreach ($fs in $FileSystems) {
                # build base object with FS properties
                $fsData = [PSCustomObject]@{
                    AccountId            = $Account.accountId
                    AccountName          = $Account.name
                    Region               = $Region
                    FileSystemId         = $fs.FileSystemId
                    CreationTime         = $fs.CreationTime
                    LifeCycleState       = $fs.LifeCycleState
                    PerformanceMode      = $fs.PerformanceMode
                    ThroughputMode       = $fs.ThroughputMode
                    Encrypted            = $fs.Encrypted
                    KmsKeyId             = $fs.KmsKeyId
                    NumberOfMountTargets = $fs.NumberOfMountTargets
                    SizeInBytes          = $fs.SizeInBytes.Value
                }

                # stub out required tag columns
                foreach ($TagKey in $RequiredTagKeys) {
                    $fsData | Add-Member -MemberType NoteProperty -Name $TagKey -Value "" -Force
                }

                # populate tags from fs.Tags (List<Amazon.ElasticFileSystem.Model.Tag>)
                if ($fs.Tags) {
                    foreach ($t in $fs.Tags) {
                        if ($t.Key -in $RequiredTagKeys) {
                            $fsData.$($t.Key) = $t.Value
                        }
                    }
                }

                $ExportData += $fsData
            }
        }
        catch {
            Write-Log -Message "Error describing EFS in region '$Region' for account '$($Account.name)': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }

    if ($ExportData.Count -gt 0) {
        if (-not (Test-Path $OutputCsvDir)) {
            New-Item -Path $OutputCsvDir -ItemType Directory | Out-Null
        }

        $AccountNameForFilename = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
        $timestamp = (Get-Date).ToString('yyyyMMddHHmmss')
        $OutputFileName = "$($AccountNameForFilename)-EFS-filesystems-export-$timestamp.csv"
        $OutputFilePath = Join-Path $OutputCsvDir $OutputFileName

        Write-Log -Message "Exporting $($ExportData.Count) EFS file system(s) to '$OutputFilePath'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            $ExportData | Export-Csv -Path $OutputFilePath -NoTypeInformation -Force -ErrorAction Stop
            Write-Log -Message "Successfully exported EFS file systems to '$OutputFilePath'." `
                -Level INFO -LogFilePath $LogFilePath
        }
        catch {
            Write-Log -Message "Error exporting EFS CSV '$OutputFilePath': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }
    else {
        Write-Log -Message "No EFS file systems collected for export from account '$($Account.name)'." `
            -Level INFO -LogFilePath $LogFilePath
    }
}
