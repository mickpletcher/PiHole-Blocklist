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
        Mock -ModuleName PiHoleBlocklist Start-Sleep
        $script:sourceCsv = Join-Path $TestDrive 'sources.csv'
        $script:allowlist = Join-Path $TestDrive 'allowlist.txt'
        $script:denylist = Join-Path $TestDrive 'denylist.txt'
        $script:output = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        Set-Content -LiteralPath $script:allowlist -Value 'b.example' -Encoding utf8NoBOM
        Set-Content -LiteralPath $script:denylist -Value "c.example`nb.example" -Encoding utf8NoBOM
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
            -ProjectDenylistPath $script:denylist `
            -OutputDirectory $script:output

        $result.blocklistDomains | Should -Be 1
        $result.allowlistCollisionsRemoved | Should -Be 1
        $result.projectDenylistDomains | Should -Be 1
        $result.projectDenylistCollisionsRemoved | Should -Be 1
        Get-Content -LiteralPath (Join-Path $script:output 'curated-blocklist.txt') | Should -Be @('a.example')
        Get-Content -LiteralPath (Join-Path $script:output 'curated-project-denylist.txt') | Should -Be @('c.example')
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
                -ProjectDenylistPath $script:denylist `
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
                -ProjectDenylistPath $script:denylist `
                -OutputDirectory $script:output
        } | Should -Throw '*Download failed after 3 attempts*'

        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 3 -Exactly
        Test-Path -LiteralPath $script:output | Should -BeFalse
    }

    It 'recovers from an HTTP-200 rate-limit body on the final attempt' {
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            $script:requestCount++
            [pscustomobject]@{
                StatusCode = 200
                Content = if ($script:requestCount -lt 3) { '429: Too Many Requests' } else { "||a.example^`n||b.example^" }
                Headers = @{ 'Content-Type' = 'text/plain' }
            }
        }
        InModuleScope PiHoleBlocklist { $script:requestCount = 0 }
        $result = Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output
        $result.sources[0].parsedDomains | Should -Be 2
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 3 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 1 }
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
    }

    It 'exhausts retries for <Label> without replacing existing artifacts' -ForEach @(
        @{ Label = 'rate limit'; Body = '429: Too Many Requests' }
        @{ Label = 'empty'; Body = '' }
        @{ Label = 'null'; Body = $null }
        @{ Label = 'malformed'; Body = 'this is not a domain list' }
        @{ Label = 'HTML'; Body = "<html>error</html>`n||a.example^`n||b.example^" }
        @{ Label = 'excess count'; Body = "||a.example^`n||b.example^`n||c.example^`n||d.example^" }
    ) {
        $script:body = $Body
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{ StatusCode = 200; Content = $script:body; Headers = @{ 'Content-Type' = 'text/plain' } }
        }
        New-Item -Path $script:output -ItemType Directory | Out-Null
        foreach ($name in 'curated-blocklist.txt', 'curated-whitelist.txt', 'curated-project-denylist.txt', 'build-metadata-balanced.json') {
            Set-Content (Join-Path $script:output $name) 'existing artifact'
        }
        $before = @(Get-ChildItem $script:output | Get-FileHash | Select-Object -ExpandProperty Hash)
        { Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output } | Should -Throw '*Download failed after 3 attempts*'
        @(Get-ChildItem $script:output | Get-FileHash | Select-Object -ExpandProperty Hash) | Should -Be $before
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 3 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 2 -Exactly
    }

    It 'does not retry configuration errors in <Field>' -ForEach @(
        @{ Field = 'Format'; Value = 'Bogus' }
        @{ Field = 'ExpectedDomains'; Value = 'invalid' }
        @{ Field = 'MaxChangePercent'; Value = 'invalid' }
        @{ Field = 'URL'; Value = 'file:///tmp/list.txt' }
    ) {
        $row = Import-Csv $script:sourceCsv
        $row.$Field = $Value
        $row | Export-Csv $script:sourceCsv -NoTypeInformation
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest { throw 'must not request' }
        { Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output } | Should -Throw
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 0 -Exactly
    }

    It 'fails immediately for oversized responses' {
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{ Content = 'too large'; Headers = @{} }
        }
        { Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output -MaxResponseBytes 1 } | Should -Throw '*exceeds MaxResponseBytes*'
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 1 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 0 -Exactly
    }

    It 'keeps diagnostics free of response text and URL secrets' {
        $row = Import-Csv $script:sourceCsv
        $row.URL = 'https://user:secret@example.invalid/private?token=secret#secret'
        $row | Export-Csv $script:sourceCsv -NoTypeInformation
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{ Content = "429: Too Many Requests`nsecret$([char]27)[31m"; Headers = @{} }
        }
        $warnings = @()
        try {
            Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output -MaxAttempts 1 -WarningVariable warnings
        }
        catch { $message = $_.Exception.Message }
        $message | Should -Match 'host=example.invalid.*rate-limit.*actual=0'
        ($message + ($warnings -join ' ')) | Should -Not -Match 'secret|private|token|Too Many Requests|\x1b'
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 0 -Exactly
    }

    It 'rejects malformed URLs without requests, retries, or secret diagnostics' {
        $row = Import-Csv $script:sourceCsv
        $row.URL = 'https://synthetic-user:synthetic-password@example.invalid:badport/synthetic-private?token=synthetic-token#synthetic-fragment'
        $row | Export-Csv $script:sourceCsv -NoTypeInformation
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest { throw 'must not request' }
        $warnings = @()
        $failure = $null
        try {
            Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output -WarningVariable warnings
        }
        catch { $failure = $_ }
        $failure | Should -Not -BeNullOrEmpty
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 0 -Exactly
        Test-Path $script:output | Should -BeFalse
        # Include the complete error record and the wrapper's Write-Error rendering.
        $diagnostics = ($failure | Format-List * -Force | Out-String) +
            (& { Write-Error -ErrorRecord $failure -ErrorAction Continue } 2>&1 | Out-String) +
            ($warnings -join ' ')
        $diagnostics | Should -Not -Match 'synthetic-user|synthetic-password|synthetic-private|synthetic-token|synthetic-fragment|badport'
        $failure.Exception.Message | Should -Be 'Source URL must be an absolute HTTP or HTTPS URL.'
    }

    It 'preserves the archived 35-domain CNAME response on the first attempt' {
        $row = Import-Csv $script:sourceCsv
        $row.Format = 'Domains'
        $row.ExpectedDomains = 35
        $row.MaxChangePercent = 200
        $row | Export-Csv $script:sourceCsv -NoTypeInformation
        $script:cnameBytes = [System.IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'fixtures/cname-cloaking.txt'))
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{ Content = $script:cnameBytes; Headers = @{ 'Content-Type' = 'application/octet-stream' } }
        }
        $result = Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output
        $result.sources[0].parsedDomains | Should -Be 35
        $result.blocklistDomains | Should -Be 35
        @(Get-Content (Join-Path $script:output 'curated-blocklist.txt')) | Should -Be @(Get-Content (Join-Path $PSScriptRoot 'fixtures/cname-cloaking.txt') | Sort-Object)
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 1 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 0 -Exactly
    }

    It 'shares the attempt budget across transport and invalid payload failures' {
        InModuleScope PiHoleBlocklist { $script:requestCount = 0 }
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            $script:requestCount++
            if ($script:requestCount -eq 1) { throw 'temporary transport failure' }
            [pscustomobject]@{ Content = '429: Too Many Requests'; Headers = @{} }
        }
        { Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output } | Should -Throw '*after 3 attempts*'
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 3 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 2 -Exactly
        Test-Path $script:output | Should -BeFalse
    }

    It 'caps exponential backoff at 30 seconds' {
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{ Content = ''; Headers = @{} }
        }
        { Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output -MaxAttempts 10 } | Should -Throw '*after 10 attempts*'
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 10 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 9 -Exactly
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 4 -Exactly -ParameterFilter { $Seconds -eq 30 }
        Should -Invoke -ModuleName PiHoleBlocklist Start-Sleep -Times 0 -Exactly -ParameterFilter { $Seconds -gt 30 }
    }

    It 'does not confuse numeric domain labels with HTTP error bodies' {
        $row = Import-Csv $script:sourceCsv
        $row.Format = 'Domains'
        $row | Export-Csv $script:sourceCsv -NoTypeInformation
        Mock -ModuleName PiHoleBlocklist Invoke-WebRequest {
            [pscustomobject]@{ Content = "429.example`n500.example"; Headers = @{} }
        }
        $result = Invoke-PiHoleListBuild -SourceCsv $script:sourceCsv -ProjectAllowlistPath $script:allowlist -ProjectDenylistPath $script:denylist -OutputDirectory $script:output
        $result.blocklistDomains | Should -Be 2
        Should -Invoke -ModuleName PiHoleBlocklist Invoke-WebRequest -Times 1 -Exactly
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
                -ProjectDenylistPath $script:denylist `
                -OutputDirectory $script:output
        } | Should -Throw '*Source CSV is missing required column: DisabledReason*'
    }
}
