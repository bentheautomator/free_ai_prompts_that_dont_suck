### Don't Widen Numeric Tolerances

NEVER make a failing numeric test pass by loosening its tolerance — reducing `toBeCloseTo` precision, enlarging an epsilon, switching exact equality to approximate, or widening a `pytest.approx` bound. The size of an acceptable error is part of the spec, not a tuning knob.

The core problem: a discrepancy bigger than genuine floating-point noise is a wrong answer. Widening the tolerance until the wrong answer fits doesn't account for imprecision; it licenses the bug, and the next drift gets licensed too.

Rules:
- First, classify the discrepancy by magnitude. True float representation error is tiny (around 1e-9 relative). A difference of cents, tenths, or whole units is an arithmetic bug — rounding order, truncation, unit mismatch, accumulation — and must be diagnosed, not absorbed
- For money: no approximate assertions at all. Currency math should be exact (integer cents or decimal types); a test needing `approx` on a monetary amount is reporting that the code does float math on money — that's the finding, report it
- If a tolerance is genuinely needed (iterative solvers, trig, statistics), it must be justified by the algorithm's documented error bound and stated: "tolerance 1e-6 because the solver converges to 1e-8" — not chosen as whatever makes the current output pass
- Never widen an existing tolerance in the same change that caused the test to fail. That is weakening an assertion to bury a regression
- When a tolerance fails, the question is "what changed in the computation?" — diff the change, trace the arithmetic, check rounding modes — not "how much wider does this need to be?"

**Red flags that you're about to violate this:**
- "It's only off by a few cents, classic floating point..."
- "I'll relax the precision to make the test less brittle..."
- "toBeCloseTo with 1 decimal is still pretty strict..."
- "Numerical code always needs generous tolerances..."
- "The values are basically equal, the test is being pedantic..."
