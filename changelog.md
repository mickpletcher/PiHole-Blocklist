# Changelog

## 2026-08-11

- Added a prominent README source inventory with total, enabled, and disabled counts plus direct links to the CSV source of truth and both human-readable catalogs.
- Squash integrated the current `generated` branch publication into `main` to restore the legacy raw blocklist and allowlist URLs.
- Preserved the source repository README and source files while adding the generated profile lists, JSON build metadata, and validation report.
- Documented that the `main` artifacts are compatibility snapshots and the daily workflow continues refreshing only the canonical `generated` branch.
- Replaced the monolithic all-source build with Balanced, Strict, Device, and Policy profiles.
- Made Balanced the default using HaGeZi Threat Intelligence Feeds and HaGeZi Pro.
- Moved device and policy-enforcement sources into separate opt-in outputs.
- Added source enablement, profile, format, risk, expected-domain, and maximum-change metadata to the CSV source of truth.
- Removed the stale third-party whitelist source and added an empty project-owned `project-allowlist.txt`.
- Fixed byte-array response decoding. Disconnect.me Simple Tracking now yields 34 domains when parsed correctly.
- Disabled HaGeZi Spam TLDs because its dotless rules cannot be represented as plain Pi-hole domains.
- Added retries, response-size limits, profile-size limits, strict DNS validation, count baselines, and fail-closed exit behavior.
- Changed output writes to atomic replacement after every selected source succeeds.
- Replaced PowerShell `Sort-Object` over millions of domains with .NET hash-set and array sorting, reducing observed large-build memory from about 3.5 GiB to about 718 MiB.
- Added JSON build metadata with per-source counts, exclusive contribution, elapsed time, and output SHA-256.
- Added 18 Pester tests for decoding, byte-order marks, domain and IP validation, parsing, retries, baseline failures, atomic publication, sorting, and allowlist behavior.
- Added PSScriptAnalyzer, generated-documentation, inventory, Markdown, and live URL checks for pull requests and `main`.
- Moved generated outputs off `main` to a history-limited orphan `generated` branch with lease-protected publication.
- Removed tracked per-source files, curated outputs, the saved root validation report, and the duplicate legacy README from `main`.
- Updated generated source documentation to show profile, enablement, risk, and format metadata.
- Updated `AGENTS.md`, `README.md`, `assessment.md`, and `completed-upgrades.md` for the new maintenance and publication model.
- Verified all 45 URLs and all four profile builds. Outputs contained zero invalid domains, duplicates, or sort-order errors.

## 2026-08-10

- Fixed CI failure in "Build and commit generated lists" job: five hagezi blocklist source URLs using `raw.githubusercontent.com/hagezi/dns-blocklists/main/` began returning HTTP 404 (`native.winoffice.txt`, `native.tiktok.txt`, `native.samsung.txt`, `native.lgwebos.txt`, `adblock/pro.txt`).
- Replaced all five with equivalent `cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/` URLs, consistent with the other hagezi entries already in the source list.
- Updated `assessment.md` to reflect the URL migration and current reachability status.
- Reviewed `README.md`; setup, commands, outputs, and limitations remain accurate because only source URLs changed.
- Regenerated both source indexes, validated all 46 URLs, and completed a full list build with all 46 sources succeeding.
- Manually verified the merged fix with GitHub Actions run `31413013230`; all steps passed and the workflow committed refreshed lists to `main`.

## 2026-07-29

- Added `assessment.md` with the current repository condition, source audit results, risks, and recommended next work.
- Added root `AGENTS.md` requiring every repository change to review and update `assessment.md`, `README.md`, and `changelog.md`.
- Updated `README.md` with the assessment and repository instruction files and the required documentation maintenance process.
- Documented the current source audit: all 46 URLs are reachable, while parser, overlap, policy-list, and third-party whitelist concerns remain.
- Added an update workflow status badge to `README.md`.
- Added a 15-minute timeout to the scheduled list-update job.
- Pinned `actions/checkout` to the v5 commit in the list-update workflow.

## 2026-06-04

- Added `LISTS.md` as a user-facing review page for blocklist and whitelist sources.
- Added `Update-ListSourceMarkdown.ps1` to regenerate source review markdown files from the CSV.
- Updated the GitHub Actions workflow to refresh source review markdown during scheduled list updates.
- Updated `.github/workflows/update-lists.yml` to use `actions/checkout@v5` to address the Node.js 20 deprecation warning in GitHub Actions.
- Cleaned up `README.md` by removing duplicate sections, normalizing path examples, and clarifying hosted curated list usage in Pi-hole.
- Updated `README.md` with clearer raw GitHub URL instructions for importing curated lists into Pi-hole.
- Added a GitHub Actions workflow to validate, rebuild, replace, and commit the `Lists` directory automatically.
- Updated `README.md` with direct GitHub raw URLs for curated blocklist and whitelist files and clearer Pi-hole linking steps.
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
