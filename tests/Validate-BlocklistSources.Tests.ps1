BeforeAll {
    $script:repositoryRoot = Split-Path $PSScriptRoot -Parent
    $path = Join-Path $script:repositoryRoot 'Validate-BlocklistSources.ps1'
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
    $function = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Test-SourceUrl' }, $true)
    $source = Get-Content -LiteralPath $path -Raw
    # Replace only transport with a deterministic fake; execute the actual validator.
    $fake = @'
function Test-SourceUrl {
    param($Client, $Url)
    $script:checkedUrls.Add($Url)
    $status = if ($Url -eq $script:failingUrl) { 410 } else { 200 }
    @{ HttpStatus = $status; FinalUrl = $Url; Error = $null }
}
'@
    $source = $source.Substring(0, $function.Extent.StartOffset) + $fake + $source.Substring($function.Extent.EndOffset)
    $source = $source.Replace('exit 1', "throw 'Validation failed'").Replace('exit 0', 'return')
    $script:validator = [scriptblock]::Create($source)
}

Describe 'Source URL validation policy' {
    BeforeEach {
        $script:checkedUrls = [System.Collections.Generic.List[string]]::new()
        $script:failingUrl = ''
        Push-Location $script:repositoryRoot
    }
    AfterEach { Pop-Location }

    It 'checks every enabled URL and skips disabled retired feeds' {
        $script:failingUrl = 'https://urlhaus.abuse.ch/downloads/hostfile/'
        & $script:validator
        $enabled = @(Import-Csv ./pihole-blocklist-sources.csv | Where-Object Enabled -eq 'true')
        @($script:checkedUrls | Sort-Object) | Should -Be @($enabled.URL | Sort-Object)
        $script:checkedUrls | Should -Not -Contain 'https://urlhaus.abuse.ch/downloads/hostfile/'
        $script:checkedUrls | Should -Not -Contain 'https://threatfox.abuse.ch/downloads/hostfile/'
    }

    It 'fails when an enabled source returns HTTP 410' {
        $script:failingUrl = (Import-Csv ./pihole-blocklist-sources.csv | Where-Object Enabled -eq 'true' | Select-Object -First 1).URL
        { & $script:validator } | Should -Throw '*Validation failed*'
    }

    It 'retains metadata validation for disabled sources' {
        $rows = Import-Csv ./pihole-blocklist-sources.csv
        ($rows | Where-Object Source -eq 'URLhaus').DisabledReason = ''
        $csv = Join-Path $TestDrive 'invalid.csv'
        $rows | Export-Csv -LiteralPath $csv -NoTypeInformation
        { & $script:validator -CsvPath $csv -SkipUrlChecks } | Should -Throw '*Validation failed*'
        $script:checkedUrls.Count | Should -Be 0
    }
}
