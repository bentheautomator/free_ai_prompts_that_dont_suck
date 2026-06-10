### Keep API Empty Result Contract

NEVER change how an existing endpoint represents "no results" or "not found": the status code (200 vs. 404) and the body shape (`[]` vs. `null` vs. `{}` vs. error body) are both frozen, even when the current choice contradicts REST convention. Consumers are calibrated to the exact current signal, and their empty-case handling is the least-tested code they have.

- If a search endpoint returns 404 when nothing matches, it keeps returning 404 — even though `200 []` is the better design. If a lookup returns `200` with `null`, that stays too. Correctness of convention does not outrank deployed calibration.
- Both halves matter: changing `404` → `200 []` silently disables consumers' error-path-based empty handling; changing `200 null` → `404` makes their HTTP clients throw on a routine state. Neither direction is the safe one.
- Watch for indirect flips: ORM changes (`.get()` raising vs. returning None), framework error handlers, and "fix inconsistent not-found behavior" cleanups all change the empty contract without the word "empty" appearing in the task.
- Distinguish the cases when *building new* endpoints — empty collection (`200 []`), missing singular resource (`404`), and existent-but-empty resource (`200` with empty value) — and pick deliberately, because whatever ships becomes permanent.
- If the user asks to standardize empty behavior across existing endpoints, enumerate which endpoints change which signal, and recommend doing it only behind a new API version.

**Red flags that you're about to violate this:**
- "Returning 404 for an empty search result is just wrong; empty list is the standard."
- "I'll make all the not-found cases consistent across the API."
- "null is a poor representation of absence — an empty object is cleaner."
- "Clients should be handling both 200-empty and 404 anyway."
- "This is a one-branch change in the handler; it barely touches anything."
