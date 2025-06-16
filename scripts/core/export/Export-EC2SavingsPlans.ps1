function Export-EC2SavingsPlans {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable]$Account,
        [Parameter(Mandatory = $true)][array]$Regions,
        [Parameter(Mandatory = $true)][string]$LogFilePath,
        [Parameter(Mandatory = $true)][string]$OutputCsvDir
    )

    Write-Host "Starting EC2 Savings Plan subscription export for $($Account.name) ($($Account.accountId))" -ForegroundColor Cyan
    Write-Log -Message "Exporting EC2 Savings Plans for account '$($Account.name)' ($($Account.accountId))" -Level "INFO" -LogFilePath $LogFilePath

    $ExportData = @()
    $Region = $Regions[0]

    Write-Log -Message "Getting EC2 Savings Plans in region '$Region' using profile '$($Account.profileName)'..." -Level "INFO" -LogFilePath $LogFilePath
    try {
        $SavingsPlans = Get-SPSavingsPlan -ProfileName $Account.profileName -Region $Region -ErrorAction Stop
        Write-Log -Message "Retrieved $($SavingsPlans.Count) savings plan(s)." -Level "INFO" -LogFilePath $LogFilePath
    
        foreach ($SP in $SavingsPlans) {
            $ExportData += [PSCustomObject]@{
                AccountId        = $Account.accountId
                AccountName      = $Account.name
                SavingsPlanId    = $SP.SavingsPlanId
                State            = $SP.State
                Region           = $SP.Region
                Description      = $SP.Description
                StartDate        = $SP.Start
                EndDate          = $SP.End
                StartDateExcel   = (Get-Date $SP.Start).ToString("yyyy-MM-dd")
                EndDateExcel     = (Get-Date $SP.End).ToString("yyyy-MM-dd")
                TermDurationDays = [math]::Round($SP.TermDurationInSeconds / 86400, 0)
                HourlyCommitment = $SP.Commitment
                SavingsPlanType  = $SP.SavingsPlanType
                PaymentOption    = $SP.PaymentOption
            }
        }

    }
    catch {
        Write-Log -Message "Error retrieving Savings Plans: $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
    }
    

    if ($ExportData.Count -gt 0) {
        $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
        $safeName = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
        $outputPath = Join-Path $OutputCsvDir "$timestamp-$safeName-SavingsPlanSubscriptions.csv"

        Write-Host "Exporting to $outputPath" -ForegroundColor Cyan
        $ExportData | Export-Csv -Path $outputPath -NoTypeInformation -Force
        Write-Log -Message "Exported $($ExportData.Count) savings plans to CSV." -Level "INFO" -LogFilePath $LogFilePath
    }
    else {
        Write-Log -Message "No savings plans to export for $($Account.name)" -Level "WARN" -LogFilePath $LogFilePath
    }
}
