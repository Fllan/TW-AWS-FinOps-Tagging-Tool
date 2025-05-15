function Export-RDSDBInstances {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable] $Account,
        [Parameter(Mandatory = $true)][string[]]  $Regions,
        [Parameter(Mandatory = $true)][string]    $LogFilePath,
        [Parameter(Mandatory = $true)][string]    $OutputCsvDir,
        [Parameter(Mandatory = $true)][string[]]  $RequiredTagKeys
    )

    Write-Log -Message "Starting RDS instance export for account '$($Account.name)' ($($Account.accountId)) in regions: $($Regions -join ', ')" `
        -Level INFO -LogFilePath $LogFilePath

    $ExportData = @()

    foreach ($Region in $Regions) {
        Write-Log -Message "Describing RDS DB instances in region '$Region' using profile '$($Account.profileName)'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            # Auto-pagination will retrieve all DB instances
            $DBs = Get-RDSDBInstance `
                -ProfileName $Account.profileName `
                -Region      $Region `
                -ErrorAction Stop

            $count = if ($DBs) { $DBs.Count } else { 0 }
            Write-Log -Message "Found $count RDS DB instance(s) in '$Region'." `
                -Level INFO -LogFilePath $LogFilePath

            foreach ($db in $DBs) {
                # build base object with core properties
                $dbData = [PSCustomObject]@{
                    AccountId            = $Account.accountId
                    AccountName          = $Account.name
                    Region               = $Region
                    DBInstanceIdentifier = $db.DBInstanceIdentifier
                    DBInstanceClass      = $db.DBInstanceClass
                    Engine               = $db.Engine
                    EngineVersion        = $db.EngineVersion
                    DBInstanceStatus     = $db.DBInstanceStatus
                    AllocatedStorage     = $db.AllocatedStorage
                    MultiAZ              = $db.MultiAZ
                    PubliclyAccessible   = $db.PubliclyAccessible
                    EndpointAddress      = $db.Endpoint.Address
                    InstanceCreateTime   = $db.InstanceCreateTime
                }

                # stub out required tag columns
                foreach ($TagKey in $RequiredTagKeys) {
                    $dbData | Add-Member -MemberType NoteProperty -Name $TagKey -Value "" -Force
                }

                # fill from TagList (List<Amazon.RDS.Model.Tag>)
                if ($db.TagList) {
                    foreach ($t in $db.TagList) {
                        if ($t.Key -in $RequiredTagKeys) {
                            $dbData.$($t.Key) = $t.Value
                        }
                    }
                }

                $ExportData += $dbData
            }
        }
        catch {
            Write-Log -Message "Error describing RDS in region '$Region' for account '$($Account.name)': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }

    if ($ExportData.Count -gt 0) {
        if (-not (Test-Path $OutputCsvDir)) {
            New-Item -Path $OutputCsvDir -ItemType Directory | Out-Null
        }

        $AccountNameForFilename = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
        $timestamp = (Get-Date).ToString('yyyyMMddHHmmss')
        $OutputFileName = "$($AccountNameForFilename)-RDS-dbinstances-export-$timestamp.csv"
        $OutputFilePath = Join-Path $OutputCsvDir $OutputFileName

        Write-Log -Message "Exporting $($ExportData.Count) RDS DB instance(s) to '$OutputFilePath'..." `
            -Level INFO -LogFilePath $LogFilePath

        try {
            $ExportData | Export-Csv -Path $OutputFilePath -NoTypeInformation -Force -ErrorAction Stop
            Write-Log -Message "Successfully exported RDS DB instances to '$OutputFilePath'." `
                -Level INFO -LogFilePath $LogFilePath
        }
        catch {
            Write-Log -Message "Error exporting RDS CSV '$OutputFilePath': $($_.Exception.Message)" `
                -Level ERROR -LogFilePath $LogFilePath
        }
    }
    else {
        Write-Log -Message "No RDS DB instances collected for export from account '$($Account.name)'." `
            -Level INFO -LogFilePath $LogFilePath
    }
}
