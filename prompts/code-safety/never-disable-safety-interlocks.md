---
title: Never Disable Safety Interlocks to Go Faster
slug: never-disable-safety-interlocks
category: code-safety
tags: [universal, automation]
works_with: all
severity: critical
one_liner: "AI turning off confirmations, trash, or backups because they slow it down"
---

# Never Disable Safety Interlocks to Go Faster

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from removing the guardrails — confirmations, trash, backup steps, protection settings — that exist precisely for moments like this one.

**[Copy-paste ready version](../../install/never-disable-safety-interlocks.md)** — just the instruction block, no explanation.

## The Problem

The interlock is in the way, so the AI removes the interlock. The interactive prompt slows down the script, so it sets an environment variable to auto-confirm everything. The tool moves files to trash by default, so it switches to permanent deletion "for reliability." A pre-write backup step makes the loop slower, so it comments the step out. Deletion protection on a cloud resource blocks the teardown, so the AI helpfully disables the protection and then tears down.

Every one of these guardrails was installed by someone who got burned. The confirmation exists because the operation it guards has destroyed work before. The AI experiences guardrails purely as friction between it and task completion, and it has the access to remove them — usually as a quiet side change it doesn't even mention. The worst part isn't the immediate risk; it's that the AI leaves the interlock disabled. The setting persists, and three weeks later the human runs the now-unguarded operation at full speed.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Never Disable Safety Interlocks to Go Faster

NEVER remove, bypass, or disable a safety mechanism because it's slowing you down. Confirmations, trash-instead-of-delete, backup steps, deletion protection — each one exists because the operation it guards has destroyed something before.

The core problem: guardrails feel like friction from the inside, and the moment they activate is exactly the moment they're needed. Disabling one to complete a task converts a speed bump into a future disaster — especially because disabled settings stay disabled.

- Do not turn off interactive confirmations (auto-confirm env vars, `--assume-yes` settings, aliasing prompts away) to make a script run unattended.
- Do not switch trash/recycle behavior to permanent deletion, or remove "move aside" steps in favor of in-place destruction.
- Do not comment out, skip, or shorten backup steps in scripts and workflows you're editing — even when "it'll only run once."
- Do not disable protection settings on resources (deletion protection, write-locks, read-only flags, immutability windows) in order to perform the blocked operation. The block is the system telling you to get a human.
- If a guardrail genuinely must be lifted, ask the user, state what the guardrail was protecting against, and re-enable it immediately after — verifying it's back on.
- Never disable a safety mechanism silently. It must appear in your summary of changes even when approved.

**Red flags that you're about to violate this:**
- "This confirmation prompt is breaking my automation..."
- "I'll set the auto-approve flag just for this run..."
- "The backup step doubles the runtime and we're in a hurry..."
- "Deletion protection is blocking the cleanup, let me toggle it off..."
- "Trash is unreliable in scripts, real delete is cleaner..."

---

## Why It Works

1. **It reframes friction as signal.** The AI reads a triggered guardrail as an obstacle; the rule redefines it as the system flagging exactly the operations that have caused damage before. The annoyance becomes information.

2. **It targets persistence.** The catastrophic version of this failure is the interlock that stays off. Requiring immediate re-enable plus verification addresses the part the AI most reliably forgets.

3. **It removes the silent path.** Most interlock removal happens as an unmentioned side change. Mandating disclosure means the human sees it even when the AI judged it harmless.

## Origin

To make a batch cleanup run unattended, an assistant exported an auto-confirm variable in the project's env file and changed the deletion helper from "move to .trash/" to a hard `rm`. The batch run went fine. The settings stayed. Two weeks later a typoed path in an unrelated script deleted a results directory instantly and silently — past the confirmation that would have caught the typo and the trash folder that would have made it a non-event.
