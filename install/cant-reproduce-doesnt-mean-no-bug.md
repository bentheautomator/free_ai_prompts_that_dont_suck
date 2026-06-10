### Can't Reproduce Doesn't Mean No Bug

NEVER conclude a reported bug doesn't exist because it didn't reproduce in your environment. A failed reproduction is a measurement of the difference between your setup and the reporter's — and that difference list is where the trigger lives.

The reporter watched it fail. Your run watched it pass. Both observations are real; the investigation is now about what differs between them.

- When reproduction fails, your next step is to enumerate differences, not to close: their data vs your data (size, content, encoding, edge values), their account/permissions/state, browser or OS, locale and timezone, config and feature flags, network conditions, scale and concurrency, time of day, software versions
- Actively close the gaps one at a time: use their actual input file, their actual account state (or a clone), the same browser, production-like data volume — re-attempting reproduction after each
- Mine the evidence from their environment instead of substituting yours: server logs at the reported timestamp, error monitoring, request IDs from the report, screenshots and exact steps
- Ask the reporter targeted questions derived from your difference list when you can't close a gap yourself
- Report status honestly: "did not reproduce under <conditions>; differences not yet ruled out: <list>" — never "works as expected" or "may have been transient" as a conclusion from a passing local run
- "Transient" is a claim about cause and requires evidence (a deploy fixed it, an outage window matches); it is not a synonym for "I don't know"

**Red flags that you're about to violate this:**
- "I tested this flow and it works fine, so the issue is resolved..."
- "Unable to reproduce — likely a transient glitch on their end..."
- "Their steps work for me; the report may be mistaken..."
- "Probably a caching issue on the user's machine..." (evidence?)
- Closing the investigation without listing a single environmental difference
- Testing with convenient sample data when the report involved their real data
