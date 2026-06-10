---
title: Respect Trailing Newline Discipline
slug: respect-trailing-newlines
category: file-handling
tags: [universal, files, git]
works_with: all
severity: medium
one_liner: "Stops edits from adding or dropping the final newline and dirtying diffs"
---

# Respect Trailing Newline Discipline

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents edits from flipping a file's final-newline state, which dirties diffs, trips linters, and breaks a surprising number of text tools.

**[Copy-paste ready version](../../install/respect-trailing-newlines.md)** — just the instruction block, no explanation.

## The Problem

The last byte of a text file is a policy decision, and an AI assistant that rewrites a file makes that decision by accident. Drop the trailing newline and git decorates the diff with `\ No newline at end of file`, the last line shows as modified even though only its invisible terminator changed, and POSIX-line-oriented tools start misbehaving: `wc -l` undercounts, `read` in a shell loop drops the final line, `cat a.txt b.txt` glues the last line of one file to the first of the next. Add a trailing newline where the project deliberately omits one (some fixtures, some golden files, files compared byte-for-byte in tests) and snapshot tests fail on a "no-op" edit.

Either flip also picks a fight with the repo's tooling. Most projects enforce final newlines via `.editorconfig` (`insert_final_newline`), Prettier, or a linter rule — so an assistant that strips one creates a CI failure, and one that "fixes" newlines across a file it was merely visiting creates diff churn. The terminator of the last line is content. It just doesn't render.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Respect Trailing Newline Discipline

Preserve each file's final-newline state exactly, unless changing it is the task. When creating files, end text files with exactly one newline.

The last byte is invisible in every rendered view and visible to git, linters, snapshot tests, and every line-oriented Unix tool.

- When editing the last line of a file, reproduce its terminator state: if the file ended with a newline, it still does; if it didn't, it still doesn't. `tail -c 1 <path> | xxd` settles any doubt.
- Watch the diff: a `\ No newline at end of file` marker appearing in (or disappearing from) `git diff` on a file where you didn't intend to touch the ending means you flipped it. Fix before finishing.
- New text files: one trailing newline, no more. Multiple blank lines at EOF are churn bait for formatters.
- Honor project config: if `.editorconfig` sets `insert_final_newline` or Prettier governs the file, follow it for new content but still don't mass-fix existing files you weren't asked to touch.
- Files compared byte-for-byte — golden files, snapshots, fixtures with `expected` in the name — are exact artifacts. Never "normalize" their endings; you'll fail the very tests they exist for.
- Shell heredocs and `printf`-composed files are easy to get wrong by one `\n`. Verify the last byte when composing files that other tools parse.

**Red flags that you're about to violate this:**

- "A missing final newline is a mistake; I'll fix it while I'm here."
- "That diff marker about no newline is noise."
- "One newline, two newlines, whatever ends the file."
- "Snapshot files are text like any other text."
- "The file looks identical, so it is identical."

---

## Why It Works

1. **It names the concrete tool breakage** — `wc -l`, shell `read` loops, `cat` concatenation — turning "trailing newlines matter" from etiquette into a list of things that actually malfunction.
2. **The git diff marker is a built-in detector.** `\ No newline at end of file` appearing unexpectedly is unambiguous, free, and visible in the assistant's own workflow at exactly the right moment.
3. **The golden-file carve-out prevents the well-intentioned variant**, where "fixing" a fixture's ending breaks byte-exact comparisons and sends someone debugging a test that was never wrong.

## Origin

A one-word change to the last line of a Kubernetes manifest also dropped its trailing newline. The GitOps differ flagged the resource as changed on every sync cycle thereafter, paging the platform team with phantom drift until someone diffed the bytes instead of the text and found the only real difference was the file's final character no longer existing.
