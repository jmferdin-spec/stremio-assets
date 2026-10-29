<#
.SYNOPSIS
    Clears jsDelivr's cache for every image linked in your Nuvio collections file,
    so Nuvio picks up new or replaced images right away instead of waiting for the CDN.

.USAGE
    From the repo folder (after your changes are pushed to GitHub):
        powershell -ExecutionPolicy Bypass -File .\collections\scripts\purge-all.ps1
    Or point it at a different collections file:
        .\collections\scripts\purge-all.ps1 -CollectionsFile .\my-other-file.json
#>
param(
    [string]$CollectionsFile = (Join-Path $PSScriptRoot '..\..\collections-nuvio-latest.json')
)

$cdn   = 'https://cdn.jsdelivr.net/gh/'
$purge = 'https://purge.jsdelivr.net/gh/'

$text = Get-Content -LiteralPath $CollectionsFile -Raw -Encoding UTF8
$urls = [regex]::Matches($text, [regex]::Escape($cdn) + '[^"\s]+') |
        ForEach-Object { $_.Value } | Sort-Object -Unique

Write-Host "Purging $($urls.Count) URLs from jsDelivr..."
$ok = 0; $fail = 0
foreach ($u in $urls) {
    $p = $u.Replace($cdn, $purge)
    try {
        Invoke-RestMethod -Uri $p -Method Get -TimeoutSec 30 | Out-Null
        $ok++
    } catch {
        $fail++
        Write-Warning "Failed: $p ($($_.Exception.Message))"
    }
    Start-Sleep -Milliseconds 200   # be gentle with the purge API
}
Write-Host "Done. Purged: $ok  Failed: $fail"
