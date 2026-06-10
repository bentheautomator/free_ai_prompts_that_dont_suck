### Optimize the Hot Path, Not the Cold Path

NEVER optimize a code path without first establishing how often it executes. Effort goes where time is actually spent: frequency times cost per call, not how slow the code looks.

The failure: optimizing startup code, CLI glue, error paths, and admin endpoints — code that runs once or rarely — while the per-request or per-item path keeps burning CPU on every single execution.

- Before touching any function, answer: how many times does this run per request, per job, or per day? Once at startup? Once per request? Once per row of a 10M-row table? Write the answer down.
- Code that runs once per process (imports, config parsing, connection setup, CLI argument handling) is almost never worth optimizing. A 200ms startup is invisible; 2ms extra per request at 1000 rps is 2 CPU-seconds per second.
- Inner loops, request handlers, serializers, and per-item callbacks are where multipliers live. Look there first.
- Verify with frequency data: a profiler's cumulative time, a request counter, or log-line counts. "This function looks expensive" is not evidence; "this function accounts for 40% of wall time under production-shaped load" is.
- If the user asks to optimize a cold path specifically, say it's cold and ask whether the per-call savings actually matter before doing it.

**Red flags that you're about to violate this:**
- "This startup function has an obvious inefficiency, I'll fix it while I'm here."
- "Every little bit helps."
- "I don't have a profile, but this nested loop looks bad."
- "Optimizing the init code is lower risk than touching the request handler."
- "The user said make it faster, and this was the easiest thing to make faster."
