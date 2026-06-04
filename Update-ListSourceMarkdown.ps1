param(
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath = "./pihole-blocklist-sources.csv",

    [string]$SourceIndexPath = "./pihole-list-sources.md",

    [string]$ReviewPath = "./LISTS.md"
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$rows = @(Import-Csv -Path $CsvPath)

if ($rows.Count -eq 0) {
    Write-Error "CSV has no rows: $CsvPath"
}

$categories = @($rows | Select-Object -ExpandProperty Category -Unique)
$blocklistRows = @($rows | Where-Object { $_.Category -ne 'Whitelist' })
$whitelistRows = @($rows | Where-Object { $_.Category -eq 'Whitelist' })

function Add-SourceSections {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [object[]]$Rows
    )

    foreach ($category in @($Rows | Select-Object -ExpandProperty Category -Unique)) {
        $Lines.Add('')
        $Lines.Add("## $category")
        $Lines.Add('')
        $Lines.Add('| Source | URL |')
        $Lines.Add('|---|---|')

        foreach ($row in @($Rows | Where-Object { $_.Category -eq $category })) {
            $Lines.Add("| $($row.Source) | $($row.URL) |")
        }
    }
}

$sourceIndex = [System.Collections.Generic.List[string]]::new()
$sourceIndex.Add('# Pi-hole List Sources')
$sourceIndex.Add('')
$sourceIndex.Add('Full index of curated blocklist and whitelist sources organized by category. The CSV is the source of truth for automation. Keep this file in parity with pihole-blocklist-sources.csv.')
Add-SourceSections -Lines $sourceIndex -Rows $rows
Set-Content -Path $SourceIndexPath -Value $sourceIndex -Encoding UTF8

$review = [System.Collections.Generic.List[string]]::new()
$review.Add('# Curated Pi-hole Lists')
$review.Add('')
$review.Add('This file lists every source used to build the curated Pi-hole blocklist and whitelist outputs.')
$review.Add('')
$review.Add('## Curated Output URLs')
$review.Add('')
$review.Add('| Output | Raw URL |')
$review.Add('|---|---|')
$review.Add('| Curated blocklist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-blocklist.txt |')
$review.Add('| Curated whitelist | https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-whitelist.txt |')
$review.Add('')
$review.Add('## Inventory Summary')
$review.Add('')
$review.Add('| Metric | Count |')
$review.Add('|---|---:|')
$review.Add("| Total source rows | $($rows.Count) |")
$review.Add("| Blocklist sources | $($blocklistRows.Count) |")
$review.Add("| Whitelist sources | $($whitelistRows.Count) |")
$review.Add("| Categories | $($categories.Count) |")
$review.Add('')
$review.Add('## Blocklist Sources')
Add-SourceSections -Lines $review -Rows $blocklistRows
$review.Add('')
$review.Add('## Whitelist Sources')
Add-SourceSections -Lines $review -Rows $whitelistRows
Set-Content -Path $ReviewPath -Value $review -Encoding UTF8

Write-Host "Updated $SourceIndexPath"
Write-Host "Updated $ReviewPath"
