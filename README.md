# Pi-hole Blocklist Builder

[![Validate](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/validate.yml/badge.svg)](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/validate.yml)
[![Update Pi-hole lists](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/update-lists.yml/badge.svg)](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/update-lists.yml)

PowerShell 7 tooling for validated, profile-based Pi-hole blocklists.

The default list is intentionally small in scope. Device and policy restrictions are separate opt-in subscriptions.

## Hosted Lists

Use the raw URLs from the history-limited `generated` branch.

| Profile | Raw URL | Scope |
|---|---|---|
| Balanced | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist.txt` | Default security, privacy, advertising, and tracking protection |
| Strict | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-strict.txt` | Balanced plus OISD Big |
| Device | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-device.txt` | Device and service-specific restrictions |
| Policy | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-policy.txt` | Piracy, shortener, bypass, fake-news, and SafeSearch policy restrictions |
| Project allowlist | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-whitelist.txt` | Reviewed project-owned exceptions only |

Start with Balanced. Add Device or Policy only when those restrictions are wanted.

Pi-hole setup:

1. Add the selected blocklist URL as a subscribed denylist.
2. Add the project allowlist URL as a subscribed allowlist if needed.
3. Run a gravity update.

```bash
pihole -g
```

## Profiles

### Balanced

Balanced is the hosted default. It uses:

- HaGeZi Threat Intelligence Feeds
- HaGeZi Pro

### Strict

Strict includes the Balanced sources plus OISD Big. It is broader and more likely to require local exceptions.

### Device

Device contains opt-in Apple, Microsoft, TikTok, Smart TV, and similar service restrictions. It is not a general advertising list.

### Policy

Policy contains opt-in anti-piracy, URL-shortener, encrypted DNS or VPN bypass, fake-news, and unsupported SafeSearch restrictions.

Source assignments, risk labels, formats, expected parsed counts, and change thresholds are stored in `pihole-blocklist-sources.csv`. Disabled overlapping sources remain in the catalog for review but are not published.

## Requirements

- PowerShell 7.4 or later
- Internet access for URL validation and list builds
- Git only when publishing repository changes

Windows PowerShell 5.1 is not supported.

## Local Validation

Regenerate the source documentation and validate metadata:

```powershell
.\Update-ListSourceMarkdown.ps1
.\Validate-BlocklistSources.ps1 -SkipUrlChecks
```

Run live URL checks:

```powershell
.\Validate-BlocklistSources.ps1 -TimeoutSeconds 20
```

Build a profile outside the repository:

```powershell
$output = Join-Path $env:TEMP 'PiHole-Blocklist-build'
.\Merge-PiholeBlocklists.ps1 `
    -SourceCsv .\pihole-blocklist-sources.csv `
    -ProjectAllowlistPath .\project-allowlist.txt `
    -BuildProfile Balanced `
    -OutputDirectory $output
```

Supported profile names are `Balanced`, `Strict`, `Device`, and `Policy`.

## Build Safety

The builder:

- Retries transient downloads three times.
- Decodes byte responses using the declared charset or UTF-8 fallback.
- Accepts hosts, AdBlock, and plain-domain input formats.
- Rejects invalid DNS hostnames, including underscore labels.
- Deduplicates with ordinal, case-insensitive matching.
- Fails when a selected source parses zero domains.
- Fails when a parsed count leaves its reviewed baseline range.
- Fails when a response or final profile exceeds configured safety limits.
- Writes final files atomically only after every selected source succeeds.
- Applies only the repository-owned `project-allowlist.txt`.
- Writes a JSON build report with counts, exclusive contribution, elapsed time, and output SHA-256.

Dotless TLD rules such as `||actor^` cannot be represented in a Pi-hole plain-domain list. The HaGeZi Spam TLD source remains documented but disabled.

## Main Files

| File | Purpose |
|---|---|
| `pihole-blocklist-sources.csv` | Source of truth for metadata, profiles, baselines, and enablement |
| `pihole-list-sources.md` | Generated complete source catalog |
| `LISTS.md` | User-facing profile and source review page |
| `project-allowlist.txt` | Empty-by-default reviewed project allowlist |
| `PiHoleBlocklist.psm1` | Parser and fail-closed build implementation |
| `Merge-PiholeBlocklists.ps1` | Profile build command |
| `Validate-BlocklistSources.ps1` | Inventory, metadata, parity, duplicate, and live URL validation |
| `Update-ListSourceMarkdown.ps1` | Regenerates both source review files |
| `Test-Markdown.ps1` | Repository Markdown checks |
| `tests/PiHoleBlocklist.Tests.ps1` | Pester parser and fail-closed build tests |
| `.github/workflows/validate.yml` | Pull request and main validation |
| `.github/workflows/update-lists.yml` | Daily history-limited list publication |

## Adding or Changing Sources

1. Edit `pihole-blocklist-sources.csv`.
2. Set `Enabled`, `Profiles`, `Format`, `Risk`, `ExpectedDomains`, and `MaxChangePercent` deliberately.
3. Run the source documentation generator.
4. Run local metadata validation.
5. Run live URL validation.
6. Build every affected profile.
7. Update `assessment.md`, `README.md`, and `changelog.md`.

Do not enable a source with `Format=AdblockTld`. Create a separate Pi-hole regex design first.

## Automation

The `Validate` workflow runs on pull requests and pushes to `main`. It checks generated documentation, inventory metadata, Pester tests, PowerShell analysis, Markdown formatting, and live source URLs.

The daily update workflow builds every profile in a temporary directory. A successful run replaces the orphan `generated` branch using a lease-protected force push. Generated feed history is not retained on `main`.

The update workflow never publishes partial output. Failed downloads, unexpected parsed counts, invalid content, or safety-limit violations stop publication and leave the previous generated branch intact.

## Known Limitations

- Plain-domain outputs cannot express TLD-wide or regex rules.
- Source baselines require manual review when a legitimate upstream change exceeds the configured threshold.
- Broad upstream aggregates can still produce false positives. Use local Pi-hole allowlisting for site-specific exceptions.
- Old generated commits remain in the existing Git history. The new publication model stops future daily feed growth but does not rewrite past history.

## Repository Maintenance

Every source-code or configuration change must review and update:

- `assessment.md`
- `README.md`
- `changelog.md`

Generated deployments on the `generated` branch are publication artifacts. Changes to their behavior or structure still require the documentation updates above on `main`.

See [assessment.md](assessment.md), [changelog.md](changelog.md), and [completed-upgrades.md](completed-upgrades.md).
