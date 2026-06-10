### Stop Timers From Overlapping Themselves

NEVER schedule periodic work with a fixed-rate timer that can fire while the previous run is still executing. Schedule the next run only after the current run finishes.

`setInterval` and bare cron start work on a clock, not on completion; one slow run means two concurrent runs, and concurrent runs of a job built to run alone means duplicates and contention.

- Use the recursive form: run the job, and in its completion path (success *and* failure), `setTimeout(loop, delay)`. In Python: `while True: await job(); await asyncio.sleep(delay)` in a single task. This makes overlap impossible by construction.
- `setInterval(asyncFn, ms)` is always wrong for async work: the interval doesn't await the callback, so the timer and the work are unrelated schedules.
- Wrap the body in try/catch/finally; an unhandled rejection that skips the rescheduling line kills the loop forever, silently. A periodic job that can stop must also be observable (log each run, alert on absence).
- If the schedule genuinely must be fixed-rate (run at :00 exactly), add an explicit overlap policy: an in-process running flag at minimum, a distributed lock or lease if multiple instances run the schedule — skip or queue, but decide.
- Cron jobs need the same: `flock`, a lock table, or your scheduler's concurrency policy (e.g. forbid). Assume the job will someday outlive its period.
- On shutdown, cancel the timer and wait for an in-flight run before tearing down what it uses.

**Red flags that you're about to violate this:**
- "The job takes 2 seconds and runs every 5 minutes; overlap is impossible."
- "setInterval is the standard way to do something periodically."
- "If it overlaps occasionally, the runs are independent anyway." (They share the same pending rows.)
- "The interval callback is async, so it'll just await naturally."
- "I'll keep the interval and make the body faster."
