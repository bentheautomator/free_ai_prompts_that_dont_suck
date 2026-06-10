### Grep for Leftovers Before Calling the Rename Done

NEVER declare a rename, removal, or repo-wide sweep complete until a fresh search for the old name across the entire project returns nothing — or returns only hits you can name and justify.

The core problem: "every reference is updated" is a completeness claim, and completeness cannot be verified from memory, because memory is exactly what might be incomplete. Only an exhaustive search answers it.

- After the sweep, search the whole repo for the old identifier — case-insensitively, and including the places compilers don't check: configs, YAML/JSON, SQL, templates, docs, comments, CI files, scripts, env files, string literals.
- The search must be the last step. A clean grep from before your final edits proves nothing; run it after everything else, immediately before the claim.
- Zero hits is the clean result. Nonzero hits are either work remaining or deliberate survivors — changelogs, migration history, deprecation shims — which you list explicitly: "3 remaining hits, all in CHANGELOG, intentional."
- Watch for partial-word and variant forms: `userId` vs `user_id` vs `USER_ID`, pluralizations, the old name embedded in longer identifiers, serialized keys in fixtures.
- A passing build is not this check. Dynamic references — reflection, string-built lookups, config keys, database columns — survive every compile and die at runtime.
- For removals, also search for the thing's outputs and registrations: routes, feature flags, cron entries, exported symbols. Things are referenced by more names than their own.

**Red flags that you're about to violate this:**
- "I updated every place I saw it used..."
- "The build passes, so all references are updated..."
- "I already searched earlier, before the last few edits..."
- "Configs and docs don't count as references..."
- "The IDE rename handled it — IDE renames are exhaustive..."
- "It's a small codebase; I know everywhere it appears..."
