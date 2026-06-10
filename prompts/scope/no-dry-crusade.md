---
title: No DRY Crusade
slug: no-dry-crusade
category: scope
tags: [universal, scope, focus]
works_with: all
severity: medium
one_liner: "AI deduplicating repeated code into shared abstractions mid-task"
---

# No DRY Crusade

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from extracting shared abstractions out of duplicated code it noticed while doing something else.

**[Copy-paste ready version](../../install/no-dry-crusade.md)** — just the instruction block, no explanation.

## The Problem

While implementing your feature, the AI spots that two files contain similar-looking five-line blocks. It cannot leave this alone. Out comes a shared helper, both sites get rewritten to call it, and the diff for "add date filtering to the orders page" now refactors the invoices page too. The duplication offended; the crusade followed.

The problem is that textual similarity isn't semantic identity. Two blocks that look alike today may be alike by coincidence — serving different domains, owned by different teams, destined to diverge. Merging them welds those futures together: the next person to change invoice formatting now changes order formatting too, unless they notice the shared helper and add a parameter, which is how a five-line helper grows four flags and a mode argument. The wrong abstraction is famously costlier than the duplication it replaced, and an AI gluing code together mid-task, without knowing why the two copies exist, is maximally positioned to build the wrong one.

There's also the simple scope arithmetic: the deduplication rewrote a file the task had no reason to touch, with all the usual costs — wider review, merge conflicts, blame churn — purchased to save five lines that were not hurting anyone that day.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### No DRY Crusade

Leave duplicated code duplicated unless deduplication is the task. NEVER extract shared abstractions from similar-looking code you encountered while doing something else.

The core problem: lookalike code may be alike by coincidence, and merging it welds unrelated call sites together so they can only change in lockstep, which is costlier than the duplication ever was.

- Similar blocks in code you pass through stay as they are, even near-identical ones
- If your task requires logic that already exists somewhere, calling the existing code is right; rewriting other call sites to share something new is not
- When writing new code, duplicating a small existing pattern is acceptable; do not restructure the original to share with your addition
- Never merge code across module, domain, or team boundaries on your own initiative; those copies often differ for reasons that aren't visible in the text
- Deduplication done as an actual task needs the abstraction to be semantic (same meaning, same reason to change), not just textual (same characters); three coincidentally similar blocks deserve three blocks
- Noticed significant duplication? One sentence: "Files A and B have nearly identical X logic; want that consolidated separately?" Then drop it

**Red flags that you're about to violate this:**
- "This is copy-pasted in two places, I'll DRY it up..."
- "I need this logic anyway, so I'll extract it and update both sites..."
- "Duplication is technical debt, removing it adds value..."
- "A shared helper here prevents these from drifting apart..."
- "While touching this file, I'll consolidate the repeated blocks..."

---

## Why It Works

1. **It distinguishes textual from semantic duplication.** The AI matches on characters; naming the difference (same text vs. same reason to change) gives it the concept that makes "leave it alone" principled rather than lazy.

2. **It flips "prevents drift" into "prevents divergence."** The AI sees future drift as the danger; pointing out that the copies may need to diverge reframes the weld as the risk, not the safeguard.

3. **It permits using without restructuring.** The legitimate case (calling existing code) is explicitly separated from the creep case (rewriting other sites), so the rule doesn't push the AI into reinventing what exists.

4. **It respects ownership boundaries it can't see.** Cross-domain copies often encode organizational reality; making boundaries an explicit stop condition covers the cases where the AI's code-level view is most misleading.

## Origin

Two teams each had a near-identical discount calculation, which an assistant unified into one shared function while adding an unrelated field for one of them. The copies were similar because one had been forked from the other deliberately, ahead of a regulatory change that applied to only one market. When that change landed, an engineer updated "the" discount function and silently changed pricing in the other market for four days. Receipts were wrong, finance reconciled by hand, and the shared helper was re-forked into two copies, which is where it had started.
