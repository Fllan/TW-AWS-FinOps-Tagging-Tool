function Export-SUSEMarketplaceAgreements {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable]$Account,
        [Parameter(Mandatory = $true)][array]$Regions,
        [Parameter(Mandatory = $true)][string]$LogFilePath,
        [Parameter(Mandatory = $true)][string]$OutputCsvDir
    )

    Write-Host "Starting SUSE Marketplace Agreement export for $($Account.name) ($($Account.accountId))" -ForegroundColor Cyan
    Write-Log -Message "Exporting SUSE Marketplace Agreements for account '$($Account.name)' ($($Account.accountId))" -Level "INFO" -LogFilePath $LogFilePath

    $ExportData = @()
    # $Region = $Regions[0]  # Use first region as primary
    $Region = 'us-east-1'

    # Build SUSE filter
    $Filter = @(
        @{ Name = "AgreementType"; Values = @("PurchaseAgreement") }
        @{ Name = "AcceptorAccountId"; Values = @($Account.accountId) }
        @{ Name = "Status"; Values = @("ACTIVE") }
        # @{ Name = "ResourceIdentifier"; Values = @("suse") }
    )

    try {
        $SUSEAgreements = Search-MASAgreement -ProfileName $Account.profileName -Region $Region `
            -Filter $Filter `
            -ErrorAction Stop

        Write-Log -Message "Found $($SUSEAgreements.Agreements.Count) active SUSE PurchaseAgreement(s)." -Level "INFO" -LogFilePath $LogFilePath

        foreach ($summary in $SUSEAgreements.Agreements) {
            try {
                $agreement = Get-MASAgreement -ProfileName $Account.profileName -Region $Region -AgreementId $summary.AgreementId

                $ExportData += [PSCustomObject]@{
                    AccountId           = $Account.accountId
                    AccountName         = $Account.name
                    AgreementId         = $agreement.AgreementId
                    AgreementType       = $agreement.AgreementType
                    Status              = $agreement.Status
                    AcceptorAccountId   = $agreement.Acceptor.AccountId
                    ProposerAccountId   = $agreement.Proposer.AccountId
                    StartTime           = $agreement.StartTime
                    EndTime             = $agreement.EndTime
                    StartDateExcel      = (Get-Date $agreement.StartTime).ToString("yyyy-MM-dd")
                    EndDateExcel        = if ($agreement.EndTime) { (Get-Date $agreement.EndTime).ToString("yyyy-MM-dd") } else { $null }
                    AcceptanceTime      = $agreement.AcceptanceTime
                    AcceptanceDateExcel = (Get-Date $agreement.AcceptanceTime).ToString("yyyy-MM-dd")
                    EstimatedValue      = $agreement.EstimatedCharges.AgreementValue
                    CurrencyCode        = $agreement.EstimatedCharges.CurrencyCode
                    OfferId             = $agreement.ProposalSummary.OfferId
                    ResourceIds         = ($agreement.ProposalSummary.Resources | ForEach-Object { $_.id }) -join ', '
                    ResourceTypes       = ($agreement.ProposalSummary.Resources | ForEach-Object { $_.type }) -join ', '
                }
            }
            catch {
                Write-Log -Message "Error fetching details for AgreementId $($summary.AgreementId): $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
            }
        }

    }
    catch {
        Write-Log -Message "Search-MASAgreement failed in region '$Region': $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
    }

    if ($ExportData.Count -gt 0) {
        $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
        $safeName = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
        $outputPath = Join-Path $OutputCsvDir "$timestamp-$safeName-SUSE-Marketplace-Agreements.csv"

        Write-Host "Exporting to $outputPath" -ForegroundColor Cyan
        $ExportData | Export-Csv -Path $outputPath -NoTypeInformation -Force
        Write-Log -Message "Exported $($ExportData.Count) SUSE agreements to CSV." -Level "INFO" -LogFilePath $LogFilePath
    }
    else {
        Write-Log -Message "No SUSE Marketplace agreements found to export for $($Account.name)" -Level "WARN" -LogFilePath $LogFilePath
    }
}
