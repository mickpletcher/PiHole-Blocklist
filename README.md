# Pi-hole Blocklist Builder

Curated Pi-hole blocklist and whitelist builder with source validation and automated list generation.

This project takes a list of trusted Pi-hole source URLs, downloads them, cleans them into plain domain lists, saves each source as its own text file, then creates two final files:

- `Lists\curated-blocklist.txt`
- `Lists\curated-whitelist.txt`

Use the blocklist file to block ads, tracking, malware, spam, and other unwanted domains. Use the whitelist file to allow known good domains that should not be blocked.

## What This Project Does

This repo helps you maintain Pi-hole lists without manually copying domains from many websites.

It can:

- Track blocklist and whitelist source URLs in one CSV file.
- Validate that the CSV and markdown source index match.
- Check for duplicate source names and duplicate URLs.
- Check whether source URLs are valid and reachable.
- Download every source list.
- Normalize each source into a plain `.txt` domain list.
- Save one cleaned file per source.
- Merge all blocklist source files into one curated blocklist.
- Merge all whitelist source files into one curated whitelist.
- Remove duplicate domains from the final output.
- Remove whitelist domains from the final blocklist when the same domain appears in both.

## Output Files

After running the builder, the main files are:

| File | Use |
|---|---|
| `Lists\curated-blocklist.txt` | Import this into Pi-hole as the blocklist |
| `Lists\curated-whitelist.txt` | Import this into Pi-hole as the whitelist or allowlist |
| `Lists\Sources\blocklist\*.txt` | Cleaned per-source blocklist files |
| `Lists\Sources\whitelist\*.txt` | Cleaned per-source whitelist files |

The files in `Lists\Sources` are useful for troubleshooting. They show what each individual source contributed before the final merge.

## Main Project Files

| File | Purpose |
|---|---|
| `pihole-blocklist-sources.csv` | Main source inventory used by the scripts |
| `pihole-list-sources.md` | Human-readable source inventory |
| `Validate-BlocklistSources.ps1` | Validates source inventory health |
| `Merge-PiholeBlocklists.ps1` | Downloads sources and builds the final lists |
| `validation-report.txt` | Latest saved validation report |
| `changelog.md` | Change history |
| `completed-upgrades.md` | Completed project improvements |
| `future-upgrades.md` | Local future work notes |

## Requirements

You need:

- Windows PowerShell or PowerShell 7
- Internet access
- Git, if you want to push the generated lists to GitHub
- Pi-hole, if you want to use the generated lists

No extra PowerShell modules are required.

## Quick Start

Open PowerShell in the repo folder:

```powershell
cd "C:\Users\mick0\OneDrive\Documents\Code & Dev\GitHub\PiHole-Blocklist"
```

Validate the source list:

```powershell
.\Validate-BlocklistSources.ps1
```

Build the curated blocklist and whitelist:

```powershell
.\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv
```

The final files will be written here:

```text
Lists\curated-blocklist.txt
Lists\curated-whitelist.txt
```

## Fast Validation

Use this when you only want to check local CSV and markdown parity without testing every URL:

```powershell
.\Validate-BlocklistSources.ps1 -SkipUrlChecks
```

Use the full validation before publishing changes:

```powershell
.\Validate-BlocklistSources.ps1
```

Refresh the saved validation report:

```powershell
.\Validate-BlocklistSources.ps1 *> .\validation-report.txt
```

## Build Details

The build script does this:

1. Reads `pihole-blocklist-sources.csv`.
2. Downloads each URL.
3. Parses common list formats.
4. Saves each source as a separate `.txt` file.
5. Merges all blocklist source files.
6. Merges all whitelist source files.
7. Removes duplicate domains.
8. Removes whitelist domains from the final blocklist.
9. Writes the final curated list files.

Supported source formats:

- Hosts format, like `0.0.0.0 example.com`
- Hosts format, like `127.0.0.1 example.com`
- AdBlock format, like `||example.com^`
- Plain domains, like `example.com`

## Using The Lists In Pi-hole

Pi-hole needs a direct raw text URL. Do not use the normal GitHub page URL. Use the `raw.githubusercontent.com` URL.

Use these URLs:

```text
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-blocklist.txt
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-whitelist.txt
```

The blocklist URL is:

```text
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-blocklist.txt
```

The whitelist URL is:

```text
https://raw.githubusercontent.com/mickpletcher/PiHole-Blocklist/main/Lists/curated-whitelist.txt
```

To add the curated blocklist:

1. Open the Pi-hole admin page.
2. Go to the adlist or subscribed denylist section.
3. Paste the blocklist raw URL.
4. Update gravity.

To add the curated whitelist:

1. Use Pi-hole v6 or newer.
2. Go to the subscribed allowlist section.
3. Paste the whitelist raw URL.
4. Update gravity.

Older Pi-hole versions may need whitelist domains added directly instead of as a subscribed list.

Update gravity from the Pi-hole host:

```bash
pihole -g
```

## Automatic GitHub Updates

This repo includes a GitHub Actions workflow:

```text
.github\workflows\update-lists.yml
```

The workflow:

1. Runs every day at 10:00 UTC.
2. Can also be started manually from the GitHub Actions tab.
3. Validates the source inventory.
4. Deletes the existing `Lists` directory in the GitHub runner.
5. Rebuilds every per-source list file.
6. Rebuilds `Lists\curated-blocklist.txt`.
7. Rebuilds `Lists\curated-whitelist.txt`.
8. Refreshes `validation-report.txt`.
9. Commits the changed generated files back to the repo.

This means the GitHub repo can update the generated list files without running the script locally.

For this to work, the repo must be pushed to GitHub and GitHub Actions must have permission to write to the repository. In GitHub, check:

```text
Settings > Actions > General > Workflow permissions > Read and write permissions
```

## Adding A New Source

Edit `pihole-blocklist-sources.csv`.

Each row needs:

```csv
Category,Source,URL
```

Example:

```csv
Advertising,Example List,https://example.com/blocklist.txt
```

Use `Whitelist` as the category when the source is an allowlist:

```csv
Whitelist,Example Whitelist,https://example.com/whitelist.txt
```

After editing the CSV:

```powershell
.\Validate-BlocklistSources.ps1
.\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv
```

Also update `pihole-list-sources.md` so the human-readable index stays in sync.

## Current Inventory

Current source inventory:

- 46 total CSV rows
- 45 blocklist sources
- 1 whitelist source

## Troubleshooting

If validation fails with `ParityDifferences`, the CSV and markdown source index do not match.

Fix:

- Check `pihole-blocklist-sources.csv`.
- Check `pihole-list-sources.md`.
- Make sure both contain the same source names, categories, and URLs.

If validation reports `FailedHttp`, one or more source URLs failed the live URL check.

Fix:

- Open the URL in a browser.
- Replace dead URLs.
- Remove abandoned sources.

If the final blocklist is very large, that is expected. The project combines large public threat, ad, and tracking lists.

## Project History

See [changelog.md](changelog.md) for change history.

See [completed-upgrades.md](completed-upgrades.md) for completed project improvements.

See [future-upgrades.md](future-upgrades.md) for planned local improvements.
