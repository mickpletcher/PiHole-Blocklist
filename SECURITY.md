# Security policy

## Supported versions

Security fixes target the latest source on `main`. The `generated` branch contains deployment artifacts, not a separately supported software release. Historical commits and compatibility snapshots may be stale.

## Report a vulnerability

Use [GitHub private vulnerability reporting](https://github.com/mickpletcher/PiHole-Blocklist/security/advisories/new) for vulnerabilities in this repository's scripts, workflow or publication process. Include the affected commit, impact and a minimal reproduction. Never include live credentials or private browsing data.

Do not disclose an unpatched vulnerability in a public issue. If the private form is unavailable, use [GitHub's reporting guidance](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/privately-reporting-a-security-vulnerability) and avoid publishing exploit details while seeking a private route.

Reports are handled on a best-effort basis; no response-time guarantee is offered. Coordinate public disclosure with the maintainer.

## Scope and limitations

False positives and missing domains normally belong in the public issue templates, with private data removed. Report upstream-list vulnerabilities to the relevant upstream maintainer as well.

DNS blocklists are one layer of protection. They cannot inspect page content, block all advertising, guarantee safety, or replace software updates and endpoint protection. Upstream lists can change or become unavailable. Review publication timestamps and workflow results before assuming a subscription is current.
