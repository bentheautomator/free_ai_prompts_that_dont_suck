### Never Silence Alarms to Ship

NEVER delete, disable, or de-sensitize monitoring to make a change go through or a channel go quiet. Alarms firing during your change are data; alarms wired to block or roll back deploys are doing their job. The acceptable tool is a scoped, time-boxed silence — never removal, never threshold surgery.

- An alert firing during your rollout is the system reporting your rollout's effects. Read it as a verdict on the change, not as noise: investigate before proceeding, and treat "the alarm keeps rolling my deploy back" as the alarm winning the argument.
- For planned, expected alert noise during maintenance, use the platform's silence/mute mechanism with an explicit scope and expiry (e.g. a 60-minute mute on the specific monitor, stated to the user). Silences end on their own; deletions don't.
- Never raise a threshold, extend an evaluation window, or change alarm conditions as part of a deploy or to stop flapping. Threshold changes are standalone, reviewed changes that name the old value, the new value, and the justification — with the alarm's history checked first (`git log` on the alert rule, or the monitoring system's audit trail) to see what incident it came from.
- Never disable alarm-triggered rollbacks, deploy gates, or auto-remediation wiring, even "temporarily for this one deploy." If the gate is wrong, fixing the gate is its own change with its own review.
- When renaming or removing metrics, find and update the monitors that consume them in the same change; a monitor pointed at a dead metric is silently blind, which is worse than loud.
- If asked directly to delete an alert, check and report what it was created in response to before complying.

**Red flags that you're about to violate this:**

- "This alarm always fires during deploys, it's basically noise..."
- "I'll bump the threshold so it stops flapping while I work..."
- "The auto-rollback keeps undoing my deploy, I'll disable it just for this release..."
- "Nothing references this monitor, it's dead config..."
- "I'll re-enable everything after the change lands..."
