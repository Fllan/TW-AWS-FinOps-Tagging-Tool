#–– IMPORT & INIT ––#
Remove-Variable Selected* -ErrorAction SilentlyContinue
$ScriptDir = $PSScriptRoot

. "$ScriptDir\scripts\functions\Write-Log.ps1"
. "$ScriptDir\scripts\functions\Import-RequiredModules.ps1"
. "$ScriptDir\scripts\functions\Initialize-AndConnectAwsAccount.ps1"
. "$ScriptDir\scripts\functions\Get-MenuSelection.ps1"
. "$ScriptDir\scripts\core\export\Export-EC2Instances.ps1"
. "$ScriptDir\scripts\core\export\Export-EC2OnDemandAndSPRates.ps1"
. "$ScriptDir\scripts\core\export\Export-EC2Volumes.ps1"
. "$ScriptDir\scripts\core\export\Export-S3Buckets.ps1"
. "$ScriptDir\scripts\core\export\Export-EFSFileSystems.ps1"
. "$ScriptDir\scripts\core\export\Export-RDSDBInstances.ps1"
. "$ScriptDir\scripts\core\apply\Set-ResourceTagsFromCsv.ps1"
. "$ScriptDir\scripts\core\export\Update-BadTagValuesOnSnapshots.ps1"
. "$ScriptDir\scripts\core\export\Export-EC2SavingsPlans.ps1"
. "$ScriptDir\scripts\core\export\Export-SUSEMarketplaceAgreements.ps1"



$LogDir = Join-Path $ScriptDir logs
if (-not (Test-Path $LogDir)) { New-Item $LogDir -ItemType Directory | Out-Null }

$time = Get-Date -Format "yyyyMMddHHmmss"
$LogFile = Join-Path $LogDir ("{0}-finops-tagging-tool-log.txt" -f $time)


Write-LogInformation "Script started"
Write-LogInformation "Log file: $LogFile"

#–– LOAD CONFIG ––#
$configFiles = Get-ChildItem (Join-Path $ScriptDir config) -Filter *.psd1
$selCfgIdx = Get-MenuSelection "Select a client configuration file:" ($configFiles | ForEach-Object Name)
$configFile = $configFiles[$selCfgIdx]
Write-Host "Loading config: $($configFile.Name)" -ForegroundColor Green
Write-LogInformation "Importing config from $($configFile.FullName)"
$config = Import-PowerShellDataFile -Path $configFile.FullName -ErrorAction Stop
Write-LogInformation "Configuration file loaded"

#–– CHOICES ––#
$accounts = $config.accounts
$services = @("ec2-instances", "ec2-savings-plans", "ec2-ondemand-sp-rates", "ec2-volumes", "s3-buckets", "efs", "rds", "badtags", "suse-marketplace-agreements")
$actions = @("Export", "Apply")

$selAcct = Get-MenuSelection "Choose account(s):" ($accounts | ForEach-Object Name)
$selSvc = Get-MenuSelection "Choose service(s):" ($services)
$selAct = Get-MenuSelection "Choose action:"     ($actions)

#–– EXECUTION ––#
foreach ($acctIdx in $selAcct) {
    $acct = $accounts[$acctIdx]
    Write-Host "`n==> Account: $($acct.name) ($($acct.accountId))" -ForegroundColor Cyan
    Write-LogInformation "Initializing account $($acct.accountId)"

    # pick explicit per-account RoleName or fallback to global
    $role = if ($acct.roleName) { $acct.roleName } else { $config.ssoConnectionDetails.roleName }
    if (-not $acct.roleName) { Write-LogInformation "Using SSO RoleName: $role" }

    $ok = Initialize-AndConnectAwsAccount `
        -ProfileName $acct.profileName `
        -AccountId   $acct.accountId `
        -RoleName    $role `
        -StartUrl    $config.ssoConnectionDetails.startUrl `
        -SSORegion   $config.ssoConnectionDetails.ssoRegion `
        -LogFilePath $LogFile

    if (-not $ok) {
        Write-Host "  [SKIP] SSO failed for $($acct.name)" -ForegroundColor Yellow
        Write-LogWarning "SSO init failed for $($acct.accountId)"
        continue
    }

    foreach ($svcIdx in $selSvc) {
        $svc = $services[$svcIdx]
        Write-Host "  -> Service: $svc" -ForegroundColor White
        Write-LogInformation "Processing $svc"

        switch ($actions[$selAct].ToLower()) {
            'export' {
                switch ($svc) {
                    'suse-marketplace-agreements' {
                        Export-SUSEMarketplaceAgreements -Account $acct `
                            -Regions       $acct.regions `
                            -LogFilePath   $LogFile `
                            -OutputCsvDir  (Join-Path $ScriptDir 'csv\output')
                    }
                    'ec2-savings-plans' {
                        Export-EC2SavingsPlans -Account $acct `
                            -Regions       $acct.regions `
                            -LogFilePath   $LogFile `
                            -OutputCsvDir  (Join-Path $ScriptDir 'csv\output')
                    }
                    'badtags' {
                        Update-BadTagValuesOnSnapshots -Account       $acct `
                            -Regions       $acct.regions `
                            -LogFilePath   $LogFile `
                            -OutputCsvDir  (Join-Path $ScriptDir 'csv\output')
                    }
                    'ec2-instances' {
                        Export-EC2Instances -Account       $acct `
                            -Regions       $acct.regions `
                            -LogFilePath   $LogFile `
                            -OutputCsvDir  (Join-Path $ScriptDir 'csv\output') `
                            -RequiredTagKeys $config.requiredTagKeys
                    }
                    'ec2-ondemand-sp-rates' {
                        Export-EC2OnDemandAndSPRates -Account       $acct `
                            -Regions       $acct.regions `
                            -LogFilePath   $LogFile `
                            -OutputCsvDir  (Join-Path $ScriptDir 'csv\output')
                    }
                    'ec2-volumes' {
                        Export-EC2Volumes -Account       $acct `
                            -Regions       $acct.regions `
                            -LogFilePath   $LogFile `
                            -OutputCsvDir  (Join-Path $ScriptDir 'csv\output') `
                            -RequiredTagKeys $config.requiredTagKeys
                    }
                    's3-buckets' {
                        Export-S3Buckets     -Account       $acct `
                            -Regions       $acct.regions `
                            -LogFilePath   $LogFile `
                            -OutputCsvDir  (Join-Path $ScriptDir 'csv\output') `
                            -RequiredTagKeys $config.requiredTagKeys
                    }
                    'efs' {
                        Export-EFSFileSystems -Account        $acct `
                            -Regions        $acct.regions `
                            -LogFilePath    $LogFile `
                            -OutputCsvDir   (Join-Path $ScriptDir 'csv\output') `
                            -RequiredTagKeys $config.requiredTagKeys
                    }
                    'rds' {
                        Export-RDSDBInstances -Account        $acct `
                            -Regions        $acct.regions `
                            -LogFilePath    $LogFile `
                            -OutputCsvDir   (Join-Path $ScriptDir 'csv\output') `
                            -RequiredTagKeys $config.requiredTagKeys
                    }
                    # … other AWS services …
                }
                Write-LogInformation "Export complete for $svc"
            }
            'apply' {
                Write-LogInformation "Applying tags for service '$svc' on account $($acct.accountId)"
                Set-ResourceTagsFromCsv `
                    -Service     $svc `
                    -Account     $acct `
                    -InputCsvDir (Join-Path $ScriptDir 'csv\input') `
                    -LogFilePath $LogFile
            }
        }
    }
}

Write-Host "`nAll done. Logs at $LogFile" -ForegroundColor Magenta
Write-LogInformation "Script finished"
