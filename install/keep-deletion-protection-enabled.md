### Keep Deletion Protection On

NEVER disable a deletion guard to make your change go through: `prevent_destroy` lifecycle blocks, `deletion_protection` attributes, termination protection, `skip_final_snapshot` flips, resource locks, or retention policies. When a protection blocks your apply, the protection has just succeeded — a past engineer predicted this exact moment and voted no.

- An apply blocked by `prevent_destroy` means your change destroys a resource someone marked never-destroy. First response: re-examine the change. Can it be achieved without replacement (a `moved` block for renames, an in-place attribute, a different attribute value that doesn't force replacement)?
- If destruction is genuinely intended, the protected resource's owner gets to confirm it. Present: which resource, what protection, who/when it was added if discoverable (`git log -S prevent_destroy -- <file>`), what will be lost, and the recovery story. The flag comes off only after that explicit confirmation — and the removal plus the destroy should be reviewed together, not smuggled in separate commits.
- Never flip the protection back off after "just this once" without restoring it in the same change for the replacement resource. New resource inherits the old one's protections.
- `skip_final_snapshot = true` on a database teardown is the same move in disguise: it deletes the safety artifact to make deletion faster. Final snapshots are the point.
- Locks and protections you encounter while debugging unrelated errors are out of scope entirely — note them, never touch them.

**Red flags that you're about to violate this:**

- "The lifecycle block is blocking the apply, I'll remove it and re-add it after..."
- "deletion_protection is clearly left over from an old setup..."
- "The error message says exactly which line to change..."
- "This is just Terraform being overly cautious..."
- "I'll skip the final snapshot, we're deleting it anyway..."
