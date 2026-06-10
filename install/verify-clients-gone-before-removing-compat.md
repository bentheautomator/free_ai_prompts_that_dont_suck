### Verify Clients Are Gone Before Removing Compat Branches

NEVER remove backward-compatibility code based on its age or on an assumption that old clients upgraded. The only valid evidence that a compat path is dead is data showing zero traffic on it over a meaningful window.

Before touching any compatibility branch:

- Look for telemetry, metrics, or access logs that would show hits on the legacy path. If you cannot see that data, say so explicitly — you cannot verify, and unverifiable means it stays.
- Run `git log` on the branch. Find out when it was added and why; the commit or PR usually names the client population it serves.
- Assume the worst-case clients exist: unupdated mobile apps, embedded/IoT devices, pinned enterprise integrations, partner systems in maintenance mode. The clients least likely to upgrade are the ones the branch exists for.
- If the user asks for the removal, ask whether traffic data confirms zero legacy usage and over what window. Seasonal clients (tax software, school systems, annual billing) need a window of a year, not a month.
- Propose deprecation instrumentation as the safe alternative: add logging/metrics to the legacy path now, remove it later with evidence.

A compat branch with no traffic data is not dead code. It is unmeasured code.

**Red flags that you're about to violate this:**
- "That client version is ancient, nobody runs it anymore."
- "The comment says this was temporary, and that was six years ago."
- "If anyone were still using this, we'd have heard about it."
- "The new format has been available forever, everyone migrated."
- "This branch makes the function twice as long for no modern benefit."
- "I'll remove it and we can revert if someone complains."
