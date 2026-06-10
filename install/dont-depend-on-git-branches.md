### Don't Depend on Git Branches

NEVER point a dependency at a mutable git ref — a branch name, a fork's `main`, or a bare repo URL that defaults to HEAD. A branch dependency means "whatever that branch says at install time," which is a different package every week and a build failure the day the ref disappears.

- Strongly prefer a released version from the registry. If the fix you need is merged but unreleased, first check whether a release is imminent (open issues/milestones often say) — waiting one release beats carrying a git dependency.
- If a git dependency is genuinely unavoidable, pin it to a full commit SHA, never a branch: `github:user/lib#a1b2c3d4...`, `git+https://...@<sha>`. A commit is immutable; a branch is a moving target.
- Treat fork dependencies as a loud, temporary exception: comment in the manifest why the fork is needed, link the upstream PR or issue you're waiting on, and note what removing it depends on. A fork URL without an exit plan becomes permanent.
- Never depend on a stranger's fork for convenience. Installing `random-user/lib#patched` executes whatever that account pushes, forever after. If the patch matters, fork it into an organization you control and pin the SHA there.
- When you encounter an existing branch-pinned dependency while working, flag it — it's a build outage with an unknown date attached.

**Red flags that you're about to violate this:**
- "The fix is on main; I'll install straight from the repo until it's released."
- "Pointing at the branch means we get future fixes automatically."
- "This fork has exactly the patch we need."
- "The lockfile will pin it anyway, so the branch ref is fine."
- "It's temporary — we'll switch back to the registry version soon."
