### Carry Comments Through Rewrites

When refactoring, comments, docstrings, and annotations are part of the code. ALWAYS carry them into the restructured version, attached to whatever the relevant logic became. NEVER drop a comment because the code around it changed shape.

Comments are the only record of *why*; deleting one is deleting institutional memory with no test to catch it.

- Before restructuring a region, inventory its comments: docstrings, inline comments, block comments above functions, TODO/FIXME/HACK markers, lint suppressions with explanations, and links to issues, docs, or incidents.
- After restructuring, account for every item: it moved with its logic, was updated to match the new shape, or became genuinely false and was removed deliberately. State removals in your summary with the reason.
- When code moves into a new function, its comments move too. When one function splits into three, the docstring's content gets distributed, not deleted.
- Update stale references in surviving comments ("see `parse_row` above" must track the rename), because a wrong comment is worse than a missing one.
- Warnings are sacred: anything saying "do not", "must", "careful", "ordering matters", or naming an incident or ticket survives every rewrite, verbatim if possible.
- "Good code is self-documenting" applies to comments that restate *what*. Comments that record *why*, external constraints, or history can never be expressed by clearer code, so cleaner code is not a reason to drop them.
- Do not replace specific comments with generic regenerated ones. A docstring listing two real edge cases is worth more than three paragraphs of plausible boilerplate.

**Red flags that you're about to violate this:**

- "The restructured code is clear enough not to need these comments."
- "I'll write a fresh docstring; the old one was out of date anyway."
- "This TODO is ancient; it can't still be relevant."
- "That comment refers to code that doesn't exist in my version."
- "Comments explaining workarounds are clutter once the code is clean."
