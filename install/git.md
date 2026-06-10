### Abort Cleanly, Don't Improvise Mid-Operation

When a merge, rebase, cherry-pick, or revert stops partway, use that operation's own controls — `--continue`, `--abort`, `--skip` — and nothing else. NEVER improvise with resets, manual `.git` file deletion, or new commits while an operation is in progress.

A paused operation is not a broken repo; it is git waiting for your decision, with a guaranteed exit (`--abort`) back to the exact pre-operation state.

- First, identify what's in progress: `git status` names it explicitly ("You are currently rebasing", "All conflicts fixed but you are still merging"). Believe that line over your assumptions.
- To proceed: resolve the conflicts properly, `git add` the resolved files, then `git rebase --continue` / `git merge --continue` / `git cherry-pick --continue`. Do not use plain `git commit` to finish a rebase or pick; `--continue` preserves the operation's metadata and authorship.
- To back out: `git <operation> --abort`. This is always safe and always available; prefer it over any clever salvage when you're unsure.
- NEVER: `git reset --hard` mid-operation, deleting `.git/MERGE_HEAD` or `.git/rebase-merge/` manually, starting a second merge/rebase on top of a stuck one, or stashing your way around the pause.
- If even `--abort` fails or the state defies the menu, stop and report the exact `git status` output to the user instead of escalating force.

**Red flags that you're about to violate this:**

- "The repo is in a weird state; a hard reset will normalize it."
- "I'll just commit what's resolved so far and clean up after."
- "Deleting the MERGE_HEAD file should clear this stuck merge."
- "git status looks broken; standard commands clearly aren't working."
- "I'll start a fresh rebase over this one; it'll overwrite the stuck state."

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

### Back Up Before Bulk History Rewrites

NEVER run a repository-wide history rewrite (`git filter-repo`, `git filter-branch`, BFG-style tools, `git rebase --root`) without, in this order: a full backup, the user's explicit informed approval, and a dry run.

A bulk rewrite changes every commit hash in the repository. Done wrong, it silently destroys content; done right, it still invalidates every existing clone, branch, and open PR.

- Backup first, no exceptions: `git clone --mirror . ../repo-backup.git` (a mirror clone preserves all refs). Confirm it exists before touching the original.
- State the consequences to the user in plain terms before proceeding: all commit hashes change; every collaborator must re-clone or hard-reset; open PRs will need rebasing; tags and release references break unless handled.
- Dry run and verify before the real thing: filter-repo's `--dry-run`/analysis output, then after the rewrite compare expectations — does the purged file still appear in `git log --all -- <path>`? Is content you meant to keep intact? Is repo size what you predicted (`git count-objects -vH`)?
- Never run a bulk rewrite to fix something smaller. Wrong author on one unpushed commit is an amend; a secret at HEAD is targeted handling. Reach for whole-history tools only when the problem is genuinely whole-history.
- Pushing the rewritten history is a separate, explicitly approved step — it is where the blast radius goes from local to everyone.

**Red flags that you're about to violate this:**

- "filter-repo is the documented tool for this, so I'll just run it."
- "The operation is well-understood; a backup would be redundant."
- "I'll rewrite first and explain the hash changes afterward."
- "The dry run output is long; the real run will reveal any problems."
- "While I'm rewriting history anyway, I'll clean up a few other things."

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

### Cherry-Pick With Provenance

When cherry-picking, always preserve traceability and remember you are copying, not moving.

- Use `-x` on every cherry-pick of a commit that exists on a public branch: `git cherry-pick -x <sha>`. The appended "(cherry picked from commit ...)" line is the only durable link between the copy and the original.
- A cherry-pick does not remove the original. If the source branch will later merge into the destination, the duplicate pair can produce confusing conflicts; say so when proposing the pick, and prefer merging the source branch (or waiting for it) when the whole branch is destined for the target anyway.
- "Move this commit to branch X" means cherry-pick onto X *and then* deal with the original: remove it from the source branch if the source is private to you, or tell the user it still exists there if not.
- Range syntax drops commits silently: `git cherry-pick A..B` excludes A itself; use `A^..B` to include it. Verify what you picked afterward: `git log --oneline -<n>`.
- If a cherry-pick conflicts, resolve it like any merge conflict or run `git cherry-pick --abort`; never commit half-applied picks, and never resolve by discarding one side wholesale.
- Cherry-pick from a known sha, not from memory of "the fix commit." Confirm with `git show --stat <sha>` that the commit is the one you mean before copying it anywhere.

**Red flags that you're about to violate this:**

- "Cherry-picking it over effectively moves it."
- "-x just adds noise to the message."
- "A..B obviously includes both endpoints."
- "The branches will never meet, so duplicates don't matter."
- "I remember which commit the fix was; no need to inspect it."

### Commit Messages Explain Why, Not What

Write commit messages that record why the change was made. NEVER write a message that merely restates the diff; the diff already stores the what, permanently and precisely.

- Subject line: imperative mood, under 72 characters, naming the change at the level of intent: `fix: prevent session expiry during long uploads`, not `update session.py`.
- Body (for anything non-trivial): explain the motivation — the bug observed, the requirement, the constraint that forced this approach. If you considered an obvious alternative and rejected it, say why in one line.
- Banned message patterns: `update <filename>`, `fix bug`, `changes`, `address feedback`, `WIP`, and any message that lists edited files or paraphrases hunks line by line.
- If you genuinely don't know why the change is being made, that's a signal to ask the user, not to write a vague message around the gap.
- Include issue or ticket references when the user has mentioned them.
- Don't pad: a one-line subject is correct for a genuinely trivial change. The rule is no missing why, not mandatory essays.

**Red flags that you're about to violate this:**

- "I'll just summarize what the diff does."
- "The change is self-explanatory, the filename is enough."
- "I don't actually know why this was needed, but 'fix bug' covers it."
- "Listing the modified functions makes the message look thorough."
- "It's a small commit, the message doesn't matter."

### A Committed Secret Is a Leaked Secret

When a secret has been committed, deleting it in a new commit does NOT remove it; it remains readable in history (`git log -p`). Never report a secret as removed when it is merely deleted at HEAD.

Treat any pushed secret as compromised the moment it left the machine. On public repos, automated scanners harvest credentials from pushes within minutes.

- First question, always: was the commit pushed? `git branch -r --contains <sha>`.
- Not pushed: remove it from history for real. If it's in the latest commit, `git commit --amend` after fixing the file. If deeper, rebase the local commits to drop or edit the offending one. Verify afterward: `git log -p -S '<secret fragment>' --all` returns nothing.
- Pushed: tell the user immediately that rotation is the primary fix, before any git surgery. The credential must be revoked and reissued; history rewriting on a shared remote is secondary cleanup that does not un-leak anything (forks, clones, and caches persist) and needs team coordination.
- Never present "I removed the key in a new commit" as remediation. State plainly: the key is still in history, and here is what that means.
- Prevent the sequel: add the secret's file pattern to `.gitignore` and recommend the user check for the same value in other commits or repos.

**Red flags that you're about to violate this:**

- "I deleted the key from the file and committed; problem solved."
- "It was only pushed a few minutes ago; probably nobody saw it."
- "It's a private repo, so the leak doesn't really count."
- "Rotating the key is the user's department; my part is the git fix."
- "A history rewrite would be disruptive; the deletion commit is good enough."

### Detect the Default Branch, Don't Guess

Never assume the default branch is named `main` or `master`. Detect it once per repo before any operation that references a base branch — branching, diffing, merging, rebasing, or describing where changes will land.

- Detect with: `git symbolic-ref refs/remotes/origin/HEAD --short` (gives e.g. `origin/main`). If unset, `git remote show origin` and read the "HEAD branch" line; it can be cached locally afterward with `git remote set-head origin --auto`.
- Mere existence of a branch named `main` or `master` proves nothing. Repos often carry both, one of them stale by months. Existence is not defaultness.
- Use the detected name everywhere a base appears: `git checkout -b feature/x origin/<default>`, `git diff origin/<default>...HEAD`, merge targets, and in your prose to the user ("this will merge into `develop`").
- Some teams integrate through a branch that is NOT the repo's HEAD branch (e.g. PRs target `develop` while `main` tracks releases). If both patterns are plausible, look for evidence — recent merge commits (`git log --oneline --merges -10 <branch>`), contributing docs — or ask, rather than picking the famous name.
- If you catch yourself typing a base branch name you have not verified in this repo, that line is wrong until proven otherwise.

**Red flags that you're about to violate this:**

- "It's main; it's always main these days."
- "master exists in this repo, so that's the one."
- "Checking the default branch is overhead for a simple diff."
- "The last repo I worked in used develop, so this one probably does too."
- "The checkout succeeded, so I picked the right base."

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

### Don't Sync With a Bare git pull

Do not run `git pull` as a reflex. Fetch first, look at what's incoming, then integrate deliberately — or don't.

`git pull` is fetch plus an immediate merge or rebase (whichever the local config says) into the current tree. Run blind, it creates surprise merge commits, starts conflicts you didn't plan for, and acts on a dirty working tree.

- To get up to date safely: `git fetch`, then inspect: `git status` (are we behind, ahead, or diverged?) and `git log --oneline HEAD..@{upstream}` (what exactly is incoming?).
- Integrate based on what you saw: behind only — `git merge --ff-only @{upstream}` (fast-forwards or refuses, never invents a merge commit); diverged — decide merge vs. rebase deliberately based on whether local commits are shared, and tell the user if it's not obvious.
- Never pull or merge with uncommitted changes in the tree. Commit or stash (with a message) first.
- Don't update the branch at all unless the task needs it. "Sync first" is not a universal opening move; pulling mid-task can change the code under your feet.
- If a pull/merge you ran starts a conflict you weren't prepared for, `git merge --abort` and reassess rather than resolving under pressure.

**Red flags that you're about to violate this:**

- "First, let me pull to make sure everything's current."
- "git pull is harmless; it just downloads updates."
- "Whatever the pull config does — merge or rebase — is fine."
- "There are uncommitted changes, but the pull will probably leave them alone."
- "Diverged? The pull will sort the histories out automatically."

### Finish git bisect With a Reset

Every `git bisect start` must end with `git bisect reset` in the same task — no exceptions, including when the bisect is interrupted, errors out, or finds its answer early. Bisect is a mode: until reset, the repo sits detached on an arbitrary historical commit.

- Before starting, confirm the tree is clean (`git status`); bisecting with uncommitted changes mixes them into every checkout.
- Get the labels right before the first mark: `bad` = the commit where the problem EXISTS (usually newer), `good` = where it does NOT (usually older). When bisecting for when something was *fixed*, the vocabulary inverts confusingly; use `git bisect start --term-new=fixed --term-old=broken` and matching terms instead of forcing good/bad to mean their opposites.
- Verify both endpoints empirically before trusting them: actually run the test at the alleged good commit and the alleged bad one. A wrong endpoint silently produces a wrong answer with full confidence.
- Prefer automation where a command can decide: `git bisect run <test-command>` removes per-step labeling errors entirely.
- When bisect names a first-bad commit, sanity-check it: `git show <sha>` — does the change plausibly relate to the symptom? Then `git bisect reset` before doing anything else, including writing your report.
- If you find a repo already mid-bisect (`git status` mentions bisecting, or `.git/BISECT_LOG` exists), reset it before normal work.

**Red flags that you're about to violate this:**

- "Found the culprit; let me investigate it right from here."
- "The bisect crashed, so the mode probably cleared itself."
- "Good means the older commit, always."
- "I'll skip verifying the endpoints; the user told me where it broke."
- "I'll leave the bisect open in case we need to continue later."

### Force-Push With Lease, Never Bare --force

NEVER run `git push --force`. If a forced push is genuinely required and the user has approved it, use `git push --force-with-lease` and nothing else.

A bare `--force` replaces the remote branch unconditionally, deleting any commits teammates pushed since your last fetch. `--force-with-lease` refuses to overwrite history you have not seen, which is the entire safety difference.

- A rejected push is information, not an obstacle. Diagnose why the remote is ahead (`git fetch` then `git log HEAD..@{upstream}`) before considering any forced push.
- Never force-push to a default branch (`main`, `master`, `develop`, release branches) under any circumstances.
- Force-pushing is acceptable only on a branch the user owns, after history was deliberately rewritten, with the user's explicit approval for that specific push.
- Run `git fetch` immediately before `git push --force-with-lease` so the lease reflects current remote state; a stale lease is barely better than no lease.
- If `--force-with-lease` is rejected, the remote has new commits. Stop and show them to the user; do not retry with `--force`.

**Red flags that you're about to violate this:**

- "The push was rejected, so I need --force."
- "It's probably just my own rewritten commits up there."
- "--force-with-lease failed, so I'll use the stronger flag."
- "This is a feature branch, force-pushing is fine without checking."
- "The user wants this pushed; whatever is on the remote is outdated."

### Keep Generated Artifacts Out of Commits

NEVER commit generated files: build output, dependency directories, caches, coverage reports, compiled binaries, logs, or data dumps. Git history keeps every byte forever; a single committed artifact bloats every future clone, and removing it later requires rewriting history.

- Treat these as radioactive unless the repo demonstrably tracks them already: `node_modules/`, `dist/`, `build/`, `out/`, `target/`, `.next/`, `__pycache__/`, `*.pyc`, `coverage/`, `*.log`, `.DS_Store`, `*.sqlite`, `*.dump`, virtualenv directories.
- Before committing, scan `git status` for files no human wrote. The test: if deleting it and re-running the build recreates it, it does not belong in git.
- If a needed ignore pattern is missing, add it to `.gitignore` in the same change, scoped to the actual path (e.g. `dist/`).
- Lockfiles (`package-lock.json`, `Cargo.lock`, `poetry.lock`) are the exception: they are generated but belong in git. Follow the repo's existing convention.
- Any single file over ~5MB gets flagged to the user before staging, whatever it is. If large binaries genuinely must be versioned, that is a Git LFS conversation, not a regular `git add`.
- If you notice an artifact was already committed earlier in your session and not yet pushed, remove it from history now (`git rm -r --cached <path>` plus amend or a fixup) rather than leaving it for someone else to excavate.

**Red flags that you're about to violate this:**

- "These files appeared during my build, so they're part of my change."
- "The dist folder is small right now; it won't matter."
- "It's untracked and not ignored, so the repo must want it tracked."
- "Committing the build output will save the next person a build step."
- "I'll include the database dump so the tests are reproducible."

### Leave .git Internals Alone

NEVER manually edit, delete, or create files inside the `.git` directory. It is a database with internal consistency rules; hand modifications corrupt it. Above all, NEVER delete the `.git` directory itself — that permanently destroys all history, branches, stashes, and the reflog for anything unpushed.

Use porcelain commands for everything:

- Config changes: `git config <key> <value>`, never editing `.git/config` directly.
- Refs and branches: `git branch`, `git update-ref`, `git symbolic-ref` — never touching `.git/refs/` or `packed-refs` by hand.
- A "corrupt" index: `git read-tree HEAD` or at most removing `.git/index` is folk wisdom; before anything like it, try `git status` in a fresh shell, then report. Do not delete index, HEAD, or any state file as a debugging move.
- The one narrow exception: a stale `.git/index.lock` may be removed, but only after verifying no git process is running (`ps aux | grep git`) and saying you're doing it. Nothing else in `.git` qualifies for this treatment.
- In-progress operation state (`MERGE_HEAD`, `rebase-merge/`, `CHERRY_PICK_HEAD`) is cleared with the operation's `--abort`/`--continue`, never by deleting the files.
- If you suspect real corruption (`git fsck` errors, "bad object" messages), stop, run `git fsck` for the report, and bring the output to the user. Repository surgery is a human decision made with backups, not an autonomous fix.

**Red flags that you're about to violate this:**

- "The index seems corrupted; deleting .git/index should rebuild it."
- "I'll just edit .git/config directly; it's a plain text file."
- "Removing this ref file is faster than figuring out the command."
- "Deleting .git resets the repo but keeps all the code."
- "I saw this fix on a forum: rm a couple of files under .git."

### Never Amend Pushed Commits

NEVER run `git commit --amend` on a commit that has been pushed to a remote. Amending rewrites the commit; if the original is already on the remote, you have forked history and the only way forward is a force-push that breaks everyone who pulled it.

- Before any `--amend`, verify the commit is local-only: `git log --oneline @{upstream}..HEAD` must include HEAD. If there is no upstream, check `git branch -r --contains HEAD`; if any remote branch contains it, do not amend.
- If the commit is already pushed, make a new commit instead. A small `fix: correct typo in previous change` commit is correct; rewritten shared history is not.
- This applies to all forms: `--amend`, `--amend --no-edit`, and amend-equivalents like `git rebase` onto a parent of a pushed commit.
- The sole exception is when the user explicitly confirms the branch is theirs alone and asks for the rewrite, after you state that a force-push will be required.
- Never chain amend with push: if you find yourself planning `--amend` followed by `push --force`, stop and report instead.

**Red flags that you're about to violate this:**

- "This tiny fix belongs in the last commit, I'll just amend it."
- "Amending keeps the history clean."
- "It was only pushed a minute ago, nobody has pulled it yet."
- "I'll amend now and deal with the push rejection later."
- "The commit message has a typo; a quick amend will fix it."

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

### Never Discard Work With git checkout .

NEVER run `git checkout .`, `git checkout -- <path>`, `git restore .`, or `git restore <path>` to discard changes. These commands permanently destroy uncommitted work; there is no reflog, stash, or undo for what they delete.

The working tree may contain the user's uncommitted changes mixed with yours. A wildcard discard cannot tell them apart.

- To undo your own changes, prefer reversible moves: re-edit the file back, or `git stash push -m "discarding: <reason>" <paths>` so the content survives and can be recovered.
- If you must discard, discard only specific files you personally modified in this session, name them to the user first, and confirm via `git diff <file>` that nothing in the diff is unfamiliar.
- If `git status` or `git diff` shows changes you did not make, do not discard anything; report what you found and let the user decide.
- Never combine discards with other cleanup (`git clean`, `git reset --hard`) in one step; each destructive command needs its own justification.
- "Get back to a clean state" is not a goal that justifies deleting work. A dirty working tree is a normal condition, not an error.

**Red flags that you're about to violate this:**

- "My approach failed, I'll reset everything and start fresh."
- "The working tree is messy; let me clean it up first."
- "These modifications are probably all mine from earlier."
- "git checkout . is the standard way to undo local changes."
- "The user wants the bug fixed, not these half-finished edits."

### Never Fabricate Git Identity

NEVER invent values for `git config user.name` or `user.email`, and NEVER modify the user's global git config (`--global`, `--system`) on your own initiative. If git refuses to commit because identity is unset, that's a question for the user, not a blank for you to fill.

Commit authorship feeds attribution, audits, signing policies, and CLA checks. A made-up email pollutes all of them, and a global config edit silently changes every repository on the machine.

- When you hit "Please tell me who you are," stop and ask the user what identity to use. Don't guess from usernames, hostnames, or other repos.
- When the user provides an identity, set it for this repository only: `git config user.name "..."` and `git config user.email "..."` (no `--global`).
- Never change an *existing* configured identity because a tool, server, or hook rejects it; report the rejection instead.
- Do not use `--author` or `GIT_AUTHOR_*`/`GIT_COMMITTER_*` overrides to commit as someone else — including as the user on changes they haven't seen — unless explicitly directed.
- Never flip `commit.gpgsign` or signing keys to get past a signing failure; a commit that won't sign is a stop-and-report situation.
- If your environment has a designated bot/agent identity provided for you, use exactly that; "something like it" is fabrication.

**Red flags that you're about to violate this:**

- "Git wants an email; user@example.com unblocks the commit."
- "I'll set it globally so this never bothers us again."
- "I can derive their email from the repo's other commits."
- "The signing config is failing, so I'll just disable signing."
- "Any identity works; it's only metadata."

### Never Force a Branch Switch Over Changes

NEVER add `-f`/`--force` or `--discard-changes` to a `git checkout` or `git switch` that was refused because local changes would be overwritten. That refusal is git protecting uncommitted work, which has no reflog and no recovery once overwritten.

The error message itself lists the safe options: commit or stash. Pick one.

- Read the refused-files list. If any file's changes aren't yours from this session, stop; you were about to destroy someone's work in progress.
- Default safe path: `git stash push -m "parked to switch to <branch>"`, switch, do the task — and restore or report the stash before finishing (an unreported stash is slow-motion data loss).
- If the changes are yours and belong with the work, commit them on the current branch first, then switch.
- If you need the other branch only to *read* something, don't switch at all: `git show <branch>:<path>` reads any file, `git log <branch>` reads history, and `git worktree add` gives a second directory — all without touching this tree.
- The same rule covers cousin moves with the same effect: `git reset --hard <other-branch>` and `git checkout <branch> -- .` are also "switch by destroying"; don't.
- There is no urgency exception. Every legitimate reason to be on the other branch survives the ten seconds a stash costs.

**Red flags that you're about to violate this:**

- "Checkout failed; -f is the flag that makes it succeed."
- "Those modified files are probably mine from earlier anyway."
- "The changes blocking me look minor; nothing valuable in them."
- "I need main right now; stashing is an extra step."
- "--discard-changes sounds tidier than force, so it must be safer."

### Never Move Published Tags

NEVER move, force-update, or delete a tag that has been pushed. A published tag is a permanent name for one commit; once others may have fetched it, changing it makes the same version mean different code on different machines, silently — `git fetch` does not update moved tags by default.

- Bad release? Tag a new version (`v2.1.1`) on the fixed commit. The flawed tag stays as a historical fact. This is the entire playbook.
- Banned on any pushed tag: `git tag -f <name>`, `git push -f origin <tag>`, `git push origin :refs/tags/<name>` (deletion), and delete-then-recreate sequences, which are a move with extra steps.
- Local-only tags (never pushed; verify with `git ls-remote --tags origin <name>` returning nothing) may be freely fixed before publishing.
- Creating tags: use annotated tags for releases (`git tag -a v2.1.1 -m "release v2.1.1"`), confirm the tagged commit is the one intended (`git show v2.1.1 --stat`), and push by name (`git push origin v2.1.1`), never `git push --tags`.
- If the user explicitly insists on moving a published tag, state the consequence first — existing clones keep the old tag silently; anything that cached the version may pin stale code — and require their confirmation.

**Red flags that you're about to violate this:**

- "The release was broken, so I'll just point v2.1.0 at the fixed commit."
- "Deleting and recreating the tag is cleaner than a new version number."
- "Tags are just refs; updating one is like updating a branch."
- "Everyone will get the corrected tag next time they fetch."
- "A patch release for a one-commit fix feels like bureaucracy."

### Never Rebase Shared Branches

NEVER rebase a branch that exists on a remote and may have been pulled or branched from by anyone else. Rebasing replaces commits with new copies; everyone whose work references the old commits is stranded on abandoned history.

- Before any `git rebase`, determine whether the commits being rewritten are shared: `git branch -r --contains <commit>` on the oldest commit the rebase would rewrite. If any remote branch contains it, treat it as shared.
- To bring upstream changes into a shared branch, use `git merge origin/main` instead of rebase. The merge commit is the cost of not breaking collaborators.
- Rebasing local, never-pushed commits onto an updated base is fine and encouraged. The line is push status, not branch type.
- A branch with an open pull request counts as shared by default: reviewers' comments and any stacked branches reference its current commits. Get explicit confirmation from the user before rebasing it.
- If the user asks you to rebase a shared branch anyway, state the consequence in one sentence (a force-push will be required and anyone tracking the branch will need to recover) and proceed only after they confirm.

**Red flags that you're about to violate this:**

- "Rebasing onto main keeps the history linear and clean."
- "I'll rebase and force-push; that's the standard workflow."
- "It's a feature branch, so rebasing it is safe by definition."
- "Nobody else is working on this branch, probably."
- "The PR has conflicts; the quickest fix is a rebase."

### Never Re-Clone to Fix Git State

NEVER delete a repository directory and re-clone as a way to fix a confusing git state, and never recommend it as the easy option. The clone only restores what the remote has; everything local-only is destroyed: unpushed commits and branches, stashes, uncommitted and untracked files, env files, local config, and the reflog.

- Diagnose before judging the state unfixable: `git status`, `git log --oneline --graph --all -20`, `git stash list`, `ls .git/` (look for `rebase-merge/`, `MERGE_HEAD`, `index.lock`).
- Most "broken" states have a one-line exit: `git rebase --abort`, `git merge --abort`, `git cherry-pick --abort`. A stale `index.lock` with no git process running can be removed by itself; that is not a reason to remove the repo.
- Inventory before any drastic step. What exists here that the remote does not? `git log --branches --not --remotes --oneline` (unpushed commits), `git stash list`, `git status --short` (uncommitted and untracked).
- If a fresh clone is genuinely the right call (e.g. actual object corruption), get the user's explicit agreement, and move the old directory aside (`mv repo repo.broken-backup`) instead of deleting it, so local-only work remains recoverable.
- "I don't understand this state" routes to investigation or to asking the user — never to disposal.

**Red flags that you're about to violate this:**

- "The fastest fix is a fresh clone."
- "This state is too tangled to be worth untangling."
- "Everything important is surely pushed already."
- "A clean clone eliminates all the variables."
- "I'll suggest re-cloning; it's what people usually do anyway."

### Never Run git clean Blind

NEVER run `git clean` without first running `git clean -n` (dry run) with identical flags and reading every line of its output. `git clean` deletes untracked files from disk; they exist nowhere in git, so there is no undo of any kind.

- Untracked files are frequently the user's newest work — files written today that haven't been added yet — plus local configs and secrets. "Untracked" does not mean "unwanted."
- Workflow, always in this order: `git clean -n -d` first; show the file list to the user or verify every single entry is something you created this session; only then run the real command, scoped to specific paths where possible (`git clean -f path/to/dir`).
- NEVER use `-x` or `-X`. They delete ignored files, which is where `.env` files, local overrides, and IDE state live. If an ignored file needs deleting, delete it by name with `rm`.
- Do not chain `git clean` after `git reset --hard` as a combo "fresh start." Each command needs its own justification and its own check.
- If the goal is removing build artifacts, prefer the build tool's own clean target (`make clean`, `npm run clean`, `cargo clean`); those know what they made.

**Red flags that you're about to violate this:**

- "A truly clean tree needs clean -fdx."
- "Untracked files are just leftovers; they're not in git for a reason."
- "The dry run is an extra step and I can guess what it'll show."
- "I'll do reset --hard plus clean -fd, the classic fresh-start combo."
- "Whatever it deletes can't be important or it would be committed."

### Never Silently Pick a Side in Merge Conflicts

NEVER resolve a merge conflict by mechanically keeping one side. Both sides of a conflict were written deliberately; a resolution must preserve the intent of both or explicitly justify dropping one.

- Banned as default moves: `git checkout --ours <file>`, `git checkout --theirs <file>`, `git merge -X ours`, `git merge -X theirs`, and hand-deleting one side's hunk without reading it.
- For each conflicted file, read both sides and state what each was trying to do. Then construct a resolution that preserves both intents; usually this means combining the changes, not choosing.
- If both intents genuinely cannot coexist (e.g., two different fixes for the same bug), choose deliberately and say so: report which side you dropped, what it contained, and why.
- After resolving, search the file for leftover markers (`<<<<<<<`, `=======`, `>>>>>>>`) and re-run the relevant tests for both sides' changes if they exist.
- If a conflict is too tangled to resolve confidently, stop and present both sides to the user instead of guessing. An aborted merge (`git merge --abort`) is recoverable; silently destroyed work is not.

**Red flags that you're about to violate this:**

- "Our version is newer, so theirs is outdated."
- "Taking --theirs for the whole file resolves all six conflicts at once."
- "The tests pass after keeping our side, so the resolution is correct."
- "The other side's change looks unrelated to what I'm doing."
- "I need this merge finished; I'll keep the simpler side."

### No Commits Unless Asked

Do not create commits unless the user explicitly asked for a commit. "Fix the bug," "add the feature," and "refactor this" are requests for changes; the deliverable is a working tree the user can review, not a commit.

- After making changes, stop. Summarize what you changed and let the user review the diff. Committing is their call unless they delegated it in so many words.
- Words that authorize a commit: "commit," "commit this," "make a commit when done." Words that do not: "finish it," "ship it" (ask what they mean), "clean this up," task descriptions of any kind.
- Never push unless pushing was also explicitly requested; a commit authorization is not a push authorization.
- If the user has staged changes in the index when you would commit, stop regardless of instructions; an authorized commit of your work is not an authorization to commit theirs.
- For multi-step tasks where intermediate commits genuinely help (e.g. a long refactor the user asked you to commit "as you go"), that standing instruction counts as explicit; absent it, batch nothing into history.
- If you believe a commit is genuinely needed (e.g. to run a tool that requires a clean tree), say so and ask; do not commit as a workaround silently.

**Red flags that you're about to violate this:**

- "The task is done, so the natural last step is committing it."
- "A good assistant delivers a complete unit of work."
- "The user will obviously want this committed; I'm saving them a step."
- "I'll commit so the change doesn't get lost."
- "Committing makes my work look finished."

### No Direct Commits to Main

NEVER commit directly to `main`, `master`, `develop`, or any release branch. Always work on a feature branch.

Committing to the default branch bypasses review and PR-based checks, and untangling a commit from main is far harder than creating a branch would have been.

- Before your first commit in any session, run `git branch --show-current`. If it prints a protected branch name, create a branch first: `git checkout -b <type>/<short-description>` (e.g. `fix/login-timeout`).
- If you discover uncommitted work sitting on main, branch from right where you are; the changes come with you: `git checkout -b fix/whatever`. Do not commit "just this once" on main.
- If you discover you already committed to main but have not pushed, move the work: `git branch fix/whatever && git reset --hard origin/main` only after confirming with `git status` that nothing uncommitted will be lost, then check out the new branch.
- If the commit on main is already pushed, stop and tell the user; the fix depends on team policy and is not yours to choose.
- Only commit to main when the user explicitly instructs it for this specific commit.

**Red flags that you're about to violate this:**

- "Main is checked out, so that's where the user wants this."
- "It's a one-line fix; a branch is overkill."
- "I'll commit here and move it to a branch later if needed."
- "This repo looks like a solo project; branch discipline doesn't apply."
- "Creating a branch will interrupt my flow; commit first, sort it out after."

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

### No Nested Git Repos

NEVER run `git init` or `git clone` inside an existing repository's working tree without the user explicitly asking for a nested repo or submodule. A repo inside a repo doesn't get tracked; it gets committed as an empty pointer (a gitlink), and clones receive an empty directory.

- Before any `git init`, check where you are: `git rev-parse --show-toplevel`. If it prints a path, you are already inside a repository; initializing here creates a nested one.
- Scaffolding tools (project generators, `create-*` CLIs) often run `git init` themselves. After scaffolding inside an existing repo, check for and remove the stray inner repo: `find <new-dir> -maxdepth 2 -name .git`, then delete that `.git` directory (the code is untouched; only the inner repo metadata goes).
- Need to read another project's code? Clone it OUTSIDE the working tree (`/tmp` or a sibling directory), never into the repo.
- The status tell: a whole directory appearing as a single untracked entry, or staging it producing one `new file (mode 160000)` line instead of many files, means there's an inner `.git`. Stop and remove it before committing.
- If a gitlink already got committed, fix it explicitly: `git rm --cached <dir>` (one level, no `-r` needed for a gitlink), remove the inner `.git`, then `git add <dir>` to track the actual files.
- If the user genuinely wants an embedded repository, that's a submodule conversation (`git submodule add <url> <path>`), not a bare nested clone.

**Red flags that you're about to violate this:**

- "I'll git init the new package directory so it has version control."
- "Cloning the example repo into the project keeps everything together."
- "The generator ran git init, but that's probably harmless."
- "git status shows the directory, so its contents are being tracked."
- "Mode 160000 is just some permission thing."

### No Push Unless Asked

NEVER run `git push` unless the user explicitly requested a push in this conversation. Committing and pushing are separate authorizations: "commit this" does not include pushing.

Pushing converts reversible local work into published state. Before push, anything can be cleaned up freely; after push, mistakes require reverts or coordinated history rewrites, and push-triggered CI/CD may act on the commits immediately.

- Words that authorize a push: "push," "push it up," "publish the branch," "open a PR" (pushing the branch is a prerequisite, say you're doing it). Words that do not: "commit," "save the work," "finish up," "we're done here."
- When your work is committed and unpushed, end your summary with the state: "Committed locally on <branch>; not pushed."
- If a push seems clearly useful (e.g. the user wants CI feedback), suggest it and wait: "Want me to push so CI runs?"
- A standing instruction in project config ("always push after committing") counts as explicit authorization; an inference from past sessions does not.
- If you discover the repo has push-triggered deploys, treat pushing with extra gravity and say what the push will trigger when you ask.

**Red flags that you're about to violate this:**

- "Commit and push go together; the task isn't done until it's on the remote."
- "Pushing now saves the user a step later."
- "They said 'wrap it up,' which surely includes pushing."
- "The branch is ahead of origin; syncing it is just hygiene."
- "Last session they always wanted pushes, so this session does too."

### No git reset --hard Without a Safety Net

NEVER run `git reset --hard` while the working tree or index contains changes you have not preserved. The command destroys all uncommitted work instantly; the reflog protects commits, not your working tree.

- Before any `reset --hard`, run `git status`. If it shows anything besides a clean tree, preserve first: `git stash push -u -m "pre-reset safety net"` (the `-u` captures untracked files too). Only then reset.
- Ask whether you need `--hard` at all. To unstage, use `git reset` (mixed) or `git restore --staged`. To move a branch pointer without touching files, use `git reset --soft` or `git branch -f`. `--hard` is for the rare case where discarding the tree is the explicit goal.
- Never use `reset --hard` to "sync with the remote" or "fix" a confusing state. Diagnose first: `git status`, `git log --oneline --graph -10`, `git stash list`. Confusion is a reason to gather information, not to erase it.
- Never run it on a branch you haven't confirmed you're on: `git branch --show-current` first.
- If you preserved a safety-net stash and the reset went fine, tell the user the stash exists rather than silently dropping it.

**Red flags that you're about to violate this:**

- "The state is confusing; a hard reset gives me a known-good baseline."
- "git status shows some changes but they're probably not important."
- "I'll reset --hard to origin to make sure we're in sync."
- "The reflog means nothing is ever really lost."
- "This is the fastest way to undo my last few steps."

### One Logical Change Per Commit

Each commit contains exactly one logical change. NEVER bundle unrelated work — a fix plus a refactor plus formatting plus config — into a single commit because they happen to share a working tree.

The test: can you describe the commit honestly in one sentence without using "and also"? If not, split it.

- Before committing, sort the modified files (and where needed, hunks within a file) into logical groups. Stage and commit each group separately with its own message: the fix, then the refactor, then the formatting pass.
- Mechanical changes (formatting, renames, generated-file regeneration) always get their own commit, clearly labeled, so reviewers and `git blame` can skip them.
- If you fixed a bug and refactored around it, the refactor that *enables* the fix may share the commit; the refactor you did because you were in the neighborhood may not.
- Order matters: commit prerequisite changes first so each commit builds and passes tests on its own when practical.
- Don't overcorrect into confetti: ten one-line commits for one coherent change is the same disease mirrored. One logical change can be large.
- If files contain interleaved changes from different logical groups, use `git add -p` style hunk staging (non-interactively if needed) rather than giving up and committing the blend.

**Red flags that you're about to violate this:**

- "Everything in the tree is from this session, so one commit covers it."
- "Splitting this up means writing four commit messages."
- "The formatting changes are riding along, but they're harmless."
- "I'll mention the refactor in the commit body, that's basically splitting."
- "The user just wants it committed; granularity is a nicety."

### Push Only the Branch You Mean

Push with a fully explicit refspec: `git push origin <branch-name>`, where `<branch-name>` is the branch you verified you're on. NEVER use `git push --all`, `git push --mirror`, or `git push --tags` as part of routine work.

Vague pushes publish things you didn't intend: the user's local experiments, stale branches, or commits on a branch you never worked on.

- Immediately before pushing, confirm the branch: `git branch --show-current`. The name in your push command must be that output, not an assumption.
- Check what you're about to publish: `git log --oneline @{upstream}..HEAD` (or `origin/<branch>..HEAD` for a first push). If commits appear that you didn't create this session, stop and ask.
- In repos with multiple remotes (`git remote -v`), confirm which remote is the intended target before pushing; forks and upstreams are routinely confused.
- First push of a new branch: `git push -u origin <branch-name>` to set the upstream once, explicitly.
- Other branches the user has locally are never yours to publish, no matter how "ready" they look.
- Tags are pushed only by name and only on request: `git push origin v1.2.3`, never `--tags`, which publishes every local tag including experiments.

**Red flags that you're about to violate this:**

- "push --all makes sure nothing is left behind."
- "I'll push main too while I'm at it; it looks ahead."
- "origin is always the right remote."
- "A bare git push will do whatever's configured, which is probably fine."
- "I'll push the tags along with the branch to be thorough."

### Rescue Commits From Detached HEAD

Before switching away from a detached HEAD, check whether you made commits there. If you did, give them a branch name first; switching away without one orphans the commits.

- Know when you're detached: `git status` says "HEAD detached at <ref>" and `git branch --show-current` prints nothing. Check after any checkout of a tag, commit hash, or `origin/<branch>`.
- Detached HEAD is a normal state for *reading* — inspecting old code, running tests against a release. Do not panic-escape it, and do not start *writing* there if you can branch first: `git switch -c investigate-v2-bug v2.0.1`.
- If you already committed on a detached HEAD, anchor the work before any checkout: `git branch rescue/<description> HEAD`, then switch wherever you need; the commits now have a name.
- If you realize you switched away and left commits behind, recover immediately: `git reflog` shows the abandoned tip; `git branch rescue/<description> <sha>` saves it. Git's own "leaving behind" warning prints the sha — read it instead of scrolling past.
- Never run history-altering or destructive commands (`rebase`, `reset --hard`) while detached; fix your footing first.

**Red flags that you're about to violate this:**

- "Detached HEAD sounds broken; I'll checkout main to fix it."
- "I'll just make this small commit here and sort out branches later."
- "The warning git printed is boilerplate."
- "My commits are in the repo somewhere; switching branches can't hurt them."
- "I don't need a branch for a quick experiment."

### Respect Worktrees, Don't rm Them

Before branch operations or directory cleanup in any repo, check whether worktrees are in play: `git worktree list`. A linked worktree is part of the repository, not a disposable copy of it.

- NEVER delete a worktree directory with `rm -rf`. Use `git worktree remove <path>`, which refuses if the tree is dirty — that refusal is your signal that uncommitted work exists there. Inspect it before deciding anything; do not escalate to `--force` to make the refusal stop.
- If git refuses a checkout with "already checked out at <path>", that branch is live in another worktree, possibly with someone's work in progress. Do not force past it (`--ignore-other-worktrees`, branch deletion, `checkout -f`). Either work in that other directory, or create a separate branch/worktree for your task.
- Know where you are: `git rev-parse --git-common-dir` differing from `--git-dir` means you're in a linked worktree. Branch deletions, config changes, and stashes affect the whole repository, not just this directory.
- If you find orphaned worktree registrations (directory gone, entry remains in `git worktree list`), clean the metadata with `git worktree prune` — after confirming the directory is truly gone, not on an unmounted path.
- Creating a worktree is a fine, low-risk way to do side tasks (`git worktree add ../repo-hotfix hotfix-branch`) without disturbing the user's checkout; prefer it over stashing their work to switch branches.

**Red flags that you're about to violate this:**

- "There's a duplicate copy of the project here; I'll delete it."
- "Git says the branch is checked out elsewhere, but force will fix that."
- "rm -rf is equivalent to whatever git's removal command does."
- "This is the only working directory; no need to check."
- "That other worktree is old; nothing in it can matter."

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

### Scope .gitignore Patterns Narrowly

Write `.gitignore` patterns as narrowly as the actual problem requires. NEVER add a broad extension or wildcard pattern (`*.json`, `*.txt`, `data/`, `config*`) to handle one specific file or directory.

Overbroad patterns silently hide future legitimate files; the failure surfaces months later when someone's new file never makes it into a commit.

- Ignore the specific path, not the class: `build/output.json`, not `*.json`. Anchor patterns with a leading `/` when you mean the repo root (`/dist/`, not `dist/` which matches at any depth).
- Before adding any pattern, test its blast radius: `git status --ignored --short` after the change, or `git check-ignore -v <path>` on files that should NOT be ignored, to confirm they aren't.
- Adding a pattern does nothing to files already tracked. If the goal is to stop tracking a file, you need both the ignore entry and `git rm --cached <path>` (which keeps the file on disk), and the user should know the file will vanish from the repo for everyone else on their next pull.
- Never "fix" a noisy `git status` by ignoring whole directories you haven't inspected.
- Comment non-obvious entries: `# generated by scripts/export.py` costs one line and saves the next archaeologist an hour.

**Red flags that you're about to violate this:**

- "Ignoring all .json files covers this case and any like it."
- "I added it to .gitignore, so git will stop tracking it now."
- "A wildcard is more robust than listing specific files."
- "git status is noisy; ignoring this whole directory cleans it up."
- "Nobody will ever need to commit a file matching this pattern."

### Stage Files by Name, Never git add -A

NEVER stage with `git add -A`, `git add .`, `git add --all`, or `git commit -a`. ALWAYS stage by explicit path: `git add src/auth.py tests/test_auth.py`.

Blanket staging commits everything in the working tree, including files you did not touch and files that must never enter history: credentials, local config, scratch files, build output.

- Before staging, run `git status` and read the output. Every file you stage must be one you deliberately changed for this task.
- Stage only the files you edited, by full path. If you edited many files, list them all; length is not an excuse for `-A`.
- If `git status` shows untracked files you did not create, leave them alone and mention them to the user.
- If `git status` shows files that look like secrets or local config (`.env`, `*.pem`, `credentials*`, `*.key`, `settings.local.*`), never stage them, even if asked vaguely to "commit everything." Name them and ask.
- After staging, run `git diff --cached --stat` and confirm the file list matches what you intended before committing.

**Red flags that you're about to violate this:**

- "There are a lot of changed files, `git add -A` is simpler."
- "The user said commit everything, so everything means everything."
- "These untracked files are probably fine to include."
- "I'll just stage it all and the gitignore will filter out the bad stuff."
- "I don't have time to figure out which files I actually changed."

### Stash Safely or Not at All

Treat the stash as a place work can be lost, not a free temp area. Every stash you create must be labeled, accounted for, and restored or reported by the end of the task.

- Always stash with a message: `git stash push -m "user's WIP on auth refactor, stashed to switch branches"`. Anonymous stash entries are how work gets orphaned.
- If you stash someone's changes to unblock an operation, restoring them is part of the task. Before finishing, run `git stash list`; if your entry is still there, restore it or explicitly tell the user it exists and why.
- Restore with `git stash apply`, not `git stash pop`. Apply keeps the entry, so a conflicted or wrong-branch restore loses nothing; drop the entry manually only after confirming the restore is intact.
- NEVER run `git stash drop` or `git stash clear` on entries you did not create in this session. Existing stashes may be the user's parked work.
- If applying a stash conflicts, stop and resolve it like any merge conflict; do not reset the tree or re-stash on top.
- Consider whether a stash is needed at all: committing to a temporary branch (`git checkout -b wip-parking && git commit -am "parking"`) is strictly more durable and visible.

**Red flags that you're about to violate this:**

- "I'll stash this quickly; no time for a message."
- "Stash pop is the normal way to get things back."
- "These old stash entries are clutter; I'll clear them."
- "The user's changes are safe in the stash, my task here is done."
- "The pop conflicted, so I'll just stash everything again and move on."

### Untrack With git rm --cached, Not git rm

When asked to remove a file from git, from tracking, or from the repo, ALWAYS use `git rm --cached <path>` — which keeps the file on disk — unless the user has explicitly said they want the file deleted from the filesystem too.

`git rm` without `--cached` deletes the file from disk as well as the index. Untracking requests usually target local-only files (`.env`, keys, machine config) that exist nowhere else; deleting them is unrecoverable by git.

- Default reading of "remove X from git": untrack it. Use `git rm --cached X` (add `-r` for directories), then add an ignore entry so it doesn't get re-added by the next broad stage.
- Immediately after, verify the file still exists on disk: `ls -la <path>`.
- Warn the user of the propagation effect: once the untracking commit is pulled, the file disappears from teammates' working trees, because for them it goes from tracked to deleted. If others need it, they must copy it aside first.
- If the file holds secrets and was ever committed, untracking does not remove it from history; say so explicitly rather than implying the secret is now gone.
- Only run bare `git rm <path>` when the user has clearly asked for the file to be deleted, and restate that consequence in your reply ("this deletes the file from disk as well").

**Red flags that you're about to violate this:**

- "Remove from git means git rm, simple."
- "The file shouldn't exist anyway if it's not supposed to be tracked."
- "--cached is an extra flag; the basic command is probably what they meant."
- "It's just a config file; it can be regenerated."
- "I'll untrack it and the history question can wait."

### Verify Merged Before Deleting Branches

NEVER delete a branch with `git branch -D` as a retry after `git branch -d` is refused. The refusal means the branch holds commits that exist nowhere else; deleting it discards them.

- Before deleting any branch, check what would be lost: `git log --oneline main..<branch>`. Empty output means safe to delete with `-d`; any output means those commits exist only there.
- If the branch was squash-merged, `-d` refuses even though the content landed. Verify before believing this: confirm the squash commit exists on the target (`git log --oneline main | head`, compare against the branch's changes with `git diff main...<branch>` — an empty diff means the content is merged).
- Use `-D` only after you have verified the content is preserved elsewhere or the user has explicitly confirmed the unmerged commits are disposable, with the commit list in front of them.
- The same rule covers remote deletion: before `git push origin --delete <branch>`, run the same unmerged-commit check against the remote ref.
- When asked to "clean up branches," produce the list of candidates with their unmerged-commit counts and let the user approve the deletions; do not bulk-delete on your own judgment.

**Red flags that you're about to violate this:**

- "-d failed, so the command I actually need is -D."
- "The branch is six months old; nobody wants it."
- "It says not fully merged, but that's probably just the squash-merge thing."
- "The user said clean up, and a clean repo has fewer branches."
- "I can always get it back from the reflog if I'm wrong."
