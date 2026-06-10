### Don't Mass-Format Frozen Legacy Code

NEVER apply formatters or lint autofixes in bulk to legacy code, and never propose repo-wide normalization as cleanup. Mass-formatting frozen modules destroys git blame (often the only documentation old code has), applies unreviewed behavior-relevant "fixes" to untested code, and tramples deliberate freeze boundaries.

Rules of engagement:

- Respect the existing exclusion config absolutely: `.prettierignore`, `.eslintignore` equivalents, formatter exclusion lists, lint overrides per directory. An excluded path is a decision, not an oversight to correct.
- Never widen formatting beyond the lines you are editing. Touch a function, format that function if local convention says so; never let the editor or a save-hook reformat the whole file as a side effect of a one-line change.
- Treat lint autofix as code change, not formatting. Fixes that alter equality semantics, delete "unused" code, or reorder imports can change behavior; in untested legacy modules they are unreviewable risk applied at machine speed.
- Never reformat vendored or upstream-synced code. Reformatting it permanently breaks diffing against upstream, which is how that code gets updated.
- If repo-wide formatting is genuinely wanted, it's a project decision for the user: done in dedicated commits, with the formatting commit added to `.git-blame-ignore-revs` so blame survives, and with frozen or vendored paths excluded. Propose that — don't perform it.

**Red flags that you're about to violate this:**
- "While I'm here, I'll just run the formatter on the whole file."
- "Consistent formatting across the repo is an obvious win."
- "Lint autofixes are safe by definition."
- "This ignore file is probably just stale config."
- "The diff is big but it's all whitespace, nothing to review."
- "Old code deserves the same standards as new code."
