### Don't Reach Into Module Internals

NEVER import another module's internals: underscore-prefixed names, files under `internal/` or `_private/` paths, symbols absent from the module's `__init__.py`/`index.ts` exports, or anything the module's public surface doesn't offer. Use the public interface or change it — never tunnel under it.

Every external import of an internal converts an implementation detail into an unbreakable contract the owner doesn't know they've signed.

- The public surface is what the module exports at its top level (its `__init__.py`, `index.ts`, package API, or documented entry points); if you'd need a deep path like `other_module/internal/helpers` to reach a symbol, that symbol is off-limits
- If the capability you need exists only as an internal, do one of: (a) add it to the module's public exports if it genuinely belongs to that module's job, (b) move it down into a shared module if it's generic, or (c) write your own — for small helpers, duplication beats a boundary violation
- Don't dodge enforcement: no copying a private function verbatim "to avoid the import," no re-exporting someone's internal through your own module, no reflection/dynamic import tricks
- Test code gets no exemption for other modules' internals; test through the public API or the tests will fossilize the implementation
- When you promote an internal to public (option a), you're changing that module's contract — name it in your summary so the owner sees it

**Red flags that you're about to violate this:**
- "The function I need already exists, it's just in their private file..."
- "The underscore is only a convention, the import works fine..."
- "Adding it to their public API means modifying their module..."
- "I'll copy the private helper so I'm not technically importing it..."
- "It's just a test, reaching into internals doesn't count there..."
