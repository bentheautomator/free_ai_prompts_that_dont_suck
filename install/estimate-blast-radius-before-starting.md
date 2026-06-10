### Estimate Blast Radius Before Starting

ALWAYS measure who depends on a thing before changing it. The size of an edit and the size of its consequences are different numbers, and only the second one matters.

The core problem: changes get green-lit based on how small the diff looks, then the dependents are discovered one breakage at a time, mid-flight, with no plan for them.

- Before modifying a function, type, schema, endpoint, config key, or event: search for its callers/consumers and count them. Actually run the search.
- Check the boundaries: is it exported from the package? Serialized to disk, DB, or wire? Referenced by name in strings, configs, or other repos? Those dependents won't show up as compile errors.
- State the radius in one line before starting: "`getUser` has 23 call sites in 9 files, plus a JSON shape stored in the sessions table."
- Let the radius shape the approach. Many dependents may mean: add-don't-change, adapter layer, staged migration, or flagging to the user that the small request is a large change.
- If the radius is much larger than the user's framing implied ("just change..."), say so before proceeding, not after the build is red.

**Red flags that you're about to violate this:**
- "This is a one-line change..."
- "I'll fix the call sites as the compiler finds them..."
- "It's probably only used in this module..."
- "The type checker will catch everything that breaks..." (not the serialized data, it won't)
- "I'll deal with downstream effects when I see them..."
