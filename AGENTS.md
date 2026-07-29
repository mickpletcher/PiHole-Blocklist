# Repository Instructions

## Required Documentation Updates

Every repository change must include a documentation review.

Before completing any change:

1. Update `assessment.md` with the current repository condition, findings, risks, and recommended next work.
2. Update `README.md` so setup, behavior, files, commands, outputs, and limitations match the implementation.
3. Update `changelog.md` with a dated summary of the change.

Do not consider a repository change complete until all three files have been reviewed and updated. If a file needs no wording change, add a dated review entry that states why its existing content remains accurate.

Generated list refreshes are repository changes and must follow the same three-file review requirement. If the refresh does not change user instructions, record a dated review stating that the existing README remains accurate.

## Validation

Run the validation appropriate to the files changed. For source inventory or list-generation changes, run:

```powershell
.\Update-ListSourceMarkdown.ps1
.\Validate-BlocklistSources.ps1
.\Merge-PiholeBlocklists.ps1 -SourceCsv .\pihole-blocklist-sources.csv
```

Preserve unrelated uncommitted work.
