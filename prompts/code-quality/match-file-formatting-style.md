---
title: Match the File's Formatting Style
slug: match-file-formatting-style
category: code-quality
tags: [universal, style]
works_with: all
severity: medium
one_liner: "AI writing in its preferred formatting instead of the file's actual style"
---

# Match the File's Formatting Style

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from injecting its own formatting preferences into files that already have a consistent style.

**[Copy-paste ready version](../../install/match-file-formatting-style.md)** — just the instruction block, no explanation.

## The Problem

Drop an AI into a file that uses single quotes, no semicolons, and 2-space indentation, and there's a decent chance its additions arrive with double quotes, semicolons, and 4-space tabs — the model's house style, formed by training-data averages and applied with total confidence to a file that disagrees on every count. The new code works. It also looks like a ransom note assembled from two different magazines.

Where a formatter runs in CI, this is a build failure over quote marks — pure wasted cycle time. Where no formatter runs, the mixed style is permanent: diffs get noisier because edits near the AI's code keep flip-flopping styles, `git blame` gets muddier, and reviewers burn attention on mechanical inconsistency instead of logic. Indentation mismatches are the aggravated case — a tab-indented block pasted into a space-indented Python file isn't a style issue, it's a `TabError`, and in YAML it can silently change the document's structure.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Match the File's Formatting Style

ALWAYS write new code in the formatting style of the file it's going into — not the style you'd choose. You have formatting preferences from training averages; the file has formatting facts. Facts win.

**Before writing into any file, observe and match:**
- Indentation: spaces vs tabs, and the width — copy it exactly; in Python and YAML a mismatch is a syntax or structure error, not a style nit
- Quotes: single vs double vs backticks, and when each is used
- Semicolons (in languages where they're optional): present or absent, consistently
- Brace and spacing style: same-line vs next-line braces, spaces inside parens/brackets, trailing commas in multiline literals
- Line-length discipline: if the file wraps at ~80, don't write 140-character lines
- Blank-line rhythm between functions and logical sections

**Also:**
- If the project has a formatter config (`.prettierrc`, `.editorconfig`, `rustfmt.toml`, `pyproject.toml [tool.black]`), that config is the answer — follow it, and run the formatter on touched files if it's available
- Never "fix" the file's existing style to match your output; your output matches the file
- If the file is internally inconsistent, match the style of the code immediately surrounding your edit

**Red flags that you're about to violate this:**
- "I'll write this in standard style..."
- "Double quotes are more common, so..."
- "I'll use proper 4-space indentation here..." (in a 2-space file)
- "The formatter will normalize it anyway..." (unverified that one exists)
- "Adding semicolons is harmless..."
- Writing a block without having consciously noted the file's quote, indent, and semicolon choices

---

## Why It Works

1. **It names the source of the AI's preferences.** The model experiences its house style as "standard." Labeling it a training-data average strips the authority and reframes the file as the only standard in scope.

2. **It separates the syntax-error cases from the cosmetic ones.** Indentation in Python/YAML breaks code, not eyes. Distinguishing severity stops the AI from treating all of it as ignorable polish.

3. **It points at the config as ground truth.** When a formatter config exists, style stops being a judgment call. Directing the AI to read it converts preference-matching into fact-lookup.

4. **It blocks the reverse fix.** Given a conflict, models sometimes reformat *existing* lines to match their output — turning a style slip into a 200-line diff. Explicitly setting the direction of conformity prevents the noisier failure.

## Origin

A one-function addition to an unformatted legacy JavaScript file arrived in the AI's preferred style — double quotes and semicolons in a single-quote, no-semicolon file. The next three human edits each half-matched whichever style was nearest, and within a month the file was an even split. When the team finally ran Prettier over it, the reformat diff was 1,400 lines, `git blame` became archaeology, and two open feature branches on that file hit conflict walls. All of it traceable to one session that didn't look at the quote marks.
