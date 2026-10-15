# Repository Assessment

Last reviewed: 2026-10-15

## 2026-10-15 Invalid Upstream Response Retry Fix

Prepared against main `faf84a7399841ed80e7b937923614810f27cc93d` in an isolated
local worktree. The existing OneDrive checkout has unrelated uncommitted work
and was left untouched.

The scheduled run failed when HaGeZi TIF parsed zero domains. Subsequent checks
reported HTTP 200 containing a `429: Too Many Requests` body; the original failed
job's body was not captured, so rate limiting remains the likely explanation.
Response decoding, error-payload classification, parsing, and unchanged count
bounds now participate in the same bounded retry budget as transport failures.
Configuration validation and size limits fail immediately. Exhausted retries
still abort before outputs are written. Diagnostics omit untrusted bodies and
URL secrets. Source URLs, thresholds, workflow publication, and CNAME behavior
are unchanged. The CNAME fixture is copied exactly from the pinned archived
source in commit `ce64b1b6b771659ba7d0a8dd5d0f59aa86fed91a`.

Validation on 2026-10-15: 36 Pester tests passed (zero failures/skips),
PSScriptAnalyzer 1.24.0 reported zero warnings/errors, Markdown checks reported
zero problems, and generated catalog regeneration had no diff. Inventory and
45 live URL checks passed (zero HTTP failures or redirects). HTTP status checks
do not detect error text returned with HTTP 200.

Local Balanced and Strict builds each retried the 199-byte HaGeZi TIF rate-limit
body three times, then failed closed with zero parsed domains and unchanged
bounds of 1,112,260 to 3,336,779. Both parsed the CNAME source's 35 domains first.
Device built 1,777 domains; Policy built 149,108. No Balanced or Strict output
was created. All local build artifacts were directed outside the worktree.
Upstream rate limiting still prevents complete live build validation. The
fetched generated ref remains `5695ca6fcda3b6c579044b33eb40843d4228b031`;
no publication was attempted.

Risk: legitimate baseline drift now takes the retry budget before failing;
three attempts and short backoff cannot guarantee recovery from prolonged
upstream rate limiting. Review and approval to publish this patch are the next
steps; no production workflow or Pi-hole changes are part of this preparation.

## Current Condition

The repository now has a fail-closed PowerShell 7 pipeline with explicit Balanced, Strict, Device, and Policy profiles.

The source catalog contains 45 blocklist rows. Forty-four rows are enabled in at least one published profile. HaGeZi Spam TLDs is the sole disabled row because its TLD-wide rules cannot be represented in a plain-domain output.

The former third-party whitelist was removed. `project-allowlist.txt` is the only allowlist input and contains nine reviewed permanent functional exceptions. Six URL-shortener exceptions intentionally override the Policy list, while the remaining entries preserve Apple location, iCloud connectivity, and App Store functions.

`project-denylist.txt` is a separate input for domains that pass local OpenClaw testing or implement an intentional local policy. It currently contains 15 reviewed entries, including only the two Apple hostnames recommended for disabling iCloud Private Relay. It publishes independently from the four profiles so Pi-hole can disable or unassign it without changing the baseline subscriptions.

`candidate-blocklist-2.txt` contains 89 user-approved advertising, tracking, and analytics domains. Eight Apple service domains were removed because current Apple documentation identifies them as RCS, iCloud DNS, Private Cloud Compute, or unnecessary for the documented Private Relay policy. It publishes as a separate subscription and is not merged into any existing profile or project list.

A generated publication snapshot is tracked on `main` again to restore the legacy raw subscription URLs. The daily workflow continues publishing final outputs, validation results, and JSON build metadata to the history-limited orphan `generated` branch. It does not refresh the `main` snapshot.

## 2026-10-11 CNAME Source Repair

The scheduled workflow failed on the NextDNS CNAME Cloaking Blocklist download
with HTTP 404 after three attempts ([failed run](https://github.com/mickpletcher/PiHole-Blocklist/actions/runs/38044309561)). The upstream repository and equivalent
jsDelivr endpoints also returned 404 during this review.

The inventory now points to the normalized source archived in this repository
at commit `ce64b1b6b771659ba7d0a8dd5d0f59aa86fed91a` (2026-08-11). Its 35-domain
set exactly matches the original upstream commit
`d86cbb9fc05f768fe18adeffd7c936a63486702a`, recovered from multiple existing
forks; [GitHub reports the upstream commit's signature as verified](https://github.com/sskafandri/cname-cloaking-blocklist/commit/d86cbb9fc05f768fe18adeffd7c936a63486702a). The archived
file was fetched over its new raw URL and matched the local Git object exactly.
Its SHA-256 is
`83d4738f8a1a1021265760700fc04f521b3345b15d83f0b50d36f4d7d3c866f7`.

No sources were disabled, no count thresholds were relaxed, and no list-building
or publication safety checks changed. Balanced and Strict retain the original
CNAME source coverage. Device, Policy, project lists, and Candidate blocklist 2
are unchanged. The source is now explicitly frozen, so future upstream updates
require review. The pinned historical commit must survive any future repository
history cleanup, or the snapshot must first be migrated.

Repair verification on 2026-10-11 (PowerShell 7.6.6): all 45 source URLs passed
live validation with zero failures or redirects; inventory and generated
catalog parity passed; all 19 Pester tests passed; PSScriptAnalyzer and Markdown
checks reported zero findings. Candidate blocklist 2 retained 89 valid, unique,
sorted domains. Generated catalog regeneration was idempotent. These checks do
not publish any lists; the daily workflow uses the repair only after merge.

All four isolated live builds passed. Output auditing confirmed valid, unique,
sorted domains and matching metadata SHA-256 hashes. All 35 archived CNAME
domains remain present in Balanced and Strict. The project allowlist and denylist
remain unchanged at nine and 15 domains, respectively.

| Profile | Sources | Domains | Build seconds |
|---|---:|---:|---:|
| Balanced | 23 | 2,942,682 | 129.37 |
| Strict | 24 | 2,977,657 | 180.96 |
| Device | 11 | 1,777 | 42.38 |
| Policy | 9 | 149,117 | 37.08 |

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
- Nine reviewed exact allow rules were promoted into the maintained project allowlist.

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
| Balanced | 23 | 3,358,001 | Not recorded |
| Strict | 24 | 3,396,100 | Not recorded |
| Device | 11 | 1,708 | Not recorded |
| Policy | 9 | 145,825 | Not recorded |

All 45 source URLs passed live validation with zero failures or redirects. All four builds published the same nine-domain project allowlist and 15-domain project denylist. The allowlist removed one collision from Balanced, Strict, and Device and six from Policy. The 89-domain Candidate blocklist 2 passed count, uniqueness, ordering, and syntax checks. Pester passed 19 tests, and the PowerShell analyzer and Markdown checks returned no findings. The previous observed working-memory comparison remains about 718 MiB for the optimized implementation versus about 3.5 GiB before optimization; this change did not repeat peak-memory instrumentation.

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
- Allowlisted URL shorteners can redirect to untrusted destinations. Their inclusion is a deliberate usability exception to the Policy profile and requires periodic review.

## Recommended Next Work

1. Monitor false positives, build duration, memory, and exclusive contribution after enabling all supported sources.
2. Promote only reviewed canary results into `project-denylist.txt`, document policy-only entries, and retain a generic reason in the pull request.
3. Decide whether to automate compatibility publication to `main` or migrate every subscriber to the canonical `generated` URLs.
4. Monitor scheduled generated-branch publications and adjust baselines only after reviewing upstream changes.
5. Decide whether repository-size reduction justifies a one-time coordinated history rewrite.
6. Add a separate reviewed Pi-hole regex publication only if TLD-wide blocking is required.
7. Consider a checksum-validated temporary download cache to avoid repeated aggregate downloads across profiles.
