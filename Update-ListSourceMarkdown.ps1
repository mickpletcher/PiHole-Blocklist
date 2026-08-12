[CmdletBinding()]
param(
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CsvPath = './pihole-blocklist-sources.csv',

    [string]$SourceIndexPath = './pihole-list-sources.md',

    [string]$ReviewPath = './LISTS.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$rows = @(Import-Csv -LiteralPath $CsvPath)
if ($rows.Count -eq 0) {
    Write-Error "CSV has no rows: $CsvPath"
}

function Add-ProfileSummary {
    param([System.Collections.Generic.List[string]]$Lines)

    $Lines.Add('## Profiles')
    $Lines.Add('')
    $Lines.Add('| Profile | Purpose | Source count |')
    $Lines.Add('|---|---|---:|')
    $descriptions = [ordered]@{
        Balanced = 'Default security, privacy, advertising, and tracking protection.'
        Strict = 'Balanced plus OISD Big for broader blocking.'
        Device = 'Opt-in device and service-specific restrictions.'
        Policy = 'Opt-in piracy, shortener, bypass, fake-news, and SafeSearch policy restrictions.'
    }
    foreach ($profileName in $descriptions.Keys) {
        $count = @($rows | Where-Object {
            $_.Enabled -eq 'true' -and $profileName -in @($_.Profiles -split ';' | ForEach-Object { $_.Trim() })
        }).Count
        $Lines.Add("| $profileName | $($descriptions[$profileName]) | $count |")
    }
}

function Add-SourceSection {
    param([System.Collections.Generic.List[string]]$Lines)

    foreach ($category in @($rows | Select-Object -ExpandProperty Category -Unique)) {
        $Lines.Add('')
        $Lines.Add("## $category")
        $Lines.Add('')
        $Lines.Add('| Enabled | Profiles | Risk | Format | Source | URL |')
        $Lines.Add('|---|---|---|---|---|---|')
        foreach ($row in @($rows | Where-Object Category -eq $category)) {
            $profiles = if ($row.Profiles) { $row.Profiles -replace ';', ', ' } else { 'None' }
            $Lines.Add("| $($row.Enabled) | $profiles | $($row.Risk) | $($row.Format) | $($row.Source) | $($row.URL) |")
        }
    }
}

$enabledRows = @($rows | Where-Object Enabled -eq 'true')
$disabledRows = @($rows | Where-Object Enabled -eq 'false')
$categories = @($rows | Select-Object -ExpandProperty Category -Unique)

$sourceIndex = [System.Collections.Generic.List[string]]::new()
$sourceIndex.Add('# Pi-hole List Sources')
$sourceIndex.Add('')
$sourceIndex.Add('The CSV is the source of truth. Disabled rows remain documented for review but are not included in published profiles.')
$sourceIndex.Add('')
Add-ProfileSummary -Lines $sourceIndex
Add-SourceSection -Lines $sourceIndex
Set-Content -LiteralPath $SourceIndexPath -Value $sourceIndex -Encoding utf8NoBOM

$review = [System.Collections.Generic.List[string]]::new()
$review.Add('# Curated Pi-hole Lists')
$review.Add('')
$review.Add('Review the profile scope before subscribing. Device and policy profiles deliberately block services beyond general advertising, tracking, and malware protection.')
$review.Add('')
$review.Add('## Curated Output URLs')
$review.Add('')
$review.Add('| Output | Raw URL |')
$review.Add('|---|---|')
$review.Add('| Balanced blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist.txt |')
$review.Add('| Strict blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-strict.txt |')
$review.Add('| Device blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-device.txt |')
$review.Add('| Policy blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-policy.txt |')
$review.Add('| Project allowlist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-whitelist.txt |')
$review.Add('')
$review.Add('## Inventory Summary')
$review.Add('')
$review.Add('| Metric | Count |')
$review.Add('|---|---:|')
$review.Add("| Total source rows | $($rows.Count) |")
$review.Add("| Enabled source rows | $($enabledRows.Count) |")
$review.Add("| Disabled source rows | $($disabledRows.Count) |")
$review.Add("| Categories | $($categories.Count) |")
$review.Add('')
Add-ProfileSummary -Lines $review
Add-SourceSection -Lines $review
Set-Content -LiteralPath $ReviewPath -Value $review -Encoding utf8NoBOM

Write-Host "Updated $SourceIndexPath"
Write-Host "Updated $ReviewPath"
