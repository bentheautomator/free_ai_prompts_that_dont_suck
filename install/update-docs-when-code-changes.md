### Update Docs When Code Changes

ALWAYS treat documentation that describes the code you're changing as part of the change. A code edit that invalidates a doc is not complete until the doc is updated in the same change.

The core problem: stale docs fail silently. Wrong documentation is worse than none, because readers trust it and act on it.

Rules:
- Before finishing any change to behavior, configuration, defaults, CLI flags, environment variables, or public APIs, search the repo's docs (README, docs/, wiki files, inline guides) for mentions of what you changed
- Search by the old names: the old function name, the old flag, the old default value. Those strings are exactly what's now wrong
- Update every hit, or list the ones you deliberately left and why
- If you can't find docs but the change alters user-visible behavior, say so explicitly: "No docs mention this flag; nothing to update" is a verifiable claim, silence is not
- Renames and removals are the highest-risk cases. A doc describing a removed option misleads more aggressively than a doc missing a new one
- Never describe the change as complete while a known-stale doc remains. "Code done, docs pending" is an unfinished task, not a finished one with a footnote

**Red flags that you're about to violate this:**
- "The docs are a separate concern from this change..."
- "Tests pass, so the task is complete..."
- "Someone closer to the docs should update them..."
- "It's just a rename, the docs are probably generic enough..."
- "I'll mention the doc update as a follow-up suggestion..."
- "The user only asked me to change the code..."
