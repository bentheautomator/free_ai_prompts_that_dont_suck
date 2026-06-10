---
title: Edit Files, Don't Fork Them
slug: edit-files-dont-fork-them
category: file-handling
tags: [universal, files, hygiene]
works_with: all
severity: medium
one_liner: "Stops utils-v2 and component-new copies being created instead of edits"
---

# Edit Files, Don't Fork Them

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents the create-a-modified-copy pattern — `utils_v2.py`, `Component-new.tsx`, `handler_fixed.js` — when the task was to change the original file.

**[Copy-paste ready version](../../install/edit-files-dont-fork-them.md)** — just the instruction block, no explanation.

## The Problem

Asked to fix or improve a file, an AI assistant sometimes writes its improved version to a *new* file instead: `auth_v2.py`, `improved_parser.ts`, `LoginForm-fixed.tsx`. From the assistant's seat this looks cautious — the original is preserved! From the repo's seat it's the worst outcome available: every import, route, and build reference still points at the old file, so the "fix" is dead code from the moment it's written. If the user notices, they have to manually merge the fork back. If they don't, the repo now carries two near-identical files, and future greps, refactors, and bug fixes hit both — with changes landing in whichever copy the maintainer found first.

The same instinct produces in-file forks: a commented-out copy of the old function above the new one, or `processDataNew()` added beside `processData()` with nothing calling it. All of it is version control re-implemented badly, inside the working tree, by an author who already has git. Caution about losing the original is legitimate; the repo's history is where that caution is already handled.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Edit Files, Don't Fork Them

When the task is to change a file, change THAT file. NEVER create a renamed copy (`_v2`, `_new`, `_fixed`, `_improved`, `-old`) as a way of making changes "safely."

A modified copy is dead code with a confusing name: nothing imports it, the original keeps running unfixed, and the repo now has two diverging versions of the truth.

- Fix `auth.py` in `auth.py`. The original is preserved by git, not by leaving a stale twin in the directory.
- The same applies inside files: replace the old implementation rather than leaving it commented out above the new one, and don't add `doThingNew()` beside `doThing()` unless a staged migration is the explicit plan.
- Creating a new file is correct when the task is genuinely additive — a new module, a split-out class, a new test file. The test: will other code reference the new file, and does the old file keep its own ongoing purpose? If the new file only exists to hold "the better version" of an existing one, it's a fork.
- If a rewrite is risky enough that you want the old version available, that's what branches and the unstaged diff are for; say so instead of encoding the rollback plan into filenames.
- Renaming as part of a real refactor is fine — but then complete it: update every reference and remove the old name in the same change, so exactly one version exists afterward.
- Before finishing, check `git status` for new files whose names are an existing file plus a qualifier. Any such file means you forked; merge it back into the original and delete it.

**Red flags that you're about to violate this:**

- "I'll put my version in a new file so nothing breaks." (Nothing changes, either.)
- "The user can diff the two files and pick."
- "I'll keep the old function commented out, just in case."
- "Naming it _v2 makes the improvement clear."
- "Editing the original feels destructive." (Git makes it perfectly reversible.)

---

## Why It Works

1. **It names the killer mechanism: references.** Imports and routes bind to the original path, so a forked fix is unreachable by construction — not risky, not partial, but precisely 0% deployed.
2. **It redirects a legitimate instinct to the right tool.** The desire to preserve the original is correct; the rule points it at git history and branches, which preserve without polluting the tree.
3. **The additive-vs-fork test is decidable** (does other code reference it; does the original keep a purpose?), so the rule doesn't ban creating files — it bans creating *shadows*.

## Origin

A bug report about retry logic was "fixed" in `retry_handler_new.py`, complete and well-tested in isolation. Nothing imported it. The bug stayed live for five weeks while the ticket sat closed, and was reopened with the unimprovable comment: "fix exists, was never wired in." The merge that finally shipped it had to reconcile three intervening changes made to the original file the fork had drifted from.
