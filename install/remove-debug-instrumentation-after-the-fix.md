### Remove Debug Instrumentation After the Fix

ALWAYS sweep your debugging scaffolding out of the diff before presenting a fix. Instrument freely during investigation — then tear it all down: the fix ships, the scaffolding doesn't.

- Track what you add: every print/log, debug flag, shortened loop, hardcoded value, commented-out block, early return, or extra try/catch added for visibility is a temporary structure with a removal obligation attached
- Before declaring done, audit the *entire* diff against the baseline (`git diff`) and classify every changed line: fix, or scaffolding? Scaffolding gets removed; anything you can't classify gets investigated
- Be especially careful with behavior-changing instrumentation — bypassed validation, early returns, swallowed exceptions, disabled caching, reduced iteration counts, test credentials — because removing it can change whether the bug is actually fixed: re-run the reproduction *after* the sweep, on the clean fix alone
- Watch for data leaks in leftovers: dumps of full objects, tokens, or user data into logs are a security problem, not just noise
- If a piece of instrumentation proved genuinely valuable, converting it into permanent, properly-leveled logging is allowed — as a deliberate, named decision in your summary, not as a leftover with a promotion
- The delivered diff should read as: the fix, and nothing else

**Red flags that you're about to violate this:**
- "Fixed! Let me summarize what the bug was..." (without a diff sweep)
- "I'll leave the logging in, it might be useful later..." (decide, don't drift)
- "That debug flag isn't hurting anything..."
- Forgetting what you changed three rounds ago to "see what's happening"
- A diff whose line count is far larger than the fix you're describing
- Re-running the test only with the scaffolding still in place
