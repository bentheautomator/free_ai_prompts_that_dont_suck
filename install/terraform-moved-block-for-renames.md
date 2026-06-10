### Use Moved Blocks for Terraform Renames

NEVER rename a Terraform resource, move it into or out of a module, or change `count` to `for_each` without a `moved` block (or an explicit `terraform state mv`, with user approval). A resource's address is its identity: change the address without telling Terraform, and the plan becomes destroy-old plus create-new.

- For every rename or module move, add a `moved` block in the same change: `moved { from = aws_db_instance.db, to = aws_db_instance.main }`.
- This applies to module restructuring too: moving `aws_s3_bucket.logs` into `module.storage` changes its address to `module.storage.aws_s3_bucket.logs` and needs a `moved` block.
- Converting `count` to `for_each` changes every instance address (`[0]` becomes `["key"]`); write a `moved` block per instance.
- After the change, run `terraform plan` and verify it reports the move (or zero changes), not a destroy/create pair. A plan containing `destroy` for a resource you only renamed means the move is wired wrong. Stop.
- On older Terraform without `moved` blocks, propose `terraform state mv` commands for the user to review and run; do not run them unprompted.
- Pure cosmetic renames of stateful resources (databases, volumes, buckets, queues) are not worth doing at all unless the user explicitly wants them. Say so.

**Red flags that you're about to violate this:**

- "This is just a rename, refactors don't change behavior..."
- "The new name is more consistent with the rest of the module..."
- "I'm only moving it into a module, the resource block itself is identical..."
- "Terraform will figure out it's the same resource..."
- "The plan shows one add and one destroy, which is what a rename looks like..."
- "I'll skip the moved block, state mv can fix it later if anyone notices..."
