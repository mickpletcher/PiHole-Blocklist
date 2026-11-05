# Accessibility

## Scope and goals

This project provides Markdown documentation, PowerShell command-line tools and plain-text blocklists. Our goal is documentation that can be navigated by keyboard and assistive technology, understandable instructions, and results that do not depend on color or images alone.

This is an accessibility commitment, not a claim of WCAG certification or a completed assistive-technology audit. GitHub and Pi-hole provide their own interfaces and accessibility behavior.

## Documentation practices

- Use one descriptive page title and sequential heading levels.
- Give links meaningful names and images useful alternative text. Badges must have text labels and link to their evidence.
- Explain status and warnings in text, not only through badge color.
- Provide copyable commands and URLs, and explain their effects.
- Keep tables simple. Provide a list or prose alternative for key subscription choices.
- Use plain language, expand unfamiliar abbreviations, and avoid unnecessary animation or decorative symbols.

## Report a barrier

Use the [accessibility issue form](https://github.com/mickpletcher/PiHole-Blocklist/issues/new?template=accessibility.yml). Tell us which page or command is affected, what you expected, and what would help. Screenshots, medical details, and assistive-technology information are optional; a text description is enough. Do not include private browsing history or identifying logs.

We review reports on a best-effort basis and cannot promise a response deadline. Contributions that improve accessibility are welcome through [CONTRIBUTING.md](CONTRIBUTING.md).

## Current limitations

The hosted-list table contains long URLs and may be cumbersome on narrow screens. The README also offers direct labeled subscription links. Automated Markdown checks are limited and do not replace keyboard, screen-reader, zoom, or command-line usability testing. Those manual checks have not been comprehensively completed.
