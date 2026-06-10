---
title: Find the Bug, Don't Rewrite the Function
slug: find-the-bug-dont-rewrite-the-function
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI regenerating whole functions because locating the bug is harder"
---

# Find the Bug, Don't Rewrite the Function

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from replacing a buggy function wholesale because regenerating code is easier than locating a defect.

**[Copy-paste ready version](../../install/find-the-bug-dont-rewrite-the-function.md)** — just the instruction block, no explanation.

## The Problem

Ask an AI to fix a bug in a 60-line function and there's a good chance you get back a brand-new 60-line function. Not a fix — a replacement, freshly generated from the function's name and apparent purpose. This is the one debugging move that's uniquely cheap for a language model and uniquely expensive for you: generating plausible code is its core competence, while pinpointing a defect requires sustained reading. When locating the bug gets hard, regeneration is the path of least resistance dressed up as decisiveness.

What gets lost in the rewrite is everything the original code knew that its name doesn't say: the workaround for the upstream API's pagination quirk, the deliberate off-by-one for a legacy data format, the order of operations that matters for a reason documented only in a five-year-old commit message. The rewrite fixes the reported bug (maybe) and reintroduces three solved problems, none of which will surface until their edge cases recur in production.

And critically: a rewrite that "fixes" the bug teaches nobody anything. You don't know what the bug was. You can't check for the same mistake elsewhere. The defect was never found — it was demolished along with the building.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Find the Bug, Don't Rewrite the Function

NEVER fix a bug by regenerating the surrounding function, file, or module. Locate the specific defective lines and change only them.

A rewrite is not a fix; it's an admission that the bug was never found, plus the silent deletion of every lesson the old code had learned.

- Identify the defect at the line level before changing anything: which statement computes the wrong value or takes the wrong branch, and why
- The fix should be roughly proportional to the defect — a wrong condition is a one-line change, not a new function
- Treat every part of the existing code you don't understand as load-bearing: odd-looking special cases, "unnecessary" checks, and weird ordering are usually fossilized fixes for bugs that already happened once
- If you genuinely cannot locate the defect, say so and show your narrowing work; "I couldn't find it, so I rewrote it" is the worst available answer, not a fallback
- If the function truly deserves a rewrite (structure makes the defect class inevitable), make that case to the user as a separate proposal after the bug is found and named — never as a substitute for finding it
- After fixing, you should be able to state the bug in one sentence: "X was wrong because Y." If you can't, you haven't fixed it; you've replaced it

**Red flags that you're about to violate this:**
- "This function is convoluted; cleaner to rewrite it correctly..."
- "Rather than untangle this logic, I'll reimplement it from the spec..."
- "I'll rewrite it and the bug will be gone..." (which bug?)
- "These edge-case branches look like cruft I can drop..."
- "It's faster to regenerate than to trace through this..."
- Producing a diff where the entire function body changed for a single-symptom bug

---

## Why It Works

1. **It names the asymmetry.** Generation is the model's cheapest operation and reading is its most expensive; calling out "rewrite = couldn't find it" reframes the easy path as a confession rather than a flex.

2. **It declares unexplained code load-bearing by default.** The rewrite's worst damage comes from dropping fossilized edge-case fixes. Flipping the burden of proof ("weird means it survived something") protects exactly those lines.

3. **It imposes a proportionality check.** Defect-sized diffs are auditable; function-sized diffs hide whether the bug was even addressed. The size mismatch becomes a visible signal instead of a normal outcome.

4. **It requires the one-sentence bug statement.** "X was wrong because Y" can't be produced by regeneration; demanding it makes locating the defect non-optional.

## Origin

A date-bucketing function had an off-by-one for events landing exactly at midnight UTC. Asked to fix it, the assistant declared the function "overly complex" and rewrote it in half the lines. The midnight bug was indeed gone. So was the handling for DST transitions and a quirk in pre-2019 records, both of which had been bolted on after past incidents. The team spent the next two sprints re-fixing bugs they had already fixed years earlier, with the original implementations sitting right there in git history.
