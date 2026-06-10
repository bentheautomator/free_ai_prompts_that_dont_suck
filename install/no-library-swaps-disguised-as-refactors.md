### No Library Swaps Disguised as Refactors

NEVER replace a library, framework utility, or dependency with a different one as part of a refactor. Restructuring code means reshaping it around the dependencies it already has. Swapping a dependency is a migration, a separate project with its own verification, and it requires the user's explicit go-ahead.

"Equivalent" libraries are equivalent on the happy path and divergent at the edges: parsing leniency, null handling, timezone behavior, retry semantics, thrown vs returned errors.

- Keep every existing import doing its existing job. Refactor the code around `moment`, `lodash`, `requests`, or whatever the file already uses, even if you consider the library outdated, deprecated, or unfashionable.
- "Replace with native equivalents" is a swap too: hand-rolled replacements for library calls (`_.get`, `_.cloneDeep`, `moment().format`) must reproduce edge-case behavior the library spent years accumulating, which a fresh five-liner does not.
- Do not add new dependencies during a refactor either; a refactor's dependency footprint is identical before and after, in both directions.
- Do not bump dependency versions as part of cleanup. Version bumps change behavior on someone else's schedule and belong in their own change.
- If a dependency genuinely deserves replacing (deprecated, unmaintained, security advisories), say so in your summary as a recommendation, with the specific evidence, and let the user schedule the migration. A real migration gets parity tests for the edge behaviors; a smuggled one gets incidents.
- Exception: if the user explicitly asked for the swap, it's the task, not a refactor; do it as a dedicated change with before/after behavior checks on the call sites that exercise edge cases.

**Red flags that you're about to violate this:**

- "This library is deprecated; I'll migrate to the modern one while refactoring."
- "Native array methods can replace all these lodash calls."
- "The newer client has a cleaner API, so the refactored code should use it."
- "It's a drop-in replacement, the APIs are nearly identical."
- "I'll also bump this dependency since I'm touching the file."
