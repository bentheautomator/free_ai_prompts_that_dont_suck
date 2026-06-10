---
title: Check the Reflog Before Declaring Loss
slug: check-the-reflog-before-declaring-loss
category: git
tags: [universal, git, recovery]
works_with: all
severity: high
one_liner: "Stops the AI from rewriting 'lost' work that the reflog still has"
---

# Check the Reflog Before Declaring Loss

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from declaring committed work unrecoverable — or recreating it from memory — without ever checking git's built-in recovery mechanisms.

**[Copy-paste ready version](../../install/check-the-reflog-before-declaring-loss.md)** — just the instruction block, no explanation.

## The Problem

Work goes missing after a bad reset, a botched rebase, a branch deletion, or an amend that shouldn't have happened. The AI looks at `git log`, doesn't see the commits, and concludes they're gone — then offers to rewrite the changes from what it remembers, or just apologizes and moves on. But `git log` only shows what's reachable from current refs. Almost everything that was ever committed is still in the object store: the reflog records every position HEAD and each branch has held for the last ~90 days, and `git fsck --lost-found` surfaces orphaned commits the reflog misses.

Recreating "lost" work is the worst possible response: it takes longest, introduces fresh bugs (the AI's memory of the diff is not the diff), and forfeits the real version that one `git reflog` command would have found. Assistants skip the reflog because absence from `git log` *looks* like nonexistence, and because recovery tooling rarely appears in the happy-path workflows they've internalized. The recovery move costs ten seconds and succeeds far more often than not — it just has to be tried before the eulogy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Check the Reflog Before Declaring Loss

NEVER declare committed work lost, and never start recreating it from memory, until you have actually checked git's recovery mechanisms. Absence from `git log` means unreachable, not gone: anything committed in the last ~90 days is almost certainly still in the repository.

- Start with `git reflog` (and `git reflog <branch>` for a specific branch). It lists every recent position of HEAD with the action that moved it: the state before a reset, rebase, amend, or merge is right there as `HEAD@{n}`.
- Found the lost tip? Anchor it before anything else: `git branch recovered/<description> <sha>`. Then inspect at leisure (`git show`, `git diff main...recovered/...`) and restore what's needed.
- Deleted branch: its commits are findable via `git reflog` (look for the last checkout of it) or `git fsck --lost-found`, which lists orphaned commits with no ref at all.
- A specific lost change can be located by content: `git log -S '<distinctive snippet>' --all --oneline` searches every reachable commit, and the same against `--reflog`.
- Scope honestly: the reflog recovers *commits*. Work that was never committed or staged is not in it; do not promise recovery of never-committed changes, and say which category the loss falls into.
- Only after reflog and fsck both come up empty may you report work as unrecoverable — and report what you checked.

**Red flags that you're about to violate this:**

- "It's not in git log, so it's gone."
- "Fastest path forward is rewriting the change; I mostly remember it."
- "The branch was deleted, and deleted means deleted."
- "The reset wiped everything; no point looking."
- "Recovery commands are for experts; safer to start fresh."

---

## Why It Works

1. **It severs the false equivalence between `git log` and existence.** The AI's entire "it's lost" conclusion rests on one unreachable-vs-gone confusion; correcting the model makes checking feel necessary rather than optional.
2. **The anchor-first habit (`git branch recovered/...`) protects the find** — recovered shas are still garbage-collectable orphans until named, and an AI that inspects before anchoring can lose the work a second time.
3. **Requiring "what I checked" in any unrecoverable verdict makes the lazy verdict expensive:** the AI can't claim loss without producing evidence of a search, so the search happens.

## Origin

After a rebase went sideways, an assistant reported that "the previous commits were unfortunately lost during the operation" and helpfully began re-implementing the feature from its recollection — introducing two regressions the original had already fixed. A developer ran `git reflog`, found the pre-rebase tip at `HEAD@{4}`, and restored the real commits in under a minute. The re-implementation was discarded; the apology was kept.
