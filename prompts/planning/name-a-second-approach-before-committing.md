---
title: Name a Second Approach Before Committing
slug: name-a-second-approach-before-committing
category: planning
tags: [universal, planning]
works_with: all
severity: medium
one_liner: "The first idea wins by default because no second idea was ever allowed to form"
---

# Name a Second Approach Before Committing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents anchoring on the first viable approach without ever considering whether it was the right one.

**[Copy-paste ready version](../../install/name-a-second-approach-before-committing.md)** — just the instruction block, no explanation.

## The Problem

The first approach an assistant generates isn't chosen — it's *emitted*. It's whatever completion the task description most strongly evokes, and the moment it exists it becomes the anchor: all subsequent thinking elaborates it, plans around it, defends it. Ask why this approach and you'll get a justification generated after the fact. At no point did a second option get compared and lose; there was never a comparison, only a first impression with a plan attached.

Sometimes the first emission is right; common problems evoke good defaults. But it's systematically wrong in predictable places — when the task resembles a common pattern superficially but differs in a load-bearing detail, or when the codebase has constraints the generic solution ignores. Without an alternative on the table, there's nothing to check the anchor against, and its weaknesses have no contrast to show up against. A single option always looks reasonable. That's a fact about having one option, not about the option.

The fix is mechanical: before committing to any non-trivial approach, generate one genuinely different alternative and state in a sentence why the chosen one beats it. Thirty seconds. Most of the time the first idea survives — now as a decision instead of a reflex. The remaining times, the better second idea exists only because the rule forced it into the room.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Name a Second Approach Before Committing

NEVER commit to a non-trivial approach without naming one real alternative and saying why the chosen approach beats it. An unopposed option always looks reasonable — that's a property of being unopposed, not of being right.

The core problem: the first idea is an emission, not a decision; once it exists, all further thought elaborates it, and no comparison ever happens unless one is forced.

- Before planning any significant design decision, write one sentence per option: "A: poll the status endpoint. B: subscribe to the webhook. Choosing B because polling at our volume hits rate limits."
- The alternative must be genuinely different — a different mechanism or structure, not the same idea with different naming. A strawman alternative is the anchor wearing a disguise.
- The comparison sentence must name a reason specific to this task or codebase. "A is more standard" is a vibe; "A avoids adding a websocket dependency this service doesn't have" is a reason.
- If the alternative starts looking better mid-comparison, that's the rule paying for itself. Switch without ceremony — nothing is built yet.
- Skip this for trivial choices. Forced comparisons on variable names is theater; this rule is for decisions that would be expensive to reverse.

**Red flags that you're about to violate this:**
- "The obvious way to do this is..." (obvious to the pattern-matcher, or correct for this task?)
- "I'll go with the standard approach..." (standard for which situation?)
- "There's really only one way to do this..." (there is almost never one way)
- "I considered alternatives" (name one)
- "Comparing options would slow things down..." (one sentence each)

---

## Why It Works

1. **It converts emission into decision.** A choice requires a rejected alternative; without one, "I chose this approach" is grammatically a decision and mechanically a reflex. The rule supplies the missing ingredient.

2. **Contrast exposes weaknesses that inspection doesn't.** The anchor's costs are invisible in isolation and obvious next to an option that doesn't pay them. "B doesn't need the cron job" is a thought that literally cannot occur until B exists.

3. **It's calibrated to where anchoring fails.** The trigger (non-trivial, expensive to reverse) and the requirement (task-specific reason, no strawmen) target the cases where first impressions go wrong, while exempting the noise where forced comparison is theater.

## Origin

Asked to deduplicate incoming records, an assistant anchored instantly on the familiar pattern: a content-hash column with a unique index, plus a migration and backfill across a large table. Plan written, migration drafted. A reviewer asked one question — "what else did you consider?" — and the forced second option (dedupe in the ingestion worker, where records were already grouped by source) turned out to need no migration, no backfill, and twenty lines. The hash-column plan wasn't wrong; it had just never had an opponent.
