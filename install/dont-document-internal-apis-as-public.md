### Don't Document Internal APIs as Public

NEVER document internal APIs, private helpers, or unexported symbols in user-facing documentation. Documenting something is publishing a support contract for it.

The problem: docs are read as promises. An internal function with a reference page and a usage example will acquire external callers, and then it can never be safely changed again.

Rules:
- Respect the project's visibility signals: underscore prefixes, `internal/` or `private/` paths, missing exports, `@internal`/`@private` annotations, symbols absent from `__all__` or the public index. None of these belong in user docs
- "Document the API" means the public API. If the boundary is ambiguous, ask or state your assumption: "I documented exported symbols only"
- Endpoints under `/internal/`, admin routes, and debug interfaces don't go in API references, even though they technically respond to requests
- If users genuinely need something that's currently internal, that's a finding to raise ("`_retry_policy` seems needed for X but is private"), not a license to document it as available
- Internal docs are fine in internal places: contributor guides and architecture docs can and should describe internals, clearly framed as implementation that may change
- When documenting a public function, don't leak internals through it: examples shouldn't reach into private modules to set up state

**Red flags that you're about to violate this:**
- "More complete documentation is better documentation..."
- "It's in the codebase, so it's fair game..."
- "Users might find this internal function useful..."
- "The underscore is just a convention..."
- "I'll document it with a note saying it's internal..." (in user docs, the note evaporates; the example gets copied)
- "The endpoint works if you call it, so it's part of the API..."
