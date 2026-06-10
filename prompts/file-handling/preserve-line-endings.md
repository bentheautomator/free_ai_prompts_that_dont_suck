---
title: Preserve Line Endings When Editing
slug: preserve-line-endings
category: file-handling
tags: [universal, files, windows]
works_with: all
severity: high
one_liner: "Stops one-line edits from flipping CRLF/LF across the entire file"
---

# Preserve Line Endings When Editing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a single-line edit from silently rewriting every line ending in the file, turning a one-line diff into a 2,000-line diff.

**[Copy-paste ready version](../../install/preserve-line-endings.md)** — just the instruction block, no explanation.

## The Problem

An AI assistant reads a file, normalizes it to LF in memory (or to whatever its tooling prefers), changes one line, and writes the whole thing back. The fix is one line; the diff is every line in the file, because every `\r\n` became `\n` or vice versa. Git shows the entire file as modified. `git blame` is destroyed for every line. The reviewer can no longer see what actually changed without `-w`-adjacent gymnastics that don't even apply, because line endings aren't whitespace flags catch by default.

This hits hardest in mixed-platform repos: a Windows-authored `.bat` file, a `.sln`, a CSV exported from Excel, or a repo with `.gitattributes` rules that the assistant's write path bypasses. Some of these aren't cosmetic — a `.bat` or `.cmd` file with bare LF endings can misbehave under `cmd.exe` (labels and multi-line constructs break), and a shell script with CRLF endings dies with `/bin/bash^M: bad interpreter`. The assistant did it because its read/write pipeline treats line endings as an implementation detail. They are file content.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Preserve Line Endings When Editing

NEVER change a file's line endings unless changing line endings is the explicit task. An edit to line 40 must leave the line endings of lines 1 through 39 and 41 onward byte-identical.

Line endings are invisible in most views but fully visible to git, parsers, and interpreters. Normalizing them as a side effect turns a one-line fix into a whole-file diff and can break scripts outright.

- Before editing, detect what the file uses: `file <path>` or `grep -c $'\r' <path>`. Match it.
- If the file is CRLF, your new or edited lines must also be CRLF. Do not write LF lines into a CRLF file "because the diff will be normalized anyway" — check `.gitattributes` before assuming that.
- Shell scripts (`.sh`), shebang'd files, and Makefiles must stay LF. Windows batch files (`.bat`, `.cmd`) and some `.sln`/`.csproj` tooling expect CRLF. When creating a new file, follow the platform convention of its consumers, then `.gitattributes`, then the repo majority, in that order.
- After editing, verify the diff: if `git diff --stat` shows the whole file changed for a small edit, you almost certainly flipped line endings. Fix it before moving on, not after the user notices.
- A file with mixed line endings is suspicious but not yours to clean. Preserve the mix unless asked.

**Red flags that you're about to violate this:**

- "I'll normalize to LF while I'm in here; CRLF is legacy anyway."
- "The diff shows every line changed, but my edit is in there somewhere, so it's fine."
- "Git will sort out line endings on commit."
- "It's easier to rewrite the file with consistent endings than match the existing ones."
- "Nobody can see line endings, so nobody will care."

---

## Why It Works

1. **A whole-file diff for a one-line fix is a correctness risk, not a style issue.** Reviewers approve diffs they can read; a 2,000-line ending flip hides the real change and anything else that snuck in with it.
2. **It names the executable failure modes** (`bad interpreter` on CRLF shell scripts, broken `cmd.exe` labels on LF batch files), so the rule reads as "this breaks builds," not "this offends taste."
3. **The post-edit `git diff --stat` check is mechanical.** "Did I preserve endings?" is unverifiable by feel; "does the stat line match the size of my edit?" takes two seconds and catches the failure every time.

## Origin

A one-character typo fix in a 1,400-line PowerShell deployment script arrived as a diff touching all 1,400 lines. The reviewer approved it after skimming, missing that the assistant had also "helpfully" reordered two parameters mid-rewrite. The reorder broke the deployment; the blame trail for the entire script now pointed at a typo fix.
