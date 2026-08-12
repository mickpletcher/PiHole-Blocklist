[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$files = @(git ls-files --cached --others --exclude-standard '*.md')
$problems = [System.Collections.Generic.List[string]]::new()

foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        continue
    }
    $lines = @(Get-Content -LiteralPath $file)
    $blankRun = 0
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $lineNumber = $index + 1
        $line = $lines[$index]
        if ($line -match '[ \t]+$') {
            $problems.Add("${file}:${lineNumber}: trailing whitespace")
        }
        if ($line -match '\t') {
            $problems.Add("${file}:${lineNumber}: tab character")
        }
        if ([string]::IsNullOrWhiteSpace($line)) {
            $blankRun++
            if ($blankRun -gt 2) {
                $problems.Add("${file}:${lineNumber}: more than two consecutive blank lines")
            }
        }
        else {
            $blankRun = 0
        }
        if ($line -match '^#{1,6}\s' -and $index -gt 0 -and -not [string]::IsNullOrWhiteSpace($lines[$index - 1])) {
            $problems.Add("${file}:${lineNumber}: heading must have a blank line before it")
        }
    }
}

if ($problems.Count -gt 0) {
    $problems | ForEach-Object { Write-Host $_ }
    exit 1
}

Write-Host "MarkdownFiles=$($files.Count)"
Write-Host 'MarkdownProblems=0'
