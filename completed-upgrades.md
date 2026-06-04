# Completed Upgrades

## 2026-06-04

- Added `LISTS.md` for user review of blocklist and whitelist sources.
- Added `Update-ListSourceMarkdown.ps1` to regenerate source review markdown files from the CSV.
- Updated GitHub Actions to refresh source review markdown during scheduled list updates.
- Clarified raw GitHub URL instructions for using the curated lists in Pi-hole.
- Added a GitHub Actions workflow to automatically rebuild and commit generated list files.
- Added a comprehensive root `README.md` for novice users.
- Added CSV source inventory in `pihole-blocklist-sources.csv`.
- Added markdown source index in `pihole-list-sources.md`.
- Renamed the markdown source index to reflect both blocklist and whitelist sources.
- Added `Validate-BlocklistSources.ps1` for source parity, duplicate, URL format, and live URL health checks.
- Added `Merge-PiholeBlocklists.ps1` to download sources and create deduplicated blocklist and whitelist outputs.
- Fixed stale and dead source URLs.
- Removed duplicate source URLs.
- Fixed the merger single-domain parser bug under strict mode.
- Changed merger output to Pi-hole-ready text.
- Changed merger output to write separate curated blocklist and whitelist files under `Lists`.
- Added per-source normalized text file output under `Lists\Sources` before final deduped merges.
- Added whitelist collision handling so whitelist domains are removed from the blocklist output.
- Hardened validation with strict URL checks and empty CSV handling.
- Refreshed `validation-report.txt`.
- Rewrote repository usage docs in `pihole-blocklist-README.md`.
- Removed the obsolete metadata artifact.
- Kept the repo documentation focused on standalone Pi-hole blocklist tooling.
- Added `.gitignore` for generated blocklist outputs.
- Initialized Git for the folder.
