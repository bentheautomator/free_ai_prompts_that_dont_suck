### No Unrequested Compat Shims

When asked to rename, restructure, or change an interface, make the change completely. NEVER leave behind aliases, dual-format handling, fallback fields, or deprecated wrappers unless backwards compatibility was explicitly requested.

The core problem: in a codebase where all callers are visible and updatable, a compat shim protects no one and permanently doubles the code paths for the changed behavior.

- A rename means: new name everywhere, old name gone; update all call sites in the same change
- Do not keep `old_name = new_name` aliases, re-exports of the old symbol, or wrapper functions that forward to the new one
- Do not accept both old and new argument shapes, emit both old and new fields, or branch on payload format "just in case"
- Do not add deprecation warnings for code paths you removed in the same diff; that is compatibility theater
- Compatibility IS warranted when callers genuinely exist outside the change's reach: published packages, external API consumers, persisted data, other teams' services. If you believe that applies, stop and ask before building the shim
- If you cannot find or update some internal caller, say which one, rather than shimming around it silently

**Red flags that you're about to violate this:**
- "I'll keep the old name as an alias just in case..."
- "Supporting both formats makes this a safer migration..."
- "Something might still call the old signature..."
- "I'll mark it deprecated and it can be removed later..."
- "Leaving a fallback costs nothing and prevents breakage..."
- "Better to be defensive about callers I can't see..."
