function Export-EC2Volumes {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable]$Account,
        [Parameter(Mandatory = $true)][string[]]$Regions,
        [Parameter(Mandatory = $true)][string]$LogFilePath,
        [Parameter(Mandatory = $true)][string]$OutputCsvDir,
        [Parameter(Mandatory = $true)][string[]]$RequiredTagKeys
    )

    Write-Log -Message "Starting EC2 volume export for account '$($Account.name)' ($($Account.accountId)) in regions: $($Regions -join ', ')" `
        -Level INFO -LogFilePath $LogFilePath

    $ExportData = @()

    foreach ($Region in $Regions) {
        Write-Log -Message "Getting EC2 volumes in region '$Region' using profile '$($Account.profileName)'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            # this returns an array of Volume objects
            $Volumes = Get-EC2Volume -ProfileName $Account.profileName -Region $Region -ErrorAction Stop

            $count = if ($Volumes) { $Volumes.Count } else { 0 }
            Write-Log -Message "Found $count EC2 volume(s) in '$Region'." `
                -Level INFO -LogFilePath $LogFilePath

            foreach ($Vol in $Volumes) {
                # build base object
                $VolData = [PSCustomObject]@{
                    AccountId          = $Account.accountId
                    AccountName        = $Account.name
                    AttachedInstanceId = $Vol.Attachments.InstanceId
                    Region             = $Region
                    VolumeId           = $Vol.VolumeId
                    SizeGiB            = $Vol.Size
                    VolumeType         = $Vol.VolumeType
                    State              = $Vol.State
                    CreateTime         = $Vol.CreateTime
                    SnapshotId         = $Vol.SnapshotId
                    Iops               = $Vol.Iops
                    Throughput         = $Vol.Throughput
                }

                # stub out required tags
                foreach ($TagKey in $RequiredTagKeys) {
                    $VolData | Add-Member -MemberType NoteProperty -Name $TagKey -Value "" -Force
                }

                # fill in existing tags
                if ($Vol.Tags) {
                    foreach ($Tag in $Vol.Tags) {
                        if ($Tag.Key -in $RequiredTagKeys) {
                            $VolData.$($Tag.Key) = $Tag.Value
                        }
                    }
                }

                $ExportData += $VolData
            }
        }
        catch {
            Write-Log -Message "Error getting EC2 volumes in region '$Region' for account '$($Account.name)': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }

    if ($ExportData.Count -gt 0) {
        if (-not (Test-Path $OutputCsvDir)) {
            New-Item -Path $OutputCsvDir -ItemType Directory | Out-Null
        }

        $AccountNameForFilename = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
        $timestamp = (Get-Date).ToString('yyyyMMddHHmmss')
        $OutputFileName = "$($AccountNameForFilename)-EC2-volumes-export-$timestamp.csv"
        $OutputFilePath = Join-Path $OutputCsvDir $OutputFileName

        Write-Log -Message "Exporting $($ExportData.Count) EC2 volumes to '$OutputFilePath'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            $ExportData | Export-Csv -Path $OutputFilePath -NoTypeInformation -Force -ErrorAction Stop
            Write-Log -Message "Successfully exported EC2 volumes to '$OutputFilePath'." `
                -Level INFO -LogFilePath $LogFilePath
        }
        catch {
            Write-Log -Message "Error exporting volumes to CSV '$OutputFilePath': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }
    else {
        Write-Log -Message "No EC2 volumes collected for export from account '$($Account.name)'." `
            -Level INFO -LogFilePath $LogFilePath
    }
}
