---
title: Checkpoint Progress in Long Tasks
slug: checkpoint-progress-in-long-tasks
category: agents-and-automation
tags: [universal, agents]
works_with: all
severity: high
one_liner: "Two hours of agent work lost because nothing was ever saved"
---

# Checkpoint Progress in Long Tasks

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents a crash, timeout, or bad late-stage edit from erasing hours of agent work that was never saved at any intermediate point.

**[Copy-paste ready version](../../install/checkpoint-progress-in-long-tasks.md)** — just the instruction block, no explanation.

## The Problem

An agent works for two hours across thirty files, holding the entire accumulated change as uncommitted, unstashed, unbacked-up working-tree state. Then something ends the session — a timeout, a crash, a context limit, or the agent itself running a `git checkout .` to back out of one bad idea. Everything goes. Not the last edit: all of it. The agent was operating like a writer with two hours of unsaved manuscript and a cat walking toward the keyboard.

Agents skip checkpointing because nothing in their step-by-step experience prompts it. Each edit succeeds; the working tree accumulates value silently; there is no autosave anxiety and no muscle-memory Ctrl+S. Checkpointing is also easy to confuse with "committing," which many agents are correctly told not to do without permission — so they round the caution off to "never persist anything," which was not the instruction. The result is maximum-fragility operation by default: total accumulated work, zero recovery points.

The risk compounds with session length. A failure at minute ten costs ten minutes; at hour three it costs three hours — and long sessions are precisely where crashes, compactions, and budget exhaustion are most likely. The longer the agent works, the more it has to lose and the more likely it is to lose it.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Checkpoint Progress in Long Tasks

ALWAYS create a recovery point after each completed unit of work in a long task. Hours of accumulated, unsaved working-tree state is a single crash away from zero.

The core problem: every edit succeeds individually, so nothing prompts you to save — and the cost of not saving grows with exactly the session length that makes failure more likely.

- After each coherent unit — a passing subtask, a completed file group, a working intermediate state — checkpoint. In a git repo with permission to commit: small WIP commits on the working branch. Without commit permission: `git stash push` is not a checkpoint you keep working past, so instead ask once at task start: "This is a long task — OK if I make periodic WIP commits we squash later?" Most users say yes instantly.
- If you truly cannot commit, copy the changed files to a backup location at milestones, or maintain a patch file (`git diff > /tmp/task-step-3.patch`). Ugly beats gone.
- Checkpoint BEFORE any risky or sweeping operation: a large rename, a codemod, a merge, anything that touches many files at once. The checkpoint is what makes "undo" possible when the operation goes sideways.
- Prefer checkpoints at green states — compiles, tests pass — so that recovery starts from something working, not from mid-surgery.
- Never run destructive workspace commands (`git checkout .`, `git reset --hard`, `git clean`) while holding un-checkpointed work, even to undo one mistake. Checkpoint first, then surgically revert the one thing.
- Note your latest checkpoint in your task notes ("checkpoint: WIP commit abc123 after step 4"), so a post-crash session knows where to resume.

**Red flags that you're about to violate this:**
- "I'll commit everything once the whole task is done..."
- "The session's been stable so far..."
- "Committing work-in-progress feels messy..."
- "This codemod should be safe to run on top of everything..."
- "I'll just reset the working tree to undo that last change..." (with two hours uncommitted)

---

## Why It Works

1. **It supplies the missing save reflex.** Humans checkpoint out of crash-burned instinct; agents have no equivalent. Binding checkpoints to recognizable events — unit done, before risky op, at green — gives the reflex a trigger that doesn't depend on anxiety the agent doesn't have.

2. **It untangles checkpointing from commit etiquette.** "Don't commit without permission" silently becomes "never persist." Naming the workaround ladder — ask once for WIP commits, else patch files, else copies — makes caution compatible with safety.

3. **It pairs checkpoints with the destructive commands.** Most total losses are self-inflicted via `reset --hard` or `checkout .` aimed at one bad edit. Requiring a checkpoint before any such command converts the catastrophic case into a non-event.

4. **It states the scaling law.** "Longer session = bigger loss AND higher failure odds" gives the agent the actuarial argument for why hour three needs checkpoints more than minute ten, not less.

## Origin

An agent spent close to three hours converting a legacy codebase's callbacks to async/await across 40 files, all uncommitted. In hour three, one conversion broke a circular import; the agent decided to "start that file fresh" and ran `git checkout .` — restoring not one file but all forty to their pre-session state. The transcript's next line, now locally famous: "It seems the previous changes are no longer present." Nothing was recoverable. The redo, with WIP commits every few files, took two hours and survived its own mishap on the first try.
