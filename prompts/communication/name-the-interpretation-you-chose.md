---
title: Name the Interpretation You Chose
slug: name-the-interpretation-you-chose
category: communication
tags: [universal, clarity, questions]
works_with: all
severity: high
one_liner: "Silently picking one of two valid readings of an ambiguous request"
---

# Name the Interpretation You Chose

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from resolving an ambiguous request silently, so the user never learns there was a fork in the road.

**[Copy-paste ready version](../../install/name-the-interpretation-you-chose.md)** — just the instruction block, no explanation.

## The Problem

"Make the search case-insensitive" has at least two readings: lowercase the query before matching, or change the database collation so all matching is case-insensitive everywhere. An AI assistant will pick one — usually the one that's easier to implement — and deliver it without ever mentioning that the other reading existed. The user reviews the diff, sees their request implemented, and approves. They never had the chance to say "no, I meant the other one," because nobody told them there was another one.

This is different from failing to ask a clarifying question. Sometimes proceeding on a reasonable interpretation is the right call — stopping to ask about every ambiguity is its own failure mode. The bug is in the *disclosure*: the model resolves the fork internally, then writes a summary in which the fork never appears. From the outside, an interpreted request and an unambiguous one look identical.

The cost surfaces late. The wrong interpretation often passes review precisely because it's a valid reading — the code does what the words said. It fails weeks later against the intent, and by then the AI's choice has hardened into architecture.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Name the Interpretation You Chose

When a request has more than one reasonable reading and you proceed on one of them, ALWAYS say which reading you chose and which you rejected. The fork is part of the deliverable.

The core problem: a silently resolved ambiguity looks identical to no ambiguity at all, so the user approves your interpretation without knowing they were choosing.

- State it in one line at the top of your response: "I read 'case-insensitive search' as lowercase-at-query-time, not a collation change. Flag me if you meant the latter"
- Do this even when you're confident. Confidence is what you feel; the fork is what existed
- Proceeding on an interpretation is fine when one reading is clearly more likely or the cost of being wrong is low. Hiding that you did so is never fine
- If the readings diverge enough that picking wrong wastes serious work, ask instead of choosing
- Bad: implementing your favorite reading and writing a summary in which the words "I interpreted" never appear
- Good: "Two ways to read this. I went with per-user limits (most common for this kind of endpoint). If you meant global limits, the change is small"

**Red flags that you're about to violate this:**
- "My reading is obviously what they meant..."
- "Mentioning the other interpretation will just create doubt and noise..."
- "If I picked wrong, they'll notice in review..."
- "The other reading would be weird, no need to bring it up..."
- "I already decided, relitigating it in the summary is wasted words..."
- "Asking or explaining makes me look indecisive..."

---

## Why It Works

1. **It separates the decision from the disclosure.** The model conflates "I may proceed without asking" with "I may proceed without telling." The instruction explicitly permits the first and bans the second, which removes the false choice between interrupting the user and going silent.

2. **One required sentence is too cheap to rationalize away.** Most disclosure failures hide behind effort ("a full discussion of alternatives is overkill"). A single named-fork line has no overkill defense, so the rationalization loses its cover.

3. **"The fork is part of the deliverable" reframes what done means.** The model treats the implemented reading as the complete answer. Defining the rejected reading as part of the work product makes silence an incomplete delivery, not a stylistic choice.

## Origin

A developer asked an assistant to "dedupe the events table." The assistant deduplicated by event ID — reasonable — and said so nowhere. The developer had meant by (user, timestamp), since duplicate IDs were the known-fine case and duplicate user-timestamps were the actual data bug. The cleanup job ran nightly for a month, deleting nothing useful, while the real duplicates kept inflating a billing report. One sentence — "I'm deduping on event ID" — would have surfaced the mismatch on day one.
