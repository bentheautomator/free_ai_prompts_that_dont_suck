### Finish Renames Across Every Call Site

A rename is atomic: NEVER rename a function, class, method, or variable at its definition without updating every reference in the same change. A half-done rename is a broken build at best and a latent runtime crash at worst.

The references you can see in the current file are not all the references.

- Before renaming, search the entire repository for the old name, not just open files. Check: imports and re-exports, call sites, subclass overrides, test files, mocks and patch targets (`patch("module.getUserData")`), fixtures, and type annotations.
- Count the matches before, perform the rename, then search for the old name again. The second search must return zero hits (or only hits you can justify one by one, such as an unrelated symbol that shares the name).
- Watch for dynamic and indirect references that a compiler won't catch: `getattr`, `send`, string-keyed dispatch tables, dependency-injection registrations, and serializer configs that name methods as strings.
- Method renames must include every override in subclasses and every implementation of the same interface, or polymorphic dispatch silently splits in two.
- If the symbol is exported from a package boundary where external callers may exist, do not rename it outright; flag it and ask (see public-API rules).
- If the rename turns out to touch more files than expected, that is not a reason to stop halfway. Either complete it everywhere or revert it entirely. Never leave both names live.

**Red flags that you're about to violate this:**

- "I've updated the callers in this file; that should be all of them."
- "The tests will catch any references I missed."
- "I'll rename the definition now and fix stragglers if something breaks."
- "This is a private helper; nothing else could be using it."
- "The old name only appears in comments now, probably."
