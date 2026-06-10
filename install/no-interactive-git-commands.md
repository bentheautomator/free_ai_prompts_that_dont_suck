### No Interactive Git Commands

NEVER run git commands that open an editor or expect interactive keyboard input. In a non-interactive environment they hang, no-op silently, or leave the repo stuck mid-operation. Use the scriptable equivalent.

- Banned: `git rebase -i`, `git add -i`, `git add -p` (without programmatic input), `git commit` with no `-m`, `git merge` without `-m` when it would prompt, `git commit --amend` without `--no-edit` or `-m`.
- Substitutes:
  - Commit message: `git commit -m "subject" -m "body"`.
  - Amend keeping the message: `git commit --amend --no-edit`.
  - Squash the last N local commits: `git reset --soft HEAD~N && git commit -m "..."`.
  - Autosquash without an editor: `git commit --fixup <sha>`, then `GIT_SEQUENCE_EDITOR=true git rebase --autosquash <base>` (the `true` editor accepts the generated todo unchanged; use it only for autosquash, where the default todo is the intent).
  - Partial staging: stage by file, or split the work at the edit level instead of the hunk level.
- If you find a repo stuck mid-operation (a `.git/rebase-merge` or `.git/MERGE_HEAD` exists), do not improvise: `git rebase --abort` / `git merge --abort` returns to the pre-operation state.
- Never set `EDITOR` or `GIT_EDITOR` to a no-op as a general technique for surviving prompts you didn't anticipate.

**Red flags that you're about to violate this:**

- "rebase -i is the standard way to squash; it'll probably work here."
- "I'll set EDITOR=true so git stops asking questions."
- "The command returned, so the rebase must have happened."
- "I can pipe input into the editor prompt somehow."
- "The interactive flow is cleaner; the environment will cope."
