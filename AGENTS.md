# Repository Instructions

## Required Documentation Updates

Every repository change must include a documentation review.

Before completing any change:

1. Update `assessment.md` with the current repository condition, findings, risks, and recommended next work.
2. Update `README.md` so setup, behavior, files, commands, outputs, and limitations match the implementation.
3. Update `changelog.md` with a dated summary of the change.

Do not consider a repository change complete until all three files have been reviewed and updated. If a file needs no wording change, add a dated review entry that states why its existing content remains accurate.

Generated publications on the history-limited `generated` branch are deployment artifacts and do not modify the source repository. Changes to publication behavior, profiles, source inventory, or generated-file structure must update all three documentation files on `main`.

## Validation

Run the validation appropriate to the files changed. For source inventory or list-generation changes, run:

```powershell
.\Update-ListSourceMarkdown.ps1
.\Validate-BlocklistSources.ps1
foreach ($profileName in 'Balanced', 'Strict', 'Device', 'Policy') {
    .\Merge-PiholeBlocklists.ps1 `
        -SourceCsv .\pihole-blocklist-sources.csv `
        -BuildProfile $profileName `
        -OutputDirectory (Join-Path $env:TEMP 'PiHole-Blocklist-validation')
}
```

Preserve unrelated uncommitted work.
