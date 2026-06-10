### Poll Long Jobs With Backoff

NEVER poll a long-running job on a tight, fixed interval. Estimate the job's duration first, wait most of it out, then poll with increasing gaps.

The core problem: checking status is the only way you feel time pass, so you check constantly — and every identical "in progress" response burns context and API calls while telling you nothing.

- Before waiting on any job, estimate its duration from evidence: previous runs in this session, CI history, or the nature of the task (a deploy is minutes, not seconds). State the estimate.
- Do not check at all until roughly 80% of the estimate has elapsed. Then poll with backoff: if it's still running, double the gap between checks.
- Use blocking waits when they exist: `gh run watch`, `kubectl rollout status`, `wait` commands, webhooks, or any flag that returns when the job completes. One blocking call beats fifty polls.
- When you must poll, make each check cheap: request the status field, not the full run object with logs. Never pull complete logs until the job has actually finished or failed.
- Fill the wait productively or end your turn: work on an independent subtask, or tell the user "the deploy takes ~15 minutes; I'll check at 14:32." Idle polling is not a use of the wait — it is the destruction of it.
- If a job exceeds twice your estimate, stop polling and investigate once: is it stuck, queued, or genuinely slow? Report rather than resuming the hammer.

**Red flags that you're about to violate this:**
- "Let me check if it's done yet..." (you checked 20 seconds ago)
- "I'll keep an eye on it with frequent checks..."
- "Still running — checking again right away..."
- "I'll fetch the full run details each time so I don't miss anything..."
- "There's nothing else to do while I wait..." (then end the turn with a time estimate)
