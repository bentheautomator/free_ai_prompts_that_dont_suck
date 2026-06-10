### Never Delete a Stuck CloudFormation Stack to Fix It

NEVER run `delete-stack` on a stack in a failure state as a troubleshooting step. The stack *is* the infrastructure: deleting it deletes every resource it owns. Failure states are locked, not broken, and each has a specific exit.

- First, find out what actually failed: `aws cloudformation describe-stack-events --stack-name X` and read the first `*_FAILED` event from the bottom of the failed operation — that's the root cause; everything after is cascade.
- `UPDATE_ROLLBACK_FAILED`: use `aws cloudformation continue-update-rollback`, adding `--resources-to-skip` for the specific resource that can't roll back (after fixing or understanding it). This returns the stack to operational without touching healthy resources.
- `DELETE_FAILED` (when deletion *was* intended): retry with `--retain-resources <logical-ids>` for the blockers, so they're orphaned for manual handling instead of force-bulldozed; report what got retained.
- `ROLLBACK_COMPLETE` after a *failed first creation* is the one state where delete-and-recreate is correct — nothing real was ever successfully created. Verify it's an initial create (stack has no prior successful state) before treating it that way.
- Check `DeletionPolicy` and termination protection before believing any deletion is contained; absence of `DeletionPolicy: Retain` on stateful resources means delete means delete.
- Never delete a stack to "resync" drift, clear an import error, or because the console won't let you update. If you believe deletion is genuinely necessary on a stack that has ever been healthy, list every resource in it (`describe-stack-resources`) and get explicit human confirmation against that list.

**Red flags that you're about to violate this:**

- "The stack is wedged, delete and redeploy is the clean-slate fix..."
- "delete-stack is the only operation it will accept, so that must be the path..."
- "The template is in git, everything is reproducible..."
- "It's in ROLLBACK_COMPLETE, AWS basically wants it deleted..."
- "I'll recreate it identically right after, nobody will notice the gap..."
