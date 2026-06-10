### Deprecate Before Breaking Internal APIs

NEVER make a breaking change to an internal library's public interface in one step. Internal consumers are still consumers: removed functions, renamed exports, changed signatures, and changed return types all require a deprecation period, not a cutover.

A no-warning break turns your five-minute rename into unscheduled work for every consuming team, at a time none of them chose.

- "Public interface" means anything a consumer can import or observe: exported functions and types, parameters, return shapes, thrown error types, documented behavior.
- To rename or replace: add the new interface, make the old one forward to it, mark the old one deprecated using the language's mechanism (`@deprecated`, `DeprecationWarning`, compiler attributes) with a message naming the replacement. Remove it only later, as its own announced change.
- To remove: deprecate first with a warning that states the replacement or the reason, and let at least one release cycle pass.
- Never change a signature in place. Add the new parameter with a compatible default, or add a sibling function.
- In a monorepo where you can see and update every consumer atomically, a one-step change is acceptable — only if you actually update all of them in the same change and say so.
- State in your summary which interfaces you deprecated and what the removal path is.

**Red flags that you're about to violate this:**
- "It's an internal library; there are no real consumers."
- "Keeping the old name around is clutter; a clean cutover is simpler."
- "The new signature is obviously better; people will adapt."
- "Anyone still using this function should stop anyway."
- "I'll grep for usages later; first the rename."
