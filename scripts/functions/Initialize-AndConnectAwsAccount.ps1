function Initialize-AndConnectAwsAccount {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)] [string] $ProfileName,
        [Parameter(Mandatory = $true)] [string] $AccountId,
        [Parameter(Mandatory = $true)] [string] $RoleName,
        [Parameter(Mandatory = $true)] [string] $StartUrl,
        [Parameter(Mandatory = $true)] [string] $SSORegion,
        [Parameter(Mandatory = $false)] [string] $SessionName,
        [Parameter(Mandatory = $true)] [string] $LogFilePath
    )

    # 1) Try to reuse an existing session
    try {
        Write-Log -Message "Checking existing session for profile '$ProfileName'..." -Level INFO -LogFilePath $LogFilePath
        Get-STSCallerIdentity -ProfileName $ProfileName -ErrorAction Stop | Out-Null

        Write-Log -Message "Existing session valid for profile '$ProfileName'; skipping SSO." -Level INFO -LogFilePath $LogFilePath
        return $true
    }
    catch {
        Write-Log -Message "No valid session for '$ProfileName'; proceeding with SSO." -Level INFO -LogFilePath $LogFilePath
    }

    # 2) Perform SSO login
    try {
        $params = @{
            ProfileName = $ProfileName
            AccountId   = $AccountId
            RoleName    = $RoleName
            StartUrl    = $StartUrl
            SSORegion   = $SSORegion
        }
        if ($SessionName) {
            $params.SessionName = $SessionName
        }

        Write-Log -Message "Initializing SSO for profile '$ProfileName' on account '$AccountId'..." -Level INFO -LogFilePath $LogFilePath
        Initialize-AWSSSOConfiguration @params -ErrorAction Stop

        Write-Log -Message "SSO login initiated successfully for profile '$ProfileName'." -Level INFO -LogFilePath $LogFilePath
        return $true
    }
    catch {
        Write-Log -Message "Failed SSO for profile '$ProfileName': $($_.Exception.Message)" -Level ERROR -LogFilePath $LogFilePath
        return $false
    }
}
