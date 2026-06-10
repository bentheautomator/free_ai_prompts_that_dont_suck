---
title: Don't Rewrite Whole Files for Small Edits
slug: dont-rewrite-whole-files
category: file-handling
tags: [universal, files, git]
works_with: all
severity: medium
one_liner: "Keeps a three-line fix from arriving as a 400-line reformatting diff"
---

# Don't Rewrite Whole Files for Small Edits

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents whole-file rewrites that bury a small change under hundreds of lines of incidental reformatting churn.

**[Copy-paste ready version](../../install/dont-rewrite-whole-files.md)** — just the instruction block, no explanation.

## The Problem

Asked to fix a three-line bug, an AI assistant regenerates the entire file from its internal representation and writes it back. The fix is in there, but so is everything else the regeneration "improved": requoted strings, rewrapped lines, reordered imports, normalized spacing, alphabetized object keys. The diff is 400 lines. The reviewer either reads all 400 (and resents it) or skims (and misses the one regenerated line that came back subtly different — a dropped default parameter, a changed string literal).

This is the most common way AI-authored PRs lose trust. A whole-file rewrite also destroys `git blame` for every untouched line, manufactures merge conflicts with every concurrent branch touching that file, and makes `git bisect` results meaningless for that region of history. Assistants do it because emitting a full file is easier than computing a minimal edit — the model's convenience, billed to the reviewer.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **A 400-line diff for a 3-line fix is a correctness risk, not a style issue.** Every regenerated line is unreviewed surface area; subtle regressions (dropped arguments, changed literals) hide precisely where nobody is looking.
2. **It preserves git's forensic tools.** `blame`, `bisect`, and conflict resolution all depend on untouched lines staying untouched; a rewrite poisons all three for the whole file.
3. **The `git diff --stat` check is mechanical and self-administered.** "Was my edit minimal?" stops being a judgment call and becomes a number you compare against the size of the task before anyone else sees the diff.

## Origin

A two-line validation fix in a 600-line Python module shipped as a full rewrite. The diff also silently changed a regex from lazy to greedy matching — not maliciously, just a regeneration artifact. Review skimmed the "formatting noise," the greedy regex matched too much in production, and the postmortem's root cause read: "the actual change was unreviewable by construction."
