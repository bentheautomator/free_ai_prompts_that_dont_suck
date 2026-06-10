### Never Fall Back to Empty Collections on Error

NEVER catch an error and return an empty list, dict, set, or array in its place. An empty collection is a successful result that claims "zero items exist" — it is not an error representation.

The moment a failure becomes `[]`, every downstream consumer treats it as truth: reports show zero, syncs propagate zero, deletes reconcile against zero.

- If a fetch, query, or parse fails, propagate the error: re-raise it, or return an explicit failure value (`Result`/`Either`, or raise a domain exception) — never `return []` or `return {}`
- Do not write `data = fetch() or []`, `items = response.get('items', [])` on a failed response, or `catch { return [] }`
- An empty collection is only a valid return when the operation genuinely succeeded and genuinely found nothing — those are the only conditions under which you may return one
- If a caller truly wants degrade-to-empty behavior (e.g. optional decorative data), that decision belongs at the call site, written explicitly by the caller — not buried inside the fetching function as a default for everyone
- When you see existing code consuming a possibly-failed fetch, do not "fix" a crash by defaulting the input to empty; fix the error path instead

**Red flags that you're about to violate this:**
- "Returning an empty list keeps the return type consistent..."
- "Downstream code handles empty lists fine, so this is safe..."
- "If the API is down we can just show nothing..."
- "I'll default to [] so the loop doesn't blow up..."
- "Empty is a reasonable neutral value here..."
