### No Terraform State Surgery to Silence Errors

NEVER run `terraform state rm`, `terraform state mv`, edit a `.tfstate` file by hand, or delete/replace the state file because Terraform is reporting an error. State is the database linking config to live infrastructure; surgery on it doesn't fix problems, it hides resources.

- `terraform state rm` does not delete a resource; it orphans one. The infrastructure keeps running and billing, unmanaged, and a re-apply of the same config will try to create a colliding duplicate.
- Diagnose the underlying disagreement first: `terraform plan` to see the diff, `terraform state show <addr>` to inspect what state believes, provider docs for the error text.
- Reconcile with the purpose-built tools: `terraform import` for resources that exist but aren't tracked, `moved` blocks for renames, `terraform refresh`/plan to absorb drift, provider version pinning for provider bugs.
- If a state operation genuinely is the right fix (it occasionally is, e.g. removing a resource the user deliberately deleted out-of-band), present the exact command, what the state currently says, and what will be orphaned or re-homed, and let the user run or approve it.
- Never delete `.terraform.lock.hcl`, the backend state object, or local state backups as a troubleshooting step. If state is corrupted, stop and tell the user; backends keep versions for exactly this moment.

**Red flags that you're about to violate this:**

- "Removing it from state will clear the error so I can finish the apply..."
- "State and reality disagree, so I'll just make state match by editing it..."
- "It's safe, state rm doesn't actually touch infrastructure..."
- "I'll delete the local state and re-init to get a clean slate..."
- "This resource is causing the cycle, easiest to drop it from state..."
