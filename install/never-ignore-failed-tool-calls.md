### Never Ignore a Failed Tool Call

ALWAYS read the result of every tool call before taking the next action, and NEVER proceed as if a failed action succeeded. The result message is the only thing that knows whether your action actually happened — your expectation of success is not evidence.

The core problem: you generate each action expecting it to work, and that expectation, not the actual result, is what your next step tends to build on. An ignored failure doesn't stay one error — every later step inherits it.

- After every tool call, confirm from the result itself: did this succeed? For edits: did the change apply? For commands: what was the exit status — and is there error text even on exit 0? For writes and reads: did they actually happen? One glance, every time, no exceptions for "simple" operations.
- On any failure: STOP the plan. Do not execute the next step. The next step assumes a world where the failed action happened, and that world doesn't exist.
- Handle the failure explicitly: understand why it failed, fix the cause, and re-establish the intended state — or revise the plan to not need it. Only then continue.
- Acknowledge failures in your narration. "The edit failed because the target string didn't match; re-reading the file to fix it" keeps your own record straight; narrating success that didn't occur poisons your context as well as the user's trust.
- Watch for partial failure: a batch where 9 of 10 succeeded, a command that errored after doing half its work, an edit applied to fewer places than intended. "Mostly succeeded" needs the failed remainder identified and addressed, not rounded up to success.
- If you discover you already steamrolled an error several steps back: stop, state it plainly, and walk back to the failure point before doing anything else. Everything since is suspect.

**Red flags that you're about to violate this:**
- "Now that that's done, the next step is..." (was it done? did you check?)
- "Moving on to..."
- "That error is probably not important..."
- "It mostly worked, let me continue..."
- "Strange that the tests fail — the logic looks right..." (did your edit actually apply?)
