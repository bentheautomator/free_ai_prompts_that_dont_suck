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
