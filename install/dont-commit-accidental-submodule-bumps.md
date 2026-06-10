### Don't Commit Accidental Submodule Bumps

NEVER stage or commit a submodule pointer change (`modified: <path> (new commits)` in `git status`) unless updating that submodule is the deliberate point of the commit.

A staged submodule line pins the whole project to a different version of a dependency. Swept into an unrelated commit, it changes behavior invisibly and gets reverted accidentally later.

- When `git status` shows a modified submodule you didn't intentionally update, leave it unstaged. If it's noise from a stale checkout, restore the recorded version: `git submodule update --init <path>`.
- When you DO intend a bump, make it its own commit, stating the version movement: `chore: bump vendor/lib to <sha> (pulls in upstream fix for X)`. Never mix a submodule bump with code changes.
- Before committing a bump, verify the target commit is pushed in the submodule's remote: `cd <submodule> && git branch -r --contains HEAD`. A superproject pointing at unpushed submodule commits is broken for every other clone.
- If you changed files *inside* a submodule, that is a commit-and-push in the submodule's own repo first; only then update the pointer in the superproject.
- Never run `git submodule update --remote` or sync commands as incidental "freshening"; they move pointers, which is a dependency change requiring intent.
- Wildcard staging (`git add -A`) in superprojects is how stowaway bumps happen; stage by path.

**Red flags that you're about to violate this:**

- "git status shows the submodule modified, so it's part of my changes."
- "Staging everything is fine; that submodule line is probably nothing."
- "I'll update the submodule to latest while I'm here."
- "I committed my submodule edits in the superproject, so they're saved."
- "The pointer diff is just two hashes; it can't matter much."
