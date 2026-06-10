---
title: Amend Only Your Own Last Commit
slug: amend-only-your-own-last-commit
category: git
tags: [universal, git, history]
works_with: all
severity: medium
one_liner: "Stops --amend from folding new work into commits it doesn't belong in"
---

# Amend Only Your Own Last Commit

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the AI from using `--amend` as a general append button, folding unrelated work into the previous commit or rewriting commits someone else authored.

**[Copy-paste ready version](../../install/amend-only-your-own-last-commit.md)** — just the instruction block, no explanation.

## The Problem

Once an AI assistant learns `git commit --amend`, it starts using it as "add to last commit" — regardless of what the last commit is. Asked for a follow-up change after committing a feature, it amends, even when the new change is logically separate work that deserves its own commit. Worse, when HEAD is a commit the *user* made — or a teammate's commit that happens to be at the tip — the amend rewrites someone else's commit: their change and the AI's new work fuse under the original message, the original sha disappears, and the history now lies about what the author wrote.

The result is commits that can't be reviewed, reverted, or understood as units. "Fix login redirect" quietly contains an unrelated config change amended in two hours later; the user's carefully scoped commit contains AI work they've never seen. Amend has exactly one honest use: correcting the commit you yourself just made, before anything else has happened. Everything beyond that is history rewriting wearing a convenience flag.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Amend Only Your Own Last Commit

Use `git commit --amend` only when ALL of these hold: you created the HEAD commit yourself in this session, it has not been pushed, and the amendment corrects that same change (typo, missed file, message fix). Everything else gets a new commit.

Amend is not an "append to history" button. It rewrites HEAD: the old commit vanishes and a new one takes its place under the old message's name.

- Before any amend, check what you'd be rewriting: `git log -1 --format='%h %an %s'`. If you didn't author it this session, do not amend it — make a new commit.
- Follow-up work that is logically distinct from the HEAD commit gets its own commit with its own message, even if it touches the same files and even if it happened thirty seconds later.
- A fix for a *non-HEAD* commit in your local stack is not an amend problem: use `git commit --fixup <sha>` so the relationship is recorded, and squash later if the user wants.
- Amending changes the sha. Anything that referenced the old sha (notes, a message you already sent the user, a fixup target) silently dangles afterward; re-verify references after amending.
- When amending only the message, use `git commit --amend -m "..."`; when amending only content, use `--no-edit` so you don't accidentally clobber a message the user wrote.

**Red flags that you're about to violate this:**

- "This is related-ish to the last commit; amending keeps things tidy."
- "Whatever HEAD is, my change belongs on top of it anyway."
- "One commit looks better than two small ones."
- "The user's commit is right there; I'll just slip my fix into it."
- "Amending avoids having to write another commit message."

---

## Why It Works

1. **The three-condition gate turns a vibe into a checklist.** "Is amending appropriate?" invites rationalization; "mine, this session, unpushed, same change" is four verifiable facts, and `git log -1 --format='%an'` settles the authorship one mechanically.
2. **It gives the tidiness impulse a correct outlet.** The AI amends to avoid messy history; `--fixup` provides the same cleanliness with the relationship recorded and the decision deferred to the user, so the rule redirects the motive instead of suppressing it.
3. **Naming the sha-change side effect** catches the subtle dangling-reference failures that make amends look safe right up until something points at a commit that no longer exists.

## Origin

A user committed a carefully scoped schema change, then asked their assistant to "also update the API docs." The assistant amended the user's commit, fusing documentation edits into a migration commit that a reviewer had already read at its original sha. The review approval now pointed at a commit that didn't exist, the migration commit no longer matched what was deployed from it, and the user discovered their own commit contained two hundred lines they had never written.
