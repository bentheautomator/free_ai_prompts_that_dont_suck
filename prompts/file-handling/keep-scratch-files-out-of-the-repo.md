---
title: Keep Scratch Files Out of the Repo
slug: keep-scratch-files-out-of-the-repo
category: file-handling
tags: [universal, files, hygiene]
works_with: all
severity: medium
one_liner: "Stops debug scripts and scratch output from landing in the project tree"
---

# Keep Scratch Files Out of the Repo

> **Works with:** All AI coding assistants (Claude Code, Cursor, Windsurf, Copilot, Cline, Aider)

> Prevents temporary debug scripts, scratch output, and exploration artifacts from being written into the repository tree and shipped with the PR.

**[Copy-paste ready version](../../install/keep-scratch-files-out-of-the-repo.md)** — just the instruction block, no explanation.

## The Problem

Mid-task, an AI assistant wants to test a hypothesis, so it writes `test_debug.py` into the repo root. Then `check_output.json`. Then `repro2.sh` and `notes.txt`. Each one is reasonable in the moment; none of them is cleaned up, because by the time the task is done the assistant's attention is on the fix, not the debris. The user reviews the diff, sees the real change plus four mystery files, and now has to ask which ones matter — or doesn't ask, commits everything, and the repo accretes a `test_quick.py` that future readers assume is a real test.

The repo tree is the worst possible scratch space: everything written there shows up in `git status`, can get swept into a commit by `git add .`, can be picked up by test runners (anything named `test_*.py` *will* be collected by pytest), and pollutes the very diff the user is trying to review. Assistants default to it because the working directory is where their tools point and relative paths are easy.

## The Instruction

Copy everything between the horizontal rules into your instructions file:

---

### Keep Scratch Files Out of the Repo

NEVER write temporary files — debug scripts, scratch output, repro cases, notes — into the repository tree. Use the system temp directory.

Everything inside the repo shows up in `git status`, gets swept into commits, and gets collected by test runners. The repo tree is for deliverables.

- Put scratch work in `/tmp` (or `$TMPDIR`, `mktemp -d`): `/tmp/repro.sh`, not `./repro.sh`.
- Especially never create files matching test-discovery patterns (`test_*.py`, `*.test.js`, `*_test.go`) inside the repo unless they are real tests meant to be kept — runners will execute them.
- Need to run a quick experiment against repo code? Run it from `/tmp` with the repo on the import path, or use the language REPL / a one-liner (`python -c`, `node -e`) that creates no file at all.
- If you genuinely must drop a temporary file inside the tree (a fixture a tool insists on finding locally), delete it before finishing the task, and verify with `git status` that the working tree contains only intended changes.
- Generated debugging output (logs, dumps, screenshots) follows the same rule: temp directory, not repo.
- Before declaring any task done, run `git status`. Every untracked file should be either part of the deliverable or gone.

**Red flags that you're about to violate this:**

- "I'll just drop a quick script here to test this."
- "I'll clean these up at the end." (You won't; the end is about the fix.)
- "It's untracked, so it doesn't hurt anything."
- "The user can ignore the extra files."
- "Naming it test_debug.py makes it obvious it's temporary." (It makes it collectible.)

---

## Why It Works

1. **It moves scratch work outside the blast radius.** Files in `/tmp` cannot appear in `git status`, cannot be committed by `git add .`, and cannot be collected by a test runner — three failure modes eliminated by a path choice.
2. **The test-discovery point names a concrete mechanism:** a "temporary" `test_quick.py` isn't inert clutter, it's executable code the CI suite will run, fail on, and block merges with.
3. **The final `git status` check closes the loop.** "Did I leave anything behind?" becomes a command with an inspectable answer rather than a memory exercise at the moment of lowest diligence.

## Origin

A PR fixing a date-parsing bug arrived with the fix plus `test_repro.py`, `out.json`, and `debug_dates.py`. The reviewer merged it after a long day. CI on the next unrelated PR started failing: pytest had collected `test_repro.py`, which depended on a hardcoded date that expired that weekend. The "temporary" file blocked three merges before anyone worked out it was never meant to exist.
