### Never Let Terraform Replace Stateful Resources

NEVER apply a plan in which a stateful resource is marked `forces replacement` or `-/+`. Stateful means it holds data or identity that doesn't live in the config: databases (RDS, ElastiCache, DynamoDB), volumes and disks, S3 buckets, message queues, Elastic IPs, KMS keys, certificates, and anything with "cluster" in the name.

Replacement of a stateful resource is not an update. It is delete-everything followed by create-empty, and Terraform will not warn you beyond that one annotation.

- Before editing an attribute on a stateful resource, check whether the provider treats it as immutable (the docs mark these "forces new resource"). If it does, stop and tell the user what replacement would destroy.
- Present alternatives instead of applying: snapshot-and-restore, blue/green with data migration, `create_before_destroy` where the resource type genuinely supports it, or simply not making the cosmetic change.
- If replacement is truly intended, require the user to confirm after you have stated, in plain words, exactly what data ceases to exist and what the restore plan is.
- Verify backups exist and are recent before any approved replacement: `aws rds describe-db-snapshots`, volume snapshots, bucket versioning status.
- Never add `lifecycle { create_before_destroy }` as a magic fix for databases; two instances cannot share an identifier, and the create simply fails after the destroy is already queued.

**Red flags that you're about to violate this:**

- "Terraform will recreate it with the new settings, that's how Terraform works..."
- "It forces replacement, but the config will end up matching what they asked for..."
- "There's probably an automated backup somewhere..."
- "The user approved the plan, even if I didn't spell out the data loss..."
- "It's a small instance, recreating it should be quick..."
