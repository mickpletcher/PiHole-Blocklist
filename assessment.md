# Repository Assessment

Last reviewed: 2026-08-10

## Current Condition

The repository has a working PowerShell pipeline for validating source URLs, normalizing supported list formats, and generating separate Pi-hole blocklist and whitelist outputs.

The source inventory currently contains 45 blocklist sources and one whitelist source. On 2026-08-10 five hagezi source URLs that previously used `raw.githubusercontent.com/hagezi/dns-blocklists/main/` began returning HTTP 404. All five were migrated to the equivalent `cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/` URLs, which are already used by the other hagezi sources in the list. Post-migration, all 46 source URLs are reachable.

The generated blocklist combines broad aggregate lists with many smaller lists that overlap those aggregates. The 2026-08-10 validation build produced 3,644,678 unique blocklist domains and 191 whitelist domains.

## Findings

### High Priority

- `Disconnect.me Simple Tracking` produces zero parsed domains. URL health checks pass, but the downloaded response is not converted into usable text by the current merge process.
- `Hagezi Spam TLDs` uses dotless TLD rules such as `||actor^`. The current parser requires a dotted domain and only captured a small subset of the upstream rules.
- `Validate-BlocklistSources.ps1` verifies reachability but does not verify source content, parsed domain count, staleness, or unexpected format changes.
- The default whitelist comes from `anudeepND/whitelist`, which was last pushed in March 2024 and contains broad hosting, redirect, tracking, advertising, and dynamic DNS domains. Automatically allowing the entire list can override intentional blocking.

### Source Selection

- HaGeZi Pro, HaGeZi Threat Intelligence Feeds, OISD Big, StevenBlack Unified, RPiList, Firebog-derived sources, and smaller component lists substantially overlap.
- Several smaller lists add no exclusive domains to the saved combined output.
- Policy lists for piracy, URL shorteners, unsupported SafeSearch providers, encrypted DNS or VPN bypass, fake news, and device-specific services can cause deliberate service restrictions. They should not be part of a general-purpose default without clear labeling.

### Repository Maintenance

- `README.md` and `.github/workflows/update-lists.yml` had existing uncommitted changes when this assessment was created. Those changes add a workflow badge, pin `actions/checkout` to a commit, and add a workflow timeout.
- Root `AGENTS.md` now requires every repository change to review and update this assessment, the README, and the changelog.

## Recommendations

1. Make HaGeZi Pro plus HaGeZi Threat Intelligence Feeds the balanced default, or use OISD Big plus HaGeZi Threat Intelligence Feeds as a simpler alternative.
2. Move device-specific and policy-enforcement lists into opt-in profiles.
3. Replace the automatic third-party whitelist with an empty or tightly reviewed project-owned whitelist.
4. Add source metadata such as enabled state, profile, format, risk, maintainer, and last successful parsed count.
5. Fail validation when an enabled source unexpectedly parses zero domains.
6. Add content-type and encoding handling before parsing source responses.
7. Add overlap and exclusive-domain reporting so source removal decisions are evidence based.

## Validation Results

Validation run on 2026-08-10:

```text
MarkdownRows=46
CsvRows=46
ParityDifferences=0
InvalidUrls=0
DuplicateUrls=0
DuplicateSources=0
FailedHttp=0
Redirects=0
SourcesOK=46/46
BlocklistDomains=3644678
WhitelistDomains=191
WhitelistCollisionsRemoved=16
```
