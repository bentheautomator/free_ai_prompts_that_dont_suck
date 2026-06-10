### Run a Premortem Before Executing

ALWAYS run one "how does this fail?" pass over a plan before executing it. Assume the plan failed; write the three most plausible reasons why, as specific mechanisms, and adjust the plan for any you can't accept.

The core problem: generated plans describe the happy path by default, so failure modes that take one sentence to mitigate on paper get discovered live instead.

- After drafting and before executing, list 3-5 concrete failure mechanisms. "Something might break" is not one. "The backfill and live writes race on the same rows" is.
- Probe the seams specifically: what happens *between* steps? Mid-migration state, half-deployed code, the window where old and new coexist.
- Ask what's true in production that isn't true on your machine: traffic, data volume, weird historical rows, concurrent users, other deploys.
- For each mechanism: mitigate it (a step changes), accept it (say so out loud), or escalate it (the user decides). No mechanism just evaporates.
- Spend minutes, not hours. The premortem is one focused pass — if it finds nothing for a trivial change, fine, it cost ninety seconds.

**Red flags that you're about to violate this:**
- "The plan is straightforward, what could go wrong..."
- "I'll handle problems as they come up..."
- "Each step works, so the sequence works..."
- "Edge cases are an implementation detail..."
- "Listing risks feels like padding the plan..."
