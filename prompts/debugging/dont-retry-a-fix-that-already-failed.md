---
title: Don't Retry a Fix That Already Failed
slug: dont-retry-a-fix-that-already-failed
category: debugging
tags: [universal, debugging]
works_with: all
severity: high
one_liner: "AI circling back to fix attempts it already tried and watched fail"
---

# Don't Retry a Fix That Already Failed

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from re-proposing, in round five, the same fix that failed in round one — with new wording and the same result.

**[Copy-paste ready version](../../install/dont-retry-a-fix-that-already-failed.md)** — just the instruction block, no explanation.

## The Problem

Long debugging sessions with AI assistants develop loops. Attempt one: add an `await` to the save call — still fails. Attempts two and three go elsewhere. Attempt four: "the issue might be that the save isn't being awaited" — and there's the `await` again, re-derived from scratch, proposed with full confidence as a fresh insight. The AI isn't being stubborn; it's being *memoryless*. Each round re-reads the code, re-notices the same suspicious pattern, and re-generates the same most-plausible fix, because the most-plausible fix is a function of the code, and the code looks the same every time.

What's missing is the elimination ledger every human debugger keeps in their head: tried that, ruled out, *and here's what its failure taught us*. Without it, failed attempts don't accumulate into progress — the session has motion but no direction, and the search space never shrinks. Worse, each retry burns a full reproduce-edit-run cycle and erodes the user's confidence that anything is converging.

The loop is most pronounced in long sessions where early attempts have scrolled out of practical attention, and in sessions resumed after a break, where the AI cheerfully rediscovers Monday's failures on Wednesday.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Don't Retry a Fix That Already Failed

NEVER re-attempt a fix that has already been tried and observed to fail in this investigation. Keep an explicit ledger of attempts, and check every new proposal against it before acting.

Without a written record, you will re-derive the same most-plausible fix from the same code and propose it again as a fresh idea. Plausibility doesn't change between rounds; only the ledger accumulates.

- Maintain a running list in your working notes: for each attempt — what was changed, what the hypothesis was, what was observed, and what the failure *eliminated*
- Before proposing any fix, check it against the ledger: is this, under any phrasing, something already tried? "Add the missing await," "make the call synchronous-safe," and "ensure save completes before read" can be the same attempt in three costumes — compare mechanisms, not wording
- A failed attempt may be revisited only when something material changed: evidence shows it was applied in the wrong place, incomplete in an identified way, or tested against a contaminated baseline — state which
- Use each failure's information: if "add await" didn't fix it, the bug is *not* (only) a missing await — that eliminates a region of the search space; say what's eliminated and steer away from it
- If your ledger shows three or more failed attempts, stop generating fixes and return to evidence-gathering: reproduce again, instrument, re-read the trace — the hypothesis pool needs new input, not another draw
- When resuming a session, re-read the ledger before the code

**Red flags that you're about to violate this:**
- "It might be that the call isn't awaited..." (attempt #1, four rounds ago)
- "Let me try a variation of the earlier approach..." (what specifically failed about the original?)
- "Going back to my first instinct on this..."
- Proposing a fix without being able to list what's already been ruled out
- A feeling of fresh confidence about an idea you can't confirm is new
- Five attempts in, with no statement of what the failures have collectively eliminated

---

## Why It Works

1. **It names the memoryless mechanism.** The retry isn't stubbornness, it's re-derivation: same code in, same most-plausible fix out. Knowing *why* the loop happens makes the ledger check feel necessary rather than bureaucratic.

2. **It compares mechanisms, not phrasings.** Reworded retries are the common case; requiring mechanism-level comparison catches "ensure save completes" as a costume for "add await."

3. **It converts failures into eliminations.** "If that fix failed, the bug is not X" makes each dead attempt shrink the search space — turning the ledger from a list of defeats into the actual map of progress.

4. **It installs a circuit breaker.** Three failed fixes triggering a mandatory return to evidence-gathering breaks the generate-test-fail loop at the point where it stops converging.

## Origin

A session on a message-ordering bug ran nineteen fix attempts over two days. A developer auditing the transcript found that attempts 4, 11, and 17 were the same change to the consumer's prefetch setting — re-proposed each time with different reasoning, failing identically each time — and that attempts 7 and 14 were likewise twins. Eleven distinct ideas had been dressed as nineteen. With a written ledger imposed on day three, the duplicates became impossible, the eliminations finally accumulated, and the real cause (a partition key mismatch, never previously suspected) surfaced within six more attempts.
