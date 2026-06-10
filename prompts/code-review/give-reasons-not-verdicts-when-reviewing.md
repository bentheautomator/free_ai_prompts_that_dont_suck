---
title: Give Reasons, Not Verdicts, When Reviewing
slug: give-reasons-not-verdicts-when-reviewing
category: code-review
tags: [universal, review]
works_with: all
severity: medium
one_liner: "Stops review comments that pronounce judgment without showing the failure"
---

# Give Reasons, Not Verdicts, When Reviewing

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents writing review comments as bare pronouncements ("this is wrong," "use X instead") with no reasoning the author can verify or contest.

**[Copy-paste ready version](../../install/give-reasons-not-verdicts-when-reviewing.md)** — just the instruction block, no explanation.

## The Problem

An assistant reviewing a PR drops comments like "This is not thread-safe." "Don't use recursion here." "This should be a single query." Each might be right. None says why, what input breaks, or what the cost of ignoring it is. The author now has three options, all bad: comply blindly (and learn nothing, and maybe "fix" working code), push back blindly (and start an evidence-free argument), or ignore it (and maybe ship a real bug the comment correctly flagged but failed to make legible).

Assistants write verdict-comments because verdicts are what terse review comments look like in training data, and because generating "this is wrong" is cheap while generating *the failing scenario* requires actually tracing the code. The verdict format also hides the reviewer's own uncertainty — a confident "not thread-safe" and a hallucinated "not thread-safe" read identically.

Reasoned comments are self-policing: to write "two goroutines can hit this map between the check and the insert," the reviewer has to find the actual interleaving — and when there isn't one, the comment dies before it's posted instead of wasting an author's afternoon.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Give Reasons, Not Verdicts, When Reviewing

When you review code, NEVER post a comment that asserts a problem without including the reasoning that makes it checkable. Every critical comment carries three parts: what's wrong, the concrete scenario where it bites, and what to do instead (or an honest "not sure of the fix").

A verdict without reasoning can't be verified, can't be contested, and can't be distinguished from a hallucination — by the author or by you.

- Bad: "This is not thread-safe." Good: "Two requests can pass the `if !exists` check before either inserts; the second insert overwrites the first's session. Needs the check-and-set under the mutex."
- Bad: "Use a single query." Good: "This runs one query per item; at the 1k-item carts we see in prod that's 1k round trips. A `WHERE id IN (...)` does it in one."
- The scenario must be specific enough that the author can reproduce or refute it. If you can't produce the scenario, downgrade the comment to a question: "Can this be reached with `items` empty? I couldn't rule it out."
- Style preferences get labeled as preferences with the convention they come from, or they don't get posted.
- If writing the reasoning reveals you were wrong, that's the system working. Delete the comment, don't soften it into a vague "might want to double-check this."

**Red flags that you're about to violate this:**

- "It's obviously wrong, spelling it out is condescending..."
- "I'm fairly sure there's a race here somewhere..."
- "Short punchy comments are what senior reviewers write..."
- "I'll assert it confidently and they can figure out the details..."
- "Explaining would mean tracing the call path, and the verdict is probably right..."

---

## Why It Works

1. **The scenario requirement is a hallucination filter.** Producing a concrete failing interleaving forces the model to trace the code; comments it can't substantiate get demoted to questions or deleted before posting.
2. **Checkable comments make disagreement cheap.** The author refutes a scenario in minutes; refuting a verdict requires proving a negative, which is where review threads go to rot.
3. **Confidence labeling is built into the format.** Provable problems are assertions with scenarios; unproven suspicions are questions. The author can triage on sight.
4. **It converts review from authority to evidence.** Authors act on reasoned comments faster because compliance doesn't require trusting the reviewer — only reading the argument.

## Origin

An assistant acting as first-pass reviewer flagged a queue consumer with "This has a race condition" and nothing else. The author spent most of a day attempting to find it, added a mutex around code that a single-threaded event loop already serialized, and shipped a throughput regression. There was no race. There was, in an adjacent function the assistant hadn't commented on, an actual one — which the now-skeptical author dismissed when a later review flagged it the same wordless way.
