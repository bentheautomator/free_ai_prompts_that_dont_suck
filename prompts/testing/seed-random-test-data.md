---
title: Seed Random Test Data
slug: seed-random-test-data
category: testing
tags: [universal, testing, determinism]
works_with: all
severity: medium
one_liner: "Unseeded faker and Math.random in tests producing unreproducible failures"
---

# Seed Random Test Data

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents tests built on unseeded randomness that fail once, can't be reproduced, and get dismissed.

**[Copy-paste ready version](../../install/seed-random-test-data.md)** — just the instruction block, no explanation.

## The Problem

The AI reaches for `faker.person.fullName()`, `Math.random()`, or `random.randint(1, 1000)` to generate test data — it looks professional, the data is "realistic," and the test passes. Then, one run in two hundred, faker produces a name with an apostrophe — `O'Brien` — and the unescaped SQL in the search feature falls over. The test goes red exactly once, with data nobody recorded, on a CI machine that's already recycled the logs. The next run passes. The failure gets filed under "flaky," which is the graveyard where reproducible bugs go when their inputs were random and unlogged.

That's the tragedy of unseeded randomness in tests: it occasionally does the most valuable thing a test can do — find a real input-dependent bug — and then destroys the evidence. AI assistants generate it because random data is the path of least thought (no need to decide what values matter) and because faker idioms are heavily represented in the test code they've learned from. They almost never add the seed, because the test passes without one — today.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Seed Random Test Data

NEVER use unseeded randomness in tests. If a test's inputs vary between runs, its failures can't be reproduced — and an unreproducible failure gets dismissed as flaky instead of investigated as a bug.

The core problem: random data occasionally hits a real input-dependent bug (the apostrophe name, the zero quantity, the leap-day date), fails once, and leaves no way to make it fail again. The discovery is wasted and the test earns a reputation for lying.

Rules:
- Prefer fixed, deliberately chosen values. If the test needs a name, pick one — and pick one that earns its keep (`"O'Brien-Müller"` exercises more than `"John Smith"`)
- When variation is genuinely useful, seed it: `faker.seed(42)`, `random.seed(42)`, `rng = new Random(1337)`, or the framework's per-run seed support — so any failure replays exactly
- If you use a randomized-but-seeded mode where the seed varies per run (legitimate for fuzz-style tests), the seed MUST be printed in the test output so a failure can be replayed (`pytest-randomly` does this; do the equivalent if hand-rolling)
- Never let random values determine which branch the test exercises: `randint(1, 100)` items means the bulk-discount branch is tested probabilistically. Test both branches deterministically instead
- Don't generate random values and then assert properties loose enough to hold for all of them — that's vagueness wearing a lab coat. Either fix the input and assert exactly, or do real property-based testing (Hypothesis, fast-check) which shrinks and reports failing cases for you
- If an existing test fails with random data in the logs, treat it as a probable real bug with a lost input — try to reconstruct it, don't rerun until green

**Red flags that you're about to violate this:**
- "Faker makes the fixtures more realistic..."
- "Random data gives us broader coverage over time..."
- "It passed when I ran it, the random values are fine..."
- "A random ID avoids collisions, no seed needed..."
- "If it fails someday we'll deal with it then..."

---

## Why It Works

1. **It exposes the evidence-destruction problem.** The AI evaluates random data on generation day, when it costs nothing. Framing the cost at failure time — a found bug with no reproduction — explains why the habit is expensive in the only run that matters.

2. **It redirects "broader coverage over time" to its real form.** That instinct is property-based testing done badly: variation without shrinking, reporting, or replay. Naming Hypothesis/fast-check gives the impulse a tool that actually delivers it.

3. **It keeps the seed loophole honest.** Per-run seeds are fine *only if printed* — a precise condition that preserves fuzz-style value while guaranteeing every failure is replayable.

## Origin

A registration test using unseeded faker emails failed three times over two months, each time on a different CI run, each time passing on retry. It was labeled flaky and muted in the team's notifications. The pattern: faker occasionally generated an email local-part longer than 64 characters, which the registration code truncated — duplicating another user's address and merging two accounts. A customer-reported account merge finally got it diagnosed; the test had found it months earlier, three separate times, with inputs nobody could recover.
