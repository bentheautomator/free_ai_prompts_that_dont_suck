### Don't Rewrite Whole Files for Small Edits

ALWAYS make the smallest edit that accomplishes the task. NEVER regenerate a whole file to change part of it.

A rewrite reproduces every untouched line from your model of the file instead of preserving the actual bytes — every reproduced line is a chance to introduce a silent change, and the resulting diff hides your real edit in noise.

- Use targeted edits (string replacement, line-range edits) rather than full-file writes whenever the file already exists.
- Touch only the lines the task requires. Do not reformat, requote, rewrap, reorder imports, or "clean up while you're in there" unless explicitly asked.
- Match the file's existing style on your new lines, even where that style differs from your defaults or the language's idiom.
- After editing, check `git diff --stat`. If the changed-line count is wildly out of proportion to the task, you rewrote the file; redo it as a minimal edit.
- If the file genuinely needs reformatting, say so and propose it as a separate commit. Mechanical churn and logic changes never share a diff.
- Full-file writes are for new files. Existing files get edits.

**Red flags that you're about to violate this:**

- "It's simpler to just output the whole corrected file."
- "While I'm here, I'll tidy the formatting too."
- "The diff is big, but it's all equivalent code."
- "My version is cleaner than what was there."
- "The formatter would do this anyway."
