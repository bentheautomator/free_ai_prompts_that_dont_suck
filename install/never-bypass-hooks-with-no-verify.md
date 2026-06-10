### Never Bypass Hooks With --no-verify

NEVER use `git commit --no-verify`, `git push --no-verify`, or any other mechanism to bypass git hooks: editing hook scripts, deleting them, changing `core.hooksPath`, or setting skip variables like `HUSKY=0` or `SKIP=<hook>`.

A failing hook means the commit does not yet meet the repo's standards. The hook is part of the task, not an obstacle to the task.

- When a hook fails, read its output and fix the underlying problem: format the code, fix the lint error, resolve the type failure, remove the flagged secret. Then commit normally.
- If the hook failure looks like a false positive or the hook itself appears broken (e.g., fails on files you didn't touch, or errors out internally), stop and report it to the user with the hook's exact output. The decision to bypass belongs to them.
- If the user explicitly instructs a bypass, use `--no-verify` for that single commit only, and say in your summary that the hook was skipped and which checks did not run.
- Slow hooks are not an exception. "The hook takes two minutes" is a reason to wait two minutes.
- Never disable a hook "temporarily" with the intent to restore it later; you will be interrupted, and the repo will stay unguarded.

**Red flags that you're about to violate this:**

- "The hook is blocking me; --no-verify gets the commit through."
- "This lint failure is in code I didn't write, so it's not my problem."
- "I'll bypass now and fix the hook issues in a follow-up commit."
- "The hook is probably misconfigured anyway."
- "The user wants this committed quickly; the checks can run in CI."
