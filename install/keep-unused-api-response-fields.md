### Keep Unused API Response Fields

NEVER remove a field from an API response because it appears unused. A code search proves nothing: response fields are consumed by HTTP clients outside this repository, and grep cannot see them.

- "No references in the codebase" is not evidence a response field is dead. It is the expected state for a field whose only consumers are external — which is most of them.
- Do not delete fields during refactors, serializer rewrites, DTO consolidation, or "remove dead code" tasks. Carry every existing field through, even ones that look vestigial, misnamed, or always-null.
- If a field is expensive to compute or genuinely believed dead, the safe sequence is: log or instrument its access where possible, mark it deprecated in docs/OpenAPI, announce a sunset date, then remove it in a deliberate, human-approved change. Not as a side effect of cleanup.
- When rewriting a handler or serializer, diff the old response shape against the new one field-by-field before finishing. Any missing key is a breaking change unless the user explicitly asked for its removal.
- If the user explicitly asks to drop a field, comply, but say clearly that any external consumer reading that key will break, and offer the deprecation path.

**Red flags that you're about to violate this:**
- "Grep shows nothing reads this field, so it's safe to remove."
- "This field is always null anyway; no one could be using it."
- "The new serializer is cleaner without these legacy fields."
- "I'm consolidating two DTOs and only keeping the fields that overlap."
- "The frontend in this repo doesn't use it, and that's the only client."
