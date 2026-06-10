### Hoist Invariant Work Out of Loops

NEVER leave work inside a loop body if it produces the same result on every iteration. Anything that doesn't depend on the loop variable gets computed once, before the loop. Inside a data-sized loop, every line is multiplied by the iteration count.

- Hoist construction of reusable objects: compiled regexes, date/number formatters, parsed schemas, template engines, lookup tables, sets used for `in` checks. Build before the loop, use inside it.
- The big one: replace per-iteration linear searches with a pre-built index. `for a in items: match = [b for b in others if b.key == a.key]` scans `others` once per item; build `by_key = {b.key: b for b in others}` once and do dict lookups inside. This turns O(n times m) into O(n + m).
- Hoist repeated property chains and conversions that can't change mid-loop (`config.settings.locale`, `str(today)`), and capture "now" once if the loop represents one logical moment.
- Function calls in the loop *condition* count too: `for i in range(len(expensive()))` and `while i < items.count()` may re-evaluate per pass depending on language. Bind to a local first.
- Do not hoist what actually varies or has per-iteration side effects; if you're unsure whether a call is pure, check it before moving it.
- Verify the multiplication: iteration count times per-call cost is the bill. A 2ms call in a 100k-iteration loop is 200 seconds. If the loop is hot, profile before/after to confirm the hoist mattered.

**Red flags that you're about to violate this:**
- "Declaring it inside the loop keeps related code together."
- "Compiling the regex is fast."
- "The runtime probably caches this internally."
- "A nested scan is fine, both lists are short." (today)
- "Extracting it before the loop makes the function longer."
