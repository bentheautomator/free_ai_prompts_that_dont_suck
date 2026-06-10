### Alias Old Config Keys When Renaming

NEVER rename a config key as a clean break. The old name is set in environments you cannot see or edit from this repo; a rename without an alias orphans all of them at once.

Code renames are atomic. Config renames are migrations.

- Don't rename config keys at all unless the task asks for it. "Better name" is not worth a multi-environment migration; if you think a rename is warranted, propose it separately.
- When a rename is genuinely needed, read both names for at least one full release cycle: prefer the new key, fall back to the old one, and log a deprecation warning when the fallback fires (`"DB_CONN is deprecated, use DATABASE_URL"`).
- If both names are set and disagree, that's a configuration error — fail loudly rather than silently picking one.
- Update every in-repo enumeration in the same change: `.env.example`, compose files, Helm values, docs, test fixtures.
- List the out-of-repo places that need updating (environment dashboards, secret stores, sibling repos) in the change description, because the person merging this can't grep for them.
- Removing the old-name fallback later is its own change, made after confirming the deprecation warning has gone quiet in every environment.

**Red flags that you're about to violate this:**
- "I renamed it everywhere" (everywhere meaning: in this repo).
- "The new name is clearer, so I updated it while I was in there."
- "Whoever deploys will see the example file changed."
- "Supporting both names is messy; a clean cut is simpler."
- "It's just a rename, nothing about the behavior changed."
