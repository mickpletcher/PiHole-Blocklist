<#
.SYNOPSIS
    Downloads Pi-hole list sources and writes separate curated blocklist and
    whitelist files.

.DESCRIPTION
    Reads a CSV containing Category, Source, and URL columns. For each URL,
    downloads the list and parses it across three common formats:
      - Hosts file   : 0.0.0.0 domain.com / 127.0.0.1 domain.com
      - AdBlock      : ||domain.com^
      - Plain domain : domain.com
    Each parsed source is saved as its own text file under the source output
    directory. The final curated blocklist and whitelist are then built by
    merging those source text files and removing duplicates. If a domain is
    present in both final outputs, the whitelist wins and the domain is removed
    from the blocklist.

.PARAMETER SourceCsv
    Path to the input CSV. Must contain columns: Category, Source, URL.

.PARAMETER OutputDirectory
    Directory where curated list files are written. Default: .\Lists.

.PARAMETER SourceDirectoryName
    Subdirectory under OutputDirectory where per-source text files are written.
    Default: Sources.

.PARAMETER BlocklistFileName
    File name for the curated blocklist. Default: curated-blocklist.txt.

.PARAMETER WhitelistFileName
    File name for the curated whitelist. Default: curated-whitelist.txt.

.PARAMETER WhitelistCategory
    Category name treated as whitelist input. Default: Whitelist.

.PARAMETER TimeoutSeconds
    Per-request HTTP timeout in seconds. Default: 30.

.EXAMPLE
    .\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv

.EXAMPLE
    .\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv -OutputDirectory .\Lists -TimeoutSeconds 60
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$SourceCsv,

    [string]$OutputDirectory = ".\Lists",

    [string]$SourceDirectoryName = "Sources",

    [string]$BlocklistFileName = "curated-blocklist.txt",

    [string]$WhitelistFileName = "curated-whitelist.txt",

    [string]$WhitelistCategory = "Whitelist",

    [int]$TimeoutSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        default { 'Cyan' }
    }

    Write-Host "[$ts][$Level] $Message" -ForegroundColor $color
}

function Get-ListContent {
    param (
        [string]$Url,
        [int]$Timeout
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec $Timeout -UseBasicParsing -ErrorAction Stop
        return $response.Content
    }
    catch {
        Write-Log "Download failed: $Url -- $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

function Get-DomainsFromContent {
    param ([string]$Content)

    $skipValues = [System.Collections.Generic.HashSet[string]]@(
        'localhost', 'broadcasthost', 'ip6-localhost', 'ip6-loopback',
        '0.0.0.0', '127.0.0.1', '::1', '255.255.255.255'
    )

    $domains = [System.Collections.Generic.List[string]]::new()

    foreach ($rawLine in ($Content -split '\r?\n')) {
        $line = $rawLine.Trim()

        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match '^[#!\[\s]') { continue }

        $domain = $null

        switch -Regex ($line) {
            '^(?:0\.0\.0\.0|127\.0\.0\.1)\s+(\S+)' {
                $domain = $Matches[1] -replace '\s*#.*$', ''
                break
            }

            '^\|\|([a-zA-Z0-9][a-zA-Z0-9._-]+)\^' {
                $domain = $Matches[1]
                break
            }

            '^([a-zA-Z0-9][a-zA-Z0-9._-]{0,252}\.[a-zA-Z]{2,})$' {
                $domain = $Matches[1]
                break
            }
        }

        if ([string]::IsNullOrWhiteSpace($domain)) { continue }

        $domain = $domain.ToLower().Trim('.')

        if ($skipValues.Contains($domain)) { continue }
        if ($domain -notmatch '\.') { continue }
        if ($domain -match '[^a-z0-9.\-_]') { continue }

        $domains.Add($domain)
    }

    return $domains
}

function Get-SafeFileName {
    param (
        [string]$Category,
        [string]$Source,
        [int]$Index
    )

    $safeName = "$('{0:D2}' -f $Index)-$Category-$Source".ToLower()
    $safeName = $safeName -replace '[^a-z0-9]+', '-'
    $safeName = $safeName.Trim('-')

    return "$safeName.txt"
}

function Write-DomainFile {
    param (
        [string]$Path,
        [string[]]$Domains
    )

    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    [System.IO.File]::WriteAllLines(
        $resolvedPath,
        $Domains,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Merge-DomainFiles {
    param (
        [string]$Path
    )

    $domains = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    if (-not (Test-Path -Path $Path -PathType Container)) {
        return [string[]]@()
    }

    foreach ($file in Get-ChildItem -Path $Path -Filter '*.txt' -File) {
        foreach ($line in Get-Content -Path $file.FullName) {
            $domain = $line.Trim()
            if (-not [string]::IsNullOrWhiteSpace($domain)) {
                [void]$domains.Add($domain)
            }
        }
    }

    return [string[]]($domains | Sort-Object)
}

$startTime = Get-Date

Write-Log "Pi-hole List Builder"
Write-Log "Source CSV       : $SourceCsv"
Write-Log "Output directory : $OutputDirectory"
Write-Log "Source directory : $SourceDirectoryName"
Write-Log "Blocklist file   : $BlocklistFileName"
Write-Log "Whitelist file   : $WhitelistFileName"
Write-Log "Whitelist category: $WhitelistCategory"
Write-Log "Timeout          : ${TimeoutSeconds}s"

$sources = @(Import-Csv -Path $SourceCsv)

if ($sources.Count -eq 0) {
    Write-Log "Source CSV has no rows: $SourceCsv" -Level ERROR
    exit 1
}

$requiredColumns = @('Category', 'Source', 'URL')
foreach ($col in $requiredColumns) {
    if ($col -notin $sources[0].PSObject.Properties.Name) {
        Write-Log "Source CSV is missing required column: $col" -Level ERROR
        exit 1
    }
}

if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$sourceDirectory = Join-Path -Path $OutputDirectory -ChildPath $SourceDirectoryName
$blocklistSourceDirectory = Join-Path -Path $sourceDirectory -ChildPath "blocklist"
$whitelistSourceDirectory = Join-Path -Path $sourceDirectory -ChildPath "whitelist"

foreach ($path in @($blocklistSourceDirectory, $whitelistSourceDirectory)) {
    if (Test-Path -Path $path -PathType Container) {
        Get-ChildItem -Path $path -Filter '*.txt' -File | Remove-Item -Force
    }
    else {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

$successCount = 0
$failCount = 0
$index = 0
$sourceFileCount = 0

foreach ($entry in $sources) {
    $index++
    $category = $entry.Category.Trim()
    $name = $entry.Source.Trim()
    $url = $entry.URL.Trim()
    $targetName = if ($category -eq $WhitelistCategory) { 'whitelist' } else { 'blocklist' }
    $targetDirectory = if ($category -eq $WhitelistCategory) { $whitelistSourceDirectory } else { $blocklistSourceDirectory }
    $sourceFileName = Get-SafeFileName -Category $category -Source $name -Index $index
    $sourceFilePath = Join-Path -Path $targetDirectory -ChildPath $sourceFileName

    Write-Log "[$index/$($sources.Count)] $name -> $targetName"

    $content = Get-ListContent -Url $url -Timeout $TimeoutSeconds

    if ($null -eq $content) {
        $failCount++
        continue
    }

    $parsed = @(Get-DomainsFromContent -Content $content)
    Write-DomainFile -Path $sourceFilePath -Domains $parsed
    $sourceFileCount++

    Write-Log "  $($parsed.Count) parsed | saved $sourceFileName" -Level SUCCESS
    $successCount++
}

Write-Log "Merging source text files..."

$blocklistDomains = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($domain in @(Merge-DomainFiles -Path $blocklistSourceDirectory)) {
    [void]$blocklistDomains.Add($domain)
}

$whitelistDomains = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)
foreach ($domain in @(Merge-DomainFiles -Path $whitelistSourceDirectory)) {
    [void]$whitelistDomains.Add($domain)
}

$collisionCount = 0
foreach ($domain in @($whitelistDomains)) {
    if ($blocklistDomains.Remove($domain)) {
        $collisionCount++
    }
}

$finalBlocklistDomains = [string[]]($blocklistDomains | Sort-Object)
$finalWhitelistDomains = [string[]]($whitelistDomains | Sort-Object)
$blocklistPath = Join-Path -Path $OutputDirectory -ChildPath $BlocklistFileName
$whitelistPath = Join-Path -Path $OutputDirectory -ChildPath $WhitelistFileName

Write-Log "Writing output..."
Write-DomainFile -Path $blocklistPath -Domains $finalBlocklistDomains
Write-DomainFile -Path $whitelistPath -Domains $finalWhitelistDomains

$elapsed = (Get-Date) - $startTime
$elapsedFmt = '{0:mm\:ss}' -f $elapsed

Write-Log "------------------------------------------------------"
Write-Log "Elapsed          : $elapsedFmt"
Write-Log "Sources OK       : $successCount / $($sources.Count)" -Level $(if ($failCount -gt 0) { 'WARN' } else { 'SUCCESS' })

if ($failCount -gt 0) {
    Write-Log "Sources failed   : $failCount" -Level WARN
}

Write-Log "Source files     : $sourceFileCount"
Write-Log "Whitelist wins   : $($collisionCount.ToString('N0')) collisions removed from blocklist"
Write-Log "Blocklist domains: $($finalBlocklistDomains.Count.ToString('N0'))" -Level SUCCESS
Write-Log "Whitelist domains: $($finalWhitelistDomains.Count.ToString('N0'))" -Level SUCCESS
Write-Log "Blocklist output : $blocklistPath" -Level SUCCESS
Write-Log "Whitelist output : $whitelistPath" -Level SUCCESS
