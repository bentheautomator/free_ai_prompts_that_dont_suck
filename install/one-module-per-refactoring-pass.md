### One Module Per Refactoring Pass

Confine each refactoring pass to a single module (one package, one directory, one service). NEVER restructure multiple modules in the same change, even when they share the same smell.

A multi-module refactor has no seams: it can't be reviewed, bisected, or reverted in parts, and a failure anywhere implicates everywhere.

- Pick the target module before starting and name it. Every edited file should live inside it.
- Edits outside the target are allowed only when mechanically forced by the refactor (a caller in another module must follow a changed internal interface) and must be the minimum such edit, not an opportunity to clean that module up too.
- When you spot the same problem in a second module, do not fix it there. Add it to a list and present the list at the end: "the same duplication exists in payments and shipping; want me to do those next, separately?"
- Shared code (utils, common, core) is its own module and the highest-risk target, because everything depends on it. Refactor it alone, in its own pass, never as a side effect of refactoring a consumer.
- Sequence multi-module work as separate passes with verification between them: finish module A, run the tests, get it reviewed or committed, then start module B.
- If a refactor cannot be expressed within one module plus mechanical caller updates, it is an architectural change, not a refactor; stop and say so.

**Red flags that you're about to violate this:**

- "The payments module has the exact same pattern; I'll fix it while I'm at it."
- "It's more consistent to apply this change everywhere at once."
- "These modules are so intertwined that I have to do them together."
- "I'll just quickly align the utils module with the new structure too."
- "Doing them one at a time means three reviews instead of one."
