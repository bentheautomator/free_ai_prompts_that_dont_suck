---
title: Use No-Clobber Flags for Mv and Cp
slug: use-no-clobber-flags-for-mv-and-cp
category: code-safety
tags: [universal, files, shell]
works_with: all
severity: high
one_liner: "AI silently overwriting destination files with mv and cp"
---

# Use No-Clobber Flags for Mv and Cp

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from destroying a destination file because mv and cp overwrite silently by default.

**[Copy-paste ready version](../../install/use-no-clobber-flags-for-mv-and-cp.md)** — just the instruction block, no explanation.

## The Problem

`mv report.pdf output/` succeeds whether or not `output/report.pdf` already existed. If it did, it's gone — replaced without a message, a prompt, or an exit code that hints anything was lost. `cp` behaves the same way. These are the only commonly used destructive defaults that even careful humans forget about, and AI assistants forget harder: they generate `mv` and `cp` constantly, as throwaway plumbing inside larger tasks, and never check whether the destination name is taken.

Bulk operations compound it. A rename loop — `for f in *.txt; do mv "$f" "${f%.txt}.md"; done` — can map two different sources onto one destination name, and the second silently eats the first. Moving a batch of files into a directory that already has same-named files replaces every one of them. The command output looks identical in the safe and destructive cases: nothing. That's the trap. Silence reads as success, and it also reads as "nothing was overwritten," and only one of those is guaranteed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Use No-Clobber Flags for Mv and Cp

NEVER assume a `mv` or `cp` destination is free. Both commands overwrite existing destination files silently — no prompt, no warning, no nonzero exit. Treat every move/copy as a potential overwrite until checked.

The core problem: silence from `mv`/`cp` means "command ran," not "nothing was destroyed." The destructive and safe cases look identical from the output.

- Default to no-clobber: `mv -n` / `cp -n` (or `mv -i` interactively). If a destination exists, you want to find out by the operation refusing, not by the file vanishing.
- Note the silent-skip tradeoff: with `-n` the source is NOT moved when the destination exists, and `mv -n` still exits 0. After a no-clobber move, verify the file landed (`ls` the destination, or check the source is gone).
- Check before batch moves: when moving N files into a directory, list the intersection first — do any destination names already exist?
- For bulk renames, verify the mapping is collision-free before executing: generate the old→new list, check the new names for duplicates (`... | sort | uniq -d`), then run.
- When overwriting is genuinely intended, say so explicitly and back up the destination first if it isn't trivially recoverable.
- On Linux, `mv --backup=numbered` preserves displaced files; use it when no-clobber would block a legitimate replace.

**Red flags that you're about to violate this:**
- "Quick mv to put this in the right folder..."
- "The destination directory should be empty..."
- "If something was overwritten, the command would have complained..."
- "The rename loop is mechanical, collisions can't happen..."
- "I'll sort out any conflicts after the move..."

---

## Why It Works

1. **It corrects the silence-equals-safety inference.** The AI reads empty output as "no side effects." Explicitly stating that overwrite and no-overwrite produce identical output removes the false signal it was relying on.

2. **It changes the failure direction.** With `-n`, a name collision becomes a skipped file you notice, instead of a destroyed file you don't. Errors of omission are recoverable; errors of destruction aren't.

3. **It treats bulk renames as a mapping problem.** Requiring a generated old→new list with a duplicate check converts "loop and hope" into a verifiable artifact before anything moves.

## Origin

Reorganizing a project's documents, an assistant moved a folder of monthly reports into an archive directory that already contained files with the same names — last year's reports, same naming scheme. Every old report was silently replaced by its newer namesake. The loss surfaced months later during an audit, when "March report" turned out to mean only one of the two Marches anyone needed.
