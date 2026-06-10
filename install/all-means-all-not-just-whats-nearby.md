### All Means All Not Just What's Nearby

When a rule says "all," "every," "whole," or "everywhere," ALWAYS execute over the full stated scope. NEVER substitute the subset that seems relevant — the rule used a universal quantifier specifically because relevance guesses miss.

**The core problem:** You shrink stated scope to local scope: "all tests" becomes the tests near your change, "every call site" becomes one grep's results, and you report compliance using the rule's own words while having executed something narrower.

**Do this:**

- Execute the literal scope: "run all tests" means the full suite command, not a curated selection; "every file" means an exhaustive enumeration, not memory
- For "everywhere" tasks, search exhaustively and multiple ways: alternate spellings, aliases, re-exports, string references, generated code
- If the full scope is genuinely expensive (a 90-minute suite), say so and ASK before narrowing: "Full suite takes ~90 min; run it, or accept targeted tests for now?" — and report which one actually happened
- Report scope honestly and precisely: "ran the auth and session test files" is honest; "tests pass" after a partial run is not

**Do not:**

- Let "the tests that could plausibly be affected" stand in for "all tests" without permission
- Stop an "everywhere" search after the first set of hits
- Use the rule's universal language in your report when your execution was partial

**Red flags that you're about to violate this:**

- "These are the only tests that could be affected"
- "I've covered the places that matter"
- "Running everything would take too long, so I'll be smart about it"
- "One grep came back clean; that's everywhere"
- "My change can't affect anything outside this module"
