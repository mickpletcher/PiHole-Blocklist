# Pi-hole Blocklist

Curated Pi-hole source inventory with PowerShell tooling to validate sources and build separate blocklist and whitelist files.

## Files

| File | Purpose |
|---|---|
| `pihole-blocklist-sources.csv` | Source of truth for list categories, names, and URLs |
| `pihole-list-sources.md` | Human-readable blocklist and whitelist source index generated from the CSV |
| `Validate-BlocklistSources.ps1` | Checks CSV and markdown parity, duplicate sources, invalid URLs, and live URL health |
| `Merge-PiholeBlocklists.ps1` | Downloads all sources, saves one text file per source, then writes deduplicated blocklist and whitelist files |
| `validation-report.txt` | Latest saved validator output |
| `Lists\Sources\blocklist\` | Normalized per-source blocklist text files |
| `Lists\Sources\whitelist\` | Normalized per-source whitelist text files |
| `Lists\curated-blocklist.txt` | Generated curated blocklist |
| `Lists\curated-whitelist.txt` | Generated curated whitelist |

## Validate Sources

Run a fast local parity and duplicate check:

```powershell
.\Validate-BlocklistSources.ps1 -SkipUrlChecks
```

Run the full validation with live URL checks:

```powershell
.\Validate-BlocklistSources.ps1
```

Refresh the saved report:

```powershell
.\Validate-BlocklistSources.ps1 *> .\validation-report.txt
```

## Build Curated Lists

Write the curated blocklist and whitelist files:

```powershell
.\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv
```

Default outputs:

- `Lists\Sources\blocklist\*.txt`
- `Lists\Sources\whitelist\*.txt`
- `Lists\curated-blocklist.txt`
- `Lists\curated-whitelist.txt`

The script saves each source as a separate normalized text file first. It then merges the source text files into the curated blocklist and whitelist outputs, removing duplicates during the final merge. The `Whitelist` category is written to the whitelist output. All other categories are written to the blocklist output. If a domain appears in both, the whitelist wins and the domain is removed from the blocklist.

## Add Or Remove Sources

Update `pihole-blocklist-sources.csv` first. Then regenerate `pihole-list-sources.md`, run validation, and refresh `validation-report.txt`.

Current inventory:

- 46 CSV rows
- 45 blocklist sources
- 1 whitelist source
