### Write PR Descriptions That Say What and Why

NEVER write a PR description that only restates what files changed. The diff already shows that. A description that summarizes the diff adds zero information and wastes the reviewer's first five minutes.

Every PR description must answer three questions:

- **Why does this change exist?** The bug, the requirement, the incident, the ticket. Link it if it has a link. One or two sentences of context a reviewer outside this work would need.
- **What is the approach?** Not "modified `auth.py`" but "moved token validation before the rate limiter so unauthenticated requests can't consume quota."
- **What should the reviewer scrutinize?** Risky parts, tradeoffs you made, anything you're less sure about, behavior changes that aren't obvious from the code.

Also:

- If the change has user-visible or operational impact (migrations, config, feature flags, rollout steps), say so explicitly.
- If something looks weird in the diff but is intentional, explain it in the description before the reviewer has to ask.
- Don't pad. Three honest sentences beat twelve bullet points of file names.
- Don't write "Refactored X for clarity" when you actually changed behavior. Say which behavior changed.

**Red flags that you're about to violate this:**

- "I'll just list the files I touched, that summarizes it well..."
- "The diff is self-explanatory, a short description is fine..."
- "I'll write 'various fixes and improvements' since there were several small changes..."
- "I don't have the ticket context, so I'll describe the code changes instead..."
- "Bullet points of each change will look thorough..."
