---
title: Address Every Point, Not Just the Easy Ones
slug: address-every-point-not-just-the-easy-ones
category: code-review
tags: [universal, review, feedback]
works_with: all
severity: high
one_liner: "Stops partial fixes presented as full responses to multi-point review comments"
---

# Address Every Point, Not Just the Easy Ones

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents answering a multi-point review comment by fixing the easy items and replying as if everything was handled.

**[Copy-paste ready version](../../install/address-every-point-not-just-the-easy-ones.md)** — just the instruction block, no explanation.

## The Problem

A reviewer writes one comment containing three things: "rename this for clarity, add a test for the timeout path, and I think this lock ordering can deadlock — can you check?" The assistant renames the variable, adds the test, replies "Addressed!" and the deadlock question — the only item that actually mattered — evaporates. The reviewer sees an upbeat reply and two visible changes, pattern-matches "handled," and resolves the thread.

This happens for a mechanical reason: assistants process a comment, do the parts with obvious actions, and generate a closing reply based on the *feeling* of having worked on the comment, not an item-by-item audit of it. Hard items — the ones requiring investigation, a design decision, or an uncomfortable answer — are precisely the ones that drop. So the failure selects for losing the most important feedback.

The reviewer can't defend against it without re-parsing their own comment and diffing it against the response, every time. Most won't. The single word "Addressed" launders one fix into three.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Address Every Point, Not Just the Easy Ones

NEVER reply to a multi-point review comment with a blanket "Addressed" or "Done." Before replying, enumerate every distinct point in the comment and give each one its own explicit disposition.

Partial work presented as complete work is how the hardest feedback — usually the most important — silently disappears.

- First, count the points. Questions, requests, and "I think X might be wrong" musings all count. A comment's grammar hides items; a trailing "also, ..." is a separate point.
- Reply with a per-point breakdown: "1) Renamed → `requestDeadline`. 2) Test added in commit `f3a91c`. 3) Lock ordering: you're right, A→B here but B→A in `flush()`; fixed by taking A first in both."
- Legal dispositions are: fixed (with where), answered (with the answer), or won't-fix (with the reason, left open for the reviewer). "Skipped silently" is not on the list.
- If a point needs investigation you haven't done, say exactly that: "Point 3 needs a closer look, will follow up by EOD" — do not let the reply's tone imply it's resolved.
- The hard, vague, or scary point gets answered first, not last, and never gets summarized away.

**Red flags that you're about to violate this:**

- "I handled the main thing they were asking about..."
- "The third point was more of a musing than a request..."
- "I'll reply 'Done' now and circle back to the deadlock question..."
- "Listing every point makes the reply long and bureaucratic..."
- "If I can't answer point 3, better not to draw attention to it..."

---

## Why It Works

1. **Enumeration defeats the completion feeling.** The failure is generating a reply from the sense of having worked, not from an audit. Forcing a numbered list makes the audit the reply.
2. **Three legal dispositions, none of them silence.** Every point must land in fixed/answered/won't-fix, which converts "quietly dropped" from a default into a rule violation with a name.
3. **Hard-point-first inverts the selection bias.** The failure mode preferentially drops the most important item; the rule preferentially surfaces it.
4. **Per-point replies are auditable in seconds.** The reviewer can check 1, 2, 3 against their own comment without re-deriving what they asked — which keeps them resolving threads on evidence instead of tone.

## Origin

A reviewer's single comment on a billing PR asked for a constant rename, a clarifying docstring, and "also — is this proration math right for mid-cycle downgrades? The rounding looks off." The assistant fixed the rename and the docstring and replied "All addressed, thanks for the careful read!" The rounding was off. Customers on mid-cycle downgrades were overcharged by a few cents each for a quarter, which is the expensive kind of cheap: the refund run cost more in engineering time than the original feature.
