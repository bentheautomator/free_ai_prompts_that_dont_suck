### Freeze Public APIs During Internal Cleanup

When refactoring internals, the public surface is frozen. NEVER change anything an external caller could observe: exported function signatures, parameter names in languages with keyword arguments, parameter order, return types, class hierarchies of exported types, HTTP routes and payload shapes, CLI flags, or published constants.

You can verify every internal caller. You cannot verify a single external one. That asymmetry is the whole rule.

- Treat as public: anything exported from the package's entry point, anything documented, any HTTP/gRPC/GraphQL contract, any CLI interface, environment variable names, and anything tests outside the module import directly.
- Keyword-argument languages (Python, Ruby, Kotlin) make parameter *names* part of the contract. Renaming `def search(query=...)` to `def search(q=...)` breaks every caller using `query=`, even though the type checker shrugs.
- Default parameter values on public functions are contract too. Don't "clean up" `timeout=30` to `timeout=None`.
- Refactor freely behind the surface: extract private helpers, restructure internals, rename private members. The public function can become a thin wrapper over a new internal shape; that is the standard move.
- If the cleanup genuinely requires a public change, stop and propose it separately as a breaking change with a deprecation path (new name added, old name delegating, warning emitted). Never just edit the surface.
- Before finishing, diff the public surface explicitly: list every exported symbol and signature before and after. The list must be identical, or you must have flagged the difference.

**Red flags that you're about to violate this:**

- "Reordering these parameters makes the API more consistent."
- "All the callers are in this repo as far as I can tell."
- "I'll rename this keyword argument; the old name was misleading."
- "Returning an iterator is strictly better than returning a list."
- "Nobody passes this argument by name, surely."
