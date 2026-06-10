### No New Package for Stdlib Tasks

NEVER add a dependency for functionality the standard library or built-in runtime APIs already provide. A dependency is a liability you adopt forever, not a feature you gain once.

Before any install command, ask: can the standard library do this in under ~20 lines? If yes, write those lines.

- Check the stdlib first: `fetch` instead of axios/node-fetch, `crypto.randomUUID()` instead of uuid, `structuredClone` instead of lodash.cloneDeep, `fs.rm` instead of rimraf, `Array.prototype.flat` instead of array-flatten, Python's `pathlib`/`json`/`urllib`/`dataclasses` instead of their package equivalents.
- If you only need one function from a utility library, write that function. `isEmpty`, `debounce`, `chunk`, and `pick` are each under ten lines.
- It is acceptable to add a dependency for genuinely hard problems: timezone math, parsers, cryptography you should not hand-roll, protocol implementations. The bar is "nontrivial to implement correctly," not "exists on npm."
- If the project already depends on a utility library, use it — do not write a parallel implementation. This rule governs adding NEW dependencies only.
- When you decide a new dependency is justified, say so explicitly and name what the stdlib lacks.

**Red flags that you're about to violate this:**
- "There's probably a package for this..."
- "Lodash is what most tutorials use here."
- "Installing it is faster than writing the helper."
- "It's a tiny package, it won't hurt."
- "axios has a nicer API than fetch."
- "Everyone depends on this anyway."
