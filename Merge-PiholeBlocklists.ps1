[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'PiHoleBlocklist.psm1') -Force

try {
    $result = Invoke-PiHoleListBuild @PSBoundParameters
    Write-Host "Profile=$($result.profile)"
    Write-Host "Sources=$($result.sourceCount)"
    Write-Host "BlocklistDomains=$($result.blocklistDomains)"
    Write-Host "AllowlistDomains=$($result.allowlistDomains)"
    Write-Host "AllowlistCollisionsRemoved=$($result.allowlistCollisionsRemoved)"
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
