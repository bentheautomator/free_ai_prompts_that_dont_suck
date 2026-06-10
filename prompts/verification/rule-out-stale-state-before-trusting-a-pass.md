---
title: Rule Out Stale State Before Trusting a Pass
slug: rule-out-stale-state-before-trusting-a-pass
category: verification
tags: [universal, verification, state]
works_with: all
severity: high
one_liner: "Trusting a green result produced by caches and leftover data, not the new code"
---

# Rule Out Stale State Before Trusting a Pass

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the assistant from accepting a passing result that stale caches or leftover data produced, rather than the change under test.

**[Copy-paste ready version](../../install/rule-out-stale-state-before-trusting-a-pass.md)** — just the instruction block, no explanation.

## The Problem

A pass can lie. The assistant runs the new lookup feature, gets the right answer, and declares victory — but the answer came from a cache populated by an earlier run, or from a database row left behind by a previous test, or from a fixture seeded last week that happens to satisfy the new query. The new code may have run; the result it "produced" was sitting there before it ran. The demo demonstrated the leftovers.

Assistants accept these passes because a green result is exactly what they were hoping to see, and nobody interrogates good news. Checking where a result came from — clearing the cache, wiping the test data, rerunning from a clean slate — costs time and risks converting a satisfying pass into an inconvenient failure. Confirmation arrives, the claim ships, the session moves on.

The failure shows up when the state isn't there: the cache expires, the demo database gets rebuilt, a fresh environment runs the code for the first time. Then the feature that was "verified working" returns nothing, and the investigation eventually discovers it never worked — every observed success was an echo of pre-existing state.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Rule Out Stale State Before Trusting a Pass

NEVER accept a passing result until you can say where the result came from. A pass produced by leftover state — caches, previous runs' data, old fixtures, pre-seeded rows — verifies the leftovers, not your change.

The core problem: success is the expected outcome, so a green result gets waved through without asking whether the new code earned it. Stale state produces convincing passes for code that has never worked.

- Before trusting a pass, identify what could have pre-supplied the result: response caches, memoized values, leftover database rows, previous runs' output files, seeded fixtures, browser storage, CDN copies.
- Prove provenance with one of: run from a deliberately clean slate (clear the cache, wipe the rows, delete the output file first); use an input that has never existed before; or confirm via logs that the new path computed the result rather than fetched it.
- Distrust a pass that arrives suspiciously fast or suspiciously easily — instant responses are the signature of a cache hit, and first-try perfection on complex changes deserves one skeptical look.
- After any failed run, clean up before the next attempt; otherwise its debris becomes the stale state that fakes your next pass.
- When a demo depends on pre-existing data, say so in the report: "works against the seeded dataset; not yet run against a clean environment."

**Red flags that you're about to violate this:**
- "It returned the right answer; I don't need to know why..."
- "Clearing the cache might break the working demo..."
- "That data was probably created by my new code..."
- "It passed on the first try — great, moving on..."
- "Wiping state is risky; I'll verify on top of what's there..."
- "The response was instant, which means the code is fast..."

---

## Why It Works

1. **It adds a provenance requirement to "pass."** A result with an unknown source stops counting as evidence, which is exactly the property stale-state passes exploit.

2. **It supplies the never-seen-input trick.** A brand-new input cannot have a cached or pre-seeded answer, so a correct response to it must have been computed — cheap to do, decisive when done.

3. **It weaponizes suspicion of easy wins.** Instant responses and first-try perfection are the two observable fingerprints of stale state; flagging them turns the most seductive moments into checkpoints.

4. **It makes cleanup part of verification, not chores.** Tying "clean up after failed runs" to "your next pass might be fake" gives hygiene a reason the model will respect.

## Origin

A search-indexing change was demoed three times, each demo returning perfect results, each result actually served from an index built before the change. The new indexer had a serialization bug and had never successfully written a single document. This was discovered when the index was rebuilt from scratch for an unrelated reason and search went completely dark in staging. Three "verifications" had measured nothing but the durability of the old index.
