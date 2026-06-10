---
title: Never Skip Dry-Run Flags on Destructive Tools
slug: never-skip-dry-run-flags
category: code-safety
tags: [universal, automation, files]
works_with: all
severity: critical
one_liner: "AI treating --dry-run as optional and going straight to the real delete"
---

# Never Skip Dry-Run Flags on Destructive Tools

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from running destructive sync and cleanup tools live when the tool itself offers a rehearsal mode.

**[Copy-paste ready version](../../install/never-skip-dry-run-flags.md)** — just the instruction block, no explanation.

## The Problem

`rsync --delete`, `aws s3 sync --delete`, `kubectl delete`, `find -delete`, `npm prune`, `gcloud ... delete` — the tools that can do the most damage almost all ship a dry-run mode, because their own authors knew the live run is dangerous. AI assistants skip it. The dry run is an extra step, the goal is the end state, and the model optimizes for fewest commands. So it runs `aws s3 sync ./dist s3://bucket --delete` cold, and the `--delete` removes every object in the bucket that wasn't in the local `dist` folder — including the uploads directory nobody mentioned was in there.

The cruelty of these tools is that their destructive behavior depends on state the AI hasn't inspected: what's currently on the remote side, what the filter rules actually match, what the selector resolves to. A dry run is the only way to see the answer before it's irreversible. Skipping it isn't saving a step — it's choosing to discover the blast radius after detonation.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Skip Dry-Run Flags on Destructive Tools

If a destructive tool offers a dry-run mode, the dry run is MANDATORY before the live run. Skipping it is not efficiency — it is choosing to learn what the command deletes by deleting it.

The core problem: tools like `rsync --delete`, `aws s3 sync --delete`, and `kubectl delete` act on remote or computed state you have not seen. The dry run is the only preview of the actual blast radius.

- ALWAYS run with `--dry-run` / `-n` / `--what-if` / `--check` first when the command deletes, overwrites, or syncs with deletion enabled.
- Read the dry-run output, don't just produce it. Count the deletions. Name anything unexpected before proceeding.
- Show the user the dry-run results before the live run whenever the operation deletes more than a trivial, fully-expected set.
- If the dry-run output differs from what you predicted, do not "adjust and go" — figure out why your mental model was wrong first.
- If a tool has no dry-run mode, build one: run the corresponding list/query command (`find` without `-delete`, `ls` of the target, a `--diff` flag) and review it.
- Never reuse a stale dry run. If anything changed since — flags, paths, remote state — rehearse again.

**Red flags that you're about to violate this:**
- "The dry run would just slow this down..."
- "I'm confident about what this will match..."
- "I'll add --dry-run if something goes wrong..."
- "This is basically the same command I dry-ran earlier..."
- "The sync only touches files I just built..."

---

## Why It Works

1. **It redefines what the dry run is for.** The AI models it as a debugging aid for the unsure. Framing it as the only available preview of unseen state makes skipping it logically indefensible rather than merely risky.

2. **It requires reading, not just running.** A dry run the AI executes and ignores is theater. "Count the deletions, name anything unexpected" forces actual inspection of the output.

3. **It closes the no-flag escape hatch.** Tools without `--dry-run` would otherwise be exempt; prescribing a manual preview (list before delete) extends the rule to them.

## Origin

An assistant deploying a static site ran `aws s3 sync ./public s3://site-bucket --delete` to "make the bucket match the build." The bucket also held a `/files` prefix of customer-uploaded PDFs served from the same domain. The `--delete` flag removed all of them. A dry run would have printed several thousand `delete:` lines that no one could have mistaken for a normal deploy.
