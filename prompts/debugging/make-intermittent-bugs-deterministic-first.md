---
title: Make Intermittent Bugs Deterministic First
slug: make-intermittent-bugs-deterministic-first
category: debugging
tags: [universal, debugging, root-cause]
works_with: all
severity: high
one_liner: "AI shipping speculative fixes for bugs it can only sometimes observe"
---

# Make Intermittent Bugs Deterministic First

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from fixing a sometimes-bug on speculation, where "it passed a few runs" is indistinguishable from "the dice came up lucky."

**[Copy-paste ready version](../../install/make-intermittent-bugs-deterministic-first.md)** — just the instruction block, no explanation.

## The Problem

The bug appears maybe one run in ten. The AI sees it once, forms a theory, applies a fix, runs three times — all pass — and declares it handled. But with a 10% failure rate, three clean runs happen by pure chance 73% of the time. Nothing was measured. The fix is a coin standing on its edge, and the AI just walked away from the table announcing it landed heads.

Against an intermittent bug, every debugging tool degrades: you can't confirm a hypothesis (the failure might just be resting), can't evaluate a fix (passing proves nothing), can't even tell whether your instrumentation changed the behavior. The first job is therefore not to fix the bug but to *change its odds* — find the lever that controls it and pin it. Run it 500 times in a loop and get a baseline rate. Add load, shrink the thread pool to 1, insert a strategic delay to force the losing interleaving, freeze the clock, fix the random seed, replay the exact event sequence. A bug that fails reliably — or whose failure *rate* is at least measured — is a bug you can do science on.

AIs skip this because hunting the trigger is indirect work with no diff to show, while a speculative fix plus a few lucky runs produces the complete *appearance* of a resolution.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Make Intermittent Bugs Deterministic First

NEVER fix an intermittent bug on speculation. Before any fix, either make the failure deterministic or establish its measured failure rate — otherwise you cannot distinguish "fixed" from "lucky."

A handful of passing runs against a sometimes-bug is statistical noise. With a 10% failure rate, three clean runs occur by chance most of the time.

- First, measure the baseline: run the reproduction in a loop (dozens to hundreds of iterations, as cost allows) and record the failure rate; this number is what any fix must visibly move
- Then hunt the trigger — what condition raises the rate? Try: concurrency up or thread pool down to 1, added load, strategic sleeps to force the suspected interleaving, fixed random seeds, frozen/advanced clocks, network latency injection, the same data/order every time, running at the reported time of day
- Each trigger experiment is evidence: "rate jumps to 100% with the pool at 1 thread" or "vanishes with a fixed seed" localizes the mechanism before you've read a line of the diff you'll eventually write
- Ideal endpoint: a deterministic reproduction. Acceptable fallback: a known baseline rate and a loop harness to test against
- Evaluate any fix statistically: the same loop, enough iterations that the pre-fix rate would have produced many failures, now producing zero — state the numbers ("0 failures in 400 runs vs baseline 41/400")
- If you ship anything before achieving this, label it explicitly as a speculative mitigation with the evidence still owed — never as a fix

**Red flags that you're about to violate this:**
- "I ran it three times after the change and it passed — looks fixed..."
- "It's hard to reproduce, so I'll fix the most likely cause..."
- "The race is probably here; this lock should take care of it..." (probably?)
- Testing a fix for a sometimes-bug with fewer runs than its failure interval
- No number anywhere in your analysis for how often the bug occurs
- Avoiding the loop harness because each run is slow (so make the repro faster first)

---

## Why It Works

1. **It makes luck arithmetically visible.** "Three passes happen by chance 73% of the time at a 10% rate" destroys the intuition that a few clean runs mean anything — the rationalization can't survive its own numbers.

2. **It turns trigger-hunting into localization.** "Vanishes with a fixed seed" or "100% at one thread" identifies the mechanism class (randomness-dependent, interleaving-dependent) before any code is changed — the indirect work pays off in diagnosis, not just reproduction.

3. **It defines the fix's acceptance test in advance.** A baseline rate plus a loop harness means "did the fix work?" has a numeric answer, closing the loophole where the question is settled by vibes and a small sample.

4. **It permits honest mitigation.** Urgent situations sometimes demand acting before determinism is achieved; the explicit "speculative mitigation, evidence owed" label keeps that possible without letting it impersonate a verified fix.

## Origin

A queue consumer occasionally processed the same job twice — roughly weekly at production volume. An assistant identified a plausible race, added a lock, watched a day pass without incident, and reported the bug fixed. At one incident per week, a quiet day was meaningless; the duplicates returned, twice, before anyone re-opened the investigation. The eventual real fix came after a developer built a loop harness that replayed the visibility-timeout expiry deterministically — reproducing in seconds what production produced weekly — and showed the lock had been guarding the wrong section all along.
