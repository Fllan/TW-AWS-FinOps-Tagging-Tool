function Update-BadTagValuesOnSnapshots {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable]$Account,
        [Parameter(Mandatory = $true)][array]$Regions,
        [Parameter(Mandatory = $true)][string]$LogFilePath,
        [Parameter(Mandatory = $true)][string]$OutputCsvDir
    )

    Write-Log -Message "Starting EC2 Snapshots fix bad tag values for account '$($Account.name)' ($($Account.accountId)) in regions: $($Regions -join ', ')" -Level "INFO" -LogFilePath $LogFilePath

    try {
        foreach ($Region in $Regions) {
            Write-Log -Message "Getting EC2 Snapshots in region '$Region' using profile '$($Account.profileName)'..." -Level "INFO" -LogFilePath $LogFilePath

            $BadTagFilter = @(
                # Change Key and Value
                @{ Name = "tag:Key"; Values = "Value" }
            )

            $GoodTag = @()

            if ($Account.accountId -eq "account_ID") {
                $GoodTag = @(
                    @{ Key = "Key"; Value = "Value" },
                    @{ Key = "Key"; Value = "Value" },
                    @{ Key = "Key"; Value = "Value" },
                    @{ Key = "Key"; Value = "Value" }
                )
            }
            elseif ($Account.accountId -eq "account_ID") {
                $GoodTag = @(
                    @{ Key = "Key"; Value = "Value" },
                    @{ Key = "Key"; Value = "Value" },
                    @{ Key = "Key"; Value = "Value" },
                    @{ Key = "Key"; Value = "Value" }
                )
            }
            else {
                Write-Log -Message "Not the good account..."
                throw
            }

            

            try {
                $Snapshots = Get-EC2Snapshot -Filter $BadTagFilter -ProfileName $Account.profileName -Region $Region -ErrorAction Stop

                if ($Snapshots) {
                    Write-Log -Message "Found $($Snapshots.Count) EC2 Snapshots(s) in '$Region'." -Level "INFO" -LogFilePath $LogFilePath

                    foreach ($Snapshot in $Snapshots) {
                        New-EC2Tag -Resource $Snapshot.SnapshotId -ProfileName $Account.profileName -Region $Region -ErrorAction Stop `
                            -Tag $GoodTag
                    }
                }
                else {
                    Write-Log -Message "No EC2 Snapshots found in region '$Region'." -Level "INFO" -LogFilePath $LogFilePath
                }

            }
            catch {
                Write-Log -Message "Error getting EC2 Snapshots in region '$Region' for account '$($Account.name)': $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
            }
        }

    }
    catch {
        Write-Log -Message "An error occurred during EC2 Snapshots fix bad tag values processing for account '$($Account.name)': $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
    }
}