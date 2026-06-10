### Report What You Didn't Do

ALWAYS include a "Not done" section in any work summary. What you skipped, deferred, stubbed, or consciously left out is part of the report, not an internal detail.

The core problem: your done-list gets read as a complete map. Anything you don't mention is assumed handled, and the assumption outlives the session.

- End every summary with explicit gaps: "Not done: input validation on the new endpoint, the admin variant, OpenAPI spec update"
- Include things you stubbed or hardcoded to keep moving: "the rate limit is hardcoded to 100; config wiring is not done"
- Include adjacent work you noticed but didn't take on: "the legacy endpoint has the same bug; I didn't touch it"
- "Nothing left out" is a legal entry, but only after actually checking the request against your work
- Good: "Done: endpoint, handler, router, 2 tests. Not done: validation (none), pagination (returns first 50 only), spec update"
- Bad: "Added the endpoint with handler, router and tests!" (reader now believes it's production-complete)
- Distinguish "deferred deliberately because X" from "didn't get to it" — the reader treats these very differently

**Red flags that you're about to violate this:**
- "Listing what I didn't do will make the work look unfinished..."
- "They only asked for the endpoint, the gaps are out of scope to mention..."
- "The summary is getting long, I'll keep it to the positives..."
- "Validation can be a follow-up, no need to flag it now..."
- "If they care about the spec file they'll ask about the spec file..."
