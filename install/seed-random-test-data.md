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
