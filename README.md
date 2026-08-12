# Pi-hole Blocklist Builder

[![Validate](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/validate.yml/badge.svg)](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/validate.yml)
[![Update Pi-hole lists](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/update-lists.yml/badge.svg)](https://github.com/mickpletcher/PiHole-Blocklist/actions/workflows/update-lists.yml)

PowerShell 7 tooling for validated, profile-based Pi-hole blocklists.

The Balanced list includes every supported moderate-risk source. Device and high-risk policy restrictions remain separate opt-in subscriptions.

## Hosted Lists

Use the raw URLs from the history-limited `generated` branch.

| Profile | Raw URL | Scope |
|---|---|---|
| Balanced | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist.txt` | Default security, privacy, advertising, and tracking protection |
| Strict | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-strict.txt` | Balanced plus OISD Big |
| Device | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-device.txt` | Device and service-specific restrictions |
| Policy | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-blocklist-policy.txt` | Piracy, shortener, bypass, fake-news, and SafeSearch policy restrictions |
| Project allowlist | `https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/generated/Lists/curated-whitelist.txt` | Reviewed project-owned exceptions only |

The generated snapshot is also tracked on `main` to restore these legacy subscription URLs:

```text
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/refs/heads/main/Lists/curated-blocklist.txt
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/refs/heads/main/Lists/curated-whitelist.txt
```

The daily workflow refreshes the `generated` branch. The `main` copies remain compatibility snapshots until publication to `main` is automated or subscribers migrate to the canonical URLs above.

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

Balanced is the hosted default. It combines 23 moderate-risk spam, advertising, tracking, malicious-domain, and aggregate sources.

### Strict

Strict includes the Balanced sources plus OISD Big. It is broader and more likely to require local exceptions.

### Device

Device contains opt-in Apple, Microsoft, TikTok, Smart TV, and similar service restrictions. It is not a general advertising list.

### Policy

Policy contains nine opt-in high-risk sources for piracy, URL shorteners, encrypted DNS or VPN bypass, fake news, unsupported SafeSearch, DynDNS, badware hosting, fake DNS, and pop-up ads.

## Source Inventory

Review the complete source inventory before subscribing or changing profiles.

| Inventory status | Count |
|---|---:|
| Total sources | 45 |
| Enabled sources | 44 |
| Disabled sources | 1 |

- [View the complete human-readable source catalog](LISTS.md), including enabled status, assigned profiles, risk, format, and upstream URL.
- [Open the CSV source of truth](pihole-blocklist-sources.csv) used by validation and list generation.
- [View the generated technical source catalog](pihole-list-sources.md).

The CSV `Enabled` and `Profiles` fields control publication. `DisabledReason` is required when a row is disabled and must be blank when it is enabled. HaGeZi Spam TLDs is the only disabled source because TLD-wide rules cannot be represented in the plain-domain outputs.

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
- Requires every disabled source to record `DisabledReason` and rejects reasons on enabled sources.
- Writes final files atomically only after every selected source succeeds.
- Applies only the repository-owned `project-allowlist.txt`.
- Writes a JSON build report with counts, exclusive contribution, elapsed time, and output SHA-256.

Dotless TLD rules such as `||actor^` cannot be represented in a Pi-hole plain-domain list. The HaGeZi Spam TLD source remains documented but disabled.

## Main Files

| File | Purpose |
|---|---|
| `pihole-blocklist-sources.csv` | Source of truth for metadata, profiles, baselines, enablement, and disabled reasons |
| `pihole-list-sources.md` | Generated complete source catalog |
| `LISTS.md` | User-facing profile and source review page |
| `project-allowlist.txt` | Empty-by-default reviewed project allowlist |
| `PiHoleBlocklist.psm1` | Parser and fail-closed build implementation |
| `Merge-PiholeBlocklists.ps1` | Profile build command |
| `Validate-BlocklistSources.ps1` | Inventory, metadata, parity, duplicate, and live URL validation |
| `Update-ListSourceMarkdown.ps1` | Regenerates both source review files |
| `Test-Markdown.ps1` | Repository Markdown checks |
| `tests/PiHoleBlocklist.Tests.ps1` | Pester parser and fail-closed build tests |
| `Lists/*.txt` | Generated profile and allowlist compatibility snapshots tracked on `main` |
| `Lists/build-metadata-*.json` | Build metadata for the compatibility snapshots |
| `validation-report.txt` | Live source validation captured with the compatibility snapshots |
| `.github/workflows/validate.yml` | Pull request and main validation |
| `.github/workflows/update-lists.yml` | Daily history-limited list publication |

## Adding or Changing Sources

1. Edit `pihole-blocklist-sources.csv`.
2. Set `Enabled`, `Profiles`, `Format`, `Risk`, `ExpectedDomains`, `MaxChangePercent`, and `DisabledReason` deliberately.
3. Run the source documentation generator.
4. Run local metadata validation.
5. Run live URL validation.
6. Build every affected profile.
7. Update `assessment.md`, `README.md`, and `changelog.md`.

Do not enable a source with `Format=AdblockTld`. Create a separate Pi-hole regex design first.

## Automation

The `Validate` workflow runs on pull requests and pushes to `main`. It checks generated documentation, inventory metadata, Pester tests, PowerShell analysis, Markdown formatting, and live source URLs.

The daily update workflow builds every profile in a temporary directory. A successful run replaces the orphan `generated` branch using a lease-protected force push. A generated snapshot is also tracked on `main` for legacy URL compatibility, but the workflow does not refresh that snapshot.

The update workflow never publishes partial output. Failed downloads, unexpected parsed counts, invalid content, or safety-limit violations stop publication and leave the previous generated branch intact.

## Known Limitations

- Plain-domain outputs cannot express TLD-wide or regex rules.
- Source baselines require manual review when a legitimate upstream change exceeds the configured threshold.
- Broad upstream aggregates can still produce false positives. Use local Pi-hole allowlisting for site-specific exceptions.
- Legacy `main` URLs point to a compatibility snapshot and can become stale after the next successful `generated` branch publication.
- Old generated commits remain in the existing Git history. The new publication model stops future daily feed growth but does not rewrite past history.

## Repository Maintenance

Every source-code or configuration change must review and update:

- `assessment.md`
- `README.md`
- `changelog.md`

Generated deployments on the `generated` branch are publication artifacts. Changes to their behavior or structure still require the documentation updates above on `main`.

See [assessment.md](assessment.md), [changelog.md](changelog.md), and [completed-upgrades.md](completed-upgrades.md).
