# Changelog

## 2026-06-04

- Removed `Lists` folder ignore rules so list outputs and per-source files can be committed to GitHub.
- Added a comprehensive root `README.md` with novice-friendly setup, validation, build, Pi-hole import, troubleshooting, and project history sections.
- Added a git ignore rule for `future-upgrades.md` so planning notes stay local and are not pushed.
- Added a git ignore rule for VS Code workspace files so local workspace settings are not pushed.
- Fixed the blocklist merger so single-domain parser results do not fail under strict mode.
- Changed merged list output to Pi-hole-ready text files.
- Changed merger output to write separate curated blocklist and whitelist files under `Lists`.
- Added per-source normalized text file output under `Lists\Sources` before final deduped merges.
- Added whitelist collision handling so whitelist domains are removed from the blocklist output.
- Renamed the markdown source index to `pihole-list-sources.md` to reflect both blocklist and whitelist sources.
- Hardened source validation with stricter URL checks and empty CSV handling.
- Regenerated the markdown source index from the CSV and refreshed stale docs.
- Removed the obsolete metadata artifact.
- Added CSV export for the curated Pi-hole blocklist source index.
- Replaced stale blocklist URLs with confirmed live RPiList sources and removed dead duplicates.
- Added a PowerShell validation script for markdown parity, duplicate detection, and URL health checks.
