# Repository Assessment

Last reviewed: 2026-08-11

## Current Condition

The repository now has a fail-closed PowerShell 7 pipeline with explicit Balanced, Strict, Device, and Policy profiles.

The source catalog contains 45 blocklist rows. Nineteen rows are enabled in at least one published profile. Disabled overlapping sources remain visible for review but are not downloaded during publication.

The former third-party whitelist was removed. `project-allowlist.txt` is the only allowlist input and is empty by default.

Generated feeds are no longer tracked on `main`. The daily workflow publishes only final outputs, validation results, and JSON build metadata to a history-limited orphan `generated` branch. Existing generated Git history remains, but daily source churn no longer grows `main`.

## Resolved Findings

- Byte-array HTTP responses are decoded using the declared charset, strict UTF-8, or Latin-1 fallback. Disconnect.me Simple Tracking now parses 34 domains when tested, though it remains disabled because it overlaps the default aggregates.
- Selected downloads retry three times and any final failure stops the build.
- Enabled sources must parse within a reviewed expected-count range. Zero-domain and anomalous-count results fail publication.
- Output files are written atomically only after all selected sources succeed.
- The parser rejects invalid DNS labels, including underscore labels accepted by the previous implementation.
- The HaGeZi Spam TLD source remains documented but disabled because dotless TLD rules cannot be represented in a plain-domain Pi-hole list.
- Device and policy-enforcement sources are separate opt-in outputs.
- The broad, stale third-party whitelist no longer overrides intentional blocking.
- Pester, PSScriptAnalyzer, generated-documentation, inventory, Markdown, and live URL checks now run in pull requests.
- The publication workflow uses lease-protected replacement of the generated branch and retains the previous publication when a build fails.
- PowerShell support is accurately documented as PowerShell 7.4 or later.

## Source Profiles

| Profile | Enabled sources | Purpose |
|---|---:|---|
| Balanced | 2 | HaGeZi Threat Intelligence Feeds plus HaGeZi Pro |
| Strict | 3 | Balanced plus OISD Big |
| Device | 11 | Device and service-specific restrictions |
| Policy | 5 | Piracy, shortener, bypass, fake-news, and SafeSearch restrictions |

## Verified Results

Local validation on 2026-08-11:

```text
MarkdownRows=45
CsvRows=45
EnabledRows=19
ParityDifferences=0
MetadataProblems=0
InvalidUrls=0
DuplicateUrls=0
DuplicateSources=0
FailedHttp=0
Redirects=0
PesterTests=18 passed, 0 failed
PSScriptAnalyzerFindings=0
MarkdownProblems=0
```

Production-equivalent isolated builds:

| Profile | Sources | Domains | Build seconds |
|---|---:|---:|---:|
| Balanced | 2 | 2,360,773 | 189.04 |
| Strict | 3 | 2,420,078 | 186.81 |
| Device | 11 | 3,396 | 1.35 |
| Policy | 5 | 68,986 | 4.49 |

All four outputs had zero invalid domains, duplicates, or out-of-order lines. The empty project allowlist produced zero overrides. Peak observed working memory during the large build was about 718 MiB, compared with about 3.5 GiB during the previous implementation.

## Remaining Risks

- The repository still contains old generated-feed objects in Git history. Removing them requires a separate coordinated history rewrite and force push.
- Broad aggregate lists can create false positives even with the safer default profile.
- Expected-count baselines require manual review when a legitimate upstream change exceeds its threshold.
- Balanced and Strict currently download their shared sources separately during the multi-profile workflow. A reviewed cache could reduce build time.
- Plain-domain outputs cannot implement TLD-wide or regex rules.

## Recommended Next Work

1. Monitor the first scheduled generated-branch publications and adjust baselines only after reviewing upstream changes.
2. Decide whether repository-size reduction justifies a one-time coordinated history rewrite.
3. Add a separate reviewed Pi-hole regex publication only if TLD-wide blocking is required.
4. Consider a checksum-validated temporary download cache to avoid repeated aggregate downloads across profiles.
