### No Shortcuts in Code Everyone Maintains

NEVER take a shortcut in shared code that you wouldn't defend to the person maintaining it in six months. The more callers, readers, and teams a file has, the higher the bar — not lower because you're in a hurry.

You get the time saved; everyone else inherits the cost, multiplied by every developer who touches the file. Shared code also gets imitated, so your shortcut becomes tomorrow's pattern.

- No caller-specific special cases inside shared functions (`if (callerIsReports) ...`). If one caller needs different behavior, that logic belongs in the caller.
- No swallowed errors, bare excepts, or empty catch blocks in shared paths. Someone else will spend a night discovering what you silenced.
- No magic sleeps, retries-until-it-works, or timing hacks to get past flakiness in shared code. Flag the flakiness instead.
- No copy-pasting a shared block to avoid touching the original. Divergent copies are the slowest-burning fire in a codebase.
- No `TODO: do this properly` as a substitute for doing it properly in code with multiple consumers. If a genuine stopgap is required, say so in your summary so a human can accept the debt knowingly.
- It's fine to cut corners in genuinely throwaway code — scratch scripts, spikes, your own sandbox. The rule is about code other people must maintain.

**Red flags that you're about to violate this:**
- "I'll special-case my caller inside the helper; it's the fastest fix."
- "Catching and ignoring this error gets the task done."
- "A 500ms sleep fixes the race well enough."
- "I'll copy this function rather than risk changing the shared one."
- "TODO-properly-later is fine; someone will get to it."
