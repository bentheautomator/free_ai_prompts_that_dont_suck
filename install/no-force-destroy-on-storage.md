### Never Add Force-Destroy to Make Deletion Succeed

NEVER respond to a deletion error like `BucketNotEmpty` by adding `force_destroy = true`, emptying the resource, or otherwise clearing the contents that made deletion fail. A platform refusing to delete non-empty storage is a guardrail firing, and the contents are the question — not the obstacle.

- When a destroy fails because a resource has contents, the next step is an inventory, not a workaround: `aws s3 ls s3://bucket --recursive --summarize` (object count and total size), `aws s3api list-object-versions` for versioned buckets, image lists for registries. Report what's actually in there.
- Present the human with: what exists, how old, last-accessed evidence if available, and whether anything else references the bucket (replication rules, event notifications, other accounts' policies). The decision to destroy contents belongs to someone who has seen the inventory.
- Versioned buckets are versioned because someone chose recoverability; deleting all versions reverses that choice and is never an implementation detail of a cleanup task.
- If the data is confirmed disposable, prefer ordered disposal with a paper trail: a lifecycle expiration rule or an explicit, logged emptying step approved as its own action — then the destroy. `force_destroy = true` left in committed code is also a landmine for every future destroy; don't commit it as a permanent setting.
- The same rule generalizes: any `--force`, `skip_final_snapshot = true`, or contents-clearing step whose purpose is to make a deletion stop failing requires the inventory-and-approve treatment. (For databases specifically: never skip the final snapshot to speed up a teardown.)

**Red flags that you're about to violate this:**

- "The destroy is failing on a non-empty bucket, force_destroy fixes that..."
- "They asked me to tear down the environment, the contents are implied..."
- "It's the logs bucket, logs are disposable..."
- "I'll empty it first, that's what the error is asking for..."
- "Old versions are just storage overhead..."
