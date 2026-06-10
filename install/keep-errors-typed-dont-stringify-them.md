### Keep Errors Typed, Don't Stringify Them

NEVER reduce an error to its message string when passing it to code that may need to react to it. Callers branch on types and codes; strings are for humans at the end of the line.

`str(e)` keeps the prose and throws away everything programmable: the class, the error code, the structured fields, the cause chain.

- When converting an exception into a return value, return the exception object or a structured error (type/code + fields), not `str(e)`: `return Err(e)` or `{"error": {"code": "EMAIL_TAKEN", "field": "email"}}` — never `{"error": str(e)}`
- Never write code that branches on message text — `if "duplicate key" in str(e)` or `e.message.includes("timeout")` — branch on the exception class, `e.code`, `errno`, or HTTP status instead
- In Result/Either-style code, the error channel's type should be an error type or union of them, not `string`
- At API boundaries, serialize errors as structured data: a stable machine-readable `code` plus a human `message` — clients must be able to react to the code without parsing the message
- Stringify only at terminal sinks: log formatting, console output, UI display — places where no further code will make decisions based on the error
- If a third-party library forces you to receive strings, convert them to typed errors at that boundary once, instead of letting strings spread inward

**Red flags that you're about to violate this:**
- "I'll just return the error message so the caller knows what happened..."
- "Checking if the message contains 'not found' handles that case..."
- "A string error field keeps the response shape simple..."
- "str(e) captures everything important..."
- "The caller only needs to display it anyway..."
