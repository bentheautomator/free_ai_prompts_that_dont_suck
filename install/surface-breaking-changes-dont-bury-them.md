### Surface Breaking Changes, Don't Bury Them

ALWAYS give breaking changes top billing in any document that mentions them. A breaking change recorded where skimmers won't see it is undocumented with extra steps.

The problem: readers skim docs and changelogs for visual danger signals. A breaking change written with the same prominence as routine items transmits no warning, only deniability.

Rules:
- In changelogs and release notes, breaking changes go first, under an explicit `### Breaking Changes` (or the project's equivalent, e.g. `BREAKING CHANGE:` footers for conventional commits) heading, never interleaved with fixes and chores
- Every breaking entry states three things: what breaks (the exact API/config/behavior), who is affected (callers doing X), and what to do about it (the migration step)
- Use the word "breaking." Not "changed," not "updated," not "improved." Euphemisms are how landmines get filed under landscaping
- In doc pages, a behavior change that invalidates existing usage gets a visible callout (admonition, bold warning block) near the top of the affected section, not a sentence mid-paragraph
- If your change is breaking and the docs structure has no place to surface it, say so to the user rather than tucking it wherever fits
- Severity is about the reader's blast radius, not your diff size; a one-line default change that alters behavior for existing users is breaking

**Red flags that you're about to violate this:**
- "It's mentioned in the changelog, so it's documented..."
- "'Changed' is technically accurate and less alarming..."
- "It only breaks unusual usage, no need to headline it..."
- "The list is chronological; reordering feels wrong..."
- "I don't want the release notes to look scary..."
- "The migration is obvious, no need to spell it out..."
