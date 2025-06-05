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
    $SavingsPlanPaymentOption = "No Upfront"
    $SavingsPlanDurationSeconds = 94608000 # 3 years for AWS
    $Currency = "USD"
    $Tenancy = "shared"

    foreach ($Region in $Regions) {
        Write-Log -Message "Getting EC2 instances in region '$Region' using profile '$($Account.profileName)'..." -Level "INFO" -LogFilePath $LogFilePath

        try {
            $Instances = Get-EC2Instance -ProfileName $Account.profileName -Region $Region -ErrorAction Stop

            if ($Instances) {
                Write-Log -Message "Found $($Instances.Count) EC2 instance(s) in '$Region'." -Level "INFO" -LogFilePath $LogFilePath

                foreach ($Instance in $Instances.Instances) {

                    # ################### Debug output
                    # Write-Host "$'instance' result + InstanceType:" -ForegroundColor Yellow
                    # $nameTag = $Instance.Tags | Where-Object { $_.Key -eq 'Name' } | Select-Object -ExpandProperty Value
                    # if ($nameTag) {
                    #     Write-Host $nameTag -ForegroundColor Yellow
                    # }
                    # else {
                    #     Write-Host "(No Name tag found)" -ForegroundColor DarkGray
                    # }
                    # Write-Host $Instance.InstanceType -ForegroundColor Yellow
                    # ################### Debug output

                    $productDescription = $Instance.PlatformDetails
                    
                    # ################### Debug output
                    # Write-Host "$'productDescription' result:" -ForegroundColor Yellow
                    # Write-Host $productDescription -ForegroundColor Yellow
                    # ################### Debug output

                    $key = "$($Region)|$($Instance.InstanceType)|$productDescription"

                    if (-not $RatesTable.ContainsKey($key)) {

                        $instanceFamily = "$($Instance.InstanceType)".Split('.')[0] # 't3.micro' → 't3'
                        $UsageTypeRegion = Get-UsageTypeRegion($Region)
                        $usageType = "$($UsageTypeRegion)-BoxUsage:$($Instance.InstanceType)"

                        $OfferingFilter = @(
                            @{ Name = "Region"; Values = @($Region) },
                            @{ Name = "InstanceFamily"; Values = @($instanceFamily) }
                        )

                        $SPOffering = Get-SPSavingsPlansOffering -ProfileName $Account.profileName -Region $Region `
                            -Filter $OfferingFilter `
                            -Currency $Currency `
                            -Duration $SavingsPlanDurationSeconds `
                            -PaymentOption $SavingsPlanPaymentOption `
                            -PlanType $SavingsPlanType `
                            -ProductType "EC2" `
                            -ServiceCode "ComputeSavingsPlans"
                        
                        # ################### Debug output
                        # Write-Host "SPOffering result:" -ForegroundColor Yellow
                        # $SPOffering | Format-List *
                        # ################### Debug output
                        
                        $OfferingRateFilter = @(
                            @{ Name = "Region"; Values = @($Region) },
                            @{ Name = "InstanceFamily"; Values = @($instanceFamily) },
                            @{ Name = "InstanceType"; Values = @($Instance.InstanceType) },
                            @{ Name = "ProductDescription"; Values = @($productDescription) },
                            @{ Name = "Tenancy"; Values = @($Tenancy) }
                        )

                        $SPOfferingRate = Get-SPSavingsPlansOfferingRate -ProfileName $Account.profileName -Region $Region `
                            -Filter $OfferingRateFilter `
                            -UsageType $usageType `
                            -SavingsPlanOfferingId $SPOffering.OfferingId

                        # ################### Debug output
                        # Write-Host "SPOfferingRate result:" -ForegroundColor Yellow
                        # $SPOfferingRate | Format-List *

                        # foreach ($rate in $SPOfferingRate) {
                        #     Write-Host "UsageType: $($rate.UsageType)"
                        #     foreach ($prop in $rate.Properties) {
                        #         Write-Host " - $($prop.Name): $($prop.Value)"
                        #     }
                        #     Write-Host ""
                        # }
                        # ################### Debug output

                        # $ServiceMetadata = Get-PLSService -ProfileName $Account.profileName -Region $Region `
                        #     -ServiceCode "AmazonEC2"

                        # ################### Debug output
                        # Write-Host "ServiceMetadata result:" -ForegroundColor Yellow
                        # $ServiceMetadata | Format-List *
                        # # foreach ($attribue in $ServiceMetadata.AttributeNames) {
                        # #     Write-Host " - $attribue" 
                        # # }
                        # ################### Debug output

                        $filters = @(
                            # @{Type = "TERM_MATCH"; Field = "instanceType"; Value = $Instance.InstanceType },
                            # @{Type = "TERM_MATCH"; Field = "operatingSystem"; Value = $productDescription },
                            # @{Type = "TERM_MATCH"; Field = "tenancy"; Value = $Tenancy },
                            # @{Type = "TERM_MATCH"; Field = "regionCode"; Value = $Region },
                            # @{Type = "TERM_MATCH"; Field = "capacitystatus"; Value = "Used" },
                            @{Type = "TERM_MATCH"; Field = "usagetype"; Value = $usageType },
                            @{Type = "TERM_MATCH"; Field = "marketoption"; Value = "OnDemand" },
                            @{Type = "TERM_MATCH"; Field = "operation"; Value = $SPOfferingRate.Operation }
                        )

                        $ProductJSONResult = Get-PLSProduct -ProfileName $Account.profileName -Region $Region `
                            -ServiceCode "AmazonEC2" `
                            -Filter $filters

                        $ProductObject = $ProductJSONResult | ConvertFrom-Json

                        $onDemandTerms = $ProductObject.terms.OnDemand
                        $firstOnDemandOffer = $onDemandTerms.PSObject.Properties.Value | Select-Object -First 1
                        $priceDimensions = $firstOnDemandOffer.priceDimensions.PSObject.Properties.Value
                        $hourlyPriceDimension = $priceDimensions | Where-Object { $_.unit -eq "Hrs" }
                        $OnDemandprice = $hourlyPriceDimension.pricePerUnit.USD

                        # ################### Debug output
                        # Write-Host "On-Demand Price: `$$OnDemandprice per hour"
                        # Write-Host "ProductJSONResult result:" -ForegroundColor Yellow
                        # $ProductJSONResult | Format-List *
                        # ################### Debug output

                        $RatesTable[$key] = @{
                            'OnDemand'    = $OnDemandprice
                            'SavingsPlan' = $SPOfferingRate.Rate
                        }
                    }

                    $ExportData += [PSCustomObject]@{
                        AccountId         = $Account.accountId
                        AccountName       = $Account.name
                        InstanceId        = $Instance.InstanceId
                        InstanceFamily    = $instanceFamily
                        InstanceType      = $Instance.InstanceType
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
        $outputPath = Join-Path $OutputCsvDir "$safeName-EC2-Savings-Plan-export-$timestamp.csv"
        Write-Host "Exporting to $outputPath" -ForegroundColor Cyan
        $ExportData | Export-Csv -Path $outputPath -NoTypeInformation -Force
        Write-Log -Message "Exported $($ExportData.Count) EC2 instances to CSV." -Level "INFO" -LogFilePath $LogFilePath
    }
    else {
        Write-Warning "No instance data to export for $($Account.name)"
    }
}

function Get-UsageTypeRegion($region) {
    switch ($region) {
        "eu-central-1" { return "EUC1" }
        "eu-west-1" { return "EUW1" }
        default { throw "Unknown region code for $region" }
    }
}