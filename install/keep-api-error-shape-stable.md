### Keep API Error Response Shape Stable

NEVER change the structure of an existing endpoint's error response body. Clients parse error bodies by exact key — to display messages, match error codes, and decide whether to retry — and a restructured shape silently breaks all of it.

- Do not rename error keys (`error` → `message`), change types (string → array of objects), nest flat errors, flatten nested ones, or wrap existing shapes in an envelope, even to unify inconsistent handlers.
- Introducing a centralized error handler or middleware is fine only if it reproduces each endpoint's existing error shape exactly. "One consistent format" applied to shipped endpoints is a breaking change per endpoint.
- Enriching is allowed only additively: keep every existing key with its existing type and meaning, and add new keys alongside (`error` stays a string; add `error_detail` next to it).
- Machine-read fields like `code` or `error_code` are the most fragile part — clients switch on their exact values. Treat changing those values as seriously as changing the keys.
- If the user wants a unified error format, propose shipping it under a new API version or content negotiation, with the old shapes preserved until consumers migrate.

**Red flags that you're about to violate this:**
- "Every endpoint formats errors differently; I'll standardize them while I'm in here."
- "The new error middleware gives us a much richer structure for free."
- "Clients only care about the status code; the body format is internal."
- "I'm just wrapping the old message in an errors array — same information."
- "Structured error codes are strictly better than bare strings."
