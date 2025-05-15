function Write-Log {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogFilePath
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    switch ($Level.ToUpper()) {
        "INFO" { Write-Host $LogEntry }
        "WARN" { Write-Warning $LogEntry }
        "ERROR" { Write-Error $LogEntry }
        default { Write-Host $LogEntry }
    }
    if (-not [string]::IsNullOrEmpty($LogFilePath)) {
        try {
            $LogEntry | Add-Content -Path $LogFilePath -Force -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            Write-Error "Failed writing to log file: $($_.Exception.Message)"
        }
    }
}
function Write-LogInformation { Write-Log -Message $args[0] -Level INFO   -LogFilePath $LogFile > $null }
function Write-LogWarning { Write-Log -Message $args[0] -Level WARN   -LogFilePath $LogFile > $null }
function Write-LogError { Write-Log -Message $args[0] -Level ERROR  -LogFilePath $LogFile > $null }