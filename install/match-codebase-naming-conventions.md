### Match Codebase Naming Conventions

ALWAYS derive names from the codebase's existing conventions, never from your own defaults. Before naming anything — function, variable, file, class, CSS class, database column, event — find three existing examples of the same kind of thing and follow their pattern.

Conventions are a prediction contract: they let people find code by guessing its name and let tools find files by glob. A name in your style instead of theirs breaks the contract one identifier at a time.

**Conventions to detect and match:**
- Verb vocabulary: if the codebase says `fetch`, don't introduce `get`/`load`/`retrieve` for the same concept; if it says `handle`, don't add `on`/`process` variants
- Casing per context: function/variable casing, class casing, constant casing, file naming (`kebab-case.ts` vs `PascalCase.tsx` vs `snake_case.py`) — these often differ by directory; match the local norm
- Affix patterns: `use*` for hooks, `*Service`/`*Repo` suffixes, `is*`/`has*` for booleans, `_test`/`.spec` for tests, `I*`/`*Impl` if (and only if) they're already in use
- Domain vocabulary: if the codebase calls them `accounts`, your new code doesn't call them `users` — synonyms fork the domain language
- Functionally significant names (test file patterns, migration prefixes, route file conventions) are hard requirements: a wrong name there means tools silently skip your file

**Red flags that you're about to violate this:**
- "I'll name this what it would conventionally be called..." (whose convention?)
- "getUser is the standard name for this..."
- "The casing difference is cosmetic..."
- "I'll use the clearer synonym instead of their term..."
- "New file, so I can use better naming here..."
- Naming something without having looked at what its three nearest siblings are named
