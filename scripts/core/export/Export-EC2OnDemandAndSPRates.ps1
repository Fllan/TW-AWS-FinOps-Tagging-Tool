function Export-EC2OnDemandAndSPRates {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][hashtable]$Account,
        [Parameter(Mandatory = $true)][array]$Regions,
        [Parameter(Mandatory = $true)][string]$LogFilePath,
        [Parameter(Mandatory = $true)][string]$OutputCsvDir
    )

    Write-Host "Starting export for $($Account.name) ($($Account.accountId))" -ForegroundColor Cyan
    Write-Log -Message "Starting EC2 Savings Plan export for account '$($Account.name)' ($($Account.accountId)) in regions: $($Regions -join ', ')" -Level "INFO" -LogFilePath $LogFilePath

    $ExportData = @()
    $RatesTable = @{}

    $SavingsPlanType = "EC2Instance" # [EC2Instance, Compute]
    $SavingsPlanPaymentOption = "No Upfront" # [No Upfront, Partial Upfront, All Upfront]
    $SavingsPlanDurationSeconds = 94608000 # 3 years for AWS
    $Currency = "USD"
    $Tenancy = "shared"

    Write-Log -Message "Savings Plan configured for : $SavingsPlanType (SavingsPlan Type) - $SavingsPlanPaymentOption (Payment option) - $($SavingsPlanDurationSeconds / (365*24*60*60)) year(s) (Term length) - $Currency (Currency) - $Tenancy (Tenancy)" -Level "WARN" -LogFilePath $LogFilePath

    $cacheHits = 0
    $totalApiCalls = 0

    foreach ($Region in $Regions) {
        Write-Log -Message "Getting EC2 instances in region '$Region' using profile '$($Account.profileName)'..." -Level "INFO" -LogFilePath $LogFilePath

        try {
            $Instances = Get-EC2Instance -ProfileName $Account.profileName -Region $Region -ErrorAction Stop

            if ($Instances) {
                Write-Log -Message "Found $($Instances.Count) EC2 instance(s) in '$Region'." -Level "INFO" -LogFilePath $LogFilePath

                foreach ($Instance in $Instances.Instances) {

                    $InstanceNameTag = $Instance.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -ExpandProperty Value
                    $InstanceType = $Instance.InstanceType
                    $InstanceFamily = "$($InstanceType)".Split('.')[0] # 't3.micro' → 't3'
                    $productDescription = $Instance.PlatformDetails

                    $key = "$($Region)|$($InstanceType)|$productDescription"

                    if (-not $RatesTable.ContainsKey($key)) {

                        $UsageTypeRegion = Get-UsageTypeRegion($Region)
                        $usageType = "$($UsageTypeRegion)-BoxUsage:$($InstanceType)"

                        $OfferingFilter = @(
                            @{ Name = "Region"; Values = @($Region) },
                            @{ Name = "InstanceFamily"; Values = @($InstanceFamily) }
                        )

                        try {
                            $totalApiCalls++

                            $SPOffering = Get-SPSavingsPlansOffering -ProfileName $Account.profileName -Region $Region `
                                -Filter $OfferingFilter `
                                -Currency $Currency `
                                -Duration $SavingsPlanDurationSeconds `
                                -PaymentOption $SavingsPlanPaymentOption `
                                -PlanType $SavingsPlanType `
                                -ProductType "EC2" `
                                -ServiceCode "ComputeSavingsPlans"
                        }
                        catch {
                            Write-Log -Message "Error fetching SavingsPlan Offering for key : $key : $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
                        }
                        
                        $OfferingRateFilter = @(
                            @{ Name = "Region"; Values = @($Region) },
                            @{ Name = "InstanceFamily"; Values = @($InstanceFamily) },
                            @{ Name = "InstanceType"; Values = @($InstanceType) },
                            @{ Name = "ProductDescription"; Values = @($productDescription) },
                            @{ Name = "Tenancy"; Values = @($Tenancy) }
                        )

                        try {
                            $totalApiCalls++

                            $SPOfferingRate = Get-SPSavingsPlansOfferingRate -ProfileName $Account.profileName -Region $Region `
                                -Filter $OfferingRateFilter `
                                -UsageType $usageType `
                                -SavingsPlanOfferingId $SPOffering.OfferingId

                        }
                        catch {
                            Write-Log -Message "Error fetching SavingsPlan Offering Rate for key : $key : $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
                        }
                        
                        $OnDemandFilter = @(
                            @{Type = "TERM_MATCH"; Field = "usagetype"; Value = $usageType },
                            @{Type = "TERM_MATCH"; Field = "marketoption"; Value = "OnDemand" },
                            @{Type = "TERM_MATCH"; Field = "operation"; Value = $SPOfferingRate.Operation }
                        )
    
                        try {
                            $totalApiCalls++

                            # The region is forced to 'eu-central-1' to avoid "An error occurred while sending the request."
                            # No idea why... But now it is working
                            $ProductJSONResult = Get-PLSProduct -ProfileName $Account.profileName -Region "eu-central-1" `
                                -ServiceCode "AmazonEC2" `
                                -Filter $OnDemandFilter

                            $ProductObject = $ProductJSONResult | ConvertFrom-Json
        
                            $onDemandTerms = $ProductObject.terms.OnDemand
                            $firstOnDemandOffer = $onDemandTerms.PSObject.Properties.Value | Select-Object -First 1
                            $priceDimensions = $firstOnDemandOffer.priceDimensions.PSObject.Properties.Value
                            $hourlyPriceDimension = $priceDimensions | Where-Object { $_.unit -eq "Hrs" }
                            $OnDemandprice = $hourlyPriceDimension.pricePerUnit.USD
                        }
                        catch {
                            Write-Log -Message "Error fetching OnDemand Rate for key : $key : $($_.Exception.Message)" -Level "ERROR" -LogFilePath $LogFilePath
                        }
                        
                        $RatesTable[$key] = @{
                            'OnDemand'    = $OnDemandprice
                            'SavingsPlan' = $SPOfferingRate.Rate
                        }

                        Write-Log -Message "Cached rates for key $key" -Level "INFO" -LogFilePath $LogFilePath
                    }
                    else {
                        $cacheHits++

                        Write-Log -Message "Using cached rates (Cache hits $cacheHits) for the key : $key" -Level "INFO" -LogFilePath $LogFilePath
                    }

                    $ExportData += [PSCustomObject]@{
                        AccountId         = $Account.accountId
                        AccountName       = $Account.name
                        InstanceId        = $Instance.InstanceId
                        InstanceTagName   = $InstanceNameTag
                        InstanceFamily    = $InstanceFamily
                        InstanceType      = $InstanceType
                        Region            = $Region
                        OperatingSystem   = $productDescription
                        OnDemandRate      = $RatesTable[$key].OnDemand
                        SavingsPlanRate   = $RatesTable[$key].SavingsPlan
                        ValueDifference   = [math]::Round(($RatesTable[$key].OnDemand - $RatesTable[$key].SavingsPlan), 6)
                        SavingsPercentage = [math]::Round((($RatesTable[$key].OnDemand - $RatesTable[$key].SavingsPlan) / $RatesTable[$key].OnDemand) * 100, 2)
                    }
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
        $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
        $safeName = $Account.name -replace '[^a-zA-Z0-9_.-]', '_'
        $outputPath = Join-Path $OutputCsvDir "$timestamp-$safeName-EC2-Savings-Plan-export.csv"
        Write-Host "Exporting to $outputPath" -ForegroundColor Cyan
        $ExportData | Export-Csv -Path $outputPath -NoTypeInformation -Force
        Write-Log -Message "Exported $($ExportData.Count) EC2 instances to CSV." -Level "INFO" -LogFilePath $LogFilePath
    }
    else {
        Write-Log -Message "No instance data to export for $($Account.name)" -Level "WARN" -LogFilePath $LogFilePath
    }

    Write-Log -Message "Total API calls made : $totalApiCalls" -Level "WARN" -LogFilePath $LogFilePath
    Write-Log -Message "Cache hits : $cacheHits" -Level "WARN" -LogFilePath $LogFilePath
    Write-Log -Message "Unique rate combinations cached : $($RatesTable.Keys.Count)" -Level "WARN" -LogFilePath $LogFilePath
}

function Get-UsageTypeRegion($region) {
    switch ($region) {
        "eu-central-1" { return "EUC1" }
        "eu-west-1" { return "EU" }
        default { throw "Unknown region code for $region" }
    }
}