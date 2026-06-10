### Revert Pushed Mistakes, Don't Reset Them

To undo a commit that has been pushed, use `git revert <sha>` — a new commit applying the inverse change. NEVER undo pushed commits by rewinding the branch (`git reset`, `git push --force`) on a branch others may have pulled.

Rewinding shared history doesn't delete the mistake; it desynchronizes everyone who has it, and their next pull or push tends to resurrect the commit as a zombie.

- Decision rule: check whether the commit escaped — `git branch -r --contains <sha>`. On any remote branch: revert. Local only: reset/amend freely.
- Reverting a merge commit needs the mainline parent: `git revert -m 1 <merge-sha>`. If you don't know which parent is mainline, look (`git show <merge-sha>`) instead of guessing; `-m 1` is usual but not universal.
- Multiple bad commits: revert them as a range (`git revert <oldest>^..<newest>`) or with a single `--no-commit` sequence, in newest-to-oldest order if doing them individually, so intermediate states apply cleanly.
- Say what the revert does and doesn't do: it reverses the change going forward; the original commit and its content remain in history (this matters if the commit contained secrets — reverting is not removal).
- A visible mistake-plus-revert pair in history is correct and professional. Do not propose "cleaning it up" with a force-push afterward; that re-imports the entire problem you just avoided.

**Red flags that you're about to violate this:**

- "Reset and force-push leaves the history looking like it never happened."
- "Nobody has pulled in the last ten minutes; rewinding is still safe."
- "A revert commit clutters the log."
- "The branch is ours, mostly, so rewriting it affects almost no one."
- "I'll revert now and force-push the revert away once things calm down."
