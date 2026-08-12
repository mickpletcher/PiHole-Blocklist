[CmdletBinding()]
param(
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$MarkdownPath = './pihole-list-sources.md',

    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string]$CsvPath = './pihole-blocklist-sources.csv',

    [ValidateRange(1, 300)]
    [int]$TimeoutSeconds = 20,

    [switch]$SkipUrlChecks
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-MarkdownSource {
    param([string]$Path)

    $category = $null
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^##\s+(.*)$') {
            $category = $Matches[1].Trim()
            continue
        }

        if ($line -match '^\|\s*(?:true|false)\s*\|.*?\|.*?\|.*?\|\s*(.+?)\s*\|\s*(https://.+?)\s*\|\s*$') {
            [pscustomobject]@{
                Category = $category
                Source = $Matches[1].Trim()
                URL = $Matches[2].Trim()
            }
        }
    }
}

function Test-SourceUrl {
    param(
        [System.Net.Http.HttpClient]$Client,
        [string]$Url
    )

    $result = [ordered]@{
        HttpStatus = $null
        FinalUrl = $null
        Error = $null
    }

    foreach ($method in @([System.Net.Http.HttpMethod]::Head, [System.Net.Http.HttpMethod]::Get)) {
        $request = [System.Net.Http.HttpRequestMessage]::new($method, $Url)
        $response = $null
        try {
            $option = [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead
            $response = $Client.SendAsync($request, $option).GetAwaiter().GetResult()
            $result.HttpStatus = [int]$response.StatusCode
            $result.FinalUrl = $response.RequestMessage.RequestUri.AbsoluteUri
            if ($method -eq [System.Net.Http.HttpMethod]::Head -and $result.HttpStatus -in @(403, 405, 501)) {
                continue
            }
            return [pscustomobject]$result
        }
        catch {
            $result.Error = $_.Exception.Message
            if ($method -eq [System.Net.Http.HttpMethod]::Get) {
                return [pscustomobject]$result
            }
        }
        finally {
            if ($response) {
                $response.Dispose()
            }
            $request.Dispose()
        }
    }

    return [pscustomobject]$result
}

$csvRows = @(Import-Csv -LiteralPath $CsvPath)
if ($csvRows.Count -eq 0) {
    Write-Error "CSV has no rows: $CsvPath"
}

$requiredColumns = @(
    'Category', 'Source', 'URL', 'Enabled', 'Profiles', 'Format', 'Risk',
    'ExpectedDomains', 'MaxChangePercent'
)
$missingColumns = @($requiredColumns | Where-Object { $_ -notin $csvRows[0].PSObject.Properties.Name })
if ($missingColumns.Count -gt 0) {
    Write-Error "CSV is missing required columns: $($missingColumns -join ', ')"
}

$allowedProfiles = @('Balanced', 'Strict', 'Device', 'Policy')
$allowedFormats = @('Auto', 'Hosts', 'Adblock', 'Domains', 'AdblockTld')
$allowedRisks = @('Low', 'Moderate', 'High')
$metadataProblems = [System.Collections.Generic.List[object]]::new()

foreach ($row in $csvRows) {
    $enabled = $false
    $enabledValid = [bool]::TryParse($row.Enabled, [ref]$enabled)
    $profiles = @($row.Profiles -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $expected = 0L
    $expectedValid = [int64]::TryParse($row.ExpectedDomains, [ref]$expected)
    $maxChange = 0.0
    $maxChangeValid = [double]::TryParse(
        $row.MaxChangePercent,
        [System.Globalization.NumberStyles]::Number,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$maxChange
    )
    $issues = [System.Collections.Generic.List[string]]::new()

    if ([string]::IsNullOrWhiteSpace($row.Category)) { $issues.Add('Category is required') }
    if ([string]::IsNullOrWhiteSpace($row.Source)) { $issues.Add('Source is required') }
    if ([string]::IsNullOrWhiteSpace($row.URL)) { $issues.Add('URL is required') }
    if (-not $enabledValid) { $issues.Add('Enabled must be true or false') }
    if ($profiles | Where-Object { $_ -notin $allowedProfiles }) { $issues.Add('Profiles contains an unknown profile') }
    if (@($profiles | Group-Object | Where-Object Count -gt 1).Count -gt 0) { $issues.Add('Profiles contains a duplicate profile') }
    if ($row.Format -notin $allowedFormats) { $issues.Add('Format is invalid') }
    if ($row.Risk -notin $allowedRisks) { $issues.Add('Risk is invalid') }
    if (-not $expectedValid -or $expected -lt 0) { $issues.Add('ExpectedDomains must be a nonnegative integer') }
    if (-not $maxChangeValid -or $maxChange -le 0 -or $maxChange -gt 1000) { $issues.Add('MaxChangePercent must be greater than 0 and no more than 1000') }
    if ($enabledValid -and $enabled -and $profiles.Count -eq 0) { $issues.Add('Enabled sources require at least one profile') }
    if ($enabledValid -and -not $enabled -and $profiles.Count -gt 0) { $issues.Add('Disabled sources cannot be assigned to a profile') }
    if ($enabledValid -and $enabled -and $expected -le 0) { $issues.Add('Enabled sources require ExpectedDomains greater than zero') }
    if ($enabledValid -and $enabled -and $row.Format -eq 'AdblockTld') { $issues.Add('AdblockTld cannot be enabled for plain-domain output') }

    foreach ($issue in $issues) {
        $metadataProblems.Add([pscustomobject]@{ Source = $row.Source; Issue = $issue })
    }
}

$profileCoverage = foreach ($profileName in $allowedProfiles) {
    $count = @($csvRows | Where-Object {
        $_.Enabled -eq 'true' -and $profileName -in @($_.Profiles -split ';' | ForEach-Object { $_.Trim() })
    }).Count
    [pscustomobject]@{ Profile = $profileName; Sources = $count }
    if ($count -eq 0) {
        $metadataProblems.Add([pscustomobject]@{ Source = '(inventory)'; Issue = "Profile has no enabled sources: $profileName" })
    }
}

$markdownRows = @(Get-MarkdownSource -Path $MarkdownPath)
$parityDifferences = @(
    Compare-Object `
        -ReferenceObject @($markdownRows | ForEach-Object { '{0}|{1}|{2}' -f $_.Category, $_.Source, $_.URL }) `
        -DifferenceObject @($csvRows | ForEach-Object { '{0}|{1}|{2}' -f $_.Category, $_.Source, $_.URL })
)
$duplicateUrls = @($csvRows | Group-Object URL | Where-Object Count -gt 1)
$duplicateSources = @($csvRows | Group-Object Source | Where-Object Count -gt 1)
$invalidUrls = @($csvRows | Where-Object {
    $uri = $null
    -not [System.Uri]::TryCreate($_.URL, [System.UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https'
})

$urlResults = @()
if (-not $SkipUrlChecks) {
    Add-Type -AssemblyName System.Net.Http
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $true
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('PiHole-Blocklist-Validator/1.0')
    try {
        $urlResults = @($csvRows | ForEach-Object {
            $test = Test-SourceUrl -Client $client -Url $_.URL
            [pscustomobject]@{
                Category = $_.Category
                Source = $_.Source
                URL = $_.URL
                HttpStatus = $test.HttpStatus
                FinalUrl = $test.FinalUrl
                Error = $test.Error
            }
        })
    }
    finally {
        $client.Dispose()
        $handler.Dispose()
    }
}

$failedUrls = @($urlResults | Where-Object {
    $null -eq $_.HttpStatus -or $_.HttpStatus -lt 200 -or $_.HttpStatus -ge 400
})
$redirects = @($urlResults | Where-Object { $_.FinalUrl -and $_.FinalUrl -ne $_.URL })

Write-Host '=== SUMMARY ==='
Write-Host "MarkdownRows=$($markdownRows.Count)"
Write-Host "CsvRows=$($csvRows.Count)"
Write-Host "EnabledRows=$(@($csvRows | Where-Object Enabled -eq 'true').Count)"
Write-Host "ParityDifferences=$($parityDifferences.Count)"
Write-Host "MetadataProblems=$($metadataProblems.Count)"
Write-Host "InvalidUrls=$($invalidUrls.Count)"
Write-Host "DuplicateUrls=$($duplicateUrls.Count)"
Write-Host "DuplicateSources=$($duplicateSources.Count)"
if (-not $SkipUrlChecks) {
    Write-Host "FailedHttp=$($failedUrls.Count)"
    Write-Host "Redirects=$($redirects.Count)"
}

Write-Host ''
Write-Host '=== PROFILE COVERAGE ==='
$profileCoverage | Format-Table -AutoSize

Write-Host '=== METADATA PROBLEMS ==='
if ($metadataProblems.Count -gt 0) { $metadataProblems | Format-Table -Wrap -AutoSize } else { Write-Host 'None' }

Write-Host ''
Write-Host '=== DUPLICATE URLS ==='
if ($duplicateUrls) { $duplicateUrls | Select-Object Count, Name | Format-Table -AutoSize } else { Write-Host 'None' }

Write-Host ''
Write-Host '=== DUPLICATE SOURCES ==='
if ($duplicateSources) { $duplicateSources | Select-Object Count, Name | Format-Table -AutoSize } else { Write-Host 'None' }

Write-Host ''
Write-Host '=== CSV VS MARKDOWN DIFF ==='
if ($parityDifferences) { $parityDifferences | Format-Table -AutoSize } else { Write-Host 'None' }

if (-not $SkipUrlChecks) {
    Write-Host ''
    Write-Host '=== FAILED URLS ==='
    if ($failedUrls) {
        $failedUrls | Select-Object Category, Source, URL, HttpStatus, Error | Format-Table -Wrap -AutoSize
    }
    else {
        Write-Host 'None'
    }

    Write-Host ''
    Write-Host '=== REDIRECTS ==='
    if ($redirects) {
        $redirects | Select-Object Source, URL, FinalUrl, HttpStatus | Format-Table -Wrap -AutoSize
    }
    else {
        Write-Host 'None'
    }
}

if ($parityDifferences -or $metadataProblems.Count -gt 0 -or $invalidUrls -or $duplicateUrls -or $duplicateSources -or $failedUrls) {
    exit 1
}

exit 0
