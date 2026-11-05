# Contributing

Thank you for helping make these lists safer and easier to use. Please follow our [code of conduct](CODE_OF_CONDUCT.md).

## Choose the right report

- Use the [issue templates](https://github.com/mickpletcher/PiHole-Blocklist/issues/new/choose) for bugs, false positives, source proposals, and accessibility barriers.
- For setup questions, see [support](SUPPORT.md).
- Report vulnerabilities privately using [SECURITY.md](SECURITY.md). Do not post secrets, private browsing history, client addresses, or unredacted logs.

## Propose a change

1. Fork the repository and create a focused branch from `main`.
2. Explain the problem, affected profile and expected behavior. For a domain change, provide public evidence and the smallest reproducible example.
3. Keep Balanced, Strict, Device and Policy scopes separate. Do not promote untested domains or edit generated subscription files by hand.
4. Update `README.md`, `assessment.md` and `changelog.md` as required by [AGENTS.md](AGENTS.md).
5. Run the checks below, then open a pull request with results and any checks you could not run.

PowerShell 7 is required. Install Pester 5.7.1 and PSScriptAnalyzer 1.24.0 from PowerShell Gallery for local validation. Review third-party dependencies before installing them.

```powershell
./Update-ListSourceMarkdown.ps1
git diff --exit-code -- LISTS.md pihole-list-sources.md
./Validate-BlocklistSources.ps1 -SkipUrlChecks
Invoke-Pester -Path ./tests -Output Detailed
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning -ExcludeRule PSAvoidUsingWriteHost
./Test-Markdown.ps1
```

For source inventory or generation changes, also run the live validation and all four profile builds documented in [AGENTS.md](AGENTS.md). Builds require network access and can fail when an upstream is unavailable. Report those failures honestly; do not weaken validation or replace a good publication with an incomplete list.

## Review and publication

Changes merge through squash pull requests after required checks pass and review conversations are resolved. Keep the `generated` branch: it is a separate deployment branch whose URLs are used by subscribers. Delete only finished feature branches after confirming their work is retained.

The project is maintained on a best-effort basis. A proposed source is not automatically endorsed or accepted. Preserve upstream attribution and licensing information; the repository's MIT license does not relicense upstream data.

## Accessible contributions

Follow [ACCESSIBILITY.md](ACCESSIBILITY.md): use descriptive links, meaningful image alternatives, logical headings, text equivalents for visual information, and copyable commands. Report barriers without having to disclose a disability or assistive technology.
