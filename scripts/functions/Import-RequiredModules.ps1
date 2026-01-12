$RequiredAwsModules = @(
    "AWS.Tools.Common"
    "AWS.Tools.EC2"
    "AWS.Tools.S3"
    "AWS.Tools.ElasticFileSystem"
    "AWS.Tools.RDS"
    "AWS.Tools.SavingsPlans"
    "AWS.Tools.Pricing"
    "AWS.Tools.MarketplaceAgreement"
)

Write-Host -ForegroundColor Cyan "Checking for required AWS PowerShell modules..."

foreach ($ModuleName in $RequiredAwsModules) {
    if (-not (Get-Module -Name $ModuleName)) {
        Write-Host -ForegroundColor Cyan "Attempting to import module: $ModuleName"
        try {
            Import-Module $ModuleName -ErrorAction Stop
            if (Get-Module -Name $ModuleName) {
                Write-Host -ForegroundColor Cyan "Successfully imported module: $ModuleName"
            }
            else {
                Write-Log -Message "Module '$ModuleName' was not loaded after Import-Module attempt. Please check your PowerShell environment." -Level "ERROR"
                exit 1
            }

        }
        catch {
            Write-Log -Message "Failed to import required PowerShell module '$ModuleName'. It might not be installed." -Level "ERROR"
            Write-Log -Message "Please install it using: Install-Module -Name $ModuleName" -Level "ERROR"
            exit 1
        }
    }
    else {
        Write-Host -ForegroundColor Cyan "Module '$ModuleName' is already loaded."
    }
}