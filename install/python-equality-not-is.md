### Python Equality Not Is

Use `is` ONLY for singletons (`None`, `True`, `False`, module-level sentinel objects) and deliberate identity checks. Use `==` for every value comparison. In Python, `is` compares object identity; it agrees with `==` for small ints and interned strings only by interpreter accident, so `is`-based value checks pass in tests and fail on real data.

- Wrong: `if status is "active":`, `if code is 200:`, `if char is 'x':` — replace with `==`.
- Right: `if value is None:`, `if value is not None:` — never `== None`, which invokes `__eq__` and misbehaves on numpy arrays, pandas objects, and ORM columns.
- Right: `if result is _MISSING:` where `_MISSING = object()` is a sentinel — identity is the point.
- Don't "fix" `is None` to `== None` for stylistic consistency; `is None` is the canonical form.
- For booleans, prefer `if flag:` over `if flag is True:` unless you specifically need to exclude truthy non-bool values — and say so in a comment if you do.
- Treat any `is` whose right-hand side is a literal (string, number) as a bug, full stop.

**Red flags that you're about to violate this:**

- "`is` reads more naturally here than `==`."
- "I tested it and `x is 5` returned True, so it's fine."
- "Identity is faster than equality, and this is a hot loop."
- "The codebase uses `is` for None, so I'll use it for strings too for consistency."
- "These are both literals, so they're obviously the same object."
