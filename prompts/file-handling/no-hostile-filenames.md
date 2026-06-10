---
title: Don't Create Hostile Filenames
slug: no-hostile-filenames
category: file-handling
tags: [universal, files, shell]
works_with: all
severity: high
one_liner: "Stops filenames with spaces and shell metacharacters from breaking scripts"
---

# Don't Create Hostile Filenames

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents creation of filenames containing spaces, shell metacharacters, or platform-forbidden characters that break scripts, builds, and checkouts.

**[Copy-paste ready version](../../install/no-hostile-filenames.md)** — just the instruction block, no explanation.

## The Problem

An assistant names a report `Test Results (final).md` or a fixture `user's data.json`, and every unquoted shell reference to it in the repo's scripts becomes a time bomb. `for f in $(ls)` splits the name into three arguments. The parentheses are syntax in several shells. The apostrophe terminates single-quoted strings in someone's Makefile. The file itself is fine; the ecosystem of scripts, CI steps, and one-liners around it — much of which was written assuming sane names, because every name in the repo was sane until now — starts failing in ways that point everywhere except the filename.

Cross-platform constraints stack on top. Windows forbids `: * ? " < > |` in names, plus reserved names like `CON`, `PRN`, `aux.ts`, and names ending in a dot or space — a checked-in file with any of these makes the repo unclonable on Windows, which is a spectacular failure mode for one file. Leading dashes (`-output.txt`) get parsed as flags by most tools. Unicode lookalikes and non-breaking spaces are unfindable by typing. Assistants generate these names because they title files like prose.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Create Hostile Filenames

ALWAYS name files using only lowercase letters, digits, hyphens, underscores, and dots: `test-results-final.md`, not `Test Results (final).md`.

A filename is an identifier consumed by shells, build tools, globs, and URLs. Every character outside the safe set is a parsing hazard in some tool the repo already uses.

- No spaces. They split words in every unquoted shell context: `$(ls)` loops, xargs without `-0`, Makefile prerequisites (which cannot portably contain spaces at all).
- No shell metacharacters: `( ) ' " ` $ & ; ! * ? [ ] < > |` — each is syntax somewhere.
- No Windows-forbidden characters (`: * ? " < > |`), no reserved basenames (`CON`, `PRN`, `NUL`, `COM1`, `aux` — even with an extension), no trailing dot or space. One such file makes the repo fail to check out on Windows.
- No leading dash (`-f.txt` is a flag to most tools) and no leading/trailing whitespace or non-breaking spaces.
- Match the directory's existing convention (kebab-case vs snake_case) rather than introducing a second style.
- These rules cover files you create or rename. Existing hostile names are a cleanup task to flag, not silently fix — references break when names change.

**Red flags that you're about to violate this:**

- "A space makes the name more readable."
- "Parentheses distinguish the version nicely."
- "It's just a doc, no script will ever touch it." (Backup scripts, `find`, and CI artifact globs touch everything.)
- "Windows reserved names are ancient history." (They're enforced in current Windows.)
- "I'll quote it properly everywhere I use it." (You don't control everywhere.)

---

## Why It Works

1. **It treats filenames as identifiers, not prose** — the correct mental model, since names are consumed far more often by tools than read by humans.
2. **The Windows reserved-name clause prevents the worst single-file failure available:** a repo that errors on `git checkout` for an entire OS's worth of contributors, caused by one innocently named `aux.ts`.
3. **"You don't control everywhere" is the load-bearing insight.** Perfect quoting at creation time does nothing for the unquoted `for f in $(ls)` already sitting in a five-year-old maintenance script.

## Origin

A generated test fixture named `results (run 2).json` sat harmlessly for a month until a cleanup script doing `for f in $(find fixtures -name '*.json')` split the name into shrapnel and `rm`'d a file literally named `(run`. CI went red on a missing-file error for an artifact nobody had ever created on purpose, and the investigation took longer than the fix: rename the fixture.
