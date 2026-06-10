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
