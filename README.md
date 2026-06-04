# Pi-hole Blocklist Builder

Curated Pi-hole blocklist and whitelist builder with source validation and automated list generation.

This project downloads trusted source lists, normalizes them into plain domains, writes per-source files, and generates two curated outputs:

- `Lists/curated-blocklist.txt`
- `Lists/curated-whitelist.txt`

## Hosted Curated Lists For Pi-hole

Use these raw GitHub URLs in Pi-hole:

```text
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-blocklist.txt
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-whitelist.txt
```

Pi-hole setup:

1. Add the blocklist URL in the adlist or subscribed denylist section.
2. Add the whitelist URL in the subscribed allowlist section (Pi-hole v6+).
3. Run gravity update.

```bash
pihole -g
```

Do not use the normal GitHub page URL. Use the `raw.githubusercontent.com` URL only.

## What This Project Does

- Tracks blocklist and whitelist sources in one CSV file.
- Validates CSV and markdown parity.
- Detects duplicate source names and duplicate URLs.
- Checks source URL health.
- Downloads each source list.
- Normalizes mixed list formats into plain domains.
- Writes one cleaned output file per source.
- Merges blocklist sources and whitelist sources into separate curated files.
- Deduplicates final outputs.
- Removes whitelist domains from the final blocklist when overlap exists.

## Main Files

| File | Purpose |
|---|---|
| `pihole-blocklist-sources.csv` | Source inventory used by scripts |
| `pihole-list-sources.md` | Human-readable source index |
| `LISTS.md` | User-facing review page for all blocklist and whitelist sources |
| `Validate-BlocklistSources.ps1` | Source validation |
| `Merge-PiholeBlocklists.ps1` | Source download and list build |
| `Update-ListSourceMarkdown.ps1` | Regenerates markdown source review files from the CSV |
| `validation-report.txt` | Latest validator output |
| `Lists/Sources/blocklist/*.txt` | Per-source normalized blocklist files |
| `Lists/Sources/whitelist/*.txt` | Per-source normalized whitelist files |
| `Lists/curated-blocklist.txt` | Final curated blocklist |
| `Lists/curated-whitelist.txt` | Final curated whitelist |

## Requirements

- PowerShell 7 or Windows PowerShell
- Internet access
- Pi-hole
- Git (optional, only needed for repo sync)

No extra PowerShell modules are required.

## Quick Start

Validate sources:

```powershell
.\Validate-BlocklistSources.ps1
```

Build curated outputs:

```powershell
.\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv
```

Fast validation only:

```powershell
.\Validate-BlocklistSources.ps1 -SkipUrlChecks
```

Refresh saved report:

```powershell
.\Validate-BlocklistSources.ps1 *> .\validation-report.txt
```

## Build Behavior

The merge script:

1. Reads `pihole-blocklist-sources.csv`.
2. Downloads each source URL.
3. Parses hosts, AdBlock, and plain domain formats.
4. Writes one normalized file per source under `Lists/Sources`.
5. Builds `Lists/curated-blocklist.txt`.
6. Builds `Lists/curated-whitelist.txt`.
7. Removes duplicates.
8. Applies whitelist override when the same domain appears in both outputs.

## Automatic GitHub Updates

Workflow file:

```text
.github/workflows/update-lists.yml
```

The workflow runs daily and can run manually. It validates sources, rebuilds `Lists`, refreshes `validation-report.txt`, and commits generated changes.

For automated commits to work, enable write permissions for workflows:

```text
Settings > Actions > General > Workflow permissions > Read and write permissions
```

## Add Or Remove Sources

Update `pihole-blocklist-sources.csv`, then run validation and merge:

```powershell
.\Update-ListSourceMarkdown.ps1
.\Validate-BlocklistSources.ps1
.\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv
```

The markdown source review files are generated from the CSV:

- [LISTS.md](LISTS.md)
- [pihole-list-sources.md](pihole-list-sources.md)

Users who want to review every source before using the curated outputs can read [LISTS.md](LISTS.md).

## Troubleshooting

If validation reports `ParityDifferences`, CSV and markdown sources are out of sync.

If validation reports `FailedHttp`, one or more URLs are dead or unreachable.

If the curated blocklist is very large, that is expected for combined security, ad, and tracking sources.

## Project History

See [changelog.md](changelog.md) and [completed-upgrades.md](completed-upgrades.md).
