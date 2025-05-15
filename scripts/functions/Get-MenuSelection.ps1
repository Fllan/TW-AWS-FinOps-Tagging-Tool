function Get-MenuSelection {
    param(
        [string] $Prompt,
        [string[]] $Options
    )
    Write-Host
    Write-Host $Prompt -ForegroundColor Cyan

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "  [$($i+1)] $($Options[$i])"
    }

    do {
        $resp = Read-Host "Enter choice number(s), comma-separated"
        $nums = $resp -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
        $idxs = $nums | ForEach-Object { [int]$_ - 1 }

        if ($idxs.Count -and ($idxs -notmatch { $_ -lt 0 -or $_ -ge $Options.Count })) {
            return $idxs
        }
        Write-Host "Invalid selection, try again." -ForegroundColor Yellow
    } while ($true)
}