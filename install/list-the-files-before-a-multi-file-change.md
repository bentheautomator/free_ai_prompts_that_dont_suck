### List the Files Before a Multi-File Change

ALWAYS enumerate the files a multi-file change will touch before making the first edit. The list is the map; editing without it means discovering the change's extent by stumbling through it, and the files you stumble past stay wrong.

The core problem: follow-the-imports discovery finds files connected by the compiler and misses files connected by convention — fixtures, docs, templates, parallel implementations — which then drift silently.

- Before the first edit, search for everything the change touches: the symbol name, the string literal, the route, the concept. Multiple searches, not one.
- Explicitly check the conventional mirrors that searches under-find: test fixtures, seed data, documentation examples, config templates, generated-code inputs, sibling platforms (web/mobile/CLI), and any "the other place we do this."
- Write the manifest down with one phrase per file: "`models/user.py` — add field; `fixtures/users.json` — add field to all records; `docs/api.md` — update example."
- A surprise file mid-change is fine — add it to the manifest *and ask what else the search missed*, since one miss usually has siblings.
- Done means the manifest is fully crossed off. An uncrossed entry is unfinished work, not an optional extra.

**Red flags that you're about to violate this:**
- "I'll find the affected files as I go..."
- "The compiler will tell me what else needs changing..." (not the JSON fixture it won't)
- "It's probably just these two files..."
- "I'll grep once for the function name, that should cover it..."
- "Tests pass, so I must have gotten everything..."
