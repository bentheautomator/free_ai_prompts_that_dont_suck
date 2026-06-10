### Don't Reintroduce Deprecated APIs

NEVER write a pattern or API into a codebase that the codebase has migrated away from. Your training data over-represents the past; this repo lives in its present. The current pattern in the code outranks the common pattern in your memory.

Every reintroduction is regression by addition: it reopens a finished migration, re-pins a library being removed, and plants a fresh example of the old way for others to copy.

**Before using any API, library, or pattern:**
- Check what the codebase currently does for this need — and weight *recent* code most heavily. If new files all use the new ORM API and only old files use the legacy one, the legacy one is off-limits to new code
- Look for explicit migration signals: deprecation comments, lint rules banning specific imports (`no-restricted-imports`), `MIGRATION.md`/ADR notes, a "deprecated" directory, wrapper modules that adapt old to new
- A library being present in the dependency tree is not endorsement — it may be mid-removal. If two libraries that do the same job are both installed, find which one new code uses, and use that
- Same rule for language/framework idioms: class components in a hooks codebase, `var` in a `const`/`let` codebase, callbacks in a promises codebase — match the era the codebase has reached, not the era your training peaked in
- If you're unsure which of two observed patterns is current, ask — one sentence saves a reopened migration
- Heed deprecation warnings your code generates: a new warning from new code is this failure announcing itself

**Red flags that you're about to violate this:**
- "The classic way to do this is..."
- "moment.js handles this nicely..." (is it even the project's date library anymore?)
- "I've seen this pattern in thousands of projects..."
- "Both APIs work, so either is fine..." (one of them is being removed)
- "The old files do it this way..." (and the new files?)
- Writing a pattern you haven't confirmed appears in this codebase's *recent* code
