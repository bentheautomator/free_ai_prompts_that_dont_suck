### Alias Renamed API Query Params

NEVER rename a query parameter on an existing endpoint without keeping the old name working as an alias. Unknown query params are silently ignored, so callers using the old name don't get errors — they get *unfiltered results*, which is usually the most dangerous possible response.

- A renamed filter param fails open: `?user_id=7` on an endpoint that now reads `userId` returns every user's data with a 200. For scoping, date-range, and `since`-style params, silent ignoring means data over-exposure or full-history reprocessing, not a visible bug.
- If a rename is justified, accept both names: read the new param, fall back to the old one, and document the old as deprecated. The alias stays until a human retires it with usage data.
- The same applies to changing a param's *value format* (IDs to UUIDs, dates to a new format, comma-separated to repeated params): old-format values that no longer match return empty or unfiltered results, not errors. Keep parsing the old format alongside the new.
- Framework migrations are the high-risk moment: binding annotations and handler-signature names often *are* the param names. After migrating, diff the full set of accepted param names per endpoint against the old code.
- Where a previously-honored param can no longer be honored at all, prefer rejecting requests that send it (explicit 400 with a pointer to the replacement) over silently ignoring it — a loud failure beats quietly unfiltered data.

**Red flags that you're about to violate this:**
- "I'm aligning all query params with the camelCase convention."
- "The handler signature changed, so the param name follows automatically."
- "Old callers will notice immediately if their param stops working."
- "It still returns 200 for old-style requests, so it degrades gracefully."
- "Nobody passes that param anyway — it's not used in any of our calls."
