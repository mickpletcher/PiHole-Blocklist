Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:DomainPattern = [regex]::new(
    '^(?=.{1,253}$)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$',
    [System.Text.RegularExpressions.RegexOptions]::Compiled -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
$script:ReservedDomains = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@('localhost', 'localhost.localdomain', 'broadcasthost', 'ip6-localhost', 'ip6-loopback'),
    [System.StringComparer]::OrdinalIgnoreCase
)

function ConvertTo-ListText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [object]$Content,

        [AllowEmptyString()]
        [string]$ContentType = ''
    )

    if ($Content -is [string]) {
        return $Content.TrimStart([char]0xFEFF)
    }

    if ($Content -isnot [byte[]]) {
        return ([string]$Content).TrimStart([char]0xFEFF)
    }

    $encoding = [System.Text.UTF8Encoding]::new($false, $true)
    if ($ContentType -match '(?i)charset\s*=\s*["'']?([^;"'']+)') {
        try {
            $encoding = [System.Text.Encoding]::GetEncoding($Matches[1].Trim())
        }
        catch {
            $encoding = [System.Text.UTF8Encoding]::new($false, $true)
        }
    }

    try {
        return $encoding.GetString($Content).TrimStart([char]0xFEFF)
    }
    catch [System.Text.DecoderFallbackException] {
        return [System.Text.Encoding]::Latin1.GetString($Content).TrimStart([char]0xFEFF)
    }
}

function Test-DomainName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Domain
    )

    $address = $null
    if ([System.Net.IPAddress]::TryParse($Domain, [ref]$address)) {
        return $false
    }

    return -not $script:ReservedDomains.Contains($Domain) -and $script:DomainPattern.IsMatch($Domain)
}

function Get-DomainsFromContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content,

        [ValidateSet('Auto', 'Hosts', 'Adblock', 'Domains')]
        [string]$Format = 'Auto'
    )

    $domains = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($rawLine in ($Content -split '\r?\n')) {
        $line = $rawLine.Trim()
        if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^[#!\[]') {
            continue
        }

        $domain = $null
        if ($Format -in @('Auto', 'Hosts') -and $line -match '^(?:0\.0\.0\.0|127\.0\.0\.1)\s+(\S+)') {
            $domain = $Matches[1]
        }
        elseif ($Format -in @('Auto', 'Adblock') -and $line -match '^\|\|([^\^/$*]+)\^') {
            $domain = $Matches[1]
        }
        elseif ($Format -in @('Auto', 'Domains') -and $line -notmatch '\s') {
            $domain = $line
        }

        if ([string]::IsNullOrWhiteSpace($domain)) {
            continue
        }

        $domain = $domain.ToLowerInvariant().Trim('.')
        if (Test-DomainName -Domain $domain) {
            [void]$domains.Add($domain)
        }
    }

    return ,$domains
}

function Get-SourceProfileList {
    param([string]$Profiles)

    if ([string]::IsNullOrWhiteSpace($Profiles)) {
        return @()
    }

    return @($Profiles -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Get-SourceInventory {
    param([string]$Path)

    $rows = @(Import-Csv -LiteralPath $Path)
    if ($rows.Count -eq 0) {
        throw "Source CSV has no rows: $Path"
    }

    $requiredColumns = @(
        'Category', 'Source', 'URL', 'Enabled', 'Profiles', 'Format', 'Risk',
        'ExpectedDomains', 'MaxChangePercent', 'DisabledReason'
    )
    foreach ($column in $requiredColumns) {
        if ($column -notin $rows[0].PSObject.Properties.Name) {
            throw "Source CSV is missing required column: $column"
        }
    }

    return $rows
}

function Get-ListResponse {
    param(
        [string]$Url,
        [int]$TimeoutSeconds,
        [int]$MaxAttempts
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return Invoke-WebRequest `
                -Uri $Url `
                -TimeoutSec $TimeoutSeconds `
                -UserAgent 'PiHole-Blocklist/1.0' `
                -UseBasicParsing `
                -ErrorAction Stop
        }
        catch {
            $lastError = $_
            if ($attempt -lt $MaxAttempts) {
                Start-Sleep -Seconds ([Math]::Pow(2, $attempt - 1))
            }
        }
    }

    throw "Download failed after $MaxAttempts attempts: $Url -- $($lastError.Exception.Message)"
}

function Write-AtomicFile {
    param(
        [string]$Path,
        [string[]]$Lines
    )

    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $temporaryPath = "$resolvedPath.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [System.IO.File]::WriteAllLines(
            $temporaryPath,
            $Lines,
            [System.Text.UTF8Encoding]::new($false)
        )
        Move-Item -LiteralPath $temporaryPath -Destination $resolvedPath -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function ConvertTo-SortedArray {
    param([System.Collections.Generic.HashSet[string]]$Domains)

    $result = [string[]]::new($Domains.Count)
    $Domains.CopyTo($result)
    [Array]::Sort($result, [System.StringComparer]::Ordinal)
    return ,$result
}

function Invoke-PiHoleListBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$SourceCsv,

        [string]$OutputDirectory = './Lists',

        [ValidateSet('Balanced', 'Strict', 'Device', 'Policy')]
        [string]$BuildProfile = 'Balanced',

        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$ProjectAllowlistPath = './project-allowlist.txt',

        [ValidateRange(1, 300)]
        [int]$TimeoutSeconds = 60,

        [ValidateRange(1, 10)]
        [int]$MaxAttempts = 3,

        [ValidateRange(1, 10000000)]
        [int]$MaxOutputDomains = 5000000,

        [ValidateRange(1, 1073741824)]
        [int]$MaxResponseBytes = 268435456
    )

    $startTime = Get-Date
    $sources = @(Get-SourceInventory -Path $SourceCsv)
    $selectedSources = @($sources | Where-Object {
        $_.Enabled -eq 'true' -and $BuildProfile -in @(Get-SourceProfileList -Profiles $_.Profiles)
    })
    if ($selectedSources.Count -eq 0) {
        throw "No enabled sources are assigned to profile: $BuildProfile"
    }

    $blockDomains = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $sourceResults = [System.Collections.Generic.List[object]]::new()

    foreach ($source in $selectedSources) {
        Write-Host "[$BuildProfile] Downloading $($source.Source)"
        $response = Get-ListResponse `
            -Url $source.URL `
            -TimeoutSeconds $TimeoutSeconds `
            -MaxAttempts $MaxAttempts

        $content = $response.Content
        $contentLength = if ($content -is [byte[]]) {
            $content.Length
        }
        else {
            [System.Text.Encoding]::UTF8.GetByteCount([string]$content)
        }
        if ($contentLength -gt $MaxResponseBytes) {
            throw "Source response exceeds MaxResponseBytes: $($source.Source) ($contentLength bytes)"
        }

        $contentType = [string]($response.Headers.'Content-Type' | Select-Object -First 1)
        $text = ConvertTo-ListText -Content $content -ContentType $contentType
        $parsed = Get-DomainsFromContent -Content $text -Format $source.Format
        $expected = [int64]$source.ExpectedDomains
        $changePercent = [double]$source.MaxChangePercent
        $lowerBound = if ($expected -gt 0) {
            [Math]::Max(1, [Math]::Ceiling($expected * (1 - ($changePercent / 100))))
        }
        else {
            1
        }
        $upperBound = [Math]::Ceiling($expected * (1 + ($changePercent / 100)))

        if ($parsed.Count -lt $lowerBound -or $parsed.Count -gt $upperBound) {
            throw "Parsed count outside baseline for $($source.Source): actual=$($parsed.Count) expected=$expected allowed=$lowerBound..$upperBound"
        }

        $beforeCount = $blockDomains.Count
        $blockDomains.UnionWith($parsed)
        if ($blockDomains.Count -gt $MaxOutputDomains) {
            throw "Profile $BuildProfile exceeds MaxOutputDomains=$MaxOutputDomains"
        }

        $sourceResults.Add([pscustomobject][ordered]@{
            source = $source.Source
            parsedDomains = $parsed.Count
            exclusiveDomains = $blockDomains.Count - $beforeCount
            expectedDomains = $expected
            maxChangePercent = $changePercent
        })
        Write-Host "[$BuildProfile] $($source.Source): $($parsed.Count) parsed"
    }

    $allowlistContent = Get-Content -LiteralPath $ProjectAllowlistPath -Raw
    $allowlistDomains = Get-DomainsFromContent -Content $allowlistContent -Format Domains
    $collisionCount = 0
    foreach ($domain in $allowlistDomains) {
        if ($blockDomains.Remove($domain)) {
            $collisionCount++
        }
    }

    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    }

    $profileSlug = $BuildProfile.ToLowerInvariant()
    $blocklistFileName = if ($BuildProfile -eq 'Balanced') {
        'curated-blocklist.txt'
    }
    else {
        "curated-blocklist-$profileSlug.txt"
    }
    $blocklistPath = Join-Path $OutputDirectory $blocklistFileName
    $sortedBlocklist = ConvertTo-SortedArray -Domains $blockDomains
    Write-AtomicFile -Path $blocklistPath -Lines $sortedBlocklist

    $whitelistPath = $null
    if ($BuildProfile -eq 'Balanced') {
        $whitelistPath = Join-Path $OutputDirectory 'curated-whitelist.txt'
        $sortedAllowlist = ConvertTo-SortedArray -Domains $allowlistDomains
        Write-AtomicFile -Path $whitelistPath -Lines $sortedAllowlist
    }

    $metadata = [pscustomobject][ordered]@{
        generatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
        profile = $BuildProfile
        sourceCount = $selectedSources.Count
        blocklistDomains = $blockDomains.Count
        allowlistDomains = $allowlistDomains.Count
        allowlistCollisionsRemoved = $collisionCount
        elapsedSeconds = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)
        outputFile = $blocklistFileName
        outputSha256 = (Get-FileHash -LiteralPath $blocklistPath -Algorithm SHA256).Hash
        sources = $sourceResults
    }
    $metadataPath = Join-Path $OutputDirectory "build-metadata-$profileSlug.json"
    $metadataJson = $metadata | ConvertTo-Json -Depth 5
    Write-AtomicFile -Path $metadataPath -Lines @($metadataJson)

    return $metadata
}

Export-ModuleMember -Function ConvertTo-ListText, Get-DomainsFromContent, Invoke-PiHoleListBuild, Test-DomainName
