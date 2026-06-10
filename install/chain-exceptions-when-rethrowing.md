### Chain Exceptions When Rethrowing

When you catch an error and throw a new one, ALWAYS attach the original as the cause. NEVER construct the replacement from `e.message` alone — that deletes the original stack trace and type.

- Python: `raise DomainError("context") from e` — never `raise DomainError(str(e))` bare. Inside an `except` block, even re-raising a new error without `from` implicitly chains, but be explicit: `from e` for wrapping, `from None` only when hiding the cause is a deliberate, commented decision
- JavaScript/TypeScript: `throw new DomainError("context", { cause: e })` — never `throw new Error(e.message)`
- Java/C#: pass the original as the constructor's cause/innerException argument: `throw new ServiceException("context", e)`
- Go: wrap with `%w` so `errors.Is`/`errors.As` still work: `fmt.Errorf("loading config: %w", err)` — `%v` or `err.Error()` breaks unwrapping
- The wrapper's own message should add context the original lacked (operation, identifiers) — duplicating `e.message` into the wrapper adds nothing and tempts you to skip chaining
- To re-throw unchanged, use the bare form that preserves the original: `raise` (Python), `throw;` (C#), re-`throw err` (JS) — not a reconstruction of it
- Ensure log formatters print the full cause chain (`exc_info=True`, logging `err.cause`); a chain nobody prints is a chain nobody sees

**Red flags that you're about to violate this:**
- "I'll wrap the message in our custom error class..."
- "new Error(e.message) keeps the important part..."
- "The message tells you everything the stack would..."
- "Converting to our error type means building a fresh one..."
- "The original error isn't needed once we've translated it..."
