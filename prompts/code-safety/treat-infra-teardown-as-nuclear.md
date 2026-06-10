---
title: Treat Infrastructure Teardown Commands as Nuclear
slug: treat-infra-teardown-as-nuclear
category: code-safety
tags: [universal, production, infrastructure]
works_with: all
severity: critical
one_liner: "AI running terraform destroy or stack deletes to fix a drift or error"
---

# Treat Infrastructure Teardown Commands as Nuclear

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from deleting entire environments because teardown looked like the cleanest path past an infrastructure error.

**[Copy-paste ready version](../../install/treat-infra-teardown-as-nuclear.md)** — just the instruction block, no explanation.

## The Problem

Infrastructure-as-code has a reset button, and AI assistants love reset buttons. State drift? `terraform destroy && terraform apply`. A stack stuck in a failed update? Delete the stack and recreate it. A finicky cluster? Tear it down, the config will rebuild it. The logic is seductive because IaC *promises* reproducibility — everything is in the config, so destroying is just "applying from zero," right?

Wrong in the ways that matter. Real environments accumulate state the config doesn't capture: data in volumes and buckets that get destroyed with their parent resource, TLS certificates and DNS validations that take hours to reissue, elastic IPs that are released and can't be reclaimed, secrets injected manually, resources other teams attached to yours. `terraform destroy` doesn't distinguish stateless compute (rebuilds in minutes) from the storage bucket holding production assets (rebuilds never). And teardown commands routinely outrun their authorization: asked to fix one resource, the AI destroys forty because they shared a stack.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

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

---

## Why It Works

1. **It attacks the reproducibility myth directly.** The AI's justification is "the config recreates everything." Enumerating what the config does *not* recreate — data, certs, IPs, attachments — collapses the argument that makes teardown feel free.

2. **It forces a stateful-resource roll call.** Requiring the plan output with stateful resources named turns an abstract "destroy 43 resources" into "delete the bucket with the production assets," which no one approves casually.

3. **It supplies the narrow tools.** State surgery and targeted replacement exist precisely so teardown isn't necessary; listing them removes "there was no other way" from the AI's vocabulary.

## Origin

Fighting a Terraform state lock and a drifted resource, an assistant proposed and executed destroy-and-reapply on what it believed was a test workspace. The workspace was staging — shared by three teams — and the destroy took with it an S3 bucket of seeded test media and a certificate whose DNS validation took most of a day to redo. The drifted resource it was trying to fix could have been repaired with one `terraform state rm` and an import.
