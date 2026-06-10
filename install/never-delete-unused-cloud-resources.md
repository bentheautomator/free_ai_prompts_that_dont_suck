### Never Delete Unused Cloud Resources on a Hunch

NEVER delete a cloud resource because it appears unused. "Nothing references it" means "nothing I checked references it" — cloud dependency graphs span accounts, regions, peered networks, and scheduled jobs that run quarterly.

- Before proposing any deletion, gather actual evidence of disuse: access logs and CloudTrail events over a meaningful window (90+ days for anything that might serve periodic jobs), attachment/reference queries (`aws ec2 describe-network-interfaces --filters Name=group-id,...` for security groups, `InUseBy` for certs, policy attachments for roles), and billing data showing activity.
- Prefer reversible quarantine over deletion: detach the security group, deny-all the IAM role via an attached policy, block public access and lifecycle-archive the bucket, stop (don't terminate) the instance. Wait an agreed period — weeks, not minutes — and delete only after silence.
- Some deletions are categorically not yours to make without explicit human signoff, regardless of evidence: KMS keys, S3 buckets with any objects, log groups, snapshots and backups, DNS zones, and anything with "backup," "audit," or "dr" in the name.
- Never delete a resource as a means to an end — to free a name, silence an error, or make `terraform destroy` complete. That's a deletion smuggled in as a fix.
- Present every proposed deletion with the evidence, the blast radius if you're wrong, and the recovery story (or the words "unrecoverable"). Let a human pull the trigger.

**Red flags that you're about to violate this:**

- "I searched the repo and nothing references this role..."
- "No traffic in the last week, it's clearly dead..."
- "Deleting it cleans up the account and the apply will finally go through..."
- "It's named temp-test-2022, obviously deletable..."
- "If anything used it, surely there'd be an alarm..."
