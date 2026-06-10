### A Try/Catch Is Not a Bug Fix

NEVER resolve a crash by wrapping the crashing code in try/catch (or rescuing, or `except: pass`-ing) so the exception stops propagating. The exception is the report; the bug is what the report is about. Silencing the report while the operation still fails makes the failure invisible while its consequences continue.

- When code throws, find out why — the input, state, or logic defect behind the exception — and fix that, so the operation *succeeds*; the goal is a working operation, not a quiet failure
- Before any catch you write, answer: after this catch runs, has the operation succeeded, recovered, or failed? If it failed, later code must not proceed as if it succeeded — and the failure must stay visible (rethrown, surfaced, failed loudly), not logged-and-forgotten
- A catch block containing only a log line (or nothing), in a function that then continues normally, is suppression — however respectable the log message looks
- Don't widen existing handling to swallow your bug: broadening `except ValueError` to `except Exception`, or adding a new exception type to an existing catch-and-continue, is the same move in disguise
- Legitimate error handling — retries for transient faults, fallbacks with defined semantics, converting exceptions at API boundaries — is designed around *expected* failures with chosen behavior; it's not the closing move of a debugging session with an unknown root cause
- If you must keep a process alive past an unexplained error (a batch loop, a server), contain it explicitly: record the full error, mark the item failed, and state in your summary that the bug remains open

**Red flags that you're about to violate this:**
- "Wrapping this in a try/catch will make the flow more robust..."
- "We can log the error and continue processing the rest..."
- "The crash is the problem the user reported, and this stops the crash..."
- "I'll broaden the exception handling to cover this case..."
- A catch block you cannot describe the recovery semantics of
- The word "gracefully" appearing where "silently" would be more accurate
