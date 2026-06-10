---
title: Never Remove Pipeline Steps You Don't Understand
slug: never-remove-pipeline-steps-you-dont-understand
category: ci-cd
tags: [universal, ci, pipelines]
works_with: all
severity: critical
one_liner: "Stops the AI from deleting pipeline steps it cannot explain"
---

# Never Remove Pipeline Steps You Don't Understand

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from "cleaning up" pipeline steps whose purpose it never figured out.

**[Copy-paste ready version](../../install/never-remove-pipeline-steps-you-dont-understand.md)** — just the instruction block, no explanation.

## The Problem

Pipelines accumulate steps that look like cruft: a `sleep 30` before the integration tests, a curl to an internal URL with no comment, a step that copies one file to a weird path, an env var export nobody references in the repo. When an AI assistant is asked to "simplify the workflow" or just to modify a nearby step, it routinely deletes these — confidently, with a commit message like "remove unused step." The step was not unused. The `sleep 30` was waiting for a database container to accept connections. The curl was warming a cache that the deploy depends on. The weird file copy was feeding a compliance scanner.

This is Chesterton's Fence with a YAML extension. The defining feature of load-bearing-but-undocumented steps is that they look exactly like dead ones, and an assistant that can't find a step's purpose in the repo concludes the purpose doesn't exist. But pipeline steps often serve systems *outside* the repo — deploy targets, monitoring, audit requirements — which is precisely why grep can't vouch for them.

The failure is asymmetric. Keeping a useless step costs seconds per run. Deleting a load-bearing one can break deploys, audits, or downstream teams, often days later when nobody connects the breakage to the "cleanup" commit.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Remove Pipeline Steps You Don't Understand

NEVER delete, comment out, or reorder a CI/CD pipeline step unless you can state specifically what it does and why it is no longer needed. "I can't see what this is for" is a reason to ask, not a reason to delete.

Pipeline steps frequently serve systems outside the repository — deploy targets, caches, compliance scanners, downstream consumers — so absence of in-repo references is not evidence of deadness.

- Before touching a step, establish its purpose: read its commands, check `git log` and `git blame` on those lines, search for the step name in docs and other workflows, and look at what runs would fail without it.
- Treat suspicious-looking steps as the most likely to be load-bearing: unexplained `sleep`s (waiting on a service), curls to internal hosts (warmups, notifications, registrations), file copies to odd paths (consumed elsewhere), env exports with no in-repo readers.
- If after investigating you still cannot explain a step, leave it alone and report it: name the step, what you checked, and what you'd need to know. Let the user decide.
- If removal is genuinely justified, make it its own commit with the evidence in the message — never folded into an unrelated change.
- Reordering counts. Steps may depend on side effects of earlier steps even without declared dependencies.

**Red flags that you're about to violate this:**

- "Nothing in the repo references this, so it's dead."
- "This sleep is obviously a hack someone forgot to remove."
- "The workflow will be cleaner without these legacy steps."
- "It still passes locally without this step, so it's safe to drop."
- "Whoever needs this would have documented it."

---

## Why It Works

1. **It inverts the burden of proof.** The assistant's default is "delete unless proven needed"; the rule requires "explain before touching," which is the correct asymmetry given the failure costs.
2. **It explains why grep lies here.** Assistants trust repo-wide search as ground truth; naming the out-of-repo consumers (deploy targets, scanners, downstream teams) breaks that false confidence.
3. **It flags the disguises specifically.** Sleeps, mystery curls, odd file copies — calling these "most likely load-bearing" reverses the assistant's instinct that ugly equals dead.
4. **The report-instead-of-delete path gives the assistant a way to finish the task** without either deleting blindly or stalling, which is when rules usually get bent.

## Origin

Asked to "tidy up this workflow file," an assistant removed an uncommented step that POSTed a build manifest to an internal endpoint, reasoning that nothing in the repo consumed it. The endpoint belonged to the release-attestation system; without the manifest, the next three releases shipped unattested. The gap was discovered during a customer security audit, and reconstructing attestations for the affected releases took the platform team most of a week.
