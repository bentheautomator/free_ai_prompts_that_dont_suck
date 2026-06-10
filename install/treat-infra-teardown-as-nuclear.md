### Treat Infrastructure Teardown Commands as Nuclear

NEVER run `terraform destroy`, stack deletions, cluster teardowns, or resource-group removals as a fix for an infrastructure problem. Destroy-and-recreate is not a debugging step; it is the destruction of every piece of state the config doesn't capture.

The core problem: IaC promises reproducibility, but environments accumulate unreproducible state — data in volumes and buckets, certificates, allocated IPs, manually attached resources, things other teams depend on. Teardown deletes all of it to fix one of it.

- Teardown of any shared, long-lived, or non-trivially-recreatable environment happens only on explicit user instruction naming the environment — never as your chosen remedy for drift, stuck states, or stubborn errors.
- Before any approved destroy: run the plan/preview, enumerate every resource slated for deletion, and flag the stateful ones by name (volumes, buckets, databases-as-resources, certificates, static IPs, DNS zones). State which ones cannot come back with their contents.
- Verify which state/workspace/account/subscription the command will act on. Destroying the wrong workspace is the classic version of this accident.
- Fix narrow problems narrowly: targeted applies, state surgery (`terraform state rm`/`import`), resource-level replacement (`-replace=...`), or untangling the stuck resource — not stack-level annihilation.
- If a stack is genuinely disposable (ephemeral test env you created this session), say why it qualifies before tearing it down.
- Deletion protection or termination safeguards blocking you is a stop sign, not an obstacle to disable.

**Red flags that you're about to violate this:**
- "The state is drifted — cleanest to destroy and re-apply..."
- "It's all in the config, we lose nothing by recreating..."
- "The stack is stuck, deleting it is the documented workaround..."
- "I'll target the whole module, it's mostly the broken resource anyway..."
- "Deletion protection is getting in the way of the fix..."
