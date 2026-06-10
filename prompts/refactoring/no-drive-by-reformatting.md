---
title: No Drive-By Reformatting
slug: no-drive-by-reformatting
category: refactoring
tags: [universal, refactoring]
works_with: all
severity: medium
one_liner: "Stops whole-file restyling that buries a small refactor in whitespace noise"
---

# No Drive-By Reformatting

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from reformatting, restyling, and reflowing an entire file while refactoring one part of it.

**[Copy-paste ready version](../../install/no-drive-by-reformatting.md)** — just the instruction block, no explanation.

## The Problem

A 12-line extract-method refactor arrives as a 600-line diff because the assistant also normalized quotes, reflowed every long line, alphabetized the imports, converted indentation, and restyled all the docstrings to its preferred convention. The actual change is in there somewhere, statistically. The reviewer must now find twelve meaningful lines inside six hundred cosmetic ones, which in practice means they stop looking, approve it, and whatever bug rode along in the twelve lines ships unexamined. The noise doesn't just waste review time; it provides cover.

The damage outlives the review. `git blame` on every restyled line now points at the reformatting commit instead of the commit that explains the logic, and future branches that touch the file inherit merge conflicts against hundreds of lines that didn't meaningfully change. Models do this because they generate code in their own house style; reproducing the file's existing style takes active effort, and "while I'm here, fix the formatting" feels like free value-add rather than what it is: vandalizing the diff.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No Drive-By Reformatting

When refactoring, change only the lines the refactor requires. NEVER reformat, restyle, or "tidy" untouched code in the same change: no quote normalization, import reordering, line reflowing, whitespace fixes, or docstring restyling outside the edited region.

A diff is a signal; formatting churn is noise that hides your actual change from review and rewrites blame history for lines you never meaningfully touched.

- Match the file's existing style in the lines you do edit, even when it differs from your preference or the language's common convention. Consistency with the file beats consistency with the universe.
- Leave formatting you disagree with alone: tabs in a spaces world, single quotes in a double-quote file, 100-character lines, unsorted imports. Not your change, not your problem today.
- New lines you write inside an existing function adopt the surrounding indentation, quote style, and naming conventions verbatim.
- If the project has an auto-formatter configured (prettier, black, gofmt), run it the way the project runs it, on the files you changed, and accept its output. Do not hand-format beyond it, and do not run it with different settings.
- If a file's formatting genuinely needs fixing, propose a dedicated formatting-only change, clearly labeled, containing zero logic edits. Pure-noise diffs are reviewable in seconds precisely because they promise no signal.
- Quick self-check before finishing: for each hunk in your diff, can you name the refactoring step that required it? Hunks that exist "because it looked better" get reverted.

**Red flags that you're about to violate this:**

- "While I'm in this file, I'll clean up the formatting too."
- "Mixed quote styles in one file is just wrong; I'll normalize them."
- "Sorting the imports is harmless."
- "The reviewer will thank me for making the whole file consistent."
- "My editor reformatted on save, but the changes are all cosmetic anyway."

---

## Why It Works

1. **It reframes the diff as a communication channel.** The model thinks of reformatting as added value; "noise that hides your change and provides cover for bugs" names the actual cost in the currency that matters, review attention.
2. **"Match the file, not the universe" resolves the style conflict in advance.** The model's restyling impulse comes from a genuine clash between the file's style and its trained preferences; ruling that the file wins removes the decision that goes wrong.
3. **The per-hunk justification is a mechanical filter.** "Name the refactoring step that required this hunk" catches cosmetic drift after the fact, including the editor-reformatted-on-save variety the model didn't consciously choose.
4. **The dedicated formatting-change outlet keeps real cleanups possible.** Formatting fixes are legitimate work; isolating them into zero-logic diffs makes them safe instead of forbidden.

## Origin

A two-function extraction in a payment-processing file arrived as a 700-line diff after the assistant normalized the entire file's string quoting and reflowed comments. Review fatigue did its thing, and the diff was approved with a transposed argument pair in one of the extracted calls, plainly visible in the twelve lines that mattered, invisible inside seven hundred. The bug double-charged a small set of customers before the next release rolled it back.
