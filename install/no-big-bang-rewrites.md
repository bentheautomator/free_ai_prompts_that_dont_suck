### No Big-Bang Rewrites

NEVER refactor by rewriting a file or module from scratch. ALWAYS decompose the refactor into a sequence of small, independently verifiable transformations, and apply them one at a time.

Wholesale rewrites silently drop edge cases, workarounds, and fixes that took years to accumulate. A pile of small mechanical steps preserves them; a regeneration does not.

- Before touching code, list the planned steps (e.g. "1. extract validation into `validate_order`, 2. replace the three duplicated blocks with calls to it, 3. rename `tmp` to `pending_orders`"). Each step should be a named, recognizable transformation: extract, inline, rename, move.
- Each step must leave the code compiling and the tests passing. If a step can't, it's two steps.
- Prefer the smallest diff that achieves each step. If your diff for one step exceeds roughly 50 changed lines, stop and split it.
- If the code is genuinely beyond incremental repair, say so and ask whether the user wants a rewrite. A rewrite is a different task with different risks, and it requires explicit sign-off. Never silently upgrade "refactor" into "rewrite."
- After each step, re-read the diff and confirm no behavior changed: same inputs, same outputs, same side effects, same errors.

**Red flags that you're about to violate this:**

- "Honestly, it's easier to rewrite this file from scratch."
- "The structure is so tangled that incremental changes won't help."
- "I'll rewrite it carefully and keep all the behavior, basically."
- "Most of this code is doing the same thing anyway."
- "A clean-slate version will be much easier to review."
- "I'll just restructure everything in one pass to save time."

**Output checkpoint:** Before submitting a refactor, confirm you can name each transformation you applied. If the honest answer is "I rewrote it," start over.
