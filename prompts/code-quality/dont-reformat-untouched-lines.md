---
title: Don't Reformat Untouched Lines
slug: dont-reformat-untouched-lines
category: code-quality
tags: [universal, diffs, edits]
works_with: all
severity: medium
one_liner: "AI burying a 3-line change inside a 300-line cosmetic rewrite"
---

# Don't Reformat Untouched Lines

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents AI from rewriting and reformatting code it wasn't asked to touch, drowning the real change in noise.

**[Copy-paste ready version](../../install/dont-reformat-untouched-lines.md)** — just the instruction block, no explanation.

## The Problem

You ask for a null check in one function. The diff comes back 280 lines: the null check is in there somewhere, along with requoted strings throughout the file, reordered object keys, rewrapped comments, renamed loop variables, and whitespace "normalization" — none requested, all generated because the AI regenerated the whole file from its own stylistic distribution instead of surgically editing it. Models that emit full files do this structurally; even edit-based assistants drift into "while I'm here" polishing.

The noise is not free. Review attention is the scarcest resource in the pipeline, and a reviewer staring at 280 changed lines to find 3 meaningful ones will either spend twenty minutes or — far more likely — skim, which is how the *actual* change ships unreviewed. `git blame` on every touched line now points at "add null check," destroying the archaeology developers rely on to understand why code is the way it is. Concurrent branches touching the same file hit merge conflicts against pure cosmetics. And buried among the "harmless" reformats, regenerated lines sometimes differ *behaviorally* — a subtly changed regex, a reordered condition — invisible precisely because they're camouflaged in noise everyone has agreed to ignore.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Reformat Untouched Lines

ALWAYS keep your diff to the lines the task requires. NEVER reformat, restyle, reorder, or "improve" code you weren't asked to change. The diff IS the deliverable — a 3-line fix must produce a 3-line diff, not a 300-line one with a fix hidden inside.

Every gratuitous changed line costs review attention, pollutes `git blame`, and creates merge conflicts — and noisy diffs are where unintended behavioral changes hide from review.

**Rules:**
- Edit surgically: change the lines that implement the request, plus only what those changes structurally force (an added import, an adjusted indent level around a new block)
- Never requote strings, reorder keys/imports/members, rewrap lines, rename locals, convert syntax (`function`→arrow, `%`→f-string), or fix unrelated style on lines the task doesn't touch — even if the file's style offends you
- If you regenerate a full file for tooling reasons, reproduce every untouched line *exactly* — byte for byte. Untouched lines that differ are a failure, not a bonus
- Spotted something genuinely worth fixing nearby (a real bug, not a style nit)? Mention it in your summary and offer to fix it separately. Don't fold it in silently
- If a formatter is configured and runs on save/commit in this project, formatting your *touched* lines per the config is correct; running it over the whole file when the file wasn't previously formatted is the same noise with extra steps
- Before presenting your change, look at the diff: can you justify every changed line by pointing at the request? Lines you can't justify get reverted

**Red flags that you're about to violate this:**
- "While I'm in this file, I'll tidy up..."
- "I standardized the formatting as I went..."
- "These improvements were too small to mention..."
- "I rewrote the file with the fix included..." (and the other 290 lines?)
- "The reviewer will appreciate the cleanup..." (the reviewer must now review it)
- A diff dramatically larger than the change you were asked to make

---

## Why It Works

1. **It names the diff as the deliverable.** The AI optimizes the resulting file, treating the diff as incidental exhaust. Reframing the diff as the product — the thing humans review, merge, and blame — makes its size a quality metric the model will minimize.

2. **It demands byte-exact reproduction in regeneration.** Full-file rewrites are where drift sneaks in. "Untouched lines must match byte for byte" converts vague restraint into a checkable invariant.

3. **It gives the improvement instinct an outlet.** "Mention it and offer" preserves the genuinely useful observations while stripping them of their ability to contaminate the current diff. Outlawed instincts leak; rerouted ones don't.

4. **It ends with a per-line justification test.** "Point from each changed line to the request" is a concrete final audit that catches the lines no deliberate decision produced — which, in regenerated files, is most of the noise.

## Origin

A two-line timezone fix arrived as a 340-line diff — the AI had regenerated the file, requoting and rewrapping everything. The reviewer, facing a wall of green and red over a "trivial fix," approved on skim. Among the cosmetic changes, one regenerated line had reordered a date comparison in a way that wasn't cosmetic at all. The regression shipped, took a week to bisect — the bisect landed on a commit titled "fix timezone handling," which everyone agreed couldn't be it — and the team's new diff-size rule was written the same afternoon.
