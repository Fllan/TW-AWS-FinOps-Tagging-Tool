function Export-EC2Instances {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable]$Account,
        [Parameter(Mandatory = $true)][array]$Regions,
        [Parameter(Mandatory = $true)][string]$LogFilePath,
        [Parameter(Mandatory = $true)][string]$OutputCsvDir,
        [Parameter(Mandatory = $true)][array]$RequiredTagKeys
    )

    Write-Log -Message "Starting EC2 instance export for account '$($Account.name)' ($($Account.accountId)) in regions: $($Regions -join ', ')" -Level "INFO" -LogFilePath $LogFilePath

    $ExportData = @()

    try {
        foreach ($Region in $Regions) {
            Write-Log -Message "Getting EC2 instances in region '$Region' using profile '$($Account.profileName)'..." -Level "INFO" -LogFilePath $LogFilePath

            try {
                # Use -ProfileName and -Region directly on Get-EC2Instance
                $Instances = Get-EC2Instance -ProfileName $Account.profileName -Region $Region -ErrorAction Stop

                if ($Instances) {
                    Write-Log -Message "Found $($Instances.Count) EC2 instance(s) in '$Region'." -Level "INFO" -LogFilePath $LogFilePath

                    foreach ($Instance in $Instances.Instances) {
                        $InstanceData = [PSCustomObject]@{
                            AccountId        = $Account.accountId
                            AccountName      = $Account.name
                            Region           = $Region
                            InstanceId       = $Instance.InstanceId
                            InstanceType     = $Instance.InstanceType
                            State            = $Instance.State.Name
                            LaunchTime       = $Instance.LaunchTime
                            PlateformDetails = $Instance.PlateformDetails
                        }

                        foreach ($TagKey in $RequiredTagKeys) {
                            $InstanceData | Add-Member -MemberType Noteproperty -Name $TagKey -Value "" -Force
                        }

                        if ($Instance.Tags) {
                            foreach ($Tag in $Instance.Tags) {
                                if ($Tag.Key -in $RequiredTagKeys) {
                                    $InstanceData.$($Tag.Key) = $Tag.Value
                                }
                            }
                        }

                        $ExportData += $InstanceData
                    }
                }
                else {
                    Write-Log -Message "No EC2 instances found in region '$Region'." -Level "INFO" -LogFilePath $LogFilePath
                }

            }
            catch {
                Write-Log -Message "Error getting EC2 instances in region '$Region' for account '$($Account.name)': $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
            }
        }

        if ($ExportData.Count -gt 0) {
            # Use Account Name in filename
            $AccountNameForFilename = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
            $timestamp = (Get-Date).ToString('yyyyMMddHHmmss')
            $OutputFileName = "$($AccountNameForFilename)-EC2-instances-export-$timestamp.csv"
            $OutputFilePath = Join-Path $OutputCsvDir $OutputFileName

            Write-Log -Message "Exporting $($ExportData.Count) EC2 instances to '$OutputFilePath'..." -Level "INFO" -LogFilePath $LogFilePath

            try {
                $ExportData | Export-Csv -Path $OutputFilePath -NoTypeInformation -Force -ErrorAction Stop
                Write-Log -Message "Successfully exported EC2 instances to '$OutputFilePath'." -Level "INFO" -LogFilePath $LogFilePath
            }
            catch {
                Write-Log -Message "Error exporting EC2 instances to CSV '$OutputFilePath': $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
            }

        }
        else {
            Write-Log -Message "No EC2 instances collected for export from account '$($Account.name)'." -Level "INFO" -LogFilePath $LogFilePath
        }

    }
    catch {
        Write-Log -Message "An error occurred during EC2 instance export processing for account '$($Account.name)': $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
    }
}