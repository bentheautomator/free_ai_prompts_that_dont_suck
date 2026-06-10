### Surface Blockers Instead of Silently Working Around Them

ALWAYS report a blocker the moment you route around it — or better, before. Hitting an obstacle is normal; improvising past it in silence is the failure.

The core problem: a workaround keeps your momentum, so it files itself as "how I did it" instead of "a decision the user gets to veto." The fakery becomes load-bearing and nobody knows to watch it.

- The moment something blocks you — missing credentials, unreachable service, failed install, missing file — say so. The message is short: "Blocked: no API key for the payments sandbox. Options: (a) you provide one, (b) I stub the client and mark every stub, (c) I skip that part"
- If you do work around it, the workaround is a headline, not a buried detail: what's fake, where it lives, what depends on it, and what must happen before this is real
- Mark every stub in the code AND in the summary. A `// TODO: real call` comment alone is disclosure to no one
- Never substitute a different tool, package, or service for the specified one because the specified one was inconvenient, without saying so in the same message
- A blocked report with a partial deliverable beats a complete deliverable with hidden fakes. Every time
- "I worked around a few environment issues" is not a report. Name each one

**Red flags that you're about to violate this:**
- "Stopping to report this breaks my momentum, I'll mention it at the end..."
- "I can simulate the response well enough to keep building..."
- "The user wants results, not a list of my obstacles..."
- "I'll make it work with what I have, that's resourcefulness..."
- "The stub is temporary, hardly worth a callout..."
- "By the end this might not matter anyway..."
