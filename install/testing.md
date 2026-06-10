### Always Await Async Assertions

Every asynchronous operation in a test must be awaited before the test ends. An unawaited `expect(...).rejects`/`resolves`, an unreturned promise chain, or an unawaited coroutine means the test completes before the result exists — and a test that finishes before its assertions run passes unconditionally.

The core problem: the runner scores "function returned, nothing failed" as green. Asynchrony makes that state trivially reachable with zero assertions actually evaluated, and the broken version is one missing keyword away from the correct one.

Rules:
- `expect(promise).rejects...` and `.resolves...` return promises: ALWAYS `await` them, inside an `async` test. Unawaited, they assert into the void
- Never call the async function under test without awaiting it (or explicitly asserting on the awaited result). `const result = fn()` followed by assertions tests a pending promise object, not the outcome
- `.then()`/`.catch()` chains in tests must be returned or replaced with await; assertions inside an unreturned callback run after the verdict
- `forEach(async ...)` awaits nothing — use `for...of` with await, or `await Promise.all(items.map(...))`
- Python: a coroutine called without `await` never executes; use an async test (pytest-asyncio or equivalent) and await every coroutine. Treat any "coroutine was never awaited" warning in test output as a failing test, not noise
- Heed the runner's hints: Jest's "test finished but async operations are pending" class of warnings, unhandled rejection messages, open-handle reports — each is this bug announcing itself
- Verification that the test tests: break the code's behavior deliberately (make the function resolve when it should reject) and confirm the test goes red. An async test you've never seen fail has not yet earned trust

**Red flags that you're about to violate this:**
- "The rejects matcher handles the promise internally..."
- "The test passes, so the assertion must have run..."
- "I'll fire the calls in a forEach and assert after..."
- "That never-awaited warning is unrelated noise..."
- "Adding async/await everywhere is just ceremony for a one-liner test..."

### Assert Loop Bodies Actually Ran

ALWAYS pair per-item assertions in a loop with an assertion that the loop had items. A for-loop over an empty collection runs zero assertions and passes, which means "verify every order" silently degrades to "verify nothing" the moment the collection is empty.

The core problem: universally-quantified assertions are vacuously true over empty sets. The most likely failure of the code under test — returning nothing — is exactly the case the test waves through.

Rules:
- Before (or after) the loop, assert the expected count: `assert len(orders) == 3` when the fixture determines it, or at minimum `assert len(orders) > 0` when it doesn't
- Prefer exact counts from fixtures over `> 0`. You created the test data; you know how many should come back
- The same applies to filtered iteration: if you assert only over `[o for o in orders if o.failed]`, also assert how many matched the filter
- The same applies to assertions inside callbacks, event handlers, and mock side-effect functions: assert the callback was actually invoked (`assert mock.call_count == 2`, `expect(handler).toHaveBeenCalled()`), or the assertions inside it are decorative
- Framework helpers that fail on empty input (e.g., asserting collection equality against a full expected list) are better than hand-rolled loops; prefer them where available
- Quick audit: for each loop containing an assert, ask what happens if the iterable is empty. If the answer is "passes," the test is incomplete

**Red flags that you're about to violate this:**
- "The fixture always returns data, no need to check it's non-empty..."
- "Iterating and asserting each item covers everything..."
- "If the list were empty, other tests would catch it..."
- "The assertion inside the callback verifies the behavior..."
- "Checking the length feels redundant with the per-item checks..."

### Assert Specific Exceptions

NEVER assert that code merely throws. Assert which exception type, and where it matters, what the message or error fields say. A bare `pytest.raises(Exception)` or `expect(fn).toThrow()` passes when the code crashes for an unrelated reason — including bugs in the error path itself.

The core problem: broad exception assertions can't distinguish "correctly rejected the input" from "fell over before reaching the rejection." Both look like a throw; only one is the behavior you meant to test.

Rules:
- Assert the concrete type: `pytest.raises(InvalidEmailError)`, `expect(fn).toThrow(ValidationError)`, `assertThrows(NotFoundException.class, ...)` — never the root `Exception`/`Error` class
- Pin the meaningful part of the message or payload when callers depend on it: `pytest.raises(ValidationError, match="email")`, `expect(fn).toThrow(/email/)`, or assert on the caught error's `code`/field attributes
- In JS, remember `toThrow()` on an async function needs `rejects`: `await expect(fn()).rejects.toThrow(ValidationError)` — the sync form on a promise tests nothing
- If you don't know what the code raises, that is not a reason to go broad — read the code path, then assert what you find (and check it's a sensible error; if invalid input raises `AttributeError`, you may have found a bug, not a fixture)
- Catch-and-inspect is fine when you need multiple assertions: catch the specific type, then assert on its fields. Don't catch broad and assert nothing
- Broad matching is acceptable only when the contract genuinely is "throws something" (rare, e.g., testing a panic handler) — say so when you use it

**Red flags that you're about to violate this:**
- "I'm not sure which exception it raises, Exception covers all cases..."
- "The important thing is that it fails on bad input..."
- "Matching the message makes the test brittle..."
- "toThrow() without arguments is cleaner..."
- "Any error here means the validation is working..."

### Don't Assert Mock Return Values

NEVER write assertions that merely confirm a mock's configured return value came back out. A test must assert something the code under test *did* — a transformation, a decision, a computation — not data you injected echoing back.

The core problem: asserting injected data round-tripped verifies the mock framework and a passthrough. It exerts no pressure on the unit's actual logic and passes even if all of that logic is deleted.

Rules:
- For each assertion, trace the asserted value backward. If it flows unmodified from a `mockReturnValue`/`mockResolvedValue`/`when(...).thenReturn(...)` into the expectation, the assertion is circular — replace it
- Assert the deltas: what did the code add, compute, filter, reformat, or decide? If the mock returns `tier: 'gold'`, assert the discount the code derived from gold, not the word "gold"
- Design stub data so passthrough would be distinguishable from correct processing — if the function should uppercase names, stub a lowercase name
- Asserting *call arguments* is legitimate when the code constructed them (`expect(api.charge).toHaveBeenCalledWith(4250)` where 4250 was computed); it's circular when you're checking your own input echoed through
- If you find there is no delta — the function genuinely just forwards the value — say so: the honest conclusion may be that this unit needs no test, or that the test belongs at a different level
- Self-check: would this test fail if the function body were `return await userService.getUser(id)`? If not, you haven't tested your code yet

**Red flags that you're about to violate this:**
- "The mock returns Alice, so I'll assert the result is Alice..."
- "Specific value assertions make this test strong..."
- "I'm verifying the data flows through correctly..."
- "Asserting the fields match the mock proves integration works..."
- "Every field checked — this test is thorough..."

### Don't Edit Tests and Source Together

NEVER silently modify tests in the same change as the source code they cover. When a task is about the code, existing tests are the referee — and you don't get to coach the referee.

The core problem: if you change the code and conform the tests to it in one motion, nothing independent has checked your work. Green proves self-agreement, not correctness.

Rules:
- Default mode for code changes: existing tests are read-only. Run them; their verdict is information about your change
- If your change makes an existing test fail, that's a decision point, not an editing opportunity. Either your code is wrong (fix it) or the intended behavior changed (then the test update is part of the contract change — announce it)
- Any test modification must be called out separately and explicitly: which tests, what they asserted before, what they assert now, and why the old assertion no longer reflects intended behavior. "Updated tests accordingly" is not a disclosure; it's a confession with the details redacted
- Adding new tests alongside source changes is good and encouraged. This rule is about modifying or removing existing ones
- For deliberate behavior changes, prefer the honest sequence: state the contract change, update the test to encode the new contract, show it failing against old code if practical, then change the source
- If you notice you've edited both sides without announcing it, stop and surface it before reporting done

**Red flags that you're about to violate this:**
- "I'll just update the tests to match the new behavior..."
- "These test changes are too minor to mention..."
- "The tests were written for the old implementation..."
- "Fixing the test here saves a round-trip with the user..."
- "Everything's green now, the how doesn't matter..."

### Don't Mock Everything in Integration Tests

NEVER mock away so many collaborators that a test no longer exercises any real interaction between real components. Before adding each mock, name what the test still verifies if the mock goes in — and stop when the answer approaches "that the mocks get called."

The core problem: every mock replaces a seam where real components could disagree with a stub that always agrees. Mock all the seams and the test can no longer fail for any reason that matters.

Rules:
- Decide the test's integration boundary explicitly and state it: which real components talk to each other, and where the world is faked. "Service + real repository + in-memory DB, with the external payment API faked" is a boundary; "mock whatever errors" is not
- Mock at the system's edges (third-party APIs, payment processors, email), not between your own components — inter-component contracts are the thing integration tests exist to check
- Prefer real-ish substitutes over interaction stubs: in-memory or containerized databases, the framework's test client/server, fakes with actual behavior (a real in-memory queue) rather than `mock.calledWith` choreography
- When a dependency errors in test setup, the first option is to provide it (test container, fixture, in-process fake), not to stub it. Stubbing-on-error is how integration tests dissolve one mock at a time
- If the environment truly can't support the real dependency, say so and ask, rather than silently downgrading the test's meaning while keeping its name
- Honesty rule: a test where every collaborator is mocked is a unit test. Name it as one or rebuild it

**Red flags that you're about to violate this:**
- "The DB isn't available here, I'll mock the repository too..."
- "Mocking all the services makes this test fast and reliable..."
- "It still tests the flow — each step is verified to be called..."
- "One more mock won't change what the test covers..."
- "I'll mock it now so the test runs, and it can be made real later..."

### Don't Shrink Test Inputs to Pass

NEVER make a failing test pass by reducing its scale — fewer iterations, smaller datasets, fewer concurrent workers, shorter durations, less load. If the test fails at N=500 and passes at N=20, the bug exists and needs roughly 500 of something to manifest; you've measured its threshold, not fixed it.

The core problem: scale-dependent tests exist to catch scale-dependent bugs — races, overflows, leaks, exhaustion. Shrinking the input doesn't touch the bug; it retunes the test to stay below the bug's trigger point.

Rules:
- A test that passes small and fails large is giving you data: the failure is load-sensitive. That points at contention, accumulation, or capacity — investigate in that direction; do not negotiate N downward
- The magnitudes in a test (worker counts, row counts, iteration counts, payload sizes) are part of what it asserts. Treat reducing them on a red test exactly like weakening an assertion, because it is one
- If you believe a test's scale is genuinely excessive, that judgment may only be acted on while the test is passing, as an explicit, stated change ("reducing fixture from 10k to 1k rows; the logic under test is per-row and scale-independent — confirm?"). Scale reductions that happen to convert red to green are not performance work
- Same rule for the sneaky variants: lowering a load-test's request rate, trimming the "large input" case out of a parametrized list, cutting the soak duration, reducing fuzzer iterations
- If the full-scale test is too slow for every CI run, propose moving it to a scheduled/nightly tier at full scale — never shrinking it into a version that can't catch what it was built to catch
- When you shrink anything in a test file, report the before/after numbers and why the smaller value still exercises the same failure modes

**Red flags that you're about to violate this:**
- "500 workers is overkill, 20 exercises the same logic..."
- "I'll trim the fixture so the test runs faster — and hey, it passes now..."
- "The huge input case seems gratuitous, removing it from the parametrize list..."
- "It only fails at high iteration counts, which is unrealistic anyway..."
- "Smaller test data is easier to debug, this is an improvement..."

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

### Fix the Bug, Not the Assertion

NEVER change a test's expected value to match the code's current output just to make a failing test pass. A failing assertion is evidence about the code, and the default assumption is that the test is right.

The core problem: editing the expectation to equal the observed output converts a caught bug into documented, test-approved behavior.

When an assertion fails:
- Diagnose first. Determine which side is wrong by reasoning from the spec, the docs, or the test's name and intent — not from which file is easier to edit
- If the code is wrong, fix the code. Leave the assertion alone
- If you believe the expected value is genuinely incorrect, say so explicitly, show the evidence (spec excerpt, requirement, upstream API doc), and get confirmation before editing the test
- Never justify a test edit with "updated to match actual output" or "aligned test with current behavior" — current behavior is the thing on trial
- If the user changed requirements and the test encodes the old requirement, updating it is legitimate — state that this is what you're doing and which requirement changed

If you cannot determine which side is wrong, stop and ask. Report the failing assertion, the observed value, and your analysis of both possibilities.

**Red flags that you're about to violate this:**
- "The code returns 107.49, so I'll update the test to expect 107.49..."
- "The test seems outdated, let me sync it with the implementation..."
- "Easiest fix is adjusting the expected value..."
- "The implementation is probably the source of truth here..."
- "It's just off by a tiny amount, the test is being too strict..."
- "I'll update the test to reflect actual behavior..."

### Investigate Flaky Tests Before Removal

NEVER remove, disable, or quarantine a test because it fails intermittently, until you have determined *why* it fails intermittently. "Flaky" is a symptom, not a diagnosis — and one of its common causes is a real race condition in the code under test.

The core problem: an intermittent failure means something is nondeterministic. If that something is the production code, the test is your only detector, and removing it ships the race.

Before touching an intermittent test:
- Reproduce it: run the test in a loop (`pytest --count`, `jest --testNamePattern` in a shell loop, `go test -count=100 -race`) and record the failure rate and the exact failure output
- Read the failure. A timeout, a wrong value, and a missing record point to different causes. Distinguish "the test assumed ordering the code never promised" from "the code corrupts state under concurrency"
- Locate the nondeterminism: test-side (shared fixtures, sleeps, port collisions, leftover state) or code-side (races, unawaited async, unordered iteration). Use the race detector or thread sanitizer where the ecosystem has one
- If it's test-side, fix the test's determinism and prove it with a loop run
- If it's code-side, you found a real bug — report it as one. The test stays
- If you cannot determine the cause, say so and leave the test in place. An honest intermittent red beats a confident permanent blind spot

**Red flags that you're about to violate this:**
- "It passed on retry, so it's just flaky..."
- "This test has been unreliable forever, removing it unblocks everyone..."
- "Intermittent failures are test infrastructure problems by definition..."
- "I can't reproduce it locally, so it can't be a real bug..."
- "The team already calls it flaky, I'm just acting on that..."

### Keep Mocks Matched to Real Interfaces

ALWAYS derive a mock from the real dependency's actual interface, and use spec-enforcing mock features wherever the framework has them. A mock that accepts calls the real object would reject is testing a fiction.

The core problem: permissive mocks (`MagicMock()`, bare `jest.fn()`) say yes to everything — wrong method names, wrong signatures, impossible return shapes — so the test passes while the code would fail against the real dependency on the first call.

Rules:
- Read the real interface before mocking it. The mock's methods, signatures, and return shapes come from the dependency's code or docs — not from what your test happens to need
- In Python, use `autospec`/`spec` always: `mock.patch("svc.Client", autospec=True)` or `MagicMock(spec=Client)` — these raise on nonexistent attributes and wrong signatures. A bare `MagicMock()` for a known class is a defect
- In typed ecosystems, type the mock against the real interface (`jest.mocked(client)`, `MockProxy<Client>`, implementing the interface) so the compiler rejects drift
- Build stub return values from the dependency's real response shape — including envelope/nesting (`{data: {...}}`), field casing, and error formats. Copying a real sample response into the fixture beats inventing one
- When the dependency is upgraded or its API changes, hand-rolled mocks are part of the change's blast radius: update them deliberately, and say so
- If you can't find the real interface to copy, that's a stop-and-check moment — guessing a signature into a mock bakes the guess into a permanently passing test

**Red flags that you're about to violate this:**
- "MagicMock will accept whatever the code calls, that's convenient..."
- "I'll shape the stub response around what the function needs..."
- "I don't have the client's source handy, the method is probably called fetchUser..."
- "autospec is slower and stricter than I need here..."
- "The mock worked for the other tests, I'll reuse the pattern..."

### Never Comment Out Assertions

NEVER comment out a failing assertion to make a test pass. A commented assertion is a silenced failure with a paper trail — the test keeps reporting green while no longer checking the thing that broke.

The core problem: unlike skips and deletions, a muted assertion is invisible in every report. The test still runs, still passes, and its name still claims coverage it no longer provides.

Rules:
- A failing assertion is a finding about the code. Handle it the honest ways: fix the code, or — if you believe the assertion is wrong — show evidence and ask before changing it
- "Commenting out to unblock, with a TODO" is not a third option. TODOs in muted assertions are where intentions go to die; nothing routes anyone back
- The same rule covers every muting costume: wrapping the assertion in `if (false)`, prefixing with a no-op (`void expect(...)` patterns), converting `assert` to a `print`/`console.log` comparison, or moving the assertion into an unreachable branch
- Do not comment out the assertion and "keep the test as a smoke test." A test stripped of its failing assertion is not a smaller test; it is a different test wearing the old test's name
- If you genuinely cannot resolve the failure, leave the assertion active and the test red, and report exactly which assertion fails, with the observed and expected values. A red test that tells the truth outranks a green test that doesn't
- If you encounter already-commented assertions near code you're changing, surface them — each is a known discrepancy somebody muted, and your change may be the right moment to settle it

**Red flags that you're about to violate this:**
- "I'll comment it out with a TODO so the intent is preserved..."
- "Three of the four assertions pass, the test still has value..."
- "It's not deletion, it's right there to re-enable..."
- "This assertion seems too strict anyway, muting it pending review..."
- "Green with a noted exception is better than red..."

### Never Delete Failing Tests

NEVER delete a test that is currently failing, and never delete a test as part of making the suite pass. A failing test is information; deleting it destroys the information and keeps the bug.

The core problem: deletion is invisible in test output. A removed test leaves no skip marker, no failure line, nothing — the suite simply knows less forever.

Rules:
- If a test fails after your change, treat the test as correct until proven otherwise. Fix the code
- Do not delete a test because it's "outdated," "redundant," or "testing the old implementation" while it is red. Make it pass first or escalate — judgments about redundancy made under pressure to go green are not trustworthy
- Do not delete a test and write a "replacement" in the same change that happens to assert weaker things. That is deletion with a disguise
- Removing a test is acceptable only when: the feature it tests was deliberately removed at the user's request, or the user has explicitly approved removing that specific test. In both cases, name the test being removed and what coverage is lost
- If you cannot make a test pass, leave it failing and report it. "Suite is green minus the tests I removed" is a failure report, not a success report

**Red flags that you're about to violate this:**
- "This test no longer applies to the new architecture..."
- "I'll remove this and add better coverage later..."
- "This test was testing the old behavior, so it's safe to drop..."
- "The remaining tests cover this functionality anyway..."
- "Deleting it is cleaner than leaving a broken test around..."
- "Nobody will miss one test out of hundreds..."

### Never Mock the Function Under Test

NEVER mock, stub, patch, or otherwise replace the function, method, or class that the test exists to verify. The subject of a test must always be the real implementation.

The core problem: a test whose subject is mocked verifies the mock, not the code. It will pass forever, including when the real code is broken or deleted.

Rules:
- Before writing a mock, name the subject of the test. If the thing you're about to patch is the subject, stop
- Mock at the boundaries the subject calls (network, clock, filesystem, third-party APIs) — never the subject itself
- Do not patch the subject's own methods to "simplify setup" (e.g., patching `OrderService.calculate` inside `test_order_service_calculate`). If setup is too hard, that's a design signal to report, not a thing to mock around
- Do not stub the module export and then import and test the stub. Check what the test actually imports
- A sanity check before finishing: would this test fail if the subject's body were replaced with a hardcoded return or an exception? If not, the test is testing nothing — rewrite it
- If the subject is genuinely untestable without replacing it, say so and ask, rather than shipping a vacuous test

**Red flags that you're about to violate this:**
- "This function is hard to set up, I'll just mock it and test around it..."
- "I'll patch calculate() so the test is deterministic..."
- "Mocking the whole service keeps the test fast..."
- "The function's internals are tested elsewhere, so stubbing it here is fine..."
- "I'll return a fixed value so the assertion is simple..."

### Never Skip Failing Tests

NEVER add `.skip`, `xit`, `xdescribe`, `@pytest.mark.skip`, `@Disabled`, `t.Skip()`, or any equivalent to a test that is currently failing. A failing test is a work item, not an obstacle.

**The core problem:** skipping converts a loud failure into permanent silence. The suite goes green while the behavior the test guarded goes unwatched.

When a test fails, your options in order:
- Fix the code so the test passes (the default assumption: the test is right)
- If you believe the test itself is wrong, say so explicitly, show your evidence, and ask before changing it
- If you cannot fix it, leave it failing and report exactly which tests fail and why

Rules:
- Do not skip a test "temporarily" — there is no mechanism that makes you come back
- Do not skip with a reason string like `skip("flaky")` or `skip("TODO: fix")`; that is documentation of a silenced alarm, not a fix
- Do not move a failing test to a quarantine file, tag it `@slow`/`@manual`, or exclude it via test runner config — those are skips wearing costumes
- A suite that is green because tests were skipped does not count as passing. Never report it as passing

If the user explicitly asks you to skip a test, comply, but state plainly what coverage is being lost.

**Red flags that you're about to violate this:**
- "I'll skip this for now and come back to it..."
- "This test is unrelated to my change anyway..."
- "This one looks flaky, skipping it is safer than touching it..."
- "The user wants green tests, and skip technically gets us there..."
- "I'll mark it skip with a TODO so it's tracked..."
- "It's just one test out of four hundred..."

### Never Weaken Assertions to Pass

NEVER make a failing test pass by loosening its assertions. The strength of an assertion is part of the test's contract; reducing it to achieve green is silencing the test in slow motion.

The core problem: replacing exact matches with partial ones (`toEqual` to `objectContaining`, equality to `toContain`, value checks to truthiness or length checks) removes exactly the sensitivity that was catching the current bug.

Rules:
- While a test is red, its assertions are load-bearing. Do not relax matchers, drop asserted fields, widen accepted ranges, or convert exact comparisons to substring/shape checks
- The question is never "what assertion would pass?" It is "what does correct behavior look like?" — answer that first, from the spec or the test's intent, then see which side is wrong
- If an assertion is genuinely over-specified (asserting on a timestamp, a generated ID, ordering the contract never promised), fix only that field — and say explicitly which part you relaxed and why it was never part of the contract. Replace it with a targeted matcher (`expect.any(String)` for the ID), not a blanket loosening
- Loosening as part of an explicit, user-approved contract change is fine. Loosening discovered in the same diff that broke the test is not refactoring
- After any assertion edit, state plainly: what the test could catch before, and what it can catch now. If the second list is shorter, justify it or revert

**Red flags that you're about to violate this:**
- "objectContaining is more maintainable anyway..."
- "The test was too strict, checking fields nobody cares about..."
- "I'll assert the important part and ignore the rest..."
- "Exact equality makes tests brittle, best practice is partial matching..."
- "It passes if I just check the array isn't empty..."
- "I'm not removing the assertion, just making it more flexible..."

### No Auto-Retry Flaky Band-Aids

NEVER add retry mechanisms (`jest.retryTimes`, `@pytest.mark.flaky`, rerun plugins, Playwright `retries`, retry loops inside the test) to make an intermittently failing test pass. Retries don't remove nondeterminism — they hide it behind better odds.

The core problem: a retried test reports "passed" even when it failed first, permanently converting an intermittent failure signal into silence. If the intermittency comes from the code (a race, an unawaited write), retries ship it with a green stamp.

Rules:
- An intermittent failure means something is nondeterministic. Find it: run the test in a loop to measure the failure rate, read the actual failure output, and locate the instability (shared state, timing assumption, unawaited async, real race in the code)
- Fix the instability itself: wait on conditions instead of durations, isolate test state, await the operation, or — if the code races — fix the code and report the bug
- Do not add a retry "temporarily while we investigate." Retried tests stop hurting, and investigations that stop hurting stop happening
- Do not hand-roll the same dodge inside the test body: `for attempt in range(3): try: ... break` is the decorator with extra steps
- If the team or user has an explicit policy of retrying a specific class of tests (e.g., true end-to-end tests against shared environments), follow it — but never extend retries to new tests on your own initiative, and never use retries on unit or integration tests, which have no excuse for nondeterminism
- When you remove a sleep or fix a race, prove it with a loop run (50 to 100 iterations), not a single green pass — one pass of a dice roll proves nothing

**Red flags that you're about to violate this:**
- "A retry annotation will stabilize this while we look into it..."
- "E2E tests are just flaky, everyone retries them..."
- "Two retries is harmless insurance..."
- "The test passes on rerun, so the code is fine..."
- "Other tests in this repo already use the flaky marker..."

### No Committed Focused Tests

NEVER leave a focus marker — `.only`, `fit`, `fdescribe`, `test.only`, `describe.only`, `it.focus`, or any equivalent — in test code you deliver. A focused test doesn't run one test extra; it stops every other test from running, silently.

The core problem: focus markers are debugging tools whose effect outlives the debugging. One leftover `.only` converts a 35-test file into a 1-test file while the runner keeps printing PASS.

Rules:
- Focus markers are fine while actively iterating; preferable is the runner's filter flag instead (`jest -t "handles refunds"`, `pytest -k refunds`, `--grep`), which narrows the run without editing the file and therefore cannot be committed
- Before declaring any test work done, sweep for focus markers in everything you touched: search for `.only(`, `fit(`, `fdescribe(`, `focus`, and your framework's equivalents. This sweep is part of finishing, not optional polish
- After removing a focus marker, run the full file again — the tests you benched while focusing have not run against your final code, and "it passed" so far refers only to the focused one
- Compare test counts: if the file ran 1 test where it has 35, or the suite total dropped versus the baseline, find out why before reporting anything
- If you inherit a file that already contains someone's committed `.only`, flag it immediately — every test it benched has been unexecuted for an unknown number of commits, and they need a run before anyone trusts them
- Where the project has lint support, recommend enabling it (`no-focused-tests` in eslint-plugin-jest/mocha rules) so this class of leftover fails fast

**Red flags that you're about to violate this:**
- "The focused test passes now, task complete..."
- "I'll leave the .only since I might iterate more..."
- "The suite is green, so everything must have run..."
- "Removing the marker is cosmetic, I'll mention it instead of doing it..."
- "The other tests in this file were passing before, no need to rerun them..."

### No Conditional Assertions

NEVER put a test's assertions inside an `if` (or any condition) that can skip them. A test where the assertions might not run is a test that might be testing nothing — and the runner will still report it as passing.

The core problem: test runners count failures, not assertions. When the guard condition is false, no assertion executes, and silence is scored as success — precisely when the code is most broken.

Rules:
- Assert the condition itself, unconditionally, then proceed: `expect(user).not.toBeNull()` followed by `expect(user.role).toBe('admin')`. The null case must FAIL, not skip
- Never write `if (result) { expect(...) }`, `if response.ok: assert ...`, or assertions reachable only via one branch of the data's behavior. If the data determines which branch runs, the wrong branch must hit a failing assertion or an explicit `fail()`/`pytest.fail()`
- For legitimately environment-dependent tests (feature flag off, platform-specific), use the framework's explicit skip with a reason (`test.skipIf`, `@pytest.mark.skipif`) so the report shows SKIPPED — never an `if` that lets the test pass silently
- Guarding against exceptions with conditionals is solving the wrong problem: in a test, the crash was a correct failure signal. Don't trade a loud crash for a quiet pass
- Audit check: count assertions that are guaranteed to execute on every path. If the answer can be zero, the test is broken regardless of its color

**Red flags that you're about to violate this:**
- "I'll guard the dereference so the test doesn't crash on null..."
- "Only check the body if the response succeeded..."
- "This avoids a TypeError when the list is empty..."
- "If the data isn't there, there's nothing to assert anyway..."
- "Defensive coding makes the test more robust..."

### No Coverage Theater Tests

NEVER write a test whose purpose is to make a coverage number go up. Coverage is a side effect of verifying behavior; a test that executes lines without checking their results adds coverage and subtracts trust.

The core problem: a line that runs under no meaningful assertion is counted as covered but verifies nothing — the metric inflates while the module remains exactly as unverified as before, now with a number saying otherwise.

Rules:
- Every test must assert a specific, behavior-relevant outcome of the code it executes. "It didn't throw" plus a placeholder assertion is execution, not testing
- When asked to raise coverage, the deliverable is verification of the uncovered behavior, not the threshold. For each uncovered region, determine what the code is supposed to do there, then write the test that would fail if it didn't
- Do not exclude code from coverage measurement (`/* istanbul ignore */`, `# pragma: no cover`, coverage config exclusions) to hit a threshold. Exclusion is for genuinely untestable lines (e.g., process-exit guards), and each one should be justified
- Do not call functions solely to touch their lines, suppress their errors, and move on — that converts the coverage report from "what is verified" into "what has merely run," which is worth nothing
- If a region is uncovered because it's genuinely hard to test (deep ORM internals, time-dependent branches), say so and propose options (refactor for testability, integration-level test, accept the gap) rather than papering it with theater
- Honest reporting: if coverage went up but some new tests are weak, say which ones and why

**Red flags that you're about to violate this:**
- "I just need 3% more to clear the threshold..."
- "Calling these methods covers the lines, the assertions can be light..."
- "expect(true).toBe(true) at the end keeps the runner happy..."
- "I'll exclude this file from coverage, it's hard to test anyway..."
- "The metric is what's being asked for, not a testing philosophy..."

### No Duplicate Test Names

NEVER add a test whose name already exists in the same file or class. In Python, the new definition silently replaces the old one — adding a test can delete a test, with no error and no diff line showing the loss.

The core problem: appending is how tests get added, and natural names collide. A shadowed test stops being collected entirely; the suite stays green because the alarm wasn't triggered — it was unplugged.

Rules:
- Before adding a test, search the file (and its class) for the name you're about to use — and for the behavior you're about to cover. Grep the test name; don't trust that you'd have noticed
- If the name exists, first decide whether the existing test already covers your case. The right move may be extending it or adding a distinct case, not writing a near-twin
- If you genuinely need a new test of similar intent, differentiate the name by what's different about the case: `test_validates_email_rejects_missing_at` vs `test_validates_email_accepts_subdomains` — specific names prevent the next collision too
- After adding tests, verify the collected count went UP by the number you added (`pytest --collect-only -q | tail`, compare runner totals). Same count after adding two tests means something got shadowed
- In JS/parameterized frameworks, the same discipline applies to `it()` descriptions and parametrize IDs: duplicate names break filters, reporters, and snapshot keys even when both tests run
- When you find an existing duplicate pair, flag it — one of them has been dead, and which one matters

**Red flags that you're about to violate this:**
- "I'll add the new test at the bottom, the natural name is test_validates_email..."
- "This file is huge, I'll just append without reading the whole thing..."
- "The diff is purely additive, so nothing can have been lost..."
- "If a name collided, the runner would error..."
- "Test counts bounce around anyway, no need to compare totals..."

### No Environment-Dependent Tests

A test must pass on any machine: any timezone, any locale, any OS, any shell. NEVER let a test's outcome depend on environment properties it doesn't explicitly control.

The core problem: environment assumptions enter silently — through locale-default formatting, local-time date parsing, OS path behavior, ambient env vars — and produce tests that pass for the author and fail for everyone else.

Rules:
- Timezone: never assert local-time renderings of a timestamp without pinning the zone. Construct dates explicitly in UTC (`Date.UTC(...)`, ISO strings with offsets, `datetime(..., tzinfo=timezone.utc)`); if the code under test formats in local time, set the zone for the test (`TZ=UTC` for the run, `timezone_machine`/library-level zone injection) and say which zone you pinned
- Locale: `toLocaleString`, `strftime` month names, decimal separators, and collation-based sort orders all vary by locale. Either pass the locale explicitly to the formatting call/assertion, or pin it for the test — never lean on the machine default
- Environment variables: a test that needs one sets it itself (via restoring mechanisms); a test that must not be affected by one clears it. Never depend on whatever the invoking shell exports
- Filesystem and OS: don't rely on case-insensitive filenames, path separator quirks, `/tmp` semantics, or tool availability (`which gsed`) that differ across platforms — build paths with the stdlib's path APIs and gate genuinely platform-specific tests with explicit, visible skips
- Network and ambient services: a unit test that touches a real host or assumes a port is free inherits every property of the machine around it; fake the boundary instead
- Review your own assertions for locale/zone fingerprints: slashes vs dots in dates, AM/PM, comma decimals, month names — each one is an assumption about the machine, written as an expectation about the code

**Red flags that you're about to violate this:**
- "The formatted output is 06/10/2026 here, so that's the expected value..."
- "CI also runs Linux, the path handling will be the same everywhere..."
- "That env var is always set in practice..."
- "toLocaleString output is stable enough to assert on..."
- "It passes on my run, the test is correct..."

### No Hardcoded Dates in Test Fixtures

NEVER write a test whose outcome depends on the real current date or time. Any test mixing a hardcoded date literal with the live clock is a scheduled failure.

The core problem: a fixture date that means "recent" or "expired" *today* stops meaning that as the calendar moves, and the test fails later on an unrelated change.

Rules:
- Control the clock: freeze time with the framework's tool (`jest.useFakeTimers().setSystemTime(...)`, `freezegun.freeze_time(...)`, `time-machine`, injected clock) and write fixtures relative to the frozen moment
- If freezing isn't available, compute fixture dates from now (`now - 5 days`, `now + 1 year`) so their meaning is stable — never mix computed-from-now dates with literal dates in the same logic
- Hardcoded date literals are fine only when the test never consults the real clock: pure formatting/parsing tests, or fully frozen-time tests
- Watch the boundary cases you create: a fixture at exactly 30 days hits off-by-one differently depending on time of day. Place fixtures clearly inside or outside windows, and add explicit boundary tests with frozen time
- Treat "far future" literals (`2030-01-01`) as hardcoded dates too — they expire, just slower
- When you see an existing test fail on date math you didn't touch, say so: it's a time bomb to defuse, not a regression from the current change

**Red flags that you're about to violate this:**
- "I'll use today's date for the created_at field, it's realistic..."
- "2027 is far enough in the future, this'll never matter..."
- "The test passes now, the date logic must be fine..."
- "Freezing time is overkill for one little fixture..."
- "I'll just subtract a few days from new Date() right here inline..."

### No Kitchen-Sink Snapshots

NEVER snapshot an entire rendered tree, full API response, or large object as a substitute for deciding what the test should assert. A snapshot that captures everything specifies nothing — it fails on every irrelevant change until people reflexively update it without reading.

The core problem: a giant snapshot has no intent. When it goes red, nobody can tell the meaningful line from the noise, so the diff goes unread and the update flag becomes the team's muscle memory — at which point the test enforces nothing.

Rules:
- Assert the contract explicitly: the heading text, the row count, the formatted total, the disabled state — `expect(screen.getByRole('button')).toBeDisabled()` beats 900 lines of serialized DOM
- If you must snapshot, snapshot small and targeted: a single element's text, one extracted subobject, an inline snapshot (`toMatchInlineSnapshot`) short enough to live readably in the test file. If it doesn't fit inline comfortably, it's too big
- Never snapshot trees containing volatile data (timestamps, IDs, versions, generated class names) without normalizing or masking those fields — volatile snapshots are pre-scheduled false alarms
- Don't snapshot other components' internals: a Dashboard snapshot that serializes every child widget makes every child team's change your test failure
- For full API responses, assert the fields the consumer relies on; if schema stability itself is the contract, use a schema validation, not a byte-for-byte freeze
- Before writing `toMatchSnapshot()`, answer: which specific lines of this output am I protecting? If you can name them, assert them directly; if you can't, you're not ready to write the test

**Red flags that you're about to violate this:**
- "One snapshot covers the whole component, very thorough..."
- "Snapshotting everything means we'll catch any regression..."
- "I don't know exactly what matters here, the snapshot captures it all..."
- "It's just one line of test code for full coverage..."
- "The diff will show reviewers what changed..."

### No Placeholder Passing Tests

NEVER leave a test that passes without testing anything: empty bodies, `pass`, `assert True`, `expect(true).toBe(true)`, bodies that are only comments or TODO markers. A green placeholder is a lie with a descriptive name — everyone who reads the test report believes coverage exists where there is none.

The core problem: runners score an assertion-free body as a pass. The test's name then advertises verified behavior that nothing verifies, and that advertisement persists indefinitely.

Rules:
- Write the body when you write the test. If you're sketching a test plan, sketch it as comments or a list in your summary — not as runnable green tests
- If a planned test must be deferred, use the framework's explicit mechanism so it CANNOT report as passed: `it.todo('validates input')` (Jest), `pytest.fail("not implemented")` or `pytest.skip("not implemented")` with reason, `t.Skip("TODO")` — these show up honestly in reports as todo/skipped/failed
- Never gut a test you couldn't get working down to `pass`/`assert True` to move on. Leave it failing, or mark it explicitly as unimplemented, and say so in your report
- A body of setup with no assertions is the same defect wearing more clothes — calling the function and asserting nothing still scores green. Every test asserts something real or doesn't exist
- Before finishing any test-writing task, sweep your own output: search for `pass`, `assert True`, `toBe(true)`, empty arrow bodies, and TODO inside test functions. Count assertions per test; zero is disqualifying
- Report honestly: "I wrote 8 tests; 3 more are listed as todos" beats 11 green dots of which 3 are vapor

**Red flags that you're about to violate this:**
- "I'll stub out the test structure now and fill it in after..."
- "assert True keeps the runner from complaining about an empty body..."
- "The test names document what should be tested, that's already useful..."
- "I couldn't get this one working, I'll neutralize it rather than leave it red..."
- "Nobody audits individual test bodies anyway..."

### No Real User Data in Fixtures

NEVER put real personal data, real credentials, or records copied from production into test fixtures, seed data, or test code. Committed test data is permanent, replicated, and eventually public — treat every fixture as if it will be read by strangers, because via git history, it can be.

The core problem: real data enters tests through the path of least resistance — bug reports, logs, pasted records, visible env files — and once committed, it cannot be reliably recalled.

Rules:
- Fixtures use obviously fake identities: `test-user-1@example.com` (RFC-reserved domains: example.com/.org/.net), names like "Test Testerson," phone numbers from reserved ranges (e.g., 555-01XX), addresses that don't geocode to a real residence
- Credentials in fixtures must be syntactically valid but inert: `sk_test_` style markers, `"FAKE-TOKEN-FOR-TESTS"`, locally generated throwaway keys. NEVER copy a value from an env file, a config, a log line, or the conversation into a fixture — if it ever worked anywhere, it doesn't belong in a test
- When reproducing a production bug, extract the *structure* that triggers it (field lengths, unicode, null pattern, nesting) and rebuild it with fake values. The bug lives in the shape, not in the customer's actual name
- Card numbers, SSNs, government IDs: only documented test values (e.g., 4242 4242 4242 4242-class numbers), never anything observed in real traffic
- If you encounter existing fixtures containing what looks like real PII or live secrets, flag it to the user immediately — including the git-history implication — rather than building more tests on top of it
- Realism that matters for tests is structural (edge-case shapes, encodings, lengths), and fake data can carry all of it

**Red flags that you're about to violate this:**
- "I'll use the actual record from the bug report so the repro is faithful..."
- "This API key is already in the .env file, the fixture can reference the same value..."
- "It's just one customer's email, and it's only test data..."
- "Sanitizing the dataset will change the repro conditions..."
- "The repo is private, so committed test data is safe..."

### No Shared Mutable Test Fixtures

NEVER let multiple tests share a mutable fixture object. Every test gets fresh data, built or cloned per test, so no test can inherit another test's mutations.

The core problem: `const`/module-level fixtures protect the reference, not the contents. One test pushes to an array or flips a field, and every later test in the process sees the altered object — producing failures that depend on execution order and vanish when tests run alone.

Rules:
- Use factory functions, not shared literals: `function makeOrder(overrides = {}) { return { items: [item()], status: 'pending', ...overrides }; }` — each call returns a new object graph
- Watch the shallow-copy trap: `{ ...baseOrder }` still shares the nested `items` array. Clone deep or (better) construct fresh
- In pytest, use function-scoped fixtures (the default) for anything mutable; treat `scope="module"`/`scope="session"` on mutable objects as a bug unless the fixture is genuinely read-only. Never use mutable default arguments in fixture helpers
- In JS, build mutable fixtures inside `beforeEach`, not at module load; module scope persists across every test in the file
- Shared *immutable* data (frozen constants, primitive config values) is fine — the rule is about anything a test can mutate
- Diagnostic: a test that fails in the full run but passes in isolation has, until proven otherwise, an order dependency — go looking for the shared object, not for a bug in the failing test

**Red flags that you're about to violate this:**
- "I'll hoist this fixture to module level so all the tests can reuse it..."
- "DRY applies to test data too, one baseUser for everyone..."
- "A spread copy is enough, the tests barely modify it..."
- "Session-scoped fixtures are faster, and these tests only read the data..."
- "I'll just push the extra item onto the shared list for this one case..."

### No Sleep-Based Flaky Test Fixes

NEVER fix a timing-dependent test failure by adding or increasing a fixed sleep (`sleep`, `setTimeout`-as-delay, `Thread.sleep`, `time.sleep`). Wait for conditions, not durations.

The core problem: a sleep doesn't remove a race, it re-handicaps it. The test still fails on slow machines and still wastes the full duration on fast ones — you've made the suite slower *and* kept the flake.

Instead:
- Await the actual operation: the promise, the task handle, the future. If you can't get a handle on it, that's the bug to fix
- Poll for the condition with a timeout: `waitFor(() => expect(el).toBeVisible())` (Testing Library), `await expect(locator).toHaveText(...)` (Playwright auto-waits), `eventually`/`awaitility`/tenacity-style helpers. These pass the instant the condition holds and fail loudly when it never does
- Use fake timers for code that schedules work (`jest.useFakeTimers()` then `advanceTimersByTime`), so the test controls time instead of racing it
- Synchronize via the system's own signals: completion callbacks, events, queue-drained hooks, database state checks
- If a sleep already exists and the test still flakes, do not raise the number. Find what the sleep was approximating and wait for that
- One legitimate sleep: when verifying that something does NOT happen within a window — and even then, prefer fake timers

**Red flags that you're about to violate this:**
- "It probably just needs a bit more time..."
- "I'll bump the sleep from 2s to 5s to be safe..."
- "A short delay here makes the test stable..."
- "It passed after I added the sleep, so that confirmed the fix..."
- "Polling is more complex, a sleep does the same job..."

### No Tautological Expected Values

NEVER compute a test's expected value using the same logic, formula, or production code as the thing under test. If both sides of the assertion share an error, the test passes — so they must not be able to share one.

The core problem: a test that mirrors the implementation verifies that the code equals a copy of itself. Wrong rate, wrong rounding, wrong branch — both sides agree, green forever.

Rules:
- Use precomputed literals, worked out by hand or from the spec: `assert calculate_late_fee(1000, 12) == 33.50` with a comment showing the arithmetic. A human-verifiable number is the whole point
- Do not import production helpers to build expectations: asserting `format_invoice(x) == format_invoice_expected_via_same_formatter(x)` tests nothing. The expected string should be typed out
- Do not build expected collections by applying the same `map`/`filter`/`sort` the code applies. Write the expected list literally, or assert independently checkable properties (totals, counts, specific elements)
- When the calculation is too complex for hand-derivation, use independently sourced cases: examples from the spec or RFC, known input/output pairs from documentation, values cross-checked with a different tool — anything whose correctness doesn't route through this codebase
- A duplicated-logic test is acceptable only as a differential test against a *genuinely independent* implementation (old system, reference library) — and label it as such
- Self-check: could a bug in the production formula make this test fail? If the test would inherit the bug, it's a tautology

**Red flags that you're about to violate this:**
- "I'll compute the expected value the same way the function does, to be accurate..."
- "Importing the formatter keeps the expected output in sync..."
- "Hardcoded numbers are magic values; deriving them is cleaner..."
- "The formula is right there in the implementation, no point re-deriving it..."
- "Building the expected list with a map keeps the test DRY..."

### No Test Order Dependencies

Every test must pass when run alone, and pass when run in any order. NEVER write a test that consumes state — records, files, logins, caches, globals — created by another test.

The core problem: order-dependent tests aren't individually meaningful; they're steps in a script. The moment the runner parallelizes, randomizes, filters, or someone runs one test by name, the script breaks and the failures point at innocent tests.

Rules:
- Each test creates what it needs. If three tests need a registered user, each builds one (via factory or fixture) — shared *setup code* is good; shared *runtime state* is the bug
- Never reference by name or ID something a previous test created ("the user from the signup test"). If you're tempted, that setup belongs in a fixture both tests call
- Clean up or randomize side effects: unique emails/usernames per test (`f"user-{uuid4()}@test"`), per-test temp dirs, transaction rollback or truncation between tests — so leftovers can't couple tests by accident
- Do not "fix" an order-dependent failure by reordering tests, renaming files to control run order, or disabling parallelism/randomization in the runner config. Those lock the dependency in; fix the dependency
- Multi-step flows that genuinely must be sequential (signup then login then purchase) belong inside ONE test as explicit steps, not spread across three tests holding hands
- Verification that means something: run the new test by itself, and run the file with order randomized if the runner supports it (`pytest -p randomly`, `--random-order`)

**Red flags that you're about to violate this:**
- "Test two can reuse the account test one just created..."
- "Recreating the user in every test is wasteful duplication..."
- "I'll move this test above the other one so the data exists by then..."
- "It passes when the whole file runs, that's what CI does anyway..."
- "I'll disable parallel execution for this file, the tests need their order..."

### No Timeout Bumps to Pass Tests

NEVER respond to a test timeout by raising the timeout, until you have measured what the test actually does with the time and explained why the duration is legitimate. A timeout is a performance assertion; bumping it is weakening an assertion.

The core problem: a test that newly exceeds its timeout is usually reporting that the code got slower — a hang, a retry storm, an N+1 query. Raising the limit silences the report and ships the slowness.

When a test times out:
- First ask: did this test pass within the limit before? If yes, something regressed — find it. Diff the recent changes, profile the test, log timestamps around the slow section
- Distinguish hang from slow: a test that times out at any limit (deadlock, unawaited promise, missing event) will not be fixed by 30 seconds; it will fail in 30 seconds instead of 5
- Check whether your own change introduced the slowness before blaming infrastructure
- Never raise the global/default timeout to fix one test. That weakens the performance assertion on every test in the suite
- A targeted increase is legitimate when the test genuinely does more than before (you added cases, the fixture grew) — state the new expected duration and why, and scope the increase to that one test
- If the operation is legitimately slow because it does real I/O a unit test shouldn't do, the fix is the test's design, not its budget

**Red flags that you're about to violate this:**
- "CI machines are just slow, I'll give it more headroom..."
- "Doubling the timeout is the quick fix, I'll investigate later..."
- "The error says timeout exceeded, so the timeout is the problem..."
- "I'll bump the global timeout so this stops happening anywhere..."
- "It passes at 30 seconds, so it works..."

### No Trivial Test Assertions

NEVER write a test whose only assertions are existence checks: `toBeDefined()`, `toBeTruthy()`, `not.toBeNull()`, `is not None`, `assertIsNotNone`, or length-greater-than-zero. Every test must assert something specific about the value that would fail if the code computed the wrong answer.

The core problem: existence assertions pass for wrong outputs, error objects, and empty shells. They measure that the function returned, not that it returned the right thing.

Rules:
- Assert concrete values: `expect(total).toBe(42.50)`, `assert user.email == "a@b.com"`, exact lengths, exact keys
- When exact values are impractical, assert meaningful properties: sorted order, sums, invariants, specific fields — not mere presence
- `toBeDefined()` is acceptable only as a guard immediately followed by real assertions on the same value, never as the test's conclusion
- For response objects, assert status AND body content, not just "got a response"
- If you cannot determine what the correct output is, do not paper over it with a vague assertion — read the spec or implementation until you can, or ask
- Self-check before finishing: for each test, name one realistic bug it would catch. If the honest answer is "only the function vanishing entirely," strengthen it

**Red flags that you're about to violate this:**
- "I'll just verify the function returns something..."
- "I'm not sure of the exact value, so toBeTruthy is safer..."
- "A smoke check is enough for this one..."
- "Asserting the exact output would make the test brittle..."
- "The important thing is that it doesn't return null..."

### No Try/Catch Swallowing in Tests

NEVER wrap test logic in try/catch (or try/except) to keep an exception from failing the test. An unexpected exception in a test is the test working.

The core problem: a catch block in a test eats not just the crash you were avoiding, but assertion failures too. The test becomes unfailable and the runner reports it as passing.

Rules:
- No empty or pass-only catch blocks in tests, ever. No `.catch(() => {})` on awaited operations, no `except Exception: pass`
- If the code under test is *supposed* to throw, assert it precisely: `pytest.raises(SpecificError)`, `expect(fn).toThrow(SpecificError)`, `assertRaises` — these are assertions, not exception handling
- If an exception is unexpected, let it propagate. The traceback in the failure output is the diagnostic; swallowing it deletes the evidence and the failure simultaneously
- Do not catch-and-log either (`except Exception as e: print(e)`) — a printed error in a passing test is invisible
- A catch block that ends in `pytest.fail(...)` or rethrows after adding context is legitimate; one that lets the test return normally is not
- If you find yourself adding a try/catch to get past an error you don't understand, stop: report the error and what you tried instead

**Red flags that you're about to violate this:**
- "This throws sometimes in CI, I'll add defensive handling..."
- "Wrapping it in try/except makes the test more robust..."
- "I'll catch the error and just check the parts that work..."
- "The exception is from the environment, not the code, so it's safe to ignore..."
- "Good code handles exceptions, tests are code..."

### Review Snapshot Diffs Before Updating

NEVER run a snapshot update command (`jest -u`, `--ci false` updates, `pytest --snapshot-update`, `UPDATE_SNAPSHOTS=1`, `cargo insta accept`, or equivalents) without first reading the failing diff and confirming every change is intended.

The core problem: updating a snapshot is approving new output as correct. Doing it blind converts the test from a change detector into a rubber stamp for whatever the code currently emits, including your own bugs.

Process when snapshots fail:
- Read the actual diff for each failing snapshot. The test runner prints it; do not scroll past it
- For each change, classify it: expected consequence of the requested change, or unexplained. Anything unexplained is a bug investigation, not an update candidate
- Quote or summarize the diff to the user before updating: what changed, in which snapshots, and why it's correct
- Never bulk-update dozens of snapshots in one pass on the theory that the change was global. Global changes still have diffs worth skimming, and that's where the one wrong one hides
- If a snapshot diff shows data that shouldn't be there (secrets, PII, raw error dumps), stop entirely and report it
- Updating snapshots is acceptable when the diff is read, explained, and matches the intended change. The flag isn't banned; blindness is

**Red flags that you're about to violate this:**
- "These snapshot failures are just noise from my change, I'll regenerate them..."
- "It's 40 failing snapshots, obviously they all changed for the same reason..."
- "Snapshot tests are always stale, updating is routine maintenance..."
- "I'll update them now and verify the output renders correctly later..."
- "The diff is huge, reading it all isn't practical..."

### Sandbox Test Side Effects

Tests must leave the machine exactly as they found it. NEVER write to real user directories, the repo working tree, shared paths, environment variables, or process globals without an automatic, failure-proof restore.

The core problem: leaked side effects outlive the test and corrupt later runs, parallel workers, other tests, and the developer's actual machine — producing failures whose cause is far away from their symptom.

Rules:
- Filesystem: use the framework's managed temp dirs — `tmp_path` (pytest), `t.TempDir()` (Go), `mkdtemp` in setup with teardown removal. Never write into the repo tree, `~`, or hardcoded `/tmp/myapp` paths (which collide under parallel runs)
- If the code under test has a hardwired real path, inject or patch the path for the test (`monkeypatch`, config override, env var the code respects) — don't let the test exercise the real location
- Environment variables: only through restoring mechanisms — `monkeypatch.setenv`, or save-and-restore in setup/teardown. A bare `process.env.X = ...` or `os.environ[...] = ...` in a test body is a leak in waiting
- Globals, singletons, module state, registered handlers, frozen time, network interceptors: every mutation needs a paired restore in teardown — `afterEach`, fixture finalizers, `jest.restoreAllMocks()`, `nock.cleanAll()`
- Cleanup goes in teardown hooks or fixtures, NEVER inline at the end of the test body — an assertion failure skips inline cleanup, so the test leaks exactly when it fails, which is when you least need extra chaos
- Verification: run the test twice in a row, and check `git status` is clean afterward. Second-run failure or new untracked files means you leaked

**Red flags that you're about to violate this:**
- "The test writes the file right here in the project, easy to inspect..."
- "I'll set the env var at the top of the test, it's only for this process..."
- "I added cleanup at the end of the test, after the assertions..."
- "The code always writes to ~/.appname, the test should match reality..."
- "/tmp/test-output is fine, it's temp by definition..."

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

### Test Behavior, Not Implementation

Test what the code promises to callers — inputs, outputs, observable effects — NEVER its private mechanism. A good test survives any refactor that preserves behavior and fails on any change that breaks it.

The core problem: assertions on private methods, internal call counts, and hidden data structures pin the *current implementation* in place. They fail on harmless refactors, training people to ignore red, while passing on real bugs that keep the internal choreography intact.

Rules:
- Assert through the public surface: return values, raised errors, emitted events, persisted records, rendered output. If a fact isn't observable to a caller, think hard before asserting it
- Don't test private methods directly (reaching into `_method`, rebinding privates, `@VisibleForTesting` escalation). If a private is complex enough to demand its own tests, that's a hint it wants to be a separately tested unit
- Don't assert internal call order or call counts of the unit's own helpers (`expect(this._normalize).toHaveBeenCalledBefore(...)`) — assert the result that correct ordering produces
- Call counts ARE the behavior at external boundaries: "charges the card exactly once" or "sends one email" are contracts; assert those freely. The line is whether the collaborator is part of the unit or part of the world
- In UI tests, query by role/text/label the user perceives, not by internal class names or component instance state
- Litmus test before finishing: would this test still pass if the implementation were rewritten from scratch with identical behavior? If no, you've tested the mechanism

**Red flags that you're about to violate this:**
- "I'll spy on the internal helper to make sure it's invoked..."
- "Asserting the private state directly is more precise..."
- "Checking the call sequence proves the algorithm is right..."
- "I'll export this private function just so the test can reach it..."
- "Testing through the public API is too indirect..."

### Test Boundary and Edge Inputs

Every test suite must probe the edges, not just the middle. Typical inputs catch almost nothing — bugs concentrate at boundaries, and a `>` vs `>=` error is invisible to every input except the boundary value itself.

The core problem: comfortable mid-range cases (3 items, quantity 5, "John Doe") exercise the code where it was never going to fail, producing a green suite with no opinion about the inputs that break things.

For each input domain, deliberately cover:
- Emptiness and minimal cases: empty list/string/map, single element, whitespace-only string
- Zero and signs: 0, negative numbers anywhere a quantity/amount/index flows, -0.0 where floats matter
- Every boundary in the code, three ways: at the limit, one below, one above. If the code says `if count >= 10`, you owe tests for 9, 10, and 11 — the threshold constants in the code ARE your test-case list
- Extremes: max lengths, huge collections, values at type limits, deeply nested structures
- String hostility where strings are parsed or stored: unicode beyond ASCII, emoji, RTL text, quotes/apostrophes, leading/trailing whitespace, embedded newlines
- Duplicates and order: repeated elements, already-sorted/reverse-sorted input, ties in comparisons
- Null/None/undefined for every optional parameter, and missing-vs-present-but-empty for fields
- Read the implementation for its constants and comparisons — each numeric literal and comparison operator is a boundary someone can get wrong by one
- If the correct behavior at an edge is undefined (what SHOULD an empty cart total be?), surface the question rather than asserting your guess

**Red flags that you're about to violate this:**
- "A few representative cases cover the logic..."
- "Nobody passes an empty list to this function..."
- "I tested 5 and 50, the threshold at 10 is obviously fine between them..."
- "Standard names and ASCII keep the fixtures readable..."
- "More tests of normal usage is what thorough means..."

### Test Error Paths, Not Just Happy Paths

ALWAYS test what the code does when things go wrong, not only when they go right. Every catch block, early return, validation rejection, and retry branch is code — untested code — until a test forces it to run.

The core problem: error handling is the code that runs during incidents, and it's typically the only code in the module with zero coverage. A suite of all-valid inputs certifies the system for the one day nothing fails.

For each unit you test, cover at minimum:
- Invalid input: the malformed, the missing, the wrong type, the too-large — and assert the specific rejection (error type/message), not just non-success
- Dependency failure: make the mocked database reject, the HTTP call return 500/timeout, the queue be full (`mockRejectedValue(new TimeoutError())`, `side_effect=ConnectionError`) — then assert the contract: does it retry, surface a clean error, roll back, release resources?
- Partial failure: the third item of ten fails — is the result a clean abort, a partial success with a report, or silent data loss? Whatever the contract is, pin it
- Assert the error path's *behavior*, not just that an error happened: the transaction rolled back, the temp file was cleaned up, the user-facing message contains no stack trace
- If you discover the code has no defined behavior for a failure case (the catch block is empty, the timeout case can't happen by design), report that as a finding — do not quietly test around it
- Rough budget: if fewer than a third of your tests for a unit exercise non-happy paths, you're probably describing the demo, not testing the code

**Red flags that you're about to violate this:**
- "The main functionality is covered, that's the important part..."
- "Error cases are edge cases, I'll add them if asked..."
- "Making the mock fail is a lot of setup for an unlikely path..."
- "The framework handles errors, no need to test that..."
- "All tests pass, the handler is solid..."

### Test Names Must Match What They Assert

A test's name is a claim, and the body must back it. NEVER name a test for a behavior its assertions don't actually verify — an overpromising name is how a gap in coverage hides from everyone who looks for it.

The core problem: people audit suites by reading names, not bodies. `test_handles_invalid_input` that never passes invalid input doesn't just skip the check — it answers "is invalid input tested?" with a false yes, forever.

Rules:
- After writing a test, reread the name as a checklist against the body: every behavior-word in the name (retries, rejects, concurrent, gracefully, rolls back, validates) must correspond to something the test sets up and asserts. "Retries" requires an induced failure and an assertion about subsequent attempts; "rejects" requires the bad input and the rejection
- If you couldn't make the named scenario happen — the failure was hard to induce, the concurrency was fiddly — rename the test to what it actually does, and report the named scenario as still untested. Do not let the name keep the ambition the body abandoned
- Name what's asserted, not the setup vibe: `'returns cached value when present'` beats `'cache works correctly'` — and if a name resists being specific, the test probably asserts too little or too much
- One claim per name where practical; a name with "and" in it usually contains an unverified half
- Words that earn extra suspicion in your own output: "gracefully," "correctly," "properly," "handles," "robust" — they describe a feeling, and bodies rarely assert feelings
- When auditing existing suites, treat name/body mismatches as findings worth surfacing: each one is a question someone will answer wrongly by grepping

**Red flags that you're about to violate this:**
- "The name reflects what this test is meant to cover eventually..."
- "Setting up the actual failure is complex, but the test still has the right title..."
- "handles invalid input sounds better than rejects empty string..."
- "The name comes from the ticket, the body does what was feasible..."
- "Close enough — the test is in the right area..."

### Test the Spec, Not Current Behavior

NEVER derive a test's expected value by running the code and copying its output. Expected values must come from an independent source: the spec, the docs, the ticket, a worked example, or arithmetic you did yourself.

The core problem: a test whose expectation was copied from the implementation can only confirm the implementation agrees with itself. It is incapable of catching a bug, and it actively defends existing bugs against fixes.

Rules:
- For each expected value, be able to answer: how do I know this is correct, *other than* the code producing it? If the only answer is "that's what it returned," you don't have a test yet
- Work examples by hand. If the function computes tax, compute the tax yourself for the fixture inputs and assert your number
- When the spec and the code disagree, you have found a bug, not a test problem. Report it; do not assert the code's answer
- If no spec exists and you genuinely cannot derive the correct value, you may write a characterization test, but you must label it as one (in the test name or a comment) and tell the user: "these tests pin current behavior, which I could not independently verify"
- Suspicious sign in your own output: every test you wrote passed on the first run and none required you to understand the domain

**Red flags that you're about to violate this:**
- "I'll run it once to see what it returns, then assert that..."
- "The function gave 41.99, so that's the expected value..."
- "These tests document the current behavior, which is what tests are for..."
- "I can't easily compute this by hand, but the code's answer looks plausible..."
- "All my new tests pass immediately — great sign..."
