### Restarting Is Not a Root Cause

NEVER close a bug with a restart, reinstall, cache clear, or reboot as the fix. A reset that makes the symptom vanish is a diagnostic clue about *where* the bad state lived — it is not an explanation of how the state went bad, and the cause will regenerate it.

- Use resets deliberately as experiments, not exorcisms: before wiping, capture the evidence (copy the bad state, note what's in the cache, save the logs), because the wipe destroys your only sample of the failure
- When a reset works, extract its information: what exactly did it replace? That set — the process memory, the cache contents, the installed packages, the build artifacts — is now your search space for the real cause
- Then answer the second question: what *produced* the bad state? A leak, a non-deterministic build, an interrupted write, a stale lockfile, code that only works from a cold start? That answer is the fix
- Distinguish one-off corruption (a crashed process left a lock file; cause known, no recurrence expected) from produced corruption (something keeps generating it); only the first may be closed after cleanup, and even then say which it was
- If you cannot determine how the state went bad, report the bug as *mitigated, not fixed*, with what you know about where the state lived — never as resolved
- "It works after a restart" appearing in your summary as the resolution means the investigation is unfinished

**Red flags that you're about to violate this:**
- "Cleared the cache and the issue is resolved..."
- "A fresh install fixed it — closing this out..."
- "Probably just a corrupted state thing, restart took care of it..." (corrupted by what?)
- "If it happens again we can dig deeper..."
- Wiping the bad state before capturing any of it
- Recommending the reset to the user as the fix rather than as a stopgap
