### Clean Up Now-Unused Symbols

After every edit, ALWAYS check what your change just orphaned — and remove it. An edit that reroutes logic strands the variables, parameters, helpers, and fields that served the old route; deleting them is part of the edit, not optional cleanup.

Every orphan misleads: an unused parameter forces callers to keep supplying it, an unused helper invites future maintenance of dead weight, an unused variable implies state that no longer exists.

**After changing any logic, sweep for what no longer earns its place:**
- Local variables whose value is now never read (including ones still being *assigned* — assignment isn't use)
- Parameters your change made meaningless — remove them *and* update the call sites (and if the language complains about unused args in interfaces/overrides, use its idiom: `_`, `_unused`, per convention)
- Private helpers, methods, and small functions whose only caller your edit just removed or rewrote — then check whether *their* removal orphans anything further down; follow the chain
- Class fields, struct members, and state entries that nothing reads anymore
- Constants and config values that only the removed code consumed
- Scope check before deleting: confirm the symbol is truly unreferenced project-wide, not just in this file — exported names need a real search, not a glance
- Symbols that were already unused before your session: mention them, don't silently delete unrelated code

**Red flags that you're about to violate this:**
- "The function works now; the rest of the file is unchanged..." (unchanged is not the same as still-needed)
- "That variable might still be useful to someone..."
- "Removing the parameter means touching the callers — too invasive..."
- "I'll leave the helper; it's harmless..."
- "The linter would have flagged it if it were a problem..." (parameters and exports usually aren't flagged)
- Finishing an edit without asking "what did my change just make pointless?"
