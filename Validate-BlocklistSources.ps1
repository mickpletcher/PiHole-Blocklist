param(
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$MarkdownPath = "./pihole-list-sources.md",

    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$CsvPath = "./pihole-blocklist-sources.csv",

    [int]$TimeoutSeconds = 20,

    [switch]$SkipUrlChecks
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-MarkdownRows {
    param([string]$Path)

    $category = $null

    foreach ($line in Get-Content -Path $Path) {
        if ($line -match '^##\s+(.*)$') {
            $category = $matches[1].Trim()
            continue
        }

        if ($line -match '^\|\s*(.+?)\s*\|\s*(https?://.+?)\s*\|\s*$' -and $matches[1] -ne 'Source') {
            [pscustomobject]@{
                Category = $category
                Source = $matches[1].Trim()
                URL = $matches[2].Trim()
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

    try {
        $headRequest = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Head, $Url)
        $response = $Client.Send($headRequest)
        $result.HttpStatus = [int]$response.StatusCode
        $result.FinalUrl = $response.RequestMessage.RequestUri.AbsoluteUri
        return [pscustomobject]$result
    }
    catch {
        try {
            $getRequest = [System.Net.Http.HttpRequestMessage]::new([System.Net.Http.HttpMethod]::Get, $Url)
            $response = $Client.Send($getRequest, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
            $result.HttpStatus = [int]$response.StatusCode
            $result.FinalUrl = $response.RequestMessage.RequestUri.AbsoluteUri
            return [pscustomobject]$result
        }
        catch {
            $result.Error = $_.Exception.Message
            return [pscustomobject]$result
        }
    }
}

$markdownRows = @(Get-MarkdownRows -Path $MarkdownPath)
$csvRows = @(Import-Csv -Path $CsvPath)

if ($csvRows.Count -eq 0) {
    Write-Host "CSV has no rows: $CsvPath"
    exit 1
}

$parityDifferences = @(
    Compare-Object `
        -ReferenceObject @($markdownRows | ForEach-Object { '{0}|{1}|{2}' -f $_.Category, $_.Source, $_.URL }) `
        -DifferenceObject @($csvRows | ForEach-Object { '{0}|{1}|{2}' -f $_.Category, $_.Source, $_.URL })
)

$duplicateUrls = @($csvRows | Group-Object URL | Where-Object Count -gt 1)
$duplicateSources = @($csvRows | Group-Object Source | Where-Object Count -gt 1)
$invalidUrls = @($csvRows | Where-Object {
    $uri = $null
    -not [System.Uri]::TryCreate($_.URL, [System.UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -notin @('http', 'https')
})

$urlResults = @()

if (-not $SkipUrlChecks) {
    Add-Type -AssemblyName System.Net.Http
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $true
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('Mozilla/5.0 Copilot Validation')

    foreach ($row in $csvRows) {
        $test = Test-SourceUrl -Client $client -Url $row.URL
        $urlResults += [pscustomobject]@{
            Category = $row.Category
            Source = $row.Source
            URL = $row.URL
            HttpStatus = $test.HttpStatus
            FinalUrl = $test.FinalUrl
            Error = $test.Error
        }
    }
}

$failedUrls = @($urlResults | Where-Object { ($_.HttpStatus -eq $null) -or ($_.HttpStatus -lt 200) -or ($_.HttpStatus -ge 400) })
$redirects = @($urlResults | Where-Object { $_.FinalUrl -and $_.FinalUrl -ne $_.URL })

Write-Host '=== SUMMARY ==='
Write-Host "MarkdownRows=$($markdownRows.Count)"
Write-Host "CsvRows=$($csvRows.Count)"
Write-Host "ParityDifferences=$($parityDifferences.Count)"
Write-Host "InvalidUrls=$($invalidUrls.Count)"
Write-Host "DuplicateUrls=$($duplicateUrls.Count)"
Write-Host "DuplicateSources=$($duplicateSources.Count)"
if (-not $SkipUrlChecks) {
    Write-Host "FailedHttp=$($failedUrls.Count)"
    Write-Host "Redirects=$($redirects.Count)"
}

Write-Host ''
Write-Host '=== DUPLICATE URLS ==='
if ($duplicateUrls) {
    foreach ($duplicate in $duplicateUrls) {
        Write-Host ("Count={0} URL={1}" -f $duplicate.Count, $duplicate.Name)
        foreach ($item in $duplicate.Group) {
            Write-Host ("  [{0}] {1}" -f $item.Category, $item.Source)
        }
    }
}
else {
    Write-Host 'None'
}

Write-Host ''
Write-Host '=== DUPLICATE SOURCES ==='
if ($duplicateSources) {
    foreach ($duplicate in $duplicateSources) {
        Write-Host ("Count={0} Source={1}" -f $duplicate.Count, $duplicate.Name)
    }
}
else {
    Write-Host 'None'
}

Write-Host ''
Write-Host '=== CSV VS MARKDOWN DIFF ==='
if ($parityDifferences) {
    $parityDifferences | Format-Table -AutoSize
}
else {
    Write-Host 'None'
}

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

if ($parityDifferences -or $invalidUrls -or $duplicateUrls -or $duplicateSources -or $failedUrls) {
    exit 1
}

exit 0
