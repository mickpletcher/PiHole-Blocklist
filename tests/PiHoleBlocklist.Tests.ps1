BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\PiHoleBlocklist.psm1') -Force
}

Describe 'ConvertTo-ListText' {
    It 'decodes UTF-8 byte responses without a content type' {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes("example.com`ntracker.example")
        ConvertTo-ListText -Content $bytes | Should -Be "example.com`ntracker.example"
    }

    It 'removes a leading byte-order mark' {
        ConvertTo-ListText -Content "$([char]0xFEFF)example.com" | Should -Be 'example.com'
    }
}

Describe 'Test-DomainName' {
    It 'accepts supported DNS names' -ForEach @(
        'example.com',
        'sub.example.co.uk',
        'example.xn--p1ai'
    ) {
        Test-DomainName -Domain $_ | Should -BeTrue
    }

    It 'rejects invalid DNS names' -ForEach @(
        'actor',
        '_dmarc.example.com',
        '-bad.example.com',
        'bad-.example.com',
        'https://example.com',
        '0.0.0.0',
        '127.0.0.1',
        'localhost.localdomain'
    ) {
        Test-DomainName -Domain $_ | Should -BeFalse
    }
}

Describe 'Get-DomainsFromContent' {
    It 'parses supported formats and deduplicates domains' {
        $content = @'
0.0.0.0 hosts.example
||adblock.example^
plain.example
PLAIN.example
@@||allowed.example^
||actor^
_invalid.example
'@
        $result = Get-DomainsFromContent -Content $content
        @($result | Sort-Object) | Should -Be @('adblock.example', 'hosts.example', 'plain.example')
    }

    It 'honors explicit source formats' {
        $content = "0.0.0.0 hosts.example`nplain.example"
        $result = Get-DomainsFromContent -Content $content -Format Hosts
        @($result) | Should -Be @('hosts.example')
    }
}

Describe 'Invoke-PiHoleListBuild' {
    BeforeEach {
        $script:sourceCsv = Join-Path $TestDrive 'sources.csv'
        $script:allowlist = Join-Path $TestDrive 'allowlist.txt'
        $script:output = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $script:allowlist -Value 'b.example' -Encoding utf8NoBOM
        @'
Category,Source,URL,Enabled,Profiles,Format,Risk,ExpectedDomains,MaxChangePercent,DisabledReason
Test,Fixture,https://example.invalid/list.txt,true,Balanced,Adblock,Moderate,2,10,
'@ | Set-Content -LiteralPath $script:sourceCsv -Encoding utf8NoBOM
    }

    It 'writes sorted atomic outputs and applies the project allowlist' {
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{
                Content = "||b.example^`n||a.example^"
                Headers = @{ 'Content-Type' = 'text/plain; charset=utf-8' }
            }
        }

        $result = Invoke-PiHoleListBuild `
            -SourceCsv $script:sourceCsv `
            -ProjectAllowlistPath $script:allowlist `
            -OutputDirectory $script:output

        $result.blocklistDomains | Should -Be 1
        $result.allowlistCollisionsRemoved | Should -Be 1
        Get-Content -LiteralPath (Join-Path $script:output 'curated-blocklist.txt') | Should -Be @('a.example')
        Test-Path -LiteralPath (Join-Path $script:output 'Sources') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $script:output 'build-metadata-balanced.json') | Should -BeTrue
    }

    It 'fails closed when parsed counts leave the configured baseline' {
        New-Item -Path $script:output -ItemType Directory | Out-Null
        Set-Content -LiteralPath (Join-Path $script:output 'curated-blocklist.txt') -Value 'existing.example'
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{
                Content = '||only.example^'
                Headers = @{ 'Content-Type' = 'text/plain' }
            }
        }

        {
            Invoke-PiHoleListBuild `
                -SourceCsv $script:sourceCsv `
                -ProjectAllowlistPath $script:allowlist `
                -OutputDirectory $script:output
        } | Should -Throw '*Parsed count outside baseline*'

        Get-Content -LiteralPath (Join-Path $script:output 'curated-blocklist.txt') | Should -Be 'existing.example'
    }

    It 'retries downloads and fails without publishing output' {
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest { throw 'network failure' }
        Mock -ModuleName PiHoleBlocklist Start-Sleep

        {
            Invoke-PiHoleListBuild `
                -SourceCsv $script:sourceCsv `
                -ProjectAllowlistPath $script:allowlist `
                -OutputDirectory $script:output
        } | Should -Throw '*Download failed after 3 attempts*'

        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 3 -Exactly
        Test-Path -LiteralPath $script:output | Should -BeFalse
    }

    It 'requires the DisabledReason source column' {
        @'
Category,Source,URL,Enabled,Profiles,Format,Risk,ExpectedDomains,MaxChangePercent
Test,Fixture,https://example.invalid/list.txt,true,Balanced,Adblock,Moderate,2,10
'@ | Set-Content -LiteralPath $script:sourceCsv -Encoding utf8NoBOM

        {
            Invoke-PiHoleListBuild `
                -SourceCsv $script:sourceCsv `
                -ProjectAllowlistPath $script:allowlist `
                -OutputDirectory $script:output
        } | Should -Throw '*Source CSV is missing required column: DisabledReason*'
    }
}
