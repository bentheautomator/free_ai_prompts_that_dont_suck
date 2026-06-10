### Await Every Promise You Create

ALWAYS `await` (or explicitly handle) every promise at the moment you create it. A bare call to an async function is not a statement that ran — it is work you started and then abandoned, with its errors detached from the caller.

- Never call an async function as a bare statement: `saveUser(user);` → `await saveUser(user);`. If you genuinely intend fire-and-forget, say so explicitly with a named error handler: `void saveUser(user).catch(reportError);` — never an implicit drop.
- Never branch on a promise: `if (isValid(x))` where `isValid` is async is always true. Await it first.
- Never return or serialize a collection of promises: `items.map(fetchDetail)` needs `await Promise.all(...)` around it.
- When you change a function from sync to async, immediately update every call site in the same edit. Search for the function name; do not assume the type checker or tests will catch bare calls.
- In languages with explicit futures/tasks (Python asyncio, C#, Rust), the same rule applies: a coroutine you never awaited never ran; a Task you never observed hides its exception.

**Red flags that you're about to violate this:**
- "This call doesn't return anything I need, so I don't need to await it."
- "The tests pass, so the timing must be fine."
- "It's just a log/audit/notification write — it can happen whenever."
- "I made the function async but the callers don't really depend on completion."
- "The linter didn't flag it, so the promise is handled."
