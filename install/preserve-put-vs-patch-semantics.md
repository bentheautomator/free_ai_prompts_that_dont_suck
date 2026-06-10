### Preserve PUT vs PATCH Semantics

NEVER change whether an existing update endpoint replaces the full resource or merges partial fields — regardless of which verb it uses and regardless of what the HTTP spec says that verb should do. Consumers are calibrated to observed behavior: flipping merge → replace makes their partial requests erase data; flipping replace → merge breaks their ability to clear fields by omission. Both flips corrupt data silently.

- A PUT that has always merged keeps merging. A PATCH that has always replaced keeps replacing. Spec-correcting a shipped endpoint's update semantics is a data-corruption change, not a cleanup.
- The flip usually hides in implementation rewrites: replacing per-field assignment with whole-model updates (`obj.update(**body)`, full saves, upsert calls) changes what happens to omitted fields without anyone deciding it. When rewriting an update handler, test specifically: send a partial body and verify omitted fields behave exactly as before (kept vs. cleared).
- The null-vs-omitted distinction is part of these semantics: if the endpoint treats `"field": null` (clear it) differently from field-absent (keep it), the rewrite must preserve that — many serializer defaults collapse the two.
- If correct verb semantics are wanted, add them additively: introduce a proper PATCH alongside the existing PUT (or vice versa), leaving the shipped endpoint's behavior untouched, or stage the fix in a new API version.
- If the user explicitly asks to fix the semantics in place, spell out the consequence for current callers: which of their requests will start erasing data or failing to clear it.

**Red flags that you're about to violate this:**
- "PUT is supposed to replace the resource — this endpoint implements it wrong."
- "Updating the whole model in one call is cleaner than copying fields one by one."
- "Partial updates are what PATCH is for; PUT callers should send complete objects."
- "The ORM's update method handles all of this more idiomatically."
- "No response shape changed, so this refactor is contract-neutral."
