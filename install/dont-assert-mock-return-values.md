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
