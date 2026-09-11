# Repository Assessment

Last reviewed: 2026-09-11

## Current Condition

The repository now has a fail-closed PowerShell 7 pipeline with explicit Balanced, Strict, Device, and Policy profiles.

The source catalog contains 45 blocklist rows. Forty-four rows are enabled in at least one published profile. HaGeZi Spam TLDs is the sole disabled row because its TLD-wide rules cannot be represented in a plain-domain output.

The former third-party whitelist was removed. `project-allowlist.txt` is the only allowlist input and is empty by default.

`project-denylist.txt` is a separate input for domains that pass local OpenClaw testing or implement an intentional local policy. It currently contains 15 reviewed entries, including only the two Apple hostnames recommended for disabling iCloud Private Relay. It publishes independently from the four profiles so Pi-hole can disable or unassign it without changing the baseline subscriptions.

`candidate-blocklist-2.txt` contains 89 user-approved advertising, tracking, and analytics domains. Eight Apple service domains were removed because current Apple documentation identifies them as RCS, iCloud DNS, Private Cloud Compute, or unnecessary for the documented Private Relay policy. It publishes as a separate subscription and is not merged into any existing profile or project list.

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
- Project deny entries are validated as plain domains, deduplicated, checked against the project allowlist, and published as an independent rollback unit.
- Four HaGeZi native tracker sources were migrated from retired legacy hosts URLs to the current official Adblock URLs and their reviewed count baselines were refreshed.
- Candidate blocklist 2 is validated for count, duplicates, sorting, and domain syntax before publication as an independent list.
- Fourteen reviewed local exact blocks were promoted into the project denylist, and the previously missing `mask-h2.icloud.com` Private Relay policy hostname was added.
- Eight Apple service domains were removed from Candidate blocklist 2 to prevent collateral blocking of RCS, iCloud DNS, and Private Cloud Compute.

## Source Profiles

| Profile | Enabled sources | Purpose |
|---|---:|---|
| Balanced | 23 | All supported moderate-risk sources |
| Strict | 24 | Balanced plus OISD Big |
| Device | 11 | Device and service-specific restrictions |
| Policy | 9 | High-risk policy, DNS, badware-hosting, and pop-up restrictions |

## Verified Results

Local validation on 2026-09-11:

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
| Balanced | 23 | 3,357,993 | Not recorded |
| Strict | 24 | 3,396,066 | Not recorded |
| Device | 11 | 1,709 | Not recorded |
| Policy | 9 | 145,831 | Not recorded |

All 45 source URLs passed live validation with zero failures or redirects. All four builds published the same 15-domain project denylist with zero allowlist collisions. The 89-domain Candidate blocklist 2 passed count, uniqueness, ordering, and syntax checks. Pester passed 19 tests, and the PowerShell analyzer and Markdown checks returned no findings. The previous observed working-memory comparison remains about 718 MiB for the optimized implementation versus about 3.5 GiB before optimization; this change did not repeat peak-memory instrumentation.

## Remaining Risks

- The repository still contains old generated-feed objects in Git history. Removing them requires a separate coordinated history rewrite and force push.
- Broad aggregate lists can create false positives even with the safer default profile.
- Expected-count baselines require manual review when a legitimate upstream change exceeds its threshold.
- Balanced and Strict intentionally contain heavy aggregate and component overlap. This increases download dependencies and processing cost while many sources contribute few exclusive domains.
- Legacy `main` subscription URLs now resolve, but their compatibility snapshot becomes stale when the next generated-branch publication succeeds.
- Balanced and Strict currently download their shared sources separately during the multi-profile workflow. A reviewed cache could reduce build time.
- Plain-domain outputs cannot implement TLD-wide or regex rules.
- Candidate promotion remains a human decision. The repository cannot prove that a domain passed functional testing.
- Candidate blocklist 2 intentionally blocks parent domains and may cause site or application breakage. Its separate subscription is the rollback boundary.
- The project denylist is local policy. Its entries require periodic review as vendor services and Apple endpoint guidance change.

## Recommended Next Work

1. Monitor false positives, build duration, memory, and exclusive contribution after enabling all supported sources.
2. Promote only reviewed canary results into `project-denylist.txt`, document policy-only entries, and retain a generic reason in the pull request.
3. Decide whether to automate compatibility publication to `main` or migrate every subscriber to the canonical `generated` URLs.
4. Monitor scheduled generated-branch publications and adjust baselines only after reviewing upstream changes.
5. Decide whether repository-size reduction justifies a one-time coordinated history rewrite.
6. Add a separate reviewed Pi-hole regex publication only if TLD-wide blocking is required.
7. Consider a checksum-validated temporary download cache to avoid repeated aggregate downloads across profiles.
