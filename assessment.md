# Repository Assessment

Last reviewed: 2026-08-14

## Current Condition

The repository now has a fail-closed PowerShell 7 pipeline with explicit Balanced, Strict, Device, and Policy profiles.

The source catalog contains 45 blocklist rows. Forty-four rows are enabled in at least one published profile. HaGeZi Spam TLDs is the sole disabled row because its TLD-wide rules cannot be represented in a plain-domain output.

The former third-party whitelist was removed. `project-allowlist.txt` is the only allowlist input and is empty by default.

A generated publication snapshot is tracked on `main` again to restore the legacy raw subscription URLs. The daily workflow continues publishing final outputs, validation results, and JSON build metadata to the history-limited orphan `generated` branch. It does not refresh the `main` snapshot.

## Resolved Findings

- Byte-array HTTP responses are decoded using the declared charset, strict UTF-8, or Latin-1 fallback. Disconnect.me Simple Tracking parses 34 domains and is enabled in Balanced and Strict.
- Selected downloads retry three times and any final failure stops the build.
- Enabled sources must parse within a reviewed expected-count range. Zero-domain and anomalous-count results fail publication.
- Output files are written atomically only after all selected sources succeed.
- The parser rejects invalid DNS labels, including underscore labels accepted by the previous implementation.
- The HaGeZi Spam TLD source remains documented but disabled because dotless TLD rules cannot be represented in a plain-domain Pi-hole list.
- Device and policy-enforcement sources are separate opt-in outputs.
- The broad, stale third-party whitelist no longer overrides intentional blocking.
- Pester, PSScriptAnalyzer, generated-documentation, inventory, Markdown, and live URL checks now run in pull requests.
- The publication workflow uses lease-protected replacement of the generated branch and retains the previous publication when a build fails.
- The generated branch snapshot was squash integrated into `main` without replacing the source repository README or source files.
- The README now presents source inventory counts and prominent links to the human-readable catalog, generated technical catalog, and CSV source of truth.
- The source schema requires `DisabledReason` for disabled rows and rejects reasons on enabled rows. Every supported plain-domain source is enabled.
- PowerShell support is accurately documented as PowerShell 7.4 or later.
- GitHub Actions run `31792116990` failed in the "Build and publish generated lists" job when jsDelivr returned HTTP 403 for HaGeZi host-format device sources. The four affected host URLs now point to `hagezi/dns-blocklists-legacy` on `raw.githubusercontent.com`, which currently serves those files.

## Source Profiles

| Profile | Enabled sources | Purpose |
|---|---:|---|
| Balanced | 23 | All supported moderate-risk sources |
| Strict | 24 | Balanced plus OISD Big |
| Device | 11 | Device and service-specific restrictions |
| Policy | 9 | High-risk policy, DNS, badware-hosting, and pop-up restrictions |

## Verified Results

Local validation on 2026-08-11:

```text
MarkdownRows=45
CsvRows=45
EnabledRows=44
ParityDifferences=0
MetadataProblems=0
InvalidUrls=0
DuplicateUrls=0
DuplicateSources=0
FailedHttp=0
Redirects=0
PesterTests=19 passed, 0 failed
PSScriptAnalyzerFindings=0
MarkdownProblems=0
```

Production-equivalent isolated builds:

| Profile | Sources | Domains | Build seconds |
|---|---:|---:|---:|
| Balanced | 23 | 3,535,901 | 480.16 |
| Strict | 24 | 3,573,746 | 497.73 |
| Device | 11 | 3,396 | 2.97 |
| Policy | 9 | 141,669 | 18.56 |

All 45 source URLs passed live validation with zero failures or redirects. All four outputs had zero invalid domains, duplicates, or out-of-order lines. The empty project allowlist produced zero overrides. The previous observed working-memory comparison remains about 718 MiB for the optimized implementation versus about 3.5 GiB before optimization; this change did not repeat peak-memory instrumentation.

On 2026-08-14, local live URL validation from this sandbox environment reported multiple unrelated transient or blocked upstream fetches, but the four updated HaGeZi host-format legacy URLs returned HTTP 200 in direct checks.

## Remaining Risks

- The repository still contains old generated-feed objects in Git history. Removing them requires a separate coordinated history rewrite and force push.
- Broad aggregate lists can create false positives even with the safer default profile.
- Expected-count baselines require manual review when a legitimate upstream change exceeds its threshold.
- Balanced and Strict intentionally contain heavy aggregate and component overlap. This increases download dependencies and processing cost while many sources contribute few exclusive domains.
- Legacy `main` subscription URLs now resolve, but their compatibility snapshot becomes stale when the next generated-branch publication succeeds.
- Balanced and Strict currently download their shared sources separately during the multi-profile workflow. A reviewed cache could reduce build time.
- Plain-domain outputs cannot implement TLD-wide or regex rules.

## Recommended Next Work

1. Monitor false positives, build duration, memory, and exclusive contribution after enabling all supported sources.
2. Decide whether to automate compatibility publication to `main` or migrate every subscriber to the canonical `generated` URLs.
3. Monitor scheduled generated-branch publications and adjust baselines only after reviewing upstream changes.
4. Decide whether repository-size reduction justifies a one-time coordinated history rewrite.
5. Add a separate reviewed Pi-hole regex publication only if TLD-wide blocking is required.
6. Consider a checksum-validated temporary download cache to avoid repeated aggregate downloads across profiles.
